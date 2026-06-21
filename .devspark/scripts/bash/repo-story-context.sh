#!/usr/bin/env bash
# Build repository history context for /devspark.repo-story
# Usage:
#   repo-story-context.sh [--output <path>] [--months <n>] [--scope <full|velocity|quality|business|team>] [--compare-baseline YYYY-MM] [--stdout]

set -euo pipefail

# Multi-app support (T087)
source "$(dirname "${BASH_SOURCE[0]}")/common.sh" 2>/dev/null || true
parse_app_context "$@" 2>/dev/null || true
if [[ -n "${DEVSPARK_APP_ID:-}" || "${DEVSPARK_REPO_SCOPE:-false}" == "true" ]]; then
    resolve_app_scope 2>/dev/null || true
    print_scope_summary >&2
fi

OUTPUT_PATH=".documentation/repo-story/history.json"
PRINT_STDOUT=false
MONTHS=12
SCOPE="full"
COMPARE_BASELINE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
	--output)
	  OUTPUT_PATH="$2"
	  shift 2
	  ;;
	--months)
	  MONTHS="$2"
	  shift 2
	  ;;
	--scope)
	  SCOPE="$2"
	  shift 2
	  ;;
	--compare-baseline)
	  COMPARE_BASELINE="$2"
	  shift 2
	  ;;
	--stdout)
	  PRINT_STDOUT=true
	  shift
	  ;;
	--help|-h)
	  cat <<'EOF'
Usage: repo-story-context.sh [--output <path>] [--months <n>] [--scope <full|velocity|quality|business|team>] [--compare-baseline YYYY-MM] [--stdout]

Generates a history.json file with full-repository historical context:
- commit timeline
- contributor trends
- tag milestones
- README evolution
- file change hotspots

Options:
	--output <path>           Output JSON path (default: .documentation/repo-story/history.json)
	--months <n>              Audit window in months from now (default: 12)
	--scope <name>            full | velocity | quality | business | team
	--compare-baseline YYYY-MM Optional baseline month override
	--stdout                  Also print generated JSON to stdout
EOF
	  exit 0
	  ;;
	*)
	  echo "Unknown option: $1" >&2
	  exit 1
	  ;;
  esac
done

if [[ ! "$MONTHS" =~ ^[0-9]+$ ]] || [[ "$MONTHS" -lt 1 ]]; then
	echo "ERROR: --months must be a positive integer." >&2
	exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repository." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo "ERROR: python3/python is required to generate JSON output." >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

git shortlog -sn --all | sed -E 's/^\s*([0-9]+)\s+(.+)$/\1\t\2/' > "$tmp_dir/contributors.tsv"
git log --all --date=format:'%Y' --format='%ad' | sort | uniq -c > "$tmp_dir/years.txt"
git log --all --date=format:'%Y-%m' --format='%ad' | sort | uniq -c > "$tmp_dir/months.txt"

if git ls-files --error-unmatch README.md >/dev/null 2>&1; then
  git log --all --follow --date=iso-strict --pretty=format:'%H%x09%ad%x09%an%x09%s' -- README.md > "$tmp_dir/readme_commits.tsv"
else
  : > "$tmp_dir/readme_commits.tsv"
fi

git log --all --name-only --pretty=format: | sed '/^$/d' | sort | uniq -c | sort -nr | head -n 50 > "$tmp_dir/hotspots.txt"
git for-each-ref refs/tags --sort=creatordate --format='%(refname:short)%x09%(creatordate:iso-strict)%x09%(objectname:short)' > "$tmp_dir/tags.tsv"
git log --all --pretty=format:'%s' > "$tmp_dir/subjects.txt"
git log --all -n 40 --date=iso-strict --pretty=format:'%H%x09%ad%x09%an%x09%s' > "$tmp_dir/recent_commits.tsv"

first_commit_sha=$(git rev-list --max-parents=0 HEAD | tail -n 1)
last_commit_sha=$(git rev-parse HEAD)

