#!/usr/bin/env bash
# Common functions and variables for all scripts

# Get repository root, with fallback for non-git repositories
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir
        script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current branch, with fallback for non-git repositories
get_current_branch() {
    # First check if DEVSPARK_FEATURE environment variable is set
    if [[ -n "${DEVSPARK_FEATURE:-}" ]]; then
        echo "$DEVSPARK_FEATURE"
        return
    fi

    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # For non-git repos, try to find the latest feature directory
    local repo_root
    repo_root=$(get_repo_root)
    local specs_dir="$repo_root/.documentation/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname
                dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"  # Final fallback
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[devspark] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: 001-feature-name" >&2
        return 1
    fi

    return 0
}

get_feature_dir() { echo "$1/.documentation/specs/$2"; }

# Find feature directory by numeric prefix instead of exact branch match
# This allows multiple branches to work on the same spec (e.g., 004-fix-bug, 004-add-feature)
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/.documentation/specs"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # If branch doesn't have numeric prefix, fall back to exact match
        echo "$specs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Search for directories in .documentation/specs/ that start with this prefix
    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Handle results
    if [[ ${#matches[@]} -eq 0 ]]; then
        # No match found - return the branch name path (will fail later with clear error)
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Exactly one match - perfect!
        echo "$specs_dir/${matches[0]}"
    else
        # Multiple matches - this shouldn't happen with proper naming convention
        echo "ERROR: Multiple spec directories found with prefix '$prefix': ${matches[*]}" >&2
        echo "Please ensure only one spec directory exists per numeric prefix." >&2
        echo "$specs_dir/$branch_name"  # Return something to avoid breaking the script
    fi
}

get_feature_paths() {
    local repo_root
    repo_root=$(get_repo_root)
    local current_branch
    current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Use prefix-based lookup to support multiple branches per spec
    local feature_dir
    feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

get_markdown_frontmatter() {
    local file_path="$1"

    [[ -f "$file_path" ]] || return 1

    awk '
        NR == 1 && $0 == "---" { in_block=1; next }
        in_block && $0 == "---" { exit }
        in_block { print }
    ' "$file_path"
}

get_markdown_frontmatter_value() {
    local file_path="$1"
    local key="$2"

    get_markdown_frontmatter "$file_path" | awk -F': ' -v wanted="$key" '$1 == wanted { print $2; exit }'
}

# ---------------------------------------------------------------------------
# Multi-app support helpers
# ---------------------------------------------------------------------------

# Detect whether the repository is operating in multi-app mode.
detect_devspark_mode() {
    local repo_root
    repo_root=$(get_repo_root)
    local registry="$repo_root/.documentation/devspark.json"

    if [[ -f "$registry" ]]; then
        local mode
        mode=$(jq -r '.mode // empty' "$registry" 2>/dev/null || true)
        if [[ "$mode" == "multi-app" ]]; then
            echo "multi-app"
            return
        fi
    fi
    echo "single-app"
}

# Validate the registry structure with jq before deeper processing.
validate_registry_json() {
    local registry_path="$1"

    if [[ ! -f "$registry_path" ]]; then
        echo '{"valid":false,"error":"Registry file not found"}'; return 1
    fi

    # Check JSON validity
    if ! jq empty "$registry_path" 2>/dev/null; then
        echo '{"valid":false,"error":"Invalid JSON"}'; return 1
    fi

    local version mode app_count profile_count
    version=$(jq -r '.version // 0' "$registry_path") || true
    mode=$(jq -r '.mode // ""' "$registry_path") || true
    app_count=$(jq '.apps | length' "$registry_path") || true
    profile_count=$(jq '.profiles | keys | length' "$registry_path") || true

    # Check version
    if [[ "$version" != "1" ]]; then
        echo "{\"valid\":false,\"error\":\"Unsupported version: $version\"}"; return 1
    fi

    # Check unique IDs
    local unique_ids total_ids
    total_ids=$(jq '.apps | length' "$registry_path") || true
    unique_ids=$(jq '[.apps[].id] | unique | length' "$registry_path") || true
    if [[ "$total_ids" != "$unique_ids" ]]; then
        echo '{"valid":false,"error":"Duplicate app IDs detected"}'; return 1
    fi

    # Check profile references
    local bad_profiles
    bad_profiles=$(jq -r '
        [.profiles | keys] as $pkeys |
        [.apps[].inherits[]] | unique | map(select(. as $p | $pkeys[0] | index($p) | not))
    ' "$registry_path" 2>/dev/null || echo "[]")
    if [[ "$bad_profiles" != "[]" ]]; then
        echo "{\"valid\":false,\"error\":\"Unknown profiles: $bad_profiles\"}"; return 1
    fi

    echo "{\"valid\":true,\"apps\":$app_count,\"profiles\":$profile_count}"
}

# Resolve app documentation root (T014)
resolve_app_doc_root() {
    local repo_root="$1"
    local app_id="$2"

    if [[ -z "$app_id" ]]; then
        echo "$repo_root/.documentation"
        return
    fi

    local registry="$repo_root/.documentation/devspark.json"
    if [[ ! -f "$registry" ]]; then
        echo "ERROR: No multi-app registry found" >&2; return 1
    fi

    local app_path
    app_path=$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .path // empty' "$registry" 2>/dev/null)
    if [[ -z "$app_path" ]]; then
        echo "ERROR: Unknown application: $app_id" >&2; return 1
    fi

    echo "$repo_root/$app_path/.documentation"
}

# Parse --app and --repo-scope arguments (T026)
# Sets DEVSPARK_APP_ID and DEVSPARK_REPO_SCOPE
parse_app_context() {
    DEVSPARK_APP_ID=""
    DEVSPARK_REPO_SCOPE=false
    local remaining_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app)
                shift
                if [[ $# -eq 0 || "$1" == --* ]]; then
                    echo "ERROR: --app requires an application ID" >&2; return 1
                fi
                DEVSPARK_APP_ID="$1"
                ;;
            --repo-scope)
                DEVSPARK_REPO_SCOPE=true
                ;;
            *)
                remaining_args+=("$1")
                ;;
        esac
        shift
    done

    # Export for downstream scripts
    export DEVSPARK_APP_ID DEVSPARK_REPO_SCOPE
    # Set remaining args back (used by callers after sourcing)
    export DEVSPARK_REMAINING_ARGS
    DEVSPARK_REMAINING_ARGS=("${remaining_args[@]}")
}

# Resolve scope and validate (T028, T030)
# Sets DEVSPARK_SCOPE, DEVSPARK_DOC_ROOT, DEVSPARK_SCOPE_ERROR (used by callers)
# shellcheck disable=SC2034
resolve_app_scope() {
    local repo_root
    repo_root=$(get_repo_root)
    local mode
    mode=$(detect_devspark_mode)

    DEVSPARK_SCOPE=""
    DEVSPARK_DOC_ROOT=""
    DEVSPARK_SCOPE_ERROR=""

    if [[ "$mode" == "single-app" ]]; then
        # Single-app mode
        if [[ -n "$DEVSPARK_APP_ID" ]]; then
            DEVSPARK_SCOPE_ERROR="No multi-app registry found. Cannot use --app."
            return 1
        fi
        DEVSPARK_SCOPE="repo"
        DEVSPARK_DOC_ROOT="$repo_root/.documentation"
        return 0
    fi

    # Multi-app mode
    if [[ "$DEVSPARK_REPO_SCOPE" == "true" ]]; then
        DEVSPARK_SCOPE="repo"
        DEVSPARK_DOC_ROOT="$repo_root/.documentation"
        return 0
    fi

    if [[ -n "$DEVSPARK_APP_ID" ]]; then
        local doc_root
        doc_root=$(resolve_app_doc_root "$repo_root" "$DEVSPARK_APP_ID") || {
            DEVSPARK_SCOPE_ERROR="$doc_root"
            return 1
        }
        DEVSPARK_SCOPE="single-app"
        DEVSPARK_DOC_ROOT="$doc_root"
        return 0
    fi

    # No explicit scope — check app count
    local registry="$repo_root/.documentation/devspark.json"
    local app_count
    app_count=$(jq '.apps | length' "$registry" 2>/dev/null || echo "0")

    if [[ "$app_count" -gt 1 ]]; then
        local available
        available=$(jq -r '[.apps[].id] | join(", ")' "$registry")
        DEVSPARK_SCOPE_ERROR="Multiple apps registered; specify --app <id> or use --repo-scope. Available: $available"
        return 1
    fi

    if [[ "$app_count" -eq 1 ]]; then
        local app_id app_path
        app_id=$(jq -r '.apps[0].id' "$registry")
        app_path=$(jq -r '.apps[0].path' "$registry")
        DEVSPARK_APP_ID="$app_id"
        DEVSPARK_SCOPE="single-app"
        DEVSPARK_DOC_ROOT="$repo_root/$app_path/.documentation"
        return 0
    fi

    DEVSPARK_SCOPE="repo"
    DEVSPARK_DOC_ROOT="$repo_root/.documentation"
}

# Resolve constitution with app overlay (T022)
resolve_constitution() {
    local repo_root="$1"
    local app_id="${2:-}"

    local repo_constitution="$repo_root/.documentation/memory/constitution.md"
    if [[ ! -f "$repo_constitution" ]]; then
        echo "ERROR: Repository constitution required at $repo_constitution" >&2
        return 1
    fi

    local output
    output=$(cat "$repo_constitution")

    if [[ -n "$app_id" ]]; then
        local app_doc_root
        app_doc_root=$(resolve_app_doc_root "$repo_root" "$app_id") || return 1
        local app_constitution="$app_doc_root/memory/constitution.md"

        if [[ -f "$app_constitution" ]]; then
            output="$output

---

## Application Overlay: $app_id

$(cat "$app_constitution")"
        fi
    fi

    echo "$output"
}

# Get direct downstream consumers of an app (T039)
get_downstream_apps() {
    local repo_root="$1"
    local app_id="$2"
    local registry="$repo_root/.documentation/devspark.json"

    if [[ ! -f "$registry" ]]; then
        return
    fi

    # Find all apps whose dependsOn contains app_id
    jq -r --arg id "$app_id" \
        '[.apps[] | select(.dependsOn | index($id)) | .id] | join(",")' \
        "$registry" 2>/dev/null || true
}

# Generate scope report (T039)
generate_scope_report() {
    local repo_root
    repo_root=$(get_repo_root)

    echo "## DevSpark Scope Report"
    echo ""
    echo "**Scope type**: ${DEVSPARK_SCOPE:-unknown}"
    echo "**Documentation root**: ${DEVSPARK_DOC_ROOT:-unknown}"

    if [[ -n "$DEVSPARK_APP_ID" ]]; then
        echo "**Primary application**: $DEVSPARK_APP_ID"

        # Declared downstream
        local downstream
        downstream=$(get_downstream_apps "$repo_root" "$DEVSPARK_APP_ID")
        if [[ -n "$downstream" ]]; then
            echo ""
            echo "### Declared downstream dependencies"
            IFS=',' read -r -a deps <<< "$downstream"
            for dep in "${deps[@]}"; do
                echo "- $dep"
            done
        fi
    fi
}

# Print scope summary (T035)
print_scope_summary() {
    echo "--- DevSpark Scope ---"
    echo "scope: ${DEVSPARK_SCOPE:-unknown}"
    echo "doc-root: ${DEVSPARK_DOC_ROOT:-unknown}"
    if [[ -n "$DEVSPARK_APP_ID" ]]; then
        echo "app: $DEVSPARK_APP_ID"
    fi
    echo "mode: $(detect_devspark_mode)"
    echo "---"
}

# Resolve inherited profile chain for an app (T052)
# Composes all inherited profiles + overrides + app.json into one effective profile
resolve_app_profiles() {
    local repo_root="$1"
    local app_id="$2"
    local registry="$repo_root/.documentation/devspark.json"

    if [[ ! -f "$registry" ]]; then
        echo '{"tags":{},"rules":[],"hints":{}}'; return
    fi

    local app_path
    app_path=$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .path // ""' "$registry" 2>/dev/null)
    local app_json="$repo_root/$app_path/app.json"
    local manifest='{}'
    if [[ -f "$app_json" ]]; then
        manifest=$(cat "$app_json")
    fi

    jq -n --arg id "$app_id" --argjson manifest "$manifest" --slurpfile reg "$registry" '
        $reg[0] as $r |
        ($r.apps[] | select(.id == $id)) as $app |
        reduce ($app.inherits // [])[] as $pname (
            { tags: {}, rules: [], hints: {} };
            ($r.profiles[$pname] // {}) as $p |
            .tags = (.tags * ($p.tags // {})) |
            .rules = (.rules + (($p.rules // []) - .rules)) |
            .hints = (.hints * ($p.hints // {}))
        ) |
        (($app.overrides // {}) as $o |
            .tags = (.tags * ($o.tags // {})) |
            .rules = (.rules + (($o.rules // []) - .rules)) |
            .hints = (.hints * ($o.hints // {}))
        ) |
        .tags = (.tags * ($manifest.tags // {})) |
        .rules = (.rules + (($manifest.rules // []) - .rules)) |
        .hints = (.hints * ($manifest.hints // {}))
    '
}

# Override get_feature_paths for app-scoped workflows (T028)
get_feature_paths_app_aware() {
    local repo_root
    repo_root=$(get_repo_root)
    local current_branch
    current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Determine doc root based on app context
    local doc_root="$repo_root/.documentation"
    if [[ -n "$DEVSPARK_DOC_ROOT" ]]; then
        doc_root="$DEVSPARK_DOC_ROOT"
    fi

    # Use prefix-based lookup within the resolved doc root
    local specs_dir="$doc_root/specs"
    local feature_dir
    if [[ -d "$specs_dir" ]]; then
        feature_dir=$(find_feature_dir_by_prefix "$(dirname "$doc_root")" "$current_branch" 2>/dev/null || echo "$specs_dir/$current_branch")
        # Re-base if we're in app scope
        if [[ "$doc_root" != "$repo_root/.documentation" ]]; then
            feature_dir="$specs_dir/$current_branch"
        fi
    else
        feature_dir="$specs_dir/$current_branch"
    fi

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
DEVSPARK_SCOPE='${DEVSPARK_SCOPE:-repo}'
DEVSPARK_APP_ID='${DEVSPARK_APP_ID:-}'
DEVSPARK_DOC_ROOT='$doc_root'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

