#!/usr/bin/env bash
# Constitution evolution context gathering script
# Analyzes PR reviews and audits to propose constitution amendments

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Multi-app support (T091)
parse_app_context "$@" 2>/dev/null || true
if [[ -n "${DEVSPARK_APP_ID:-}" || "${DEVSPARK_REPO_SCOPE:-false}" == "true" ]]; then
    resolve_app_scope 2>/dev/null || true
    print_scope_summary >&2
fi

# Default values
JSON_MODE=false
FROM_PR=""
FROM_AUDIT=""
SUGGESTION=""
ACTION="analyze"
CAP_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --from-pr=*)
            FROM_PR="${1#*=}"
            shift
            ;;
        --from-pr)
            FROM_PR="$2"
            shift 2
            ;;
        --from-audit=*)
            FROM_AUDIT="${1#*=}"
            shift
            ;;
        --from-audit)
            FROM_AUDIT="$2"
            shift 2
            ;;
        suggest)
            ACTION="suggest"
            shift
            # Rest of args are the suggestion
            SUGGESTION="$*"
            break
            ;;
        approve)
            ACTION="approve"
            shift
            ;;
        reject)
            ACTION="reject"
            shift
            ;;
        CAP-*)
            CAP_ID="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Get repository context
REPO_ROOT=$(get_repo_root)
CONSTITUTION_PATH="$REPO_ROOT/.documentation/memory/constitution.md"
PR_REVIEW_DIR="$REPO_ROOT/.documentation/specs/pr-review"
AUDIT_DIR="$REPO_ROOT/.documentation/copilot/audit"
PROPOSALS_DIR="$REPO_ROOT/.documentation/memory/proposals"
HISTORY_FILE="$REPO_ROOT/.documentation/memory/constitution-history.md"

# Check constitution exists
CONSTITUTION_EXISTS="false"
CONSTITUTION_VERSION=""
if [[ -f "$CONSTITUTION_PATH" ]]; then
    CONSTITUTION_EXISTS="true"
    CONSTITUTION_VERSION=$(sed -nE 's/\*\*Version\*\*:[[:space:]]*([^[:space:]|]+).*/\1/p' "$CONSTITUTION_PATH" 2>/dev/null | head -1 || echo "1.0.0")
fi

