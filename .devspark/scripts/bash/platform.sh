#!/usr/bin/env bash
# Platform detection and adapter for DevSpark scripts
# Detects GitHub, Azure DevOps, or GitLab and exports platform-specific values.
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"
#        Then use $DEVSPARK_PLATFORM_NAME, $DEVSPARK_PR_CLI, etc.
#
# Override: Set DEVSPARK_PLATFORM env var to force a platform (github|azdo|gitlab)
# Config:   Or set "platform" in .documentation/devspark.json

# Load common if not already loaded
if ! type get_repo_root &>/dev/null; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

detect_platform() {
    # 1. Explicit env var override
    if [[ -n "${DEVSPARK_PLATFORM:-}" ]]; then
        echo "$DEVSPARK_PLATFORM" | tr '[:upper:]' '[:lower:]'
        return
    fi

    # 2. Config file override
    local repo_root
    repo_root=$(get_repo_root)
    local config_file="$repo_root/.documentation/devspark.json"
    if [[ -f "$config_file" ]]; then
        local platform_val
        platform_val=$(jq -r '.platform // empty' "$config_file" 2>/dev/null || true)
        if [[ -n "$platform_val" ]]; then
            echo "$platform_val" | tr '[:upper:]' '[:lower:]'
            return
        fi
    fi

    # 3. CI environment variable detection
    if [[ -n "${GITHUB_ACTIONS:-}" || -n "${GITHUB_REPOSITORY:-}" ]]; then
        echo "github"; return
    fi
    if [[ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI:-}" || -n "${BUILD_REPOSITORY_PROVIDER:-}" ]]; then
        echo "azdo"; return
    fi
    if [[ -n "${GITLAB_CI:-}" || -n "${CI_PROJECT_ID:-}" ]]; then
        echo "gitlab"; return
    fi

    # 4. Repository structure detection
    if [[ -d "$repo_root/.github" ]]; then
        echo "github"; return
    fi
    if [[ -f "$repo_root/azure-pipelines.yml" ]]; then
        echo "azdo"; return
    fi
    if [[ -f "$repo_root/.gitlab-ci.yml" ]]; then
        echo "gitlab"; return
    fi

    # 5. Remote URL detection
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$remote_url" ]]; then
        if [[ "$remote_url" == *github.com* ]]; then echo "github"; return; fi
        if [[ "$remote_url" == *dev.azure.com* || "$remote_url" == *visualstudio.com* ]]; then echo "azdo"; return; fi
        if [[ "$remote_url" == *gitlab.com* || "$remote_url" == *gitlab.* ]]; then echo "gitlab"; return; fi
    fi

    echo "github"  # Default fallback
}

# Set platform-specific variables based on detected platform
_set_platform_config() {
    local platform="$1"

    case "$platform" in
        github)
            DEVSPARK_PLATFORM_NAME="github"
            DEVSPARK_PLATFORM_DISPLAY="GitHub"
            DEVSPARK_PR_CLI="gh"
            DEVSPARK_PR_CLI_INSTALL_URL="https://cli.github.com/"
            DEVSPARK_CI_DIR=".github/workflows"
            DEVSPARK_CI_FILE_PATTERN="*.yml"
            DEVSPARK_AGENT_CONFIG_PATH=".github/agents/copilot-instructions.md"
            DEVSPARK_BRANCH_NAME_LIMIT=244
            DEVSPARK_PR_ENV_VAR="GITHUB_PR_NUMBER"
            ;;
        azdo)
            DEVSPARK_PLATFORM_NAME="azdo"
            DEVSPARK_PLATFORM_DISPLAY="Azure DevOps"
            DEVSPARK_PR_CLI="az"
            DEVSPARK_PR_CLI_INSTALL_URL="https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
            DEVSPARK_CI_DIR="."
            DEVSPARK_CI_FILE_PATTERN="azure-pipelines*.yml"
            DEVSPARK_AGENT_CONFIG_PATH=".github/agents/copilot-instructions.md"
            DEVSPARK_BRANCH_NAME_LIMIT=250
            DEVSPARK_PR_ENV_VAR="SYSTEM_PULLREQUEST_PULLREQUESTID"
            ;;
        gitlab)
            DEVSPARK_PLATFORM_NAME="gitlab"
            DEVSPARK_PLATFORM_DISPLAY="GitLab"
            DEVSPARK_PR_CLI="glab"
            DEVSPARK_PR_CLI_INSTALL_URL="https://gitlab.com/gitlab-org/cli#installation"
            DEVSPARK_CI_DIR="."
            DEVSPARK_CI_FILE_PATTERN=".gitlab-ci.yml"
            DEVSPARK_AGENT_CONFIG_PATH=".github/agents/copilot-instructions.md"
            DEVSPARK_BRANCH_NAME_LIMIT=255
            DEVSPARK_PR_ENV_VAR="CI_MERGE_REQUEST_IID"
            ;;
        *)
            echo "ERROR: Unknown platform: $platform. Supported: github, azdo, gitlab" >&2
            return 1
            ;;
    esac
}

# Check platform CLI authentication
check_platform_auth() {
    case "$DEVSPARK_PLATFORM_NAME" in
        github) gh auth status &>/dev/null ;;
        azdo)   az account show &>/dev/null ;;
        gitlab) glab auth status &>/dev/null ;;
    esac
}

# Resolve script path: app override → team override → stock default (FR-C5)
resolve_devspark_script() {
    local script_name="$1"
    local shell="${2:-bash}"  # bash or powershell

    local repo_root
    repo_root=$(get_repo_root)

    # App-specific override (if app context is set)
    if [[ -n "${DEVSPARK_APP_ID:-}" ]]; then
        local app_doc_root
        app_doc_root=$(resolve_app_doc_root "$repo_root" "$DEVSPARK_APP_ID" 2>/dev/null || true)
        if [[ -n "$app_doc_root" ]]; then
            local app_path="$app_doc_root/scripts/$shell/$script_name"
            if [[ -f "$app_path" ]]; then echo "$app_path"; return; fi
        fi
    fi

    local team_path="$repo_root/.documentation/scripts/$shell/$script_name"
    local stock_path="$repo_root/.devspark/scripts/$shell/$script_name"
    local dev_path="$repo_root/scripts/$shell/$script_name"

    if [[ -f "$team_path" ]];  then echo "$team_path";  return; fi
    if [[ -f "$stock_path" ]]; then echo "$stock_path"; return; fi
    if [[ -f "$dev_path" ]];   then echo "$dev_path";   return; fi

    return 1
}

# Auto-detect and export on source
DEVSPARK_PLATFORM_NAME=""
DEVSPARK_PLATFORM_DISPLAY=""
DEVSPARK_PR_CLI=""
DEVSPARK_PR_CLI_INSTALL_URL=""
DEVSPARK_CI_DIR=""
DEVSPARK_CI_FILE_PATTERN=""
DEVSPARK_AGENT_CONFIG_PATH=""
DEVSPARK_BRANCH_NAME_LIMIT=""
DEVSPARK_PR_ENV_VAR=""

_set_platform_config "$(detect_platform)"

export DEVSPARK_PLATFORM_NAME DEVSPARK_PLATFORM_DISPLAY DEVSPARK_PR_CLI
export DEVSPARK_PR_CLI_INSTALL_URL DEVSPARK_CI_DIR DEVSPARK_CI_FILE_PATTERN
export DEVSPARK_AGENT_CONFIG_PATH DEVSPARK_BRANCH_NAME_LIMIT DEVSPARK_PR_ENV_VAR
