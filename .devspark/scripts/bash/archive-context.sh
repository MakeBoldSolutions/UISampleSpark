#!/usr/bin/env bash
# Deprecated compatibility wrapper for the legacy archive-context pre-scan.
# /devspark.archive now routes through /devspark.harvest. This wrapper calls
# harvest with docs scope and reshapes the result into the old archive-context
# contract for one migration window.

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "ERROR: python3/python is required to generate JSON output." >&2
    exit 1
fi

JSON_MODE=false
INCLUDE_FULL_INVENTORY=false
SAMPLE_LIMIT=50

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --include-full-inventory)
            INCLUDE_FULL_INVENTORY=true
            shift
            ;;
        --sample-limit=*)
            SAMPLE_LIMIT="${1#--sample-limit=}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [[ "$SAMPLE_LIMIT" -lt 1 ]]; then
    SAMPLE_LIMIT=50
fi

REPO_ROOT=$(get_repo_root)
ARCHIVE_BASE="$REPO_ROOT/.archive"
ARCHIVE_DIR=".archive/$(date +%Y-%m-%d)"
GUIDE_PATH=".documentation/Guide.md"
CHANGELOG_PATH="CHANGELOG.md"
GUIDE_EXISTS=false
CHANGELOG_EXISTS=false
ARCHIVE_EXISTS=false
[[ -f "$REPO_ROOT/$GUIDE_PATH" ]] && GUIDE_EXISTS=true
[[ -f "$REPO_ROOT/$CHANGELOG_PATH" ]] && CHANGELOG_EXISTS=true
[[ -d "$ARCHIVE_BASE" ]] && ARCHIVE_EXISTS=true

EFFECTIVE_SAMPLE_LIMIT="$SAMPLE_LIMIT"
if [[ "$INCLUDE_FULL_INVENTORY" == true && "$EFFECTIVE_SAMPLE_LIMIT" -lt 10000 ]]; then
    EFFECTIVE_SAMPLE_LIMIT=10000
fi

HARVEST_JSON=$("$SCRIPT_DIR/harvest.sh" --scope=docs --json --sample-limit="$EFFECTIVE_SAMPLE_LIMIT")

tmp_dir=$(mktemp -d)
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

HARVEST_JSON_FILE="$tmp_dir/harvest.json"
ARCHIVES_FILE="$tmp_dir/existing_archives.txt"

printf '%s' "$HARVEST_JSON" > "$HARVEST_JSON_FILE"

if [[ -d "$ARCHIVE_BASE" ]]; then
    find "$ARCHIVE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
        | sed "s|$REPO_ROOT/||" \
        | sort > "$ARCHIVES_FILE"
else
    : > "$ARCHIVES_FILE"
fi