# Extract constitution principles
CONSTITUTION_PRINCIPLES='[]'
if [[ -f "$CONSTITUTION_PATH" ]]; then
    CONSTITUTION_PRINCIPLES=$(grep -E '^###\s+' "$CONSTITUTION_PATH" 2>/dev/null | \
        sed 's/^###\s*//' | \
        jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
fi

# List PR reviews
PR_REVIEWS='[]'
PR_REVIEW_COUNT=0
if [[ -d "$PR_REVIEW_DIR" ]]; then
    PR_REVIEWS=$(ls "$PR_REVIEW_DIR"/pr-*.md 2>/dev/null | head -20 | while read -r f; do
        basename "$f" .md
    done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    PR_REVIEW_COUNT=$(ls "$PR_REVIEW_DIR"/pr-*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
fi

# List audit reports
AUDIT_REPORTS='[]'
AUDIT_COUNT=0
if [[ -d "$AUDIT_DIR" ]]; then
    AUDIT_REPORTS=$(ls "$AUDIT_DIR"/*_results.md 2>/dev/null | head -10 | while read -r f; do
        basename "$f"
    done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    AUDIT_COUNT=$(ls "$AUDIT_DIR"/*_results.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
fi

# List existing proposals
PROPOSALS='[]'
if [[ -d "$PROPOSALS_DIR" ]]; then
    PROPOSALS=$(ls "$PROPOSALS_DIR"/CAP-*.md 2>/dev/null | while read -r f; do
        basename "$f" .md
    done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
fi

# Calculate next proposal ID (CAP-YYYY-NNN format)
YEAR=$(date +%Y)
NEXT_CAP_NUM=1
if [[ -d "$PROPOSALS_DIR" ]]; then
    LATEST=$(find "$PROPOSALS_DIR" -maxdepth 1 -name "CAP-${YEAR}-[0-9]*.md" -exec basename {} \; 2>/dev/null | grep -E "^CAP-${YEAR}-[0-9]+\.md$" | sort -r | head -1 || echo "")
    if [[ -n "$LATEST" ]]; then
        CURRENT_NUM=$(echo "$LATEST" | sed -E "s/CAP-$YEAR-0*([0-9]+)\.md/\1/")
        NEXT_CAP_NUM=$((CURRENT_NUM + 1))
    fi
fi
NEXT_CAP_ID=$(printf "CAP-%s-%03d" "$YEAR" "$NEXT_CAP_NUM")

# Aggregate violation patterns from PR reviews
PATTERN_SUMMARY='[]'
CRITICAL_COUNT=0
HIGH_COUNT=0

if [[ -d "$PR_REVIEW_DIR" ]]; then
    # Count severity levels across all reviews
    CRITICAL_COUNT=$(grep -h "CRITICAL" "$PR_REVIEW_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    HIGH_COUNT=$(grep -h "HIGH" "$PR_REVIEW_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    # Extract principle violations (simplified pattern matching)
    PATTERN_SUMMARY=$(grep -h -E '^\| [A-Z]' "$PR_REVIEW_DIR"/*.md 2>/dev/null | \
        grep -Ev "Principle|Status|--" | \
        cut -d'|' -f2 | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        sort | uniq -c | sort -rn | head -10 | \
        awk '{print "{\"principle\": \"" $2 "\", \"count\": " $1 "}"}' | \
        jq -s '.' 2>/dev/null || echo '[]')
fi

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Output JSON if requested
if [[ "$JSON_MODE" == true ]]; then
    cat <<EOF
{
  "REPO_ROOT": "$REPO_ROOT",
  "CONSTITUTION_PATH": "$CONSTITUTION_PATH",
  "CONSTITUTION_EXISTS": $CONSTITUTION_EXISTS,
  "CONSTITUTION_VERSION": "$CONSTITUTION_VERSION",
  "CONSTITUTION_PRINCIPLES": $CONSTITUTION_PRINCIPLES,
  "PR_REVIEW_DIR": "$PR_REVIEW_DIR",
  "AUDIT_DIR": "$AUDIT_DIR",
  "PROPOSALS_DIR": "$PROPOSALS_DIR",
  "HISTORY_FILE": "$HISTORY_FILE",
  "PR_REVIEWS": $PR_REVIEWS,
  "PR_REVIEW_COUNT": $PR_REVIEW_COUNT,
  "AUDIT_REPORTS": $AUDIT_REPORTS,
  "AUDIT_COUNT": $AUDIT_COUNT,
  "PROPOSALS": $PROPOSALS,
  "NEXT_CAP_ID": "$NEXT_CAP_ID",
  "PATTERN_SUMMARY": $PATTERN_SUMMARY,
  "CRITICAL_COUNT": $CRITICAL_COUNT,
  "HIGH_COUNT": $HIGH_COUNT,
  "ACTION": "$ACTION",
  "CAP_ID": "$CAP_ID",
  "FROM_PR": "$FROM_PR",
  "FROM_AUDIT": "$FROM_AUDIT",
  "SUGGESTION": $(echo "$SUGGESTION" | jq -R -s '.'),
  "TIMESTAMP": "$TIMESTAMP"
}
EOF
else
    # Human-readable output
    echo "Constitution Evolution Context"
    echo "=============================="
    echo "Constitution: $CONSTITUTION_PATH (exists: $CONSTITUTION_EXISTS, version: $CONSTITUTION_VERSION)"
    echo "Principles: $(echo "$CONSTITUTION_PRINCIPLES" | jq 'length')"
    echo ""
    echo "PR Reviews: $PR_REVIEW_COUNT (analyzing last 20)"
    echo "Audit Reports: $AUDIT_COUNT (analyzing last 10)"
    echo "Existing Proposals: $(echo "$PROPOSALS" | jq 'length')"
    echo ""
    echo "Violation Summary:"
    echo "  Critical: $CRITICAL_COUNT"
    echo "  High: $HIGH_COUNT"
    echo ""
    echo "Action: $ACTION"
    echo "Next Proposal ID: $NEXT_CAP_ID"
fi
