#!/usr/bin/env bash
# Convenience wrapper that forwards arguments to `python -m devspark_cli run`.
#
# Usage:
#   scripts/bash/run-workflow.sh create-spec
#   scripts/bash/run-workflow.sh execute-plan --autonomy assisted
set -euo pipefail
exec python -m devspark_cli run "$@"
