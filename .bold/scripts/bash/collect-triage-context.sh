#!/usr/bin/env bash
# Collector for bold.plan (default/triage). Emits deterministic JSON facts —
# system doc inventory, active feature tiers/status, backbone principle
# status, and the project genome — so the triage prompt reasons over
# structured ground truth instead of re-deriving it from prose.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
docs_dir="$repo_root/bold-docs"

system_docs="$(collect_system_docs "$repo_root" "$docs_dir")"
active_features="$(collect_active_features "$docs_dir")"
backbone_principles="$(collect_backbone_principles "$docs_dir")"
stale_references="$(collect_stale_references "$repo_root" "$docs_dir")"

genome="null"
if [ -f "$docs_dir/project.json" ]; then
  genome="$(cat "$docs_dir/project.json")"
fi

printf '{"system_docs":%s,"active_features":%s,"backbone_principles":%s,"stale_references":%s,"genome":%s}\n' \
  "$system_docs" "$active_features" "$backbone_principles" "$stale_references" "$genome"
