#!/usr/bin/env bash
# Release context gathering script
# Supports archiving development artifacts and generating release documentation

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

json_array_length() {
    jq 'length' <<<"$1"
}

collect_archive_recovery_specs() {
    local repo_root=$1
    local from_date=$2
    local to_date=$3
    local results='[]'
    local archive_root="$repo_root/.archive"
    local tasks_file rel batch spec_name unchecked checked

    [[ -d "$archive_root" ]] || {
        printf '[]'
        return
    }

    while IFS= read -r -d '' tasks_file; do
        rel=${tasks_file#"$repo_root/"}
        batch=$(printf '%s' "$rel" | cut -d/ -f2)
        if [[ -n "$from_date" && "$batch" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$batch" < "$from_date" ]]; then
            continue
        fi
        if [[ -n "$to_date" && "$batch" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$batch" > "$to_date" ]]; then
            continue
        fi

        spec_name=$(printf '%s' "$rel" | cut -d/ -f5)
        unchecked=$(grep -c '^\s*- \[ \]' "$tasks_file" 2>/dev/null || echo "0")
        checked=$(grep -ci '^\s*- \[x\]' "$tasks_file" 2>/dev/null || echo "0")
        if [[ "$unchecked" -eq 0 && "$checked" -gt 0 ]]; then
            results=$(jq -c --arg value "$spec_name" '. + [$value] | unique' <<<"$results")
        fi
    done < <(find "$archive_root" -path '*/.documentation/specs/*/tasks.md' -print0 2>/dev/null)

    printf '%s' "$results"
}

collect_archive_recovery_quickfixes() {
    local repo_root=$1
    local from_date=$2
    local to_date=$3
    local results='[]'
    local archive_root="$repo_root/.archive"
    local quickfix_file rel batch quickfix_id

    [[ -d "$archive_root" ]] || {
        printf '[]'
        return
    }

    while IFS= read -r -d '' quickfix_file; do
        rel=${quickfix_file#"$repo_root/"}
        batch=$(printf '%s' "$rel" | cut -d/ -f2)
        if [[ -n "$from_date" && "$batch" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$batch" < "$from_date" ]]; then
            continue
        fi
        if [[ -n "$to_date" && "$batch" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$batch" > "$to_date" ]]; then
            continue
        fi

        quickfix_id=$(basename "$quickfix_file" .md)
        results=$(jq -c --arg value "$quickfix_id" '. + [$value] | unique' <<<"$results")
    done < <(find "$archive_root" -path '*/.documentation/quickfixes/QF-*.md' -print0 2>/dev/null)

    printf '%s' "$results"
}

# Multi-app support (T085)
parse_app_context "$@" 2>/dev/null || true
if [[ -n "${DEVSPARK_APP_ID:-}" || "${DEVSPARK_REPO_SCOPE:-false}" == "true" ]]; then
    resolve_app_scope 2>/dev/null || true
    print_scope_summary >&2
fi

# Default values
JSON_MODE=false
VERSION_ARG=""
DRY_RUN=false
RELEASE_FROM_ARG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --from)
            RELEASE_FROM_ARG="$2"
            shift 2
            ;;
        --from=*)
            RELEASE_FROM_ARG="${1#--from=}"
            shift
            ;;
        v*)
            VERSION_ARG="$1"
            shift
            ;;
        [0-9]*)
            VERSION_ARG="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Get repository context
REPO_ROOT=$(get_repo_root)
SPECS_DIR="$REPO_ROOT/.documentation/specs"
RELEASES_DIR="$REPO_ROOT/.documentation/releases"
QUICKFIX_DIR="$REPO_ROOT/.documentation/quickfixes"
DECISIONS_DIR="$REPO_ROOT/.documentation/decisions"
CONSTITUTION_PATH="$REPO_ROOT/.documentation/memory/constitution.md"

# Detect current version from package files
CURRENT_VERSION="0.0.0"
VERSION_SOURCE="default"

if [[ -f "$REPO_ROOT/package.json" ]]; then
    CURRENT_VERSION=$(jq -r '.version // "0.0.0"' "$REPO_ROOT/package.json" 2>/dev/null || echo "0.0.0")
    VERSION_SOURCE="package.json"
elif [[ -f "$REPO_ROOT/pyproject.toml" ]]; then
    CURRENT_VERSION=$(sed -nE 's/^version[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$REPO_ROOT/pyproject.toml" 2>/dev/null | head -1 || echo "0.0.0")
    VERSION_SOURCE="pyproject.toml"
elif [[ -f "$REPO_ROOT/Cargo.toml" ]]; then
    CURRENT_VERSION=$(sed -nE 's/^version[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$REPO_ROOT/Cargo.toml" 2>/dev/null | head -1 || echo "0.0.0")
    VERSION_SOURCE="Cargo.toml"
fi

# Get last release info from git tags
LAST_TAG=""
LAST_RELEASE_DATE=""
COMMITS_SINCE=0

if has_git; then
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -n "$LAST_TAG" ]]; then
        LAST_RELEASE_DATE=$(git log -1 --format=%ci "$LAST_TAG" 2>/dev/null || echo "")
        COMMITS_SINCE=$(git rev-list "$LAST_TAG"..HEAD --count 2>/dev/null || echo "0")
    else
        # No tags, count all commits
        COMMITS_SINCE=$(git rev-list HEAD --count 2>/dev/null || echo "0")
    fi
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RELEASE_DATE=$(date +"%Y-%m-%d")
RELEASE_FROM="$RELEASE_FROM_ARG"
if [[ -z "$RELEASE_FROM" && -n "$LAST_RELEASE_DATE" ]]; then
    RELEASE_FROM="${LAST_RELEASE_DATE:0:10}"
fi
RELEASE_TO="$RELEASE_DATE"

# Find completed specs (those with all tasks checked in tasks.md)
COMPLETED_SPECS='[]'
PENDING_SPECS='[]'

if [[ -d "$SPECS_DIR" ]]; then
    for spec_dir in "$SPECS_DIR"/*/; do
        if [[ -d "$spec_dir" ]]; then
            spec_name=$(basename "$spec_dir")
            # Skip pr-review directory
            if [[ "$spec_name" == "pr-review" ]]; then
                continue
            fi

            tasks_file="$spec_dir/tasks.md"
            if [[ -f "$tasks_file" ]]; then
                # Count unchecked tasks (- [ ])
                unchecked=$(grep -c '^\s*- \[ \]' "$tasks_file" 2>/dev/null || echo "0")
                # Count checked tasks (- [x] or - [X])
                checked=$(grep -ci '^\s*- \[x\]' "$tasks_file" 2>/dev/null || echo "0")

                if [[ "$unchecked" -eq 0 && "$checked" -gt 0 ]]; then
                    COMPLETED_SPECS=$(echo "$COMPLETED_SPECS" | jq --arg s "$spec_name" '. + [$s]')
                elif [[ -f "$spec_dir/spec.md" ]]; then
                    PENDING_SPECS=$(echo "$PENDING_SPECS" | jq --arg s "$spec_name" '. + [$s]')
                fi
            elif [[ -f "$spec_dir/spec.md" ]]; then
                # Has spec but no tasks - consider pending
                PENDING_SPECS=$(echo "$PENDING_SPECS" | jq --arg s "$spec_name" '. + [$s]')
            fi
        fi
    done
fi

# Find quickfixes since last release
QUICKFIXES='[]'
if [[ -d "$QUICKFIX_DIR" ]]; then
    if [[ -n "$LAST_RELEASE_DATE" ]]; then
        # Find quickfixes newer than last release
        QUICKFIXES=$(find "$QUICKFIX_DIR" -name "QF-*.md" -newer "$REPO_ROOT/.git/refs/tags/$LAST_TAG" 2>/dev/null | while read -r f; do
            basename "$f" .md
        done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    else
        # No previous release, include all
        QUICKFIXES=$(ls "$QUICKFIX_DIR"/QF-*.md 2>/dev/null | while read -r f; do
            basename "$f" .md
        done | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    fi
fi

ACTIVE_COMPLETED_SPECS="$COMPLETED_SPECS"
ACTIVE_QUICKFIXES="$QUICKFIXES"

ARCHIVE_RECOVERED_SPECS=$(collect_archive_recovery_specs "$REPO_ROOT" "$RELEASE_FROM" "$RELEASE_TO")
ARCHIVE_RECOVERED_QUICKFIXES=$(collect_archive_recovery_quickfixes "$REPO_ROOT" "$RELEASE_FROM" "$RELEASE_TO")

HISTORY_RECOVERED_SPECS='[]'
HISTORY_RECOVERED_QUICKFIXES='[]'
HISTORY_ARCHIVE_MOVES_DETECTED=false
HISTORY_RELEASE_FROM="$RELEASE_FROM"
HISTORY_RELEASE_TO="$RELEASE_TO"
MERGED_PR_NUMBERS='[]'
MERGED_PR_COUNT=0
PR_REVIEWS='[]'
PR_REVIEW_SUMMARY='{"matched_reviews":0,"files_changed":0,"tests_added":0,"breaking_changes":0,"resolved_high_findings":0}'
HISTORY_COMMITS='[]'
HISTORY_CONTRIBUTORS='[]'
if has_git && [[ -f "$SCRIPT_DIR/release-history-context.sh" ]]; then
    if [[ -n "$LAST_TAG" ]]; then
        HISTORY_JSON=$("$SCRIPT_DIR/release-history-context.sh" --json --base-ref "$LAST_TAG" --from "$RELEASE_FROM" --to "$RELEASE_TO" 2>/dev/null || echo '')
    else
        HISTORY_JSON=$("$SCRIPT_DIR/release-history-context.sh" --json --from "$RELEASE_FROM" --to "$RELEASE_TO" 2>/dev/null || echo '')
    fi

    if [[ -n "$HISTORY_JSON" ]]; then
        HISTORY_RECOVERED_SPECS=$(jq -c '[.RECOVERED_SPECS[]? | select(.completed == true) | .name] | unique' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
        HISTORY_RECOVERED_QUICKFIXES=$(jq -c '[.RECOVERED_QUICKFIXES[]? | .id] | unique' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
        HISTORY_ARCHIVE_MOVES_DETECTED=$(jq -r '.ARCHIVE_MOVES_DETECTED // false' <<<"$HISTORY_JSON" 2>/dev/null || echo 'false')
        HISTORY_RELEASE_FROM=$(jq -r '.RELEASE_FROM // ""' <<<"$HISTORY_JSON" 2>/dev/null || echo "$RELEASE_FROM")
        HISTORY_RELEASE_TO=$(jq -r '.RELEASE_TO // ""' <<<"$HISTORY_JSON" 2>/dev/null || echo "$RELEASE_TO")
        MERGED_PR_NUMBERS=$(jq -c '.MERGED_PR_NUMBERS // []' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
        MERGED_PR_COUNT=$(jq -r '.MERGED_PR_COUNT // 0' <<<"$HISTORY_JSON" 2>/dev/null || echo '0')
        PR_REVIEWS=$(jq -c '.PR_REVIEWS // []' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
        PR_REVIEW_SUMMARY=$(jq -c '.PR_REVIEW_SUMMARY // {"matched_reviews":0,"files_changed":0,"tests_added":0,"breaking_changes":0,"resolved_high_findings":0}' <<<"$HISTORY_JSON" 2>/dev/null || echo '{"matched_reviews":0,"files_changed":0,"tests_added":0,"breaking_changes":0,"resolved_high_findings":0}')
        HISTORY_COMMITS=$(jq -c '.COMMITS // []' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
        HISTORY_CONTRIBUTORS=$(jq -c '.CONTRIBUTORS // []' <<<"$HISTORY_JSON" 2>/dev/null || echo '[]')
    fi
fi

COMPLETED_SPECS=$(jq -c -n \
    --argjson active "$ACTIVE_COMPLETED_SPECS" \
    --argjson archive "$ARCHIVE_RECOVERED_SPECS" \
    --argjson history "$HISTORY_RECOVERED_SPECS" \
    '$active + $archive + $history | unique')

QUICKFIXES=$(jq -c -n \
    --argjson active "$ACTIVE_QUICKFIXES" \
    --argjson archive "$ARCHIVE_RECOVERED_QUICKFIXES" \
    --argjson history "$HISTORY_RECOVERED_QUICKFIXES" \
    '$active + $archive + $history | unique')

RECOVERED_COMPLETED_SPECS=$(jq -c -n \
    --argjson combined "$COMPLETED_SPECS" \
    --argjson active "$ACTIVE_COMPLETED_SPECS" \
    '[ $combined[] | select(($active | index(.)) | not) ]')

RECOVERED_QUICKFIXES=$(jq -c -n \
    --argjson combined "$QUICKFIXES" \
    --argjson active "$ACTIVE_QUICKFIXES" \
    '[ $combined[] | select(($active | index(.)) | not) ]')

ARCHIVE_RECOVERY_USED=false
if [[ $(json_array_length "$ARCHIVE_RECOVERED_SPECS") -gt 0 || $(json_array_length "$ARCHIVE_RECOVERED_QUICKFIXES") -gt 0 ]]; then
    ARCHIVE_RECOVERY_USED=true
fi

HISTORY_RECOVERY_USED=false
if [[ $(json_array_length "$HISTORY_RECOVERED_SPECS") -gt 0 || $(json_array_length "$HISTORY_RECOVERED_QUICKFIXES") -gt 0 ]]; then
    HISTORY_RECOVERY_USED=true
fi

if [[ $(json_array_length "$HISTORY_COMMITS") -gt 0 ]]; then
    COMMITS_SINCE=$(json_array_length "$HISTORY_COMMITS")
fi

if [[ $(json_array_length "$HISTORY_CONTRIBUTORS") -gt 0 ]]; then
    CONTRIBUTORS="$HISTORY_CONTRIBUTORS"
fi

# Calculate next version if not provided
NEXT_VERSION="$VERSION_ARG"
VERSION_BUMP="patch"

if [[ -z "$NEXT_VERSION" ]]; then
    # Parse current version
    IFS='.' read -r major minor patch <<< "${CURRENT_VERSION%-*}"
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}

    completed_count=$(echo "$COMPLETED_SPECS" | jq 'length')
    quickfix_count=$(echo "$QUICKFIXES" | jq 'length')

    if [[ "$completed_count" -gt 0 ]]; then
        # Minor bump for new features
        VERSION_BUMP="minor"
        NEXT_VERSION="$major.$((minor + 1)).0"
    elif [[ "$quickfix_count" -gt 0 ]]; then
        # Patch bump for fixes only
        VERSION_BUMP="patch"
        NEXT_VERSION="$major.$minor.$((patch + 1))"
    else
        # Default patch bump
        VERSION_BUMP="patch"
        NEXT_VERSION="$major.$minor.$((patch + 1))"
    fi
fi

# Get git contributors since last release
CONTRIBUTORS=${CONTRIBUTORS:-'[]'}
if [[ $(json_array_length "$CONTRIBUTORS") -eq 0 ]] && has_git; then
    if [[ -n "$LAST_TAG" ]]; then
        CONTRIBUTORS=$(git log "$LAST_TAG"..HEAD --format='%aN' 2>/dev/null | sort -u | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    else
        CONTRIBUTORS=$(git log --format='%aN' 2>/dev/null | sort -u | head -20 | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null || echo '[]')
    fi
fi

# DevSpark version stamp info
DEVSPARK_VERSION_PATH="$REPO_ROOT/.devspark/VERSION"
LEGACY_DEVSPARK_VERSION_PATH="$REPO_ROOT/.documentation/DEVSPARK_VERSION"
INSTALLED_VERSION=""
if [[ -f "$DEVSPARK_VERSION_PATH" ]]; then
    INSTALLED_VERSION=$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' "$DEVSPARK_VERSION_PATH" 2>/dev/null | head -1 || echo "")
elif [[ -f "$LEGACY_DEVSPARK_VERSION_PATH" ]]; then
    INSTALLED_VERSION=$(head -1 "$LEGACY_DEVSPARK_VERSION_PATH" 2>/dev/null || echo "")
fi

# Output JSON if requested
if [[ "$JSON_MODE" == true ]]; then
    cat <<EOF
{
  "REPO_ROOT": "$REPO_ROOT",
  "SPECS_DIR": "$SPECS_DIR",
  "RELEASES_DIR": "$RELEASES_DIR",
  "QUICKFIX_DIR": "$QUICKFIX_DIR",
  "DECISIONS_DIR": "$DECISIONS_DIR",
  "CONSTITUTION_PATH": "$CONSTITUTION_PATH",
  "CURRENT_VERSION": "$CURRENT_VERSION",
  "VERSION_SOURCE": "$VERSION_SOURCE",
  "NEXT_VERSION": "$NEXT_VERSION",
  "VERSION_BUMP": "$VERSION_BUMP",
    "RELEASE_FROM": "$HISTORY_RELEASE_FROM",
    "RELEASE_TO": "$HISTORY_RELEASE_TO",
    "ACTIVE_COMPLETED_SPECS": $ACTIVE_COMPLETED_SPECS,
  "COMPLETED_SPECS": $COMPLETED_SPECS,
    "RECOVERED_COMPLETED_SPECS": $RECOVERED_COMPLETED_SPECS,
  "PENDING_SPECS": $PENDING_SPECS,
    "ACTIVE_QUICKFIXES": $ACTIVE_QUICKFIXES,
  "QUICKFIXES": $QUICKFIXES,
    "RECOVERED_QUICKFIXES": $RECOVERED_QUICKFIXES,
  "LAST_TAG": "$LAST_TAG",
  "LAST_RELEASE_DATE": "$LAST_RELEASE_DATE",
  "COMMITS_SINCE_RELEASE": $COMMITS_SINCE,
  "CONTRIBUTORS": $CONTRIBUTORS,
    "MERGED_PR_NUMBERS": $MERGED_PR_NUMBERS,
    "MERGED_PR_COUNT": $MERGED_PR_COUNT,
    "PR_REVIEWS": $PR_REVIEWS,
    "PR_REVIEW_SUMMARY": $PR_REVIEW_SUMMARY,
    "ARCHIVE_RECOVERY_USED": $ARCHIVE_RECOVERY_USED,
    "HISTORY_RECOVERY_USED": $HISTORY_RECOVERY_USED,
    "HISTORY_ARCHIVE_MOVES_DETECTED": $HISTORY_ARCHIVE_MOVES_DETECTED,
  "TIMESTAMP": "$TIMESTAMP",
  "RELEASE_DATE": "$RELEASE_DATE",
  "DRY_RUN": $DRY_RUN,
    "DEVSPARK_VERSION_PATH": "$DEVSPARK_VERSION_PATH",
    "LEGACY_DEVSPARK_VERSION_PATH": "$LEGACY_DEVSPARK_VERSION_PATH",
  "INSTALLED_VERSION": "$INSTALLED_VERSION"
}
EOF
else
    # Human-readable output
    echo "Release Context"
    echo "==============="
    echo "Repository: $REPO_ROOT"
    echo "Current Version: $CURRENT_VERSION (from $VERSION_SOURCE)"
    echo "Next Version: $NEXT_VERSION ($VERSION_BUMP bump)"
    echo "Last Release: $LAST_TAG ($LAST_RELEASE_DATE)"
    echo "Release Window: $HISTORY_RELEASE_FROM -> $HISTORY_RELEASE_TO"
    echo "Commits Since: $COMMITS_SINCE"
    echo ""
    echo "Completed Specs: $(echo "$COMPLETED_SPECS" | jq 'length')"
    echo "Pending Specs: $(echo "$PENDING_SPECS" | jq 'length')"
    echo "Quickfixes: $(echo "$QUICKFIXES" | jq 'length')"
    echo "Contributors: $(echo "$CONTRIBUTORS" | jq 'length')"
    echo "Merged PRs: $MERGED_PR_COUNT"
    if [[ $(echo "$RECOVERED_COMPLETED_SPECS" | jq 'length') -gt 0 || $(echo "$RECOVERED_QUICKFIXES" | jq 'length') -gt 0 ]]; then
        echo ""
        echo "Recovered Specs: $(echo "$RECOVERED_COMPLETED_SPECS" | jq 'length')"
        echo "Recovered Quickfixes: $(echo "$RECOVERED_QUICKFIXES" | jq 'length')"
    fi
    echo ""
    if [[ -n "$INSTALLED_VERSION" ]]; then
        echo "Installed DevSpark Version: $INSTALLED_VERSION"
    else
        echo "Installed DevSpark Version: (VERSION stamp not found)"
    fi
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "** DRY RUN MODE - No changes will be made **"
    fi
fi
