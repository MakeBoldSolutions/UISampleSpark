#!/usr/bin/env bash
# Collector for bold.plan init. Emits deterministic facts about which entry
# path applies — legacy methodology install present, existing bold install,
# and repo file counts — so init doesn't have to re-derive them by hand.
set -euo pipefail

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

has_devspark=false
[ -d "$repo_root/.devspark" ] && has_devspark=true

has_documentation_dir=false
[ -d "$repo_root/.documentation" ] && has_documentation_dir=true

has_bold_docs=false
[ -f "$repo_root/bold-docs/backbone.md" ] && has_bold_docs=true

total_files=$(find "$repo_root" -type f -not -path "$repo_root/.git/*" | wc -l | tr -d ' ')
non_hidden_files=$(find "$repo_root" -type f -not -path "$repo_root/.git/*" -not -path '*/.*' | wc -l | tr -d ' ')

printf '{"has_devspark":%s,"has_documentation_dir":%s,"has_bold_docs":%s,"total_files":%s,"non_hidden_files":%s}\n' \
  "$has_devspark" "$has_documentation_dir" "$has_bold_docs" "$total_files" "$non_hidden_files"
