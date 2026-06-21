#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

JSON_MODE=false
BASE_REF=""
HEAD_REF="HEAD"
FROM_DATE=""
TO_DATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=true
      shift
      ;;
    --base-ref)
      BASE_REF="$2"
      shift 2
      ;;
    --head-ref)
      HEAD_REF="$2"
      shift 2
      ;;
    --from)
      FROM_DATE="$2"
      shift 2
      ;;
    --to)
      TO_DATE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if ! has_git; then
  echo "ERROR: release-history-context requires git." >&2
  exit 1
fi

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo "ERROR: python3/python is required to generate JSON output." >&2
  exit 1
fi

REPO_ROOT=$(get_repo_root)

JSON_OUTPUT=$(
  "$PYTHON_CMD" - "$REPO_ROOT" "$BASE_REF" "$HEAD_REF" "$FROM_DATE" "$TO_DATE" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path


repo_root = Path(sys.argv[1])
base_ref = sys.argv[2]
head_ref = sys.argv[3]
from_date = sys.argv[4]
to_date = sys.argv[5]


def git_lines(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines() if line.strip()]


def git_text(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return ""
    return result.stdout


def read_tracked_file(git_path: str, head: str) -> str:
    full_path = repo_root / git_path
    if full_path.exists():
        return full_path.read_text(encoding="utf-8")
    return git_text("show", f"{head}:{git_path}")


def tasks_completed(content: str) -> bool:
    unchecked = len(re.findall(r"^\s*- \[ \]", content, flags=re.MULTILINE))
    checked = len(re.findall(r"^\s*- \[[xX]\]", content, flags=re.MULTILINE))
    return checked > 0 and unchecked == 0


def extract_pr_numbers(subject: str) -> list[int]:
    pr_numbers: set[int] = set()
    for match in re.findall(r"\(#(\d+)\)", subject):
        pr_numbers.add(int(match))
    merge_match = re.search(r"Merge pull request #(\d+)", subject)
    if merge_match:
        pr_numbers.add(int(merge_match.group(1)))
    return sorted(pr_numbers)


def parse_frontmatter_value(content: str, key: str) -> str:
    match = re.match(r"^---\n(.*?)\n---\n", content, flags=re.DOTALL)
    if not match:
        return ""
    frontmatter = match.group(1)
    key_match = re.search(rf"^{re.escape(key)}:\s*\"?([^\n\"]+)\"?$", frontmatter, flags=re.MULTILINE)
    return key_match.group(1).strip() if key_match else ""


def parse_stat(content: str, label: str) -> int:
    match = re.search(rf"^- {re.escape(label)}:\s*(\d+)", content, flags=re.MULTILINE)
    return int(match.group(1)) if match else 0


if not base_ref:
    tags = git_lines("describe", "--tags", "--abbrev=0")
    if tags:
        base_ref = tags[0].strip()

if not from_date and base_ref:
    tag_dates = git_lines("log", "-1", "--format=%cs", base_ref)
    if tag_dates:
        from_date = tag_dates[0]

if not to_date:
    to_date = git_lines("log", "-1", "--format=%cs", head_ref)[0] if git_lines("log", "-1", "--format=%cs", head_ref) else ""

range_spec = f"{base_ref}..{head_ref}" if base_ref else head_ref

base_sha_lines = git_lines("rev-parse", "--verify", base_ref) if base_ref else []
base_sha = base_sha_lines[0].strip() if base_sha_lines else ""
head_sha_lines = git_lines("rev-parse", "--verify", head_ref)
head_sha = head_sha_lines[0].strip() if head_sha_lines else ""

commit_args = ["log", "--date=iso-strict", "--pretty=format:%H%x09%h%x09%ad%x09%an%x09%s"]
if from_date:
    commit_args.append(f"--since={from_date}T00:00:00")
if to_date:
    commit_args.append(f"--until={to_date}T23:59:59")
commit_args.append(head_ref)

commit_lines = git_lines(*commit_args)
commits = []
merged_pr_numbers: set[int] = set()
for line in commit_lines:
    parts = line.split("\t", 4)
    if len(parts) < 5:
        continue
    pr_numbers = extract_pr_numbers(parts[4])
    merged_pr_numbers.update(pr_numbers)
    commits.append(
        {
            "sha": parts[0],
            "short_sha": parts[1],
            "date": parts[2],
            "author": parts[3],
            "subject": parts[4],
            "pr_numbers": pr_numbers,
        }
    )

changed_files_map: dict[tuple[str, str, str], dict[str, str]] = {}
for commit in commits:
    for line in git_lines("show", "--name-status", "--find-renames", "--format=", commit["sha"]):
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        status = parts[0]
        path = parts[1]
        previous_path = ""
        if (status.startswith("R") or status.startswith("C")) and len(parts) >= 3:
            previous_path = parts[1]
            path = parts[2]
        key = (status, path, previous_path)
        changed_files_map[key] = {
            "status": status,
            "path": path,
            "previous_path": previous_path,
        }

changed_files = list(changed_files_map.values())
contributors = sorted({commit["author"] for commit in commits if commit.get("author")})

spec_paths: dict[str, list[dict[str, str]]] = {}
quickfix_paths: dict[str, str] = {}
archive_moves_detected = False

for changed_file in changed_files:
    for candidate_path in (changed_file["path"], changed_file.get("previous_path", "")):
        if not candidate_path:
            continue
        if candidate_path.startswith(".archive/"):
            archive_moves_detected = True

        spec_match = re.match(r"^(?:\.archive/[^/]+/)?\.documentation/specs/([^/]+)/(tasks|spec|plan|research)\.md$", candidate_path)
        if spec_match:
            spec_name, kind = spec_match.groups()
            spec_paths.setdefault(spec_name, []).append({"path": candidate_path, "kind": kind})

        quickfix_match = re.match(r"^(?:\.archive/[^/]+/)?\.documentation/quickfixes/(QF-[^/]+)\.md$", candidate_path)
        if quickfix_match:
            quickfix_paths.setdefault(quickfix_match.group(1), candidate_path)

recovered_specs = []
for spec_name in sorted(spec_paths):
    ordered = sorted(
        spec_paths[spec_name],
        key=lambda item: (0 if item["kind"] == "tasks" else 1, 1 if item["path"].startswith(".archive/") else 0),
    )
    selected = ordered[0]
    completed = False
    for task_entry in (entry for entry in ordered if entry["kind"] == "tasks"):
        completed = tasks_completed(read_tracked_file(task_entry["path"], head_ref))
        if completed:
            selected = task_entry
            break
    recovered_specs.append(
        {
            "name": spec_name,
            "path": selected["path"],
            "completed": completed,
            "source": "archive-history" if selected["path"].startswith(".archive/") else "active-history",
        }
    )

recovered_quickfixes = [
    {
        "id": quickfix_id,
        "path": quickfix_paths[quickfix_id],
        "source": "archive-history" if quickfix_paths[quickfix_id].startswith(".archive/") else "active-history",
    }
    for quickfix_id in sorted(quickfix_paths)
]

review_paths = list((repo_root / ".documentation" / "specs" / "pr-review").glob("pr-*.md"))
archive_root = repo_root / ".archive"
if archive_root.exists():
    for batch_dir in archive_root.iterdir():
        if not batch_dir.is_dir() or not re.match(r"^\d{4}-\d{2}-\d{2}$", batch_dir.name):
            continue
        if from_date and batch_dir.name < from_date:
            continue
        if to_date and batch_dir.name > to_date:
            continue
        review_paths.extend((batch_dir / ".documentation" / "specs" / "pr-review").glob("pr-*.md"))

matched_reviews = []
for review_path in review_paths:
    content = review_path.read_text(encoding="utf-8")
    pr_number_text = parse_frontmatter_value(content, "pr_number") or re.search(r"pr-(\d+)\.md$", review_path.name).group(1)
    pr_number = int(pr_number_text)
    if pr_number not in merged_pr_numbers:
        continue
    matched_reviews.append(
        {
            "pr_number": pr_number,
            "path": review_path.relative_to(repo_root).as_posix(),
            "files_changed": parse_stat(content, "Files changed"),
            "tests_added": parse_stat(content, "Tests added"),
            "breaking_changes": parse_stat(content, "Breaking changes"),
            "resolved_high_findings": len(re.findall(r"^###\s+[HC]-\d+.*Resolved", content, flags=re.MULTILINE)),
        }
    )

pr_review_summary = {
    "matched_reviews": len(matched_reviews),
    "files_changed": sum(item["files_changed"] for item in matched_reviews),
    "tests_added": sum(item["tests_added"] for item in matched_reviews),
    "breaking_changes": sum(item["breaking_changes"] for item in matched_reviews),
    "resolved_high_findings": sum(item["resolved_high_findings"] for item in matched_reviews),
}

result = {
    "REPO_ROOT": repo_root.as_posix(),
    "BASE_REF": base_ref,
    "BASE_SHA": base_sha,
    "HEAD_REF": head_ref,
    "HEAD_SHA": head_sha,
    "RANGE_SPEC": range_spec,
    "RELEASE_FROM": from_date,
    "RELEASE_TO": to_date,
    "COMMITS": commits,
    "COMMIT_SUBJECTS": [commit["subject"] for commit in commits],
    "CONTRIBUTORS": contributors,
    "CHANGED_FILES": changed_files,
    "MERGED_PR_NUMBERS": sorted(merged_pr_numbers),
    "MERGED_PR_COUNT": len(merged_pr_numbers),
    "RECOVERED_SPECS": recovered_specs,
    "RECOVERED_QUICKFIXES": recovered_quickfixes,
    "PR_REVIEWS": matched_reviews,
    "PR_REVIEW_SUMMARY": pr_review_summary,
    "ARCHIVE_MOVES_DETECTED": archive_moves_detected,
}

print(json.dumps(result))
PY
)

if [[ "$JSON_MODE" == true ]]; then
  printf '%s\n' "$JSON_OUTPUT"
else
  printf 'Release History Context\n'
  printf '=======================\n'
  printf 'Repository: %s\n' "$REPO_ROOT"
  printf 'Range: %s\n' "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["RANGE_SPEC"])')"
  BASE_SHA_OUT="$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["BASE_SHA"])')"
  if [[ -n "$BASE_SHA_OUT" ]]; then printf 'Base SHA: %s\n' "$BASE_SHA_OUT"; fi
  printf 'Head SHA: %s\n' "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["HEAD_SHA"])')"
  printf 'Release Window: %s -> %s\n' \
    "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["RELEASE_FROM"])')" \
    "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["RELEASE_TO"])')"
  printf 'Merged PRs: %s\n' "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["MERGED_PR_COUNT"])')"
  printf 'Recovered Specs: %s\n' "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(len(json.load(sys.stdin)["RECOVERED_SPECS"]))')"
  printf 'Recovered Quickfixes: %s\n' "$(printf '%s' "$JSON_OUTPUT" | "$PYTHON_CMD" -c 'import json,sys; print(len(json.load(sys.stdin)["RECOVERED_QUICKFIXES"]))')"
fi