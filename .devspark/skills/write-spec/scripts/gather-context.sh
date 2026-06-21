#!/usr/bin/env bash
# gather-context.sh — Gather repository context for the write-spec skill.
# Always exits 0. Always emits valid JSON to stdout.
# Records anything that could not be gathered in the skipped_context array.

set -euo pipefail

# JSON helpers — build result incrementally
CONSTITUTION_SUMMARY="null"
PRIOR_SPECS="[]"
SKIPPED_CONTEXT="[]"

add_skipped() {
    local item="$1"
    if [ "$SKIPPED_CONTEXT" = "[]" ]; then
        SKIPPED_CONTEXT="[\"$item\"]"
    else
        SKIPPED_CONTEXT="${SKIPPED_CONTEXT%]},\"$item\"]"
    fi
}

json_escape() {
    local s="$1"
    # Escape backslash, double quote, and control characters
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/ }"
    s="${s//$'\r'/ }"
    printf '%s' "$s"
}

# Detect git repository
REPO_ROOT=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
else
    add_skipped "no-git-repo"
fi

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$(pwd)"
fi

# Load constitution summary
CONSTITUTION_FOUND=false
for CONST_PATH in \
    "$REPO_ROOT/.documentation/memory/constitution.md" \
    "$REPO_ROOT/constitution.md"; do
    if [ -f "$CONST_PATH" ]; then
        # Extract first meaningful paragraph — first 10 non-empty, non-heading lines
        SUMMARY=""
        while IFS= read -r line; do
            trimmed="${line#"${line%%[! ]*}"}"
            if [ -n "$trimmed" ] && [ "${trimmed:0:1}" != "#" ]; then
                if [ -z "$SUMMARY" ]; then
                    SUMMARY="$trimmed"
                else
                    SUMMARY="$SUMMARY $trimmed"
                fi
            fi
            # Stop after collecting enough content
            word_count=$(echo "$SUMMARY" | wc -w)
            if [ "$word_count" -gt 80 ]; then
                break
            fi
        done < "$CONST_PATH" 2>/dev/null || true

        if [ -n "$SUMMARY" ]; then
            # Truncate to 500 chars
            if [ "${#SUMMARY}" -gt 500 ]; then
                SUMMARY="${SUMMARY:0:497}..."
            fi
            ESCAPED="$(json_escape "$SUMMARY")"
            CONSTITUTION_SUMMARY="\"$ESCAPED\""
            CONSTITUTION_FOUND=true
            break
        fi
    fi
done

if [ "$CONSTITUTION_FOUND" = false ]; then
    add_skipped "constitution-not-found"
fi

# Gather prior specs
SPECS_DIR="$REPO_ROOT/.documentation/specs"
if [ -d "$SPECS_DIR" ]; then
    SPECS_JSON=""
    while IFS= read -r -d '' spec_file; do
        folder_name="$(basename "$(dirname "$spec_file")")"
        # Extract title from first heading
        title_line=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^"# " ]]; then
                title_line="${line:2}"
                break
            fi
        done < "$spec_file" 2>/dev/null || true

        if [ -z "$title_line" ]; then
            title_line="$folder_name"
        fi

        escaped_name="$(json_escape "$folder_name")"
        escaped_title="$(json_escape "$title_line")"
        entry="{\"name\":\"$escaped_name\",\"title\":\"$escaped_title\"}"

        if [ -z "$SPECS_JSON" ]; then
            SPECS_JSON="$entry"
        else
            SPECS_JSON="$SPECS_JSON,$entry"
        fi
    done < <(find "$SPECS_DIR" -name "spec.md" -not -path "*/.archive/*" -print0 2>/dev/null | sort -z)

    if [ -n "$SPECS_JSON" ]; then
        PRIOR_SPECS="[$SPECS_JSON]"
    fi
else
    add_skipped "no-specs-dir"
fi

# Emit JSON — always exit 0
printf '{"constitution_summary":%s,"prior_specs":%s,"skipped_context":%s}\n' \
    "$CONSTITUTION_SUMMARY" \
    "$PRIOR_SPECS" \
    "$SKIPPED_CONTEXT"

exit 0
