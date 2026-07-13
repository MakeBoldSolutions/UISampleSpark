#!/usr/bin/env bash
# Collector for bold.ship (default and review). Emits deterministic facts —
# branch position relative to the base branch, changed-file inventory,
# active feature tiers, and backbone status — so drafting or reviewing a PR
# starts from current, structured ground truth.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
docs_dir="$repo_root/bold-docs"
cd "$repo_root"

base_branch="main"
current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

commits_ahead=0
commits_behind=0
changed_files=()
if git rev-parse --verify "$base_branch" >/dev/null 2>&1 && [ "$current_branch" != "$base_branch" ]; then
  commits_ahead="$(git rev-list --count "$base_branch..HEAD" 2>/dev/null || echo 0)"
  commits_behind="$(git rev-list --count "HEAD..$base_branch" 2>/dev/null || echo 0)"
  while IFS= read -r f; do
    [ -n "$f" ] && changed_files+=("$f")
  done < <(git diff --name-only "$base_branch...HEAD" 2>/dev/null; printf '\n')
fi

has_uncommitted_changes=false
[ -n "$(git status --porcelain 2>/dev/null)" ] && has_uncommitted_changes=true

active_features="$(collect_active_features "$docs_dir")"
backbone_principles="$(collect_backbone_principles "$docs_dir")"

printf '{"base_branch":"%s","current_branch":"%s","commits_ahead":%s,"commits_behind":%s,"changed_files":%s,"has_uncommitted_changes":%s,"active_features":%s,"backbone_principles":%s}\n' \
  "$(json_escape "$base_branch")" "$(json_escape "$current_branch")" "$commits_ahead" "$commits_behind" \
  "$(json_array "${changed_files[@]}")" "$has_uncommitted_changes" "$active_features" "$backbone_principles"