JSON_OUTPUT=$("$PYTHON_CMD" - "$HARVEST_JSON_FILE" "$ARCHIVES_FILE" "$GUIDE_PATH" "$CHANGELOG_PATH" "$ARCHIVE_DIR" "$ARCHIVE_EXISTS" "$GUIDE_EXISTS" "$CHANGELOG_EXISTS" "$SAMPLE_LIMIT" "$INCLUDE_FULL_INVENTORY" <<'PY'
import json
import sys


def read_lines(path: str) -> list[str]:
    with open(path, encoding="utf-8") as handle:
        return [line.strip() for line in handle if line.strip()]


harvest_path, archives_path, guide_path, changelog_path, archive_dir, archive_exists, guide_exists, changelog_exists, sample_limit, include_full_inventory = sys.argv[1:]

with open(harvest_path, encoding="utf-8") as handle:
    harvest = json.load(handle)

existing_archives = read_lines(archives_path)
sample_limit_int = int(sample_limit)
include_full_inventory_bool = include_full_inventory.lower() == "true"


def sample_paths(entries: list[dict]) -> list[str]:
    return [entry["path"] for entry in entries[:sample_limit_int]]


def all_paths(entries: list[dict]) -> list[str]:
    return [entry["path"] for entry in entries]


result = {
    "REPO_ROOT": harvest["repo_root"],
    "TIMESTAMP": harvest["harvest_timestamp"],
    "ARCHIVE_DIR": archive_dir,
    "ARCHIVE_EXISTS": archive_exists.lower() == "true",
    "EXISTING_ARCHIVES": existing_archives[:sample_limit_int],
    "EXISTING_ARCHIVES_COUNT": len(existing_archives),
    "GUIDE_PATH": guide_path,
    "GUIDE_EXISTS": guide_exists.lower() == "true",
    "CHANGELOG_PATH": changelog_path,
    "CHANGELOG_EXISTS": changelog_exists.lower() == "true",
    "SAMPLE_LIMIT": sample_limit_int,
    "INCLUDE_FULL_INVENTORY": include_full_inventory_bool,
    "CANDIDATE_COUNTS": {
        "drafts": len(harvest["docs"]["stale_drafts"]),
        "session_docs": len(harvest["docs"]["session_notes"]),
        "implementation_plans": len(harvest["docs"]["impl_plans"]),
        "release_docs": len(harvest["docs"]["release_docs"]),
        "quickfix_records": len(harvest["docs"]["quickfix_records"]),
        "pr_reviews": len(harvest["docs"]["completed_reviews"]),
    },
    "CANDIDATES": {
        "drafts": sample_paths(harvest["docs"]["stale_drafts"]),
        "session_docs": sample_paths(harvest["docs"]["session_notes"]),
        "implementation_plans": sample_paths(harvest["docs"]["impl_plans"]),
        "release_docs": sample_paths(harvest["docs"]["release_docs"]),
        "quickfix_records": sample_paths(harvest["docs"]["quickfix_records"]),
        "pr_reviews": sample_paths(harvest["docs"]["completed_reviews"]),
    },
    "CURRENT_DOCS": sample_paths(harvest["docs"]["living_reference"]),
    "CURRENT_DOCS_COUNT": len(harvest["docs"]["living_reference"]),
    "FULL_INVENTORY": None,
}

if include_full_inventory_bool:
    result["FULL_INVENTORY"] = {
        "existing_archives": existing_archives,
        "candidates": {
            "drafts": all_paths(harvest["docs"]["stale_drafts"]),
            "session_docs": all_paths(harvest["docs"]["session_notes"]),
            "implementation_plans": all_paths(harvest["docs"]["impl_plans"]),
            "release_docs": all_paths(harvest["docs"]["release_docs"]),
            "quickfix_records": all_paths(harvest["docs"]["quickfix_records"]),
            "pr_reviews": all_paths(harvest["docs"]["completed_reviews"]),
        },
        "current_docs": all_paths(harvest["docs"]["living_reference"]),
    }

print(json.dumps(result))
PY
)

if [[ "$JSON_MODE" == true ]]; then
    printf '%s\n' "$JSON_OUTPUT"
else
    echo "Archive Context"
    echo "==============="
    REPO_ROOT_VALUE=$("$PYTHON_CMD" -c 'import json,sys; print(json.load(sys.stdin)["REPO_ROOT"])' <<<"$JSON_OUTPUT")
    ARCHIVE_DIR_VALUE=$("$PYTHON_CMD" -c 'import json,sys; data=json.load(sys.stdin); print("{} (exists: {})".format(data["ARCHIVE_DIR"], data["ARCHIVE_EXISTS"]))' <<<"$JSON_OUTPUT")
    GUIDE_VALUE=$("$PYTHON_CMD" -c 'import json,sys; data=json.load(sys.stdin); print("{} (exists: {})".format(data["GUIDE_PATH"], data["GUIDE_EXISTS"]))' <<<"$JSON_OUTPUT")
    CHANGELOG_VALUE=$("$PYTHON_CMD" -c 'import json,sys; data=json.load(sys.stdin); print("{} (exists: {})".format(data["CHANGELOG_PATH"], data["CHANGELOG_EXISTS"]))' <<<"$JSON_OUTPUT")
    COUNTS=$("$PYTHON_CMD" -c 'import json,sys; c=json.load(sys.stdin)["CANDIDATE_COUNTS"]; print("\n".join(str(c[k]) for k in ("drafts","session_docs","implementation_plans","release_docs","quickfix_records","pr_reviews")))' <<<"$JSON_OUTPUT")
    mapfile -t COUNT_LINES <<<"$COUNTS"
    echo "Repository:   $REPO_ROOT_VALUE"
    echo "Archive dir:  $ARCHIVE_DIR_VALUE"
    echo "Guide.md:     $GUIDE_VALUE"
    echo "CHANGELOG.md: $CHANGELOG_VALUE"
    echo ""
    echo "Candidates:"
    echo "  Drafts:               ${COUNT_LINES[0]:-0}"
    echo "  Session docs:         ${COUNT_LINES[1]:-0}"
    echo "  Implementation plans: ${COUNT_LINES[2]:-0}"
    echo "  Release docs:         ${COUNT_LINES[3]:-0}"
    echo "  Quickfix records:     ${COUNT_LINES[4]:-0}"
    echo "  PR reviews:           ${COUNT_LINES[5]:-0}"
fi
