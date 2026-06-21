#!/usr/bin/env bash
# Extract PR context for review
#
# This script fetches Pull Request information from GitHub and provides it
# in JSON format for the pr-review command.
#
# Usage: ./get-pr-context.sh [PR_NUMBER] [--json]
#        ./get-pr-context.sh --json      # Auto-detect PR from current branch
#        ./get-pr-context.sh 123 --json  # Specific PR number
#        ./get-pr-context.sh #123 --json # Also accepts # prefix

set -e
set -u
set -o pipefail

#==============================================================================
# Configuration
#==============================================================================

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

# Load platform adapter (sets DEVSPARK_PLATFORM_NAME, DEVSPARK_PR_CLI, etc.)
source "$SCRIPT_DIR/platform.sh"

# Multi-app support (T041, T066)
parse_app_context "$@" 2>/dev/null || true
if [[ -n "${DEVSPARK_APP_ID:-}" || "${DEVSPARK_REPO_SCOPE:-false}" == "true" ]]; then
    resolve_app_scope 2>/dev/null || true
    print_scope_summary >&2
    # Include scope report in PR context
    generate_scope_report >&2
fi

PR_NUMBER=""
JSON_MODE=false

#==============================================================================
# Parse Arguments
#==============================================================================

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        \#*)
            # Strip # prefix if provided
            PR_NUMBER="${arg#\#}"
            ;;
        [0-9]*)
            # Numeric PR number
            PR_NUMBER="$arg"
            ;;
        *)
            # Ignore other arguments
            ;;
    esac
done

#==============================================================================
# Utility Functions
#==============================================================================

log_error() {
    if [[ "$JSON_MODE" == true ]]; then
        # Output JSON error
        cat <<EOF
{
  "error": true,
  "message": "$1",
  "details": "${2:-}"
}
EOF
    else
        echo "ERROR: $1" >&2
        [[ -n "${2:-}" ]] && echo "$2" >&2
    fi
}

#==============================================================================
# PR Number Detection
#==============================================================================