default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
if [[ -z "$default_branch" ]]; then
  if git show-ref --verify --quiet refs/heads/main; then
	default_branch="main"
  elif git show-ref --verify --quiet refs/heads/master; then
	default_branch="master"
  else
	default_branch=$(git rev-parse --abbrev-ref HEAD)
  fi
fi

total_commits=$(git rev-list --count --all)
total_contributors=$(wc -l < "$tmp_dir/contributors.tsv" | tr -d ' ')
total_tags=$(git tag --list | wc -l | tr -d ' ')

audit_start_month=$(date -u -d "-$MONTHS months" +"%Y-%m" 2>/dev/null || true)
if [[ -z "$audit_start_month" ]]; then
	audit_start_month=$("$PYTHON_CMD" - "$MONTHS" <<'PY'
import datetime as dt
import sys

months = int(sys.argv[1])
now = dt.datetime.utcnow()
year = now.year
month = now.month - months
while month <= 0:
		month += 12
		year -= 1
print(f"{year:04d}-{month:02d}")
PY
)
fi

audit_end_month=$(date -u +"%Y-%m")
baseline_month="$COMPARE_BASELINE"
if [[ -z "$baseline_month" ]]; then
	baseline_month="$audit_start_month"
fi

"$PYTHON_CMD" - "$REPO_ROOT" "$OUTPUT_PATH" "$tmp_dir" "$first_commit_sha" "$last_commit_sha" "$default_branch" "$total_commits" "$total_contributors" "$total_tags" "$MONTHS" "$SCOPE" "$baseline_month" "$audit_start_month" "$audit_end_month" <<'PY'
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys


repo_root = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
tmp_dir = pathlib.Path(sys.argv[3])
first_commit_sha = sys.argv[4]
last_commit_sha = sys.argv[5]
default_branch = sys.argv[6]
total_commits = int(sys.argv[7])
total_contributors = int(sys.argv[8])
total_tags = int(sys.argv[9])
months = int(sys.argv[10])
scope = sys.argv[11]
baseline_month = sys.argv[12]
audit_start_month = sys.argv[13]
audit_end_month = sys.argv[14]


def run_git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=repo_root, text=True).strip()


def parse_count_lines(path: pathlib.Path):
	results = []
	if not path.exists():
		return results
	for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
		m = re.match(r"^\s*(\d+)\s+(.+)$", raw)
		if m:
			results.append({"key": m.group(2), "count": int(m.group(1))})
	return results


def parse_tsv(path: pathlib.Path, columns: int):
	rows = []
	if not path.exists():
		return rows
	for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
		parts = raw.split("\t")
		if len(parts) >= columns:
			rows.append(parts)
	return rows


def get_commit_meta(sha: str):
	line = run_git("show", "-s", "--date=iso-strict", "--format=%H%x09%ad%x09%an%x09%s", sha)
	parts = line.split("\t", 3)
	return {
		"sha": parts[0],
		"date": parts[1],
		"author": parts[2],
		"subject": parts[3] if len(parts) > 3 else "",
	}


contributors = []
for row in parse_tsv(tmp_dir / "contributors.tsv", 2):
	contributors.append({"commits": int(row[0]), "name": row[1]})

commits_by_year = {item["key"]: item["count"] for item in parse_count_lines(tmp_dir / "years.txt")}
commits_by_month = {item["key"]: item["count"] for item in parse_count_lines(tmp_dir / "months.txt")}

readme_history = []
for row in parse_tsv(tmp_dir / "readme_commits.tsv", 4):
	readme_history.append({
		"sha": row[0],
		"date": row[1],
		"author": row[2],
		"subject": row[3],
	})

hotspots = []
for item in parse_count_lines(tmp_dir / "hotspots.txt"):
	hotspots.append({"path": item["key"], "changes": item["count"]})

tags = []
for row in parse_tsv(tmp_dir / "tags.tsv", 3):
	tags.append({"tag": row[0], "date": row[1], "sha": row[2]})

recent_commits = []
for row in parse_tsv(tmp_dir / "recent_commits.tsv", 4):
	recent_commits.append({
		"sha": row[0],
		"date": row[1],
		"author": row[2],
		"subject": row[3],
	})

