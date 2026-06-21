#!/usr/bin/env bash
# Helper script for /devspark.address-pr-review
# --pr-id: parse review file and emit open findings
# --gate:  enforce staged-path isolation for code-only or review-only commits

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PR_ID=""
GATE=""
JSON_OUTPUT=false

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pr-id)
            PR_ID="$2"
            shift 2
            ;;
        --gate)
            GATE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
get_staged_paths() {
    git diff --cached --name-only 2>/dev/null || true
}

is_review_path() {
    [[ "$1" =~ ^\.documentation/specs/pr-review/pr-.*\.md$ ]]
}

write_gate_failure() {
    local message="$1"
    shift
    printf 'DevSpark: %s\n' "$message" >&2
    if [[ $# -gt 0 ]]; then
        printf 'Offending staged paths:\n' >&2
        for path in "$@"; do
            printf '  - %s\n' "$path" >&2
        done
    fi
    exit 1
}

# ---------------------------------------------------------------------------
# Gate mode
# ---------------------------------------------------------------------------
if [[ -n "$GATE" ]]; then
    mapfile -t STAGED < <(get_staged_paths)

    if [[ "$GATE" == "code-only" ]]; then
        review_staged=()
        for p in "${STAGED[@]:-}"; do
            is_review_path "$p" && review_staged+=("$p") || true
        done
        if [[ ${#review_staged[@]} -gt 0 ]]; then
            write_gate_failure \
                "Code commit gate failed. Review files must not be staged for code-only commits." \
                "${review_staged[@]}"
        fi

    elif [[ "$GATE" == "review-only" ]]; then
        non_review_staged=()
        for p in "${STAGED[@]:-}"; do
            is_review_path "$p" || non_review_staged+=("$p")
        done
        if [[ ${#non_review_staged[@]} -gt 0 ]]; then
            write_gate_failure \
                "Review commit gate failed. Only PR review markdown files may be staged." \
                "${non_review_staged[@]}"
        fi

    else
        printf 'DevSpark: Invalid --gate value "%s". Expected code-only or review-only.\n' "$GATE" >&2
        exit 1
    fi

    "$JSON_OUTPUT" && printf '{"gate":"%s","passed":true}\n' "$GATE" || printf "Gate '%s' passed.\n" "$GATE"
    exit 0
fi

# ---------------------------------------------------------------------------
# PR findings mode
# ---------------------------------------------------------------------------
if [[ -z "$PR_ID" ]]; then
    printf 'DevSpark: Provide --pr-id <N> or --gate <code-only|review-only>.\n' >&2
    exit 1
fi

# Strip leading #
NORMALIZED="${PR_ID#\#}"
if ! [[ "$NORMALIZED" =~ ^[0-9]+$ ]]; then
    printf 'DevSpark: Invalid PR id "%s". Expected a positive integer.\n' "$PR_ID" >&2
    exit 1
fi

REPO_ROOT="$(get_repo_root)"
REVIEW_FILE="$REPO_ROOT/.documentation/specs/pr-review/pr-${NORMALIZED}.md"

if [[ ! -f "$REVIEW_FILE" ]]; then
    printf 'DevSpark: Review file not found: %s\n' "$REVIEW_FILE" >&2
    exit 1
fi

# Parse open findings — lines matching: - [ ] **{C|H|M|L|CON}-NN**
findings_json="["
first=true
line_num=0

while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]]+\*\*((C|H|M|L|CON)-[0-9]{2})\*\* ]]; then
        finding_id="${BASH_REMATCH[1]}"
        severity="${BASH_REMATCH[2]}"
        escaped_line="${line//\"/\\\"}"
        "$first" || findings_json+=","
        findings_json+="{\"id\":\"$finding_id\",\"severity\":\"$severity\",\"line_number\":$line_num,\"line\":\"$escaped_line\"}"
        first=false
    fi
done < "$REVIEW_FILE"

findings_json+="]"

open_count=$(printf '%s' "$findings_json" | grep -o '"id"' | wc -l)

if "$JSON_OUTPUT"; then
    printf '{"pr_id":%s,"review_file":"%s","open_findings":%s,"open_count":%s}\n' \
        "$NORMALIZED" "$REVIEW_FILE" "$findings_json" "$open_count"
else
    printf 'Review file: %s\n' "$REVIEW_FILE"
    printf 'Open findings: %s\n' "$open_count"
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]]+\*\*((C|H|M|L|CON)-[0-9]{2})\*\* ]]; then
            printf -- '- %s\n' "${BASH_REMATCH[1]}"
        fi
    done < "$REVIEW_FILE"
fi
