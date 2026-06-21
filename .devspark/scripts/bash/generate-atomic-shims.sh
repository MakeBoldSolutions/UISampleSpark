#!/usr/bin/env bash
# Generate atomic-prompt shim files for every templates/commands/*.md.
#
# Exit codes:
#   0 - success (no drift, or shims (re)generated)
#   1 - drift detected with --check (CI gate)
#   2 - I/O failure
set -euo pipefail

CHECK=0
REPO_ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

COMMANDS_DIR="$REPO_ROOT/templates/commands"
ATOMIC_DIR="$REPO_ROOT/templates/prompts/atomic"

if [[ ! -d "$COMMANDS_DIR" ]]; then
  echo "commands dir not found: $COMMANDS_DIR" >&2
  exit 2
fi
mkdir -p "$ATOMIC_DIR"

drift=()
generated=0

shopt -s nullglob
for f in "$COMMANDS_DIR"/*.md; do
  cmd="$(basename "$f" .md)"
  shim="$ATOMIC_DIR/$cmd.md"

  description="Atomic shim for /devspark.${cmd}. Resolves to templates/commands/${cmd}.md."
  if [[ ${#description} -gt 200 ]]; then
    description="${description:0:197}..."
  fi

  body=$(cat <<EOF
---
id: $cmd
name: $cmd
audience: expert
exposed: false
category: legacy-command
description: $description
inputs: []
outputs: []
legacy_command: $cmd
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at \`templates/commands/$cmd.md\`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
EOF
)

  if [[ -f "$shim" ]]; then
    if ! diff -q <(printf "%s\n" "$body") "$shim" >/dev/null 2>&1; then
      drift+=("$cmd")
      if [[ "$CHECK" -eq 0 ]]; then
        printf "%s\n" "$body" > "$shim"
        generated=$((generated + 1))
      fi
    fi
  else
    drift+=("$cmd")
    if [[ "$CHECK" -eq 0 ]]; then
      printf "%s\n" "$body" > "$shim"
      generated=$((generated + 1))
    fi
  fi
done

if [[ "$CHECK" -eq 1 ]]; then
  if [[ ${#drift[@]} -gt 0 ]]; then
    echo "Atomic-shim drift detected for ${#drift[@]} command(s):"
    for d in "${drift[@]}"; do echo "  - $d"; done
    echo ""
    echo "Run scripts/bash/generate-atomic-shims.sh to regenerate."
    exit 1
  fi
  echo "No atomic-shim drift detected."
  exit 0
fi

echo "Generated/updated ${generated} atomic-prompt shim(s) under templates/prompts/atomic/."
exit 0
