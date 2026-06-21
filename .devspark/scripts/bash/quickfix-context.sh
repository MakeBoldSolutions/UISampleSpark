#!/usr/bin/env bash
# Quickfix context gathering script
# Supports rapid bug fixes and small features without full spec overhead

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Multi-app support (T083)
parse_app_context "$@" 2>/dev/null || true
if [[ -n "${DEVSPARK_APP_ID:-}" || "${DEVSPARK_REPO_SCOPE:-false}" == "true" ]]; then
    resolve_app_scope 2>/dev/null || true
    print_scope_summary >&2
fi

# Default values
JSON_MODE=false
QUICKFIX_ID=""
ACTION="create"
DESCRIPTION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        complete)
            ACTION="complete"
            shift
            ;;
        list)
            ACTION="list"
            shift
            ;;
        QF-*)
            QUICKFIX_ID="$1"
            shift
            ;;
        *)
            # Accumulate description
            if [[ -n "$DESCRIPTION" ]]; then
                DESCRIPTION="$DESCRIPTION $1"
            else
                DESCRIPTION="$1"
            fi
            shift
            ;;
    esac
done

# Get repository context
REPO_ROOT=$(get_repo_root)
CONSTITUTION_PATH="$REPO_ROOT/.documentation/memory/constitution.md"
QUICKFIX_DIR="$REPO_ROOT/.documentation/quickfixes"
CURRENT_BRANCH=$(get_current_branch)

# Check constitution exists
CONSTITUTION_EXISTS="false"
if [[ -f "$CONSTITUTION_PATH" ]]; then
    CONSTITUTION_EXISTS="true"
fi

# Calculate next quickfix ID (QF-YYYY-NNN format)
YEAR=$(date +%Y)
NEXT_NUM=1
if [[ -d "$QUICKFIX_DIR" ]]; then
    LATEST=$(find "$QUICKFIX_DIR" -maxdepth 1 -name "QF-${YEAR}-[0-9]*.md" -exec basename {} \; 2>/dev/null | grep -E "^QF-${YEAR}-[0-9]+\.md$" | sort -r | head -1 || echo "")
    if [[ -n "$LATEST" ]]; then
        # Extract number from filename like QF-2026-001.md
        CURRENT_NUM=$(echo "$LATEST" | sed -E "s/QF-$YEAR-0*([0-9]+)\.md/\1/")
        NEXT_NUM=$((CURRENT_NUM + 1))
    fi
fi
NEXT_ID=$(printf "QF-%s-%03d" "$YEAR" "$NEXT_NUM")

# Get git user for attribution
GIT_USER="unknown"
if has_git; then
    GIT_USER=$(git config user.name 2>/dev/null || echo "unknown")
fi

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Auto-classify based on description keywords
CLASSIFICATION="minor-feature"
RISK_LEVEL="LOW"
MAX_EFFORT="4 hours"

if [[ -n "$DESCRIPTION" ]]; then
    DESC_LOWER=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')

    if [[ "$DESC_LOWER" =~ (urgent|critical|emergency|production|hotfix) ]]; then
        CLASSIFICATION="hotfix"
        RISK_LEVEL="HIGH"
        MAX_EFFORT="2 hours"
    elif [[ "$DESC_LOWER" =~ (fix|bug|error|crash|broken|issue|null|exception) ]]; then
        CLASSIFICATION="bug-fix"
        RISK_LEVEL="MEDIUM"
        MAX_EFFORT="4 hours"
    elif [[ "$DESC_LOWER" =~ (config|setting|environment|flag|env) ]]; then
        CLASSIFICATION="config-change"
        RISK_LEVEL="LOW"
        MAX_EFFORT="1 hour"
    elif [[ "$DESC_LOWER" =~ (doc|readme|comment|documentation) ]]; then
        CLASSIFICATION="docs-update"
        RISK_LEVEL="LOW"
        MAX_EFFORT="2 hours"
    fi
fi

# List existing quickfixes for list action
QUICKFIXES_JSON="[]"
if [[ -d "$QUICKFIX_DIR" ]]; then
    QUICKFIXES_JSON=$(ls "$QUICKFIX_DIR"/*.md 2>/dev/null | while read -r f; do
        basename "$f" .md
    done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
fi

# Output JSON if requested
if [[ "$JSON_MODE" == true ]]; then
    cat <<EOF
{
  "REPO_ROOT": "$REPO_ROOT",
  "CONSTITUTION_PATH": "$CONSTITUTION_PATH",
  "CONSTITUTION_EXISTS": $CONSTITUTION_EXISTS,
  "QUICKFIX_DIR": "$QUICKFIX_DIR",
  "CURRENT_BRANCH": "$CURRENT_BRANCH",
  "NEXT_ID": "$NEXT_ID",
  "GIT_USER": "$GIT_USER",
  "TIMESTAMP": "$TIMESTAMP",
  "ACTION": "$ACTION",
  "QUICKFIX_ID": "$QUICKFIX_ID",
  "DESCRIPTION": $(echo "$DESCRIPTION" | jq -R -s '.'),
  "CLASSIFICATION": "$CLASSIFICATION",
  "RISK_LEVEL": "$RISK_LEVEL",
  "MAX_EFFORT": "$MAX_EFFORT",
  "QUICKFIXES": $QUICKFIXES_JSON
}
EOF
else
    # Human-readable output
    echo "Quickfix Context"
    echo "================"
    echo "Repository: $REPO_ROOT"
    echo "Constitution: $CONSTITUTION_PATH (exists: $CONSTITUTION_EXISTS)"
    echo "Quickfix Directory: $QUICKFIX_DIR"
    echo "Current Branch: $CURRENT_BRANCH"
    echo "Next ID: $NEXT_ID"
    echo "Action: $ACTION"
    if [[ -n "$DESCRIPTION" ]]; then
        echo "Description: $DESCRIPTION"
        echo "Classification: $CLASSIFICATION"
        echo "Risk Level: $RISK_LEVEL"
        echo "Max Effort: $MAX_EFFORT"
    fi
fi
