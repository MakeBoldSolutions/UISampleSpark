#!/usr/bin/env bash
# Collector for bold.ship harvest. Emits deterministic facts — active feature
# tiers/status, the file inventory inside each feature dir, and the current
# system/ doc set — so classification (durable vs work product) starts from
# a complete inventory instead of the agent re-listing directories.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
docs_dir="$repo_root/bold-docs"

active_features="$(collect_active_features "$docs_dir")"
system_docs="$(collect_system_docs "$repo_root" "$docs_dir")"

feature_files="[]"
if [ -d "$docs_dir/features" ]; then
  entries=()
  for dir in "$docs_dir/features"/*/; do
    [ -d "$dir" ] || continue
    id="$(basename "$dir")"
    files=()
    while IFS= read -r f; do
      [ -n "$f" ] && files+=("$f")
    done < <(find "$dir" -type f -printf '%P\n' 2>/dev/null | sort; printf '\n')
    entries+=("{\"id\":\"$(json_escape "$id")\",\"files\":$(json_array "${files[@]}")}")
  done
  if [ "${#entries[@]}" -gt 0 ]; then
    feature_files="[$(IFS=,; echo "${entries[*]}")]"
  fi
fi

printf '{"active_features":%s,"system_docs":%s,"feature_files":%s}\n' \
  "$active_features" "$system_docs" "$feature_files"