detect_pr_number() {
    # Try various methods to detect PR number

    # Method 1: Check platform-specific environment variable
    if [[ -n "${!DEVSPARK_PR_ENV_VAR:-}" ]]; then
        echo "${!DEVSPARK_PR_ENV_VAR}"
        return 0
    fi

    # Method 2: Check generic env var
    if [[ -n "${PR_NUMBER_ENV:-}" ]]; then
        echo "$PR_NUMBER_ENV"
        return 0
    fi

    # Method 3: Try platform CLI for current branch
    case "$DEVSPARK_PLATFORM_NAME" in
        github)
            if command -v gh &>/dev/null; then
                local detected_pr
                detected_pr=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")
                if [[ -n "$detected_pr" ]]; then echo "$detected_pr"; return 0; fi
            fi
            ;;
        azdo)
            if command -v az &>/dev/null; then
                local branch pr_list
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
                if [[ -n "$branch" ]]; then
                    pr_list=$(az repos pr list --source-branch "$branch" --status active --top 1 --output json 2>/dev/null || echo "[]")
                    local pr_id
                    pr_id=$(echo "$pr_list" | jq -r '.[0].pullRequestId // empty' 2>/dev/null || echo "")
                    if [[ -n "$pr_id" ]]; then echo "$pr_id"; return 0; fi
                fi
            fi
            ;;
        gitlab)
            if command -v glab &>/dev/null; then
                local mr_iid
                mr_iid=$(glab mr view --output json 2>/dev/null | jq -r '.iid // empty' || echo "")
                if [[ -n "$mr_iid" ]]; then echo "$mr_iid"; return 0; fi
            fi
            ;;
    esac

    # Unable to detect
    return 1
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    # Detect PR number if not provided
    if [[ -z "$PR_NUMBER" ]]; then
        if ! PR_NUMBER=$(detect_pr_number); then
            log_error "Unable to detect PR number" \
                "Please provide PR number explicitly: /devspark.pr-review #123"
            exit 1
        fi
    fi
    
    # Validate PR number is numeric
    if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
        log_error "Invalid PR number: $PR_NUMBER" \
            "PR number must be a positive integer"
        exit 1
    fi
    
    # Check if platform CLI is available
    local cli_cmd="$DEVSPARK_PR_CLI"
    if ! command -v "$cli_cmd" &>/dev/null; then
        log_error "$DEVSPARK_PLATFORM_DISPLAY CLI ($cli_cmd) is required but not installed" \
            "Install from: $DEVSPARK_PR_CLI_INSTALL_URL"
        exit 1
    fi

    # Check platform CLI authentication
    if ! check_platform_auth; then
        local auth_cmd
        case "$DEVSPARK_PLATFORM_NAME" in
            github) auth_cmd="gh auth login" ;;
            azdo)   auth_cmd="az login" ;;
            gitlab) auth_cmd="glab auth login" ;;
            *)      auth_cmd="See platform documentation" ;;
        esac
        log_error "$DEVSPARK_PLATFORM_DISPLAY CLI not authenticated" \
            "Run: $auth_cmd"
        exit 1
    fi

    # Fetch PR data (platform-specific, normalized to common fields)
    local pr_number_int="$PR_NUMBER"
    local pr_title="" pr_body="" pr_state="" pr_author=""
    local source_branch="" target_branch=""
    local commit_sha="unknown" commit_count=0
    local files_changed_json="[]" lines_added=0 lines_deleted=0
    local created_at="" updated_at=""
    local merge_state_status="UNKNOWN"
    local file_sample_limit=200

    case "$DEVSPARK_PLATFORM_NAME" in
        github)
            local pr_data
            if ! pr_data=$(gh pr view "$PR_NUMBER" --json number,title,body,state,author,headRefName,baseRefName,commits,files,additions,deletions,createdAt,updatedAt,mergeStateStatus 2>&1); then
                log_error "Failed to fetch PR #$PR_NUMBER" \
                    "Verify PR exists and you have access. Details: $pr_data"
                exit 1
            fi
            pr_number_int=$(echo "$pr_data" | jq -r '.number')
            pr_title=$(echo "$pr_data" | jq -r '.title')
            pr_body=$(echo "$pr_data" | jq -r '.body // ""')
            pr_state=$(echo "$pr_data" | jq -r '.state')
            pr_author=$(echo "$pr_data" | jq -r '.author.login')
            source_branch=$(echo "$pr_data" | jq -r '.headRefName')
            target_branch=$(echo "$pr_data" | jq -r '.baseRefName')
            commit_sha=$(echo "$pr_data" | jq -r '.commits[-1].oid // "unknown"')
            commit_count=$(echo "$pr_data" | jq '.commits | length')
            files_changed_json=$(echo "$pr_data" | jq -c '[.files[].path]')
            lines_added=$(echo "$pr_data" | jq '.additions // 0')
            lines_deleted=$(echo "$pr_data" | jq '.deletions // 0')
            created_at=$(echo "$pr_data" | jq -r '.createdAt')
            updated_at=$(echo "$pr_data" | jq -r '.updatedAt')
            merge_state_status=$(echo "$pr_data" | jq -r '.mergeStateStatus // "UNKNOWN"')
            ;;
        azdo)
            local pr_data
            if ! pr_data=$(az repos pr show --id "$PR_NUMBER" --output json 2>&1); then
                log_error "Failed to fetch PR #$PR_NUMBER" \
                    "Verify PR exists and you have access. Details: $pr_data"
                exit 1
            fi
            pr_number_int=$(echo "$pr_data" | jq -r '.pullRequestId')
            pr_title=$(echo "$pr_data" | jq -r '.title')
            pr_body=$(echo "$pr_data" | jq -r '.description // ""')
            pr_state=$(echo "$pr_data" | jq -r '.status')
            pr_author=$(echo "$pr_data" | jq -r '.createdBy.uniqueName')
            source_branch=$(echo "$pr_data" | jq -r '.sourceRefName' | sed 's|^refs/heads/||')
            target_branch=$(echo "$pr_data" | jq -r '.targetRefName' | sed 's|^refs/heads/||')
            commit_sha=$(echo "$pr_data" | jq -r '.commits[-1].commitId // "unknown"')
            commit_count=$(echo "$pr_data" | jq '.commits | length // 0')
            created_at=$(echo "$pr_data" | jq -r '.creationDate')
            updated_at=$(echo "$pr_data" | jq -r '.completionQueueTime // .creationDate')
            # AzDO mergeStatus: notSet | conflicts | succeeded | rejectedByPolicy | failure
            merge_state_status=$(echo "$pr_data" | jq -r '.mergeStatus // "UNKNOWN"' | tr '[:lower:]' '[:upper:]')
            # Files resolved via git diff below
            ;;
        gitlab)
            local mr_data
            if ! mr_data=$(glab mr view "$PR_NUMBER" --output json 2>&1); then
                log_error "Failed to fetch MR !$PR_NUMBER" \
                    "Verify MR exists and you have access. Details: $mr_data"
                exit 1
            fi
            pr_number_int=$(echo "$mr_data" | jq -r '.iid')
            pr_title=$(echo "$mr_data" | jq -r '.title')
            pr_body=$(echo "$mr_data" | jq -r '.description // ""')
            pr_state=$(echo "$mr_data" | jq -r '.state')
            pr_author=$(echo "$mr_data" | jq -r '.author.username')
            source_branch=$(echo "$mr_data" | jq -r '.source_branch')
            target_branch=$(echo "$mr_data" | jq -r '.target_branch')
            created_at=$(echo "$mr_data" | jq -r '.created_at')
            updated_at=$(echo "$mr_data" | jq -r '.updated_at')
            local raw_merge_status
            raw_merge_status=$(echo "$mr_data" | jq -r '.merge_status // "UNKNOWN"')
            if [[ "$raw_merge_status" == "can_be_merged" ]]; then
                merge_state_status="CLEAN"
            else
                merge_state_status=$(echo "$raw_merge_status" | tr '[:lower:]' '[:upper:]')
            fi
            # Files resolved via git diff below
            ;;
    esac

    # For non-GitHub platforms, resolve file list and commit SHA via git diff
    if [[ "$DEVSPARK_PLATFORM_NAME" != "github" && -n "$source_branch" && -n "$target_branch" ]]; then
        git fetch origin "$source_branch" "$target_branch" 2>/dev/null || true
        files_changed_json=$(git diff --name-only "origin/$target_branch...origin/$source_branch" 2>/dev/null \
            | jq -R -s -c 'split("\n") | map(select(length > 0))' || echo "[]")
        if [[ "$commit_sha" == "unknown" ]]; then
            commit_sha=$(git rev-parse "origin/$source_branch" 2>/dev/null || echo "unknown")
        fi
    fi

    #==========================================================================
    # HARD RULE: Source branch MUST be in sync with target branch
    # GitHub's mergeStateStatus=="BEHIND" is treated as authoritative.
    # A universal git-based check covers AzDO, GitLab, and verifies GitHub.
    #==========================================================================
    local is_behind_target="false"

    # Fast path: GitHub API already says BEHIND
    if [[ "$merge_state_status" == "BEHIND" ]]; then
        is_behind_target="true"
    fi

    # Universal git check — fetch both refs, count target commits absent from source
    if [[ "$is_behind_target" == "false" && -n "$source_branch" && -n "$target_branch" ]]; then
        git fetch origin "$source_branch" "$target_branch" 2>/dev/null || true
        local behind_count
        behind_count=$(git rev-list "origin/$target_branch" "^origin/$source_branch" --count 2>/dev/null || echo "0")
        if [[ "$behind_count" -gt 0 ]]; then
            is_behind_target="true"
        fi
    fi

    if [[ "$is_behind_target" == "true" ]]; then
        local fix_hint
        case "$DEVSPARK_PLATFORM_NAME" in
            github) fix_hint="gh pr update-branch $PR_NUMBER  OR  git fetch origin && git rebase origin/$target_branch" ;;
            *)      fix_hint="git fetch origin && git rebase origin/$target_branch" ;;
        esac
        log_error "BLOCKED: Source branch '$source_branch' is behind target branch '$target_branch'" \
            "HARD RULE: PR review and approval are blocked until the source branch is in sync with the target branch. Fix with: $fix_hint"
        exit 1
    fi

    # Check if diff is available (platform-specific)
    local diff_available="false"
    case "$DEVSPARK_PLATFORM_NAME" in
        github)
            if gh pr diff "$PR_NUMBER" &>/dev/null; then diff_available="true"; fi
            ;;
        *)
            if git diff "origin/$target_branch...origin/$source_branch" &>/dev/null; then diff_available="true"; fi
            ;;
    esac

    # Apply file sampling
    local files_changed_total
    files_changed_total=$(echo "$files_changed_json" | jq 'length')
    local files_changed_truncated="false"
    if [[ "$files_changed_total" -gt "$file_sample_limit" ]]; then
        files_changed_json=$(echo "$files_changed_json" | jq -c ".[0:$file_sample_limit]")
        files_changed_truncated="true"
    fi

    # Check for constitution
    local constitution_path="$REPO_ROOT/.documentation/memory/constitution.md"
    local constitution_exists="false"
    if [[ -f "$constitution_path" ]]; then
        constitution_exists="true"
    fi

    #==========================================================================
    # Spec Lifecycle Detection
    # Extract feature identifier from branch name and check spec/task status
    #==========================================================================
    local spec_feature_id=""
    local spec_status="N/A"
    local spec_path=""
    local tasks_total=0
    local tasks_completed=0
    local tasks_incomplete=0
    local is_feature_branch="false"

    # Detect feature branch pattern: digits-name (e.g., 001-feature-name)
    if [[ "$source_branch" =~ ^([0-9]+-[a-zA-Z].*)$ ]]; then
        is_feature_branch="true"
        spec_feature_id="$source_branch"

        # Check for spec directory
        local feature_dir="$REPO_ROOT/.documentation/specs/$spec_feature_id"
        spec_path="$feature_dir/spec.md"

        if [[ -f "$spec_path" ]]; then
            # Extract Status field from spec.md
            spec_status=$(grep -oP '\*\*Status\*\*:\s*\K[A-Za-z ]+' "$spec_path" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//' || echo "Unknown")
            # Strip HTML comment if present
            spec_status=$(echo "$spec_status" | sed 's/<!--.*//;s/[[:space:]]*$//')
        else
            spec_status="Missing"
        fi

        # Check tasks.md completion
        local tasks_path="$feature_dir/tasks.md"
        if [[ -f "$tasks_path" ]]; then
            tasks_total=$(grep -cE '^\s*- \[([ xX])\]' "$tasks_path" 2>/dev/null || echo "0")
            tasks_completed=$(grep -cE '^\s*- \[[xX]\]' "$tasks_path" 2>/dev/null || echo "0")
            tasks_incomplete=$((tasks_total - tasks_completed))
        fi
    fi

    # Prepare review directory
    local review_dir="$REPO_ROOT/.documentation/specs/pr-review"

    # Build JSON output
    if [[ "$JSON_MODE" == true ]]; then
        cat <<EOF
{
  "REPO_ROOT": "$REPO_ROOT",
  "PR_CONTEXT": {
    "enabled": true,
    "pr_number": $pr_number_int,
    "pr_title": $(echo "$pr_title" | jq -R .),
    "pr_body": $(echo "$pr_body" | jq -R .),
    "pr_state": $(echo "$pr_state" | jq -R .),
    "pr_author": $(echo "$pr_author" | jq -R .),
    "source_branch": $(echo "$source_branch" | jq -R .),
    "target_branch": $(echo "$target_branch" | jq -R .),
    "commit_sha": "$commit_sha",
    "commit_count": $commit_count,
    "files_changed": $files_changed_json,
    "files_changed_total": $files_changed_total,
    "files_changed_truncated": $files_changed_truncated,
    "lines_added": $lines_added,
    "lines_deleted": $lines_deleted,
    "created_at": $(echo "$created_at" | jq -R .),
    "updated_at": $(echo "$updated_at" | jq -R .),
    "diff_available": $diff_available,
    "file_sample_limit": $file_sample_limit,
    "include_all_files": false,
    "merge_state_status": "$merge_state_status",
    "is_behind_target": $is_behind_target
  },
  "CONSTITUTION_PATH": "$constitution_path",
  "CONSTITUTION_EXISTS": $constitution_exists,
  "REVIEW_DIR": "$review_dir",
  "SPEC_LIFECYCLE": {
    "is_feature_branch": $is_feature_branch,
    "feature_id": $(echo "$spec_feature_id" | jq -R .),
    "spec_status": $(echo "$spec_status" | jq -R .),
    "spec_path": $(echo "$spec_path" | jq -R .),
    "tasks_total": $tasks_total,
    "tasks_completed": $tasks_completed,
    "tasks_incomplete": $tasks_incomplete
  }
}
EOF
    else
        # Human-readable output
        echo "PR Context for #$pr_number_int"
        echo "========================="
        echo "Title:  $pr_title"
        echo "Author: $pr_author"
        echo "State:  $pr_state"
        echo "Branch: $source_branch → $target_branch"
        if [[ "$is_behind_target" == "true" ]]; then
            echo "Sync:   BEHIND (blocked)"
        else
            echo "Sync:   In sync ($merge_state_status)"
        fi
        echo "Commit: $commit_sha"
        echo "Files:  $(echo "$files_changed_json" | jq 'length')"
        echo "Lines:  +$lines_added -$lines_deleted"
        echo ""
        echo "Constitution: $([[ "$constitution_exists" == "true" ]] && echo "✓ Found" || echo "✗ Missing")"
        if [[ "$is_feature_branch" == "true" ]]; then
            echo ""
            echo "Spec Lifecycle:"
            echo "  Feature:  $spec_feature_id"
            echo "  Status:   $spec_status"
            echo "  Tasks:    $tasks_completed/$tasks_total complete ($tasks_incomplete remaining)"
        fi
        echo "Review will be saved to: $review_dir/pr-$pr_number_int.md"
    fi
}

# Execute main function
main "$@"
