#!/usr/bin/env bash
# Three-tier resolution shim (bold-tool-plan.md §9.3). Given a path relative
# to the tool's content root (e.g. commands/plan/critic.md), reports which
# tier would serve it — user (.bold-user/{git-user-name}/) > team
# (bold-docs/overrides/) > source (.bold/) — first hit wins, whole-file
# replacement only (no fragment merging). Doubles as the `bold which`
# diagnostic: it reports the full chain, not just the winner.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/common.sh"

usage() {
  echo "Usage: bold-which.sh [--root <path>] <relative-path>" >&2
  exit 1
}

root_override=""
rel_path=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root_override="$2"; shift 2 ;;
    -*) usage ;;
    *) rel_path="$1"; shift ;;
  esac
done
[ -n "$rel_path" ] || usage

if [ -n "$root_override" ]; then
  repo_root="$root_override"
else
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

user_path="$repo_root/.bold-user/$(bold_user_slug "$repo_root")/$rel_path"
team_path="$repo_root/bold-docs/overrides/$rel_path"
source_path="$repo_root/.bold/$rel_path"

user_exists=false; [ -f "$user_path" ] && user_exists=true
team_exists=false; [ -f "$team_path" ] && team_exists=true
source_exists=false; [ -f "$source_path" ] && source_exists=true

resolved_tier="none"
resolved_path=""
if [ "$user_exists" = true ]; then
  resolved_tier="user"; resolved_path="$user_path"
elif [ "$team_exists" = true ]; then
  resolved_tier="team"; resolved_path="$team_path"
elif [ "$source_exists" = true ]; then
  resolved_tier="source"; resolved_path="$source_path"
fi

printf '{"path":"%s","resolved_tier":"%s","resolved_path":"%s","tiers":[{"tier":"user","path":"%s","exists":%s},{"tier":"team","path":"%s","exists":%s},{"tier":"source","path":"%s","exists":%s}]}\n' \
  "$(json_escape "$rel_path")" "$resolved_tier" "$(json_escape "$resolved_path")" \
  "$(json_escape "$user_path")" "$user_exists" \
  "$(json_escape "$team_path")" "$team_exists" \
  "$(json_escape "$source_path")" "$source_exists"