subjects = (tmp_dir / "subjects.txt").read_text(encoding="utf-8", errors="replace").splitlines() if (tmp_dir / "subjects.txt").exists() else []
type_counts = {
	"features": 0,
	"fixes": 0,
	"docs": 0,
	"refactor": 0,
	"tests": 0,
	"ci_build": 0,
	"chore": 0,
	"other": 0,
}
for s in subjects:
	text = s.lower()
	if any(k in text for k in ["feat", "feature", "add ", "introduce"]):
		type_counts["features"] += 1
	elif any(k in text for k in ["fix", "bug", "hotfix", "patch"]):
		type_counts["fixes"] += 1
	elif any(k in text for k in ["doc", "readme", "guide", "wiki"]):
		type_counts["docs"] += 1
	elif any(k in text for k in ["refactor", "restructure", "cleanup"]):
		type_counts["refactor"] += 1
	elif any(k in text for k in ["test", "spec", "coverage"]):
		type_counts["tests"] += 1
	elif any(k in text for k in ["ci", "build", "workflow", "pipeline"]):
		type_counts["ci_build"] += 1
	elif any(k in text for k in ["chore", "deps", "bump", "upgrade"]):
		type_counts["chore"] += 1
	else:
		type_counts["other"] += 1

languages = {
	"python": bool(list(repo_root.glob("**/*.py"))),
	"javascript": bool(list(repo_root.glob("**/*.js"))),
	"typescript": bool(list(repo_root.glob("**/*.ts"))),
	"powershell": bool(list(repo_root.glob("**/*.ps1"))),
	"shell": bool(list(repo_root.glob("**/*.sh"))),
	"markdown": bool(list(repo_root.glob("**/*.md"))),
}

first_meta = get_commit_meta(first_commit_sha)
last_meta = get_commit_meta(last_commit_sha)

span_days = None
try:
	start = dt.datetime.fromisoformat(first_meta["date"].replace("Z", "+00:00"))
	end = dt.datetime.fromisoformat(last_meta["date"].replace("Z", "+00:00"))
	span_days = max(0, (end - start).days)
except Exception:
	pass

history = {
	"generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
	"audit_parameters": {
		"months": months,
		"scope": scope,
		"compare_baseline": baseline_month,
		"start_month": audit_start_month,
		"end_month": audit_end_month,
	},
	"repo": {
		"name": repo_root.name,
		"root": str(repo_root),
		"remote_origin": run_git("config", "--get", "remote.origin.url") if True else "",
		"default_branch": default_branch,
	},
	"summary": {
		"total_commits": total_commits,
		"total_contributors": total_contributors,
		"total_tags": total_tags,
		"history_span_days": span_days,
	},
	"timeline": {
		"first_commit": first_meta,
		"latest_commit": last_meta,
		"commits_by_year": commits_by_year,
		"commits_by_month": commits_by_month,
	},
	"contributors": {
		"top": contributors[:25],
		"all_count": total_contributors,
	},
	"milestones": {
		"tags": tags,
		"readme_evolution": {
			"total_readme_commits": len(readme_history),
			"commits": readme_history[:200],
		},
	},
	"change_patterns": {
		"subject_type_estimates": type_counts,
		"hotspots": hotspots,
	},
	"technical_signals": {
		"language_presence": languages,
		"has_pyproject_toml": (repo_root / "pyproject.toml").exists(),
		"has_package_json": (repo_root / "package.json").exists(),
		"has_dockerfile": any(repo_root.glob("**/Dockerfile*")),
		"has_github_actions": (repo_root / ".github" / "workflows").exists(),
	},
	"recent": {
		"commits": recent_commits,
	},
}

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(json.dumps(history, indent=2), encoding="utf-8")
print(str(output_path))
PY

if [[ "$PRINT_STDOUT" == true ]]; then
  cat "$OUTPUT_PATH"
fi

echo "history.json written to: $OUTPUT_PATH"
