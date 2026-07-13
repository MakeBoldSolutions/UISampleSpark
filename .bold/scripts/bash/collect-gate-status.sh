#!/usr/bin/env bash
# Collector for bold.build (default and status). Emits deterministic facts —
# per-feature ratified tier, backbone principle enforcement status, detected
# test-runner config, and working-tree cleanliness — so gates are decided
# from ground truth instead of re-derived by reading the tree by hand.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
docs_dir="$repo_root/bold-docs"
cd "$repo_root"

active_features="$(collect_active_features "$docs_dir")"
backbone_principles="$(collect_backbone_principles "$docs_dir")"
stale_references="$(collect_stale_references "$repo_root" "$docs_dir")"

known_test_configs=(jest.config.js jest.config.ts pytest.ini tox.ini .mocharc.json .mocharc.yml karma.conf.js phpunit.xml)
test_config_present=()
for f in "${known_test_configs[@]}"; do
  [ -e "$f" ] && test_config_present+=("$f")
done
while IFS= read -r f; do
  [ -n "$f" ] && test_config_present+=("$f")
done < <(find . -maxdepth 2 -iname '*.tests.csproj' -printf '%P\n' 2>/dev/null; printf '\n')

has_uncommitted_changes=false
if git rev-parse --git-dir >/dev/null 2>&1; then
  [ -n "$(git status --porcelain 2>/dev/null)" ] && has_uncommitted_changes=true
fi

printf '{"active_features":%s,"backbone_principles":%s,"stale_references":%s,"test_config_present":%s,"has_uncommitted_changes":%s}\n' \
  "$active_features" "$backbone_principles" "$stale_references" "$(json_array "${test_config_present[@]}")" "$has_uncommitted_changes"
