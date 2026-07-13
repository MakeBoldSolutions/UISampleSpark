#!/usr/bin/env bash
# Collector for bold.plan discover. Emits deterministic facts about codified
# decisions already present in the repo — config files, CI workflows,
# dependency manifests, contribution docs, and recent commit history — so
# discover reasons over inventory instead of re-scanning the tree itself.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

root_override=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root_override="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -n "$root_override" ]; then
  repo_root="$root_override"
else
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$repo_root"

known_configs=(.editorconfig .eslintrc .eslintrc.json .eslintrc.js .eslintrc.cjs .eslintrc.yml \
  .prettierrc .prettierrc.json .prettierrc.js tsconfig.json pyproject.toml .flake8 setup.cfg \
  Dockerfile docker-compose.yml .pre-commit-config.yaml)
config_files_present=()
for f in "${known_configs[@]}"; do
  [ -e "$f" ] && config_files_present+=("$f")
done

known_manifests=(package.json requirements.txt Gemfile go.mod pom.xml)
dependency_manifests_present=()
for f in "${known_manifests[@]}"; do
  [ -e "$f" ] && dependency_manifests_present+=("$f")
done
while IFS= read -r f; do
  [ -n "$f" ] && dependency_manifests_present+=("$f")
done < <(find . -maxdepth 2 -name '*.csproj' -printf '%P\n' 2>/dev/null; printf '\n')

ci_workflows=()
if [ -d .github/workflows ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && ci_workflows+=(".github/workflows/$f")
  done < <(find .github/workflows -type f -printf '%P\n' 2>/dev/null; printf '\n')
fi

has_contributing=false
[ -f CONTRIBUTING.md ] && has_contributing=true

has_pr_template=false
[ -f .github/PULL_REQUEST_TEMPLATE.md ] && has_pr_template=true

recent_commit_messages=()
if [ -e "$repo_root/.git" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && recent_commit_messages+=("$line")
  done < <(git -C "$repo_root" log -20 --pretty=format:'%s' 2>/dev/null; printf '\n')
fi

printf '{"config_files_present":%s,"dependency_manifests_present":%s,"ci_workflows":%s,"has_contributing":%s,"has_pr_template":%s,"recent_commit_messages":%s}\n' \
  "$(json_array "${config_files_present[@]}")" \
  "$(json_array "${dependency_manifests_present[@]}")" \
  "$(json_array "${ci_workflows[@]}")" \
  "$has_contributing" "$has_pr_template" \
  "$(json_array "${recent_commit_messages[@]}")"
