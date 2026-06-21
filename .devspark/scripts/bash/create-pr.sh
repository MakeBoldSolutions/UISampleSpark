#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/platform.sh"

MODE="preflight"
export JSON_MODE=false
TITLE=""
BODY=""
BODY_FILE=""
BASE_BRANCH=""
PR_NUMBER=""
DRAFT=false
declare -a REVIEWERS=()
declare -a LABELS=()
declare -a ASSIGNEES=()
declare -a ISSUES=()

if ! command -v jq >/dev/null 2>&1; then
    printf '{"error":true,"message":"jq is required for create-pr.sh","details":"Install jq or use the PowerShell create-pr script."}\n'
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --json)
            JSON_MODE=true
            shift
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --body)
            BODY="$2"
            shift 2
            ;;
        --body-file)
            BODY_FILE="$2"
            shift 2
            ;;
        --base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --pr-number)
            PR_NUMBER="$2"
            shift 2
            ;;
        --draft)
            DRAFT=true
            shift
            ;;
        --reviewer)
            REVIEWERS+=("$2")
            shift 2
            ;;
        --label)
            LABELS+=("$2")
            shift 2
            ;;
        --assignee)
            ASSIGNEES+=("$2")
            shift 2
            ;;
        --issue)
            ISSUES+=("$2")
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

json_error() {
    local message="$1"
    local details="${2:-}"
    jq -n --arg message "$message" --arg details "$details" '{error: true, message: $message, details: $details}'
}

get_default_base_branch() {
    local branch=""
    if command -v gh >/dev/null 2>&1 && check_platform_auth; then
        branch=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || true)
    fi
    if [[ -z "$branch" ]]; then
        branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
    fi
    [[ -n "$branch" ]] || branch="main"
    printf '%s\n' "$branch"
}

resolve_body() {
    local body_value="$BODY"
    if [[ -n "$BODY_FILE" && -f "$BODY_FILE" ]]; then
        body_value=$(cat "$BODY_FILE")
    fi
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        local issue_line=""
        issue_line=$(printf '%s, ' "${ISSUES[@]}")
        issue_line=${issue_line%, }
        if [[ -n "$body_value" ]]; then
            body_value+=$'\n\n'
        fi
        body_value+="Refs: $issue_line"
    fi
    printf '%s' "$body_value"
}

trim_text() {
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

extract_section_text() {
    local file_path="$1"
    local section_name="$2"
    [[ -f "$file_path" ]] || return 0
    awk -v section="$section_name" '
        /^## / {
            h = substr($0, 4)
            sub(/^[[:space:]]+/, "", h); sub(/[[:space:]]+$/, "", h)
            if (capture) exit
            capture = (tolower(h) == tolower(section))
            next
        }
        capture { lines[n++] = $0 }
        END {
            s = 0; while (s < n && lines[s] ~ /^[[:space:]]*$/) s++
            e = n - 1; while (e >= s && lines[e] ~ /^[[:space:]]*$/) e--
            for (i = s; i <= e; i++) print lines[i]
        }
    ' "$file_path"
}

find_quickfix_record_for_branch() {
    local repo_root="$1"
    local branch_name="$2"
    local quickfix_dir="$repo_root/.documentation/quickfixes"
    [[ -d "$quickfix_dir" ]] || return 0
    local best_id="" best_path="" file branch_line quickfix_id
    shopt -s nullglob
    for file in "$quickfix_dir"/*.md; do
        branch_line=$(grep -m1 '^- \*\*Branch\*\*:' "$file" 2>/dev/null \
            | sed 's/^- \*\*Branch\*\*:[[:space:]]*//' | sed 's/[[:space:]]*$//' || true)
        if [[ "$branch_line" == "$branch_name" ]]; then
            quickfix_id=$(grep -m1 '^- \*\*ID\*\*:' "$file" 2>/dev/null \
                | sed 's/^- \*\*ID\*\*:[[:space:]]*//' | sed 's/[[:space:]]*$//' || true)
            [[ -z "$quickfix_id" ]] && quickfix_id=$(basename "$file" .md)
            if [[ -z "$best_id" || "$quickfix_id" > "$best_id" ]]; then
                best_id="$quickfix_id"
                best_path="$file"
            fi
        fi
    done
    shopt -u nullglob
    [[ -n "$best_path" ]] && printf '%s\n' "$best_path"
}

build_quickfix_json() {
    local quickfix_path="$1"
    [[ -f "$quickfix_path" ]] || { printf 'null\n'; return; }
    local classification risk_level required_gates recommended_next_step problem_statement gate_ack_text quickfix_title quickfix_id
    classification=$(get_markdown_frontmatter_value "$quickfix_path" classification || true)
    risk_level=$(get_markdown_frontmatter_value "$quickfix_path" risk_level || true)
    required_gates=$(get_markdown_frontmatter_value "$quickfix_path" required_gates || true)
    recommended_next_step=$(get_markdown_frontmatter_value "$quickfix_path" recommended_next_step || true)
    quickfix_title=$(grep -m1 '^# ' "$quickfix_path" | sed 's/^# //' || true)
    quickfix_id=$(grep -m1 '^- \*\*ID\*\*:' "$quickfix_path" | sed 's/^- \*\*ID\*\*:[[:space:]]*//' || true)
    problem_statement=$(extract_section_text "$quickfix_path" "Problem Statement" | trim_text)
    gate_ack_text=$(extract_section_text "$quickfix_path" "Gate Acknowledgements" | trim_text)

    jq -n \
        --arg path "$quickfix_path" \
        --arg id "$quickfix_id" \
        --arg title "$quickfix_title" \
        --arg classification "$classification" \
        --arg risk_level "$risk_level" \
        --arg required_gates "$required_gates" \
        --arg recommended_next_step "$recommended_next_step" \
        --arg problem_statement "$problem_statement" \
        --arg gate_acknowledgements "$gate_ack_text" \
        '{path: $path, id: $id, title: $title, classification: $classification, risk_level: $risk_level, required_gates: $required_gates, recommended_next_step: $recommended_next_step, problem_statement: $problem_statement, gate_acknowledgements: $gate_acknowledgements}'
}

count_tasks() {
    local tasks_path="$1"
    if [[ ! -f "$tasks_path" ]]; then
        printf '0\t0\t0\n'
        return
    fi
    local total completed incomplete
    total=$(grep -cE '^\s*- \[([ xX])\]' "$tasks_path" 2>/dev/null || echo '0')
    completed=$(grep -cE '^\s*- \[[xX]\]' "$tasks_path" 2>/dev/null || echo '0')
    incomplete=$((total - completed))
    printf '%s\t%s\t%s\n' "$total" "$completed" "$incomplete"
}

collect_checklists_json() {
    local checklist_dir="$1"
    if [[ ! -d "$checklist_dir" ]]; then
        printf '[]\n'
        return
    fi

    local items=()
    local file
    shopt -s nullglob
    for file in "$checklist_dir"/*.md; do
        local total completed incomplete status
        total=$(grep -cE '^\s*- \[([ xX])\]' "$file" 2>/dev/null || echo '0')
        completed=$(grep -cE '^\s*- \[[xX]\]' "$file" 2>/dev/null || echo '0')
        incomplete=$((total - completed))
        if [[ "$incomplete" -eq 0 ]]; then
            status="pass"
        else
            status="fail"
        fi
        items+=("$(jq -n --arg name "$(basename "$file")" --argjson total "$total" --argjson completed "$completed" --argjson incomplete "$incomplete" --arg status "$status" '{name: $name, total: $total, completed: $completed, incomplete: $incomplete, status: $status}')")
    done
    shopt -u nullglob
    if [[ ${#items[@]} -eq 0 ]]; then
        printf '[]\n'
    else
        printf '%s\n' "${items[@]}" | jq -s '.'
    fi
}

scan_gate_artifacts_json() {
    local feature_dir="$1"
    local items=()
    local gate path status blocking severity summary
    for gate in analyze critic checklist; do
        path=""
        if [[ -f "$feature_dir/gates/$gate.md" ]]; then
            path="$feature_dir/gates/$gate.md"
        elif [[ -f "$feature_dir/$gate.md" ]]; then
            path="$feature_dir/$gate.md"
        fi
        if [[ -n "$path" ]]; then
            status=$(grep -m1 '^status:' "$path" 2>/dev/null | sed 's/^status:[[:space:]]*//' || true)
            blocking=$(grep -m1 '^blocking:' "$path" 2>/dev/null | sed 's/^blocking:[[:space:]]*//' || true)
            severity=$(grep -m1 '^severity:' "$path" 2>/dev/null | sed 's/^severity:[[:space:]]*//' || true)
            summary=$(grep -m1 '^summary:' "$path" 2>/dev/null | sed 's/^summary:[[:space:]]*//' || true)
            [[ -n "$status" ]] || status="unknown"
            [[ -n "$blocking" ]] || blocking="false"
            [[ -n "$severity" ]] || severity="info"
            items+=("$(jq -n --arg gate "$gate" --arg path "$path" --arg status "$status" --arg severity "$severity" --arg summary "$summary" --argjson blocking "$([[ "$blocking" == "true" ]] && echo true || echo false)" '{gate: $gate, path: $path, status: $status, severity: $severity, summary: $summary, blocking: $blocking}')")
        fi
    done
    if [[ ${#items[@]} -eq 0 ]]; then
        printf '[]\n'
    else
        printf '%s\n' "${items[@]}" | jq -s '.'
    fi
}

collect_gate_acknowledgements_json() {
    local tasks_path="$1"
    [[ -f "$tasks_path" ]] || { printf '[]\n'; return; }
    local section_text
    section_text=$(extract_section_text "$tasks_path" "Gate Acknowledgements")
    [[ -n "$section_text" ]] || { printf '[]\n'; return; }

    local -a blocks=()
    local current_block=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed
        trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "$trimmed" ]]; then
            if [[ -n "$current_block" ]]; then
                blocks+=("$current_block")
                current_block=""
            fi
        elif [[ "$trimmed" == "- Gate:"* && -n "$current_block" ]]; then
            blocks+=("$current_block")
            current_block="$trimmed"
        else
            current_block="${current_block:+$current_block$'\n'}$trimmed"
        fi
    done <<< "$section_text"
    [[ -n "$current_block" ]] && blocks+=("$current_block")

    if [[ ${#blocks[@]} -eq 0 ]]; then
        printf '[]\n'
    else
        local json='[]'
        for block in "${blocks[@]}"; do
            json=$(jq --arg e "$block" '. + [$e]' <<< "$json")
        done
        printf '%s\n' "$json"
    fi
}

collect_preflight() {
    local repo_root current_branch target_branch dirty auth_ok cli_available creation_supported
    local local_head remote_head origin_exists remote_branch_exists branch_pushed_to_remote branch_push_details clean_worktree
    local feature_dir spec_path plan_path tasks_path checklist_dir quickfix_path
    local spec_exists=false plan_exists=false tasks_exists=false
    local spec_title="" classification="" risk_level="" required_gates="" recommended_next_step=""
    local tasks_total=0 tasks_completed=0 tasks_incomplete=0
    local diff_ref lines_summary changed_files_count file_changes_json commit_log_json existing_pr_json checklists_json gate_artifacts_json gate_acknowledgements_json quickfix_json
    local existing_pr=false existing_pr_number="" existing_pr_url="" existing_pr_title="" existing_pr_state="" existing_pr_draft=false

    repo_root=$(get_repo_root)
    current_branch=$(get_current_branch)
    target_branch="${BASE_BRANCH:-$(get_default_base_branch)}"
    local_head=$(git rev-parse HEAD 2>/dev/null || echo "")
    if [[ -n "$(git status --porcelain 2>/dev/null || true)" ]]; then
        dirty=true
    else
        dirty=false
    fi
    if [[ "$dirty" == "true" ]]; then
        clean_worktree=false
    else
        clean_worktree=true
    fi

    origin_exists=false
    remote_branch_exists=false
    branch_pushed_to_remote=false
    remote_head=""
    branch_push_details=""
    if git remote get-url origin >/dev/null 2>&1; then
        origin_exists=true
        remote_head=$(git ls-remote --heads origin "refs/heads/$current_branch" 2>/dev/null | awk 'NR==1 {print $1}')
        if [[ -n "$remote_head" ]]; then
            remote_branch_exists=true
        fi
    fi

    if [[ "$origin_exists" != true ]]; then
        branch_push_details="Remote 'origin' is not configured"
    elif [[ "$remote_branch_exists" != true ]]; then
        branch_push_details="Branch '$current_branch' has not been pushed to origin"
    elif [[ -n "$local_head" && "$local_head" == "$remote_head" ]]; then
        branch_pushed_to_remote=true
        branch_push_details="Branch '$current_branch' is pushed to origin"
    else
        branch_push_details="Push the latest commits from '$current_branch' to origin before creating a PR"
    fi

    if command -v gh >/dev/null 2>&1; then
        cli_available=true
        if check_platform_auth; then
            auth_ok=true
        else
            auth_ok=false
        fi
    else
        cli_available=false
        auth_ok=false
    fi

    if [[ "$DEVSPARK_PLATFORM_NAME" == "github" && "$cli_available" == true ]]; then
        creation_supported=true
    else
        creation_supported=false
    fi

    feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")
    spec_path="$feature_dir/spec.md"
    plan_path="$feature_dir/plan.md"
    tasks_path="$feature_dir/tasks.md"
    checklist_dir="$feature_dir/checklists"

    [[ -f "$spec_path" ]] && spec_exists=true
    [[ -f "$plan_path" ]] && plan_exists=true
    [[ -f "$tasks_path" ]] && tasks_exists=true

    if [[ "$spec_exists" == true ]]; then
        spec_title=$(grep -m1 '^# ' "$spec_path" | sed 's/^# //' || true)
        classification=$(get_markdown_frontmatter_value "$spec_path" classification || true)
        risk_level=$(get_markdown_frontmatter_value "$spec_path" risk_level || true)
        required_gates=$(get_markdown_frontmatter_value "$spec_path" required_gates || true)
        recommended_next_step=$(get_markdown_frontmatter_value "$spec_path" recommended_next_step || true)
    fi

    if [[ "$tasks_exists" == true ]]; then
        IFS=$'\t' read -r tasks_total tasks_completed tasks_incomplete < <(count_tasks "$tasks_path")
    fi

    checklists_json=$(collect_checklists_json "$checklist_dir")
    gate_artifacts_json=$(scan_gate_artifacts_json "$feature_dir")
    gate_acknowledgements_json=$(collect_gate_acknowledgements_json "$tasks_path")
    quickfix_path=$(find_quickfix_record_for_branch "$repo_root" "$current_branch")
    quickfix_json=$(build_quickfix_json "$quickfix_path")

    if [[ "$spec_exists" != true && "$quickfix_json" != "null" ]]; then
        classification=$(echo "$quickfix_json" | jq -r '.classification // ""')
        risk_level=$(echo "$quickfix_json" | jq -r '.risk_level // ""')
        required_gates=$(echo "$quickfix_json" | jq -r '.required_gates // ""')
        recommended_next_step=$(echo "$quickfix_json" | jq -r '.recommended_next_step // ""')
        spec_title=$(echo "$quickfix_json" | jq -r '.title // ""')
        gate_acknowledgements_json=$(echo "$quickfix_json" | jq -c '[.gate_acknowledgements] | map(select(length > 0))')
    fi

    if git rev-parse --verify "origin/$target_branch" >/dev/null 2>&1; then
        git fetch origin "$target_branch" >/dev/null 2>&1 || true
        diff_ref="origin/$target_branch...HEAD"
    else
        diff_ref="HEAD~1...HEAD"
    fi
    lines_summary=$(git diff --shortstat "$diff_ref" 2>/dev/null || echo "")
    file_changes_json=$(git diff --name-status "$diff_ref" 2>/dev/null | \
        jq -R 'split("\t") |
            if length == 3 then {status: (.[0] | .[0:1]), path: .[2], from: .[1]}
            elif length >= 2 then {status: .[0], path: .[1]}
            else empty end' | \
        jq -s '.' 2>/dev/null || printf '[]\n')
    changed_files_count=$(printf '%s' "$file_changes_json" | jq 'length')
    commit_log_json=$(git log --format='%H%x1f%s%x1f%an%x1f%ai' -n 20 "$diff_ref" 2>/dev/null | \
        jq -R 'split("") | if length >= 4 then {hash: .[0], subject: .[1], author: .[2], date: .[3]} else empty end' | \
        jq -s '.' 2>/dev/null || printf '[]\n')

    if [[ "$cli_available" == true && "$auth_ok" == true ]]; then
        existing_pr_json=$(gh pr list --head "$current_branch" --json number,url,title,state,isDraft --limit 1 2>/dev/null | jq '.[0] // {}' 2>/dev/null || echo '{}')
        existing_pr_number=$(echo "$existing_pr_json" | jq -r '.number // empty')
        if [[ -n "$existing_pr_number" ]]; then
            existing_pr=true
            existing_pr_url=$(echo "$existing_pr_json" | jq -r '.url // ""')
            existing_pr_title=$(echo "$existing_pr_json" | jq -r '.title // ""')
            existing_pr_state=$(echo "$existing_pr_json" | jq -r '.state // ""')
            existing_pr_draft=$(echo "$existing_pr_json" | jq -r '.isDraft // false')
        fi
    fi

    jq -n \
        --arg repo_root "$repo_root" \
        --arg current_branch "$current_branch" \
        --arg target_branch "$target_branch" \
        --arg spec_path "$spec_path" \
        --arg plan_path "$plan_path" \
        --arg tasks_path "$tasks_path" \
        --arg feature_dir "$feature_dir" \
        --arg checklist_dir "$checklist_dir" \
        --arg spec_title "$spec_title" \
        --arg classification "$classification" \
        --arg risk_level "$risk_level" \
        --arg required_gates "$required_gates" \
        --arg recommended_next_step "$recommended_next_step" \
        --arg lines_summary "$lines_summary" \
        --arg existing_pr_url "$existing_pr_url" \
        --arg existing_pr_title "$existing_pr_title" \
        --arg existing_pr_state "$existing_pr_state" \
        --arg local_head "$local_head" \
        --arg remote_head "$remote_head" \
        --arg branch_push_details "$branch_push_details" \
        --argjson dirty "$dirty" \
        --argjson clean_worktree "$clean_worktree" \
        --argjson auth_ok "$auth_ok" \
        --argjson cli_available "$cli_available" \
        --argjson creation_supported "$creation_supported" \
        --argjson origin_exists "$origin_exists" \
        --argjson remote_branch_exists "$remote_branch_exists" \
        --argjson branch_pushed_to_remote "$branch_pushed_to_remote" \
        --argjson spec_exists "$spec_exists" \
        --argjson plan_exists "$plan_exists" \
        --argjson tasks_exists "$tasks_exists" \
        --argjson tasks_total "$tasks_total" \
        --argjson tasks_completed "$tasks_completed" \
        --argjson tasks_incomplete "$tasks_incomplete" \
        --argjson changed_files_count "$changed_files_count" \
        --argjson existing_pr "$existing_pr" \
        --argjson existing_pr_number "${existing_pr_number:-0}" \
        --argjson existing_pr_draft "$([[ "$existing_pr_draft" == "true" ]] && echo true || echo false)" \
        --argjson commit_log "$commit_log_json" \
        --argjson file_changes "$file_changes_json" \
        --argjson checklists "$checklists_json" \
        --argjson gate_artifacts "$gate_artifacts_json" \
        --argjson gate_acknowledgements "$gate_acknowledgements_json" \
        --argjson quickfix_record "$quickfix_json" \
        '{
            repo_root: $repo_root,
            current_branch: $current_branch,
            target_branch: $target_branch,
            dirty_worktree: $dirty,
            prerequisites: {
                clean_worktree: $clean_worktree,
                branch_pushed_to_remote: $branch_pushed_to_remote
            },
            remote: {
                name: "origin",
                exists: $origin_exists,
                branch_exists: $remote_branch_exists,
                branch_pushed_to_remote: $branch_pushed_to_remote,
                local_head: $local_head,
                remote_head: $remote_head,
                details: $branch_push_details
            },
            cli_available: $cli_available,
            auth_ok: $auth_ok,
            creation_supported: $creation_supported,
            feature: {
                dir: $feature_dir,
                spec_path: $spec_path,
                plan_path: $plan_path,
                tasks_path: $tasks_path,
                checklist_dir: $checklist_dir,
                spec_exists: $spec_exists,
                plan_exists: $plan_exists,
                tasks_exists: $tasks_exists,
                spec_title: $spec_title,
                classification: $classification,
                risk_level: $risk_level,
                required_gates: $required_gates,
                recommended_next_step: $recommended_next_step,
                tasks_total: $tasks_total,
                tasks_completed: $tasks_completed,
                tasks_incomplete: $tasks_incomplete,
                checklists: $checklists,
                gate_artifacts: $gate_artifacts,
                gate_acknowledgements: $gate_acknowledgements
            },
            diff: {
                changed_files_count: $changed_files_count,
                lines_summary: $lines_summary,
                commit_log: $commit_log,
                file_changes: $file_changes
            },
            quickfix_record: $quickfix_record,
            existing_pr: {
                exists: $existing_pr,
                number: (if $existing_pr then $existing_pr_number else null end),
                url: $existing_pr_url,
                title: $existing_pr_title,
                state: $existing_pr_state,
                draft: $existing_pr_draft
            }
        }'
}

run_create_or_update() {
    local action="$1"
    local preflight_json body_value pr_to_edit gh_output pr_url pr_view_json
    preflight_json=$(collect_preflight)

    if [[ "$(echo "$preflight_json" | jq -r '.prerequisites.clean_worktree')" != "true" ]]; then
        json_error "Working tree has unmanaged changes" "Commit, stash, or discard all changes before creating or updating a PR"
        return 1
    fi
    if [[ "$(echo "$preflight_json" | jq -r '.prerequisites.branch_pushed_to_remote')" != "true" ]]; then
        json_error "Current branch is not pushed to remote" "$(echo "$preflight_json" | jq -r '.remote.details')"
        return 1
    fi

    if [[ "$(echo "$preflight_json" | jq -r '.creation_supported')" != "true" ]]; then
        json_error "Automated PR creation is only supported for GitHub in this release" "Platform: $DEVSPARK_PLATFORM_NAME"
        return 1
    fi
    if [[ "$(echo "$preflight_json" | jq -r '.auth_ok')" != "true" ]]; then
        json_error "GitHub CLI is not authenticated" "Run: gh auth login"
        return 1
    fi

    body_value=$(resolve_body)
    if [[ -z "$TITLE" || -z "$body_value" ]]; then
        json_error "Title and body are required for create/update mode" "Pass --title and --body or --body-file"
        return 1
    fi

    if [[ "$action" == "create" && "$(echo "$preflight_json" | jq -r '.existing_pr.exists')" == "true" ]]; then
        json_error "A PR already exists for this branch" "Use update mode or provide --pr-number"
        return 1
    fi

    if [[ "$action" == "update" ]]; then
        pr_to_edit="$PR_NUMBER"
        if [[ -z "$pr_to_edit" ]]; then
            pr_to_edit=$(echo "$preflight_json" | jq -r '.existing_pr.number // empty')
        fi
        if [[ -z "$pr_to_edit" ]]; then
            json_error "No PR found to update" "Create a PR first or pass --pr-number"
            return 1
        fi
        gh pr edit "$pr_to_edit" --title "$TITLE" --body "$body_value" --base "${BASE_BRANCH:-$(echo "$preflight_json" | jq -r '.target_branch')}" >/dev/null
        for reviewer in "${REVIEWERS[@]}"; do gh pr edit "$pr_to_edit" --add-reviewer "$reviewer" >/dev/null; done
        for label in "${LABELS[@]}"; do gh pr edit "$pr_to_edit" --add-label "$label" >/dev/null; done
        for assignee in "${ASSIGNEES[@]}"; do gh pr edit "$pr_to_edit" --add-assignee "$assignee" >/dev/null; done
        pr_view_json=$(gh pr view "$pr_to_edit" --json number,url,title,state,isDraft 2>/dev/null)
    else
        local -a gh_args=()
        gh_args+=(--title "$TITLE" --body "$body_value")
        gh_args+=(--base "${BASE_BRANCH:-$(echo "$preflight_json" | jq -r '.target_branch')}")
        if $DRAFT; then gh_args+=(--draft); fi
        for reviewer in "${REVIEWERS[@]}"; do gh_args+=(--reviewer "$reviewer"); done
        for label in "${LABELS[@]}"; do gh_args+=(--label "$label"); done
        for assignee in "${ASSIGNEES[@]}"; do gh_args+=(--assignee "$assignee"); done
        gh_output=$(gh pr create "${gh_args[@]}" 2>/dev/null || true)
        pr_url=$(printf '%s\n' "$gh_output" | tail -n 1)
        if [[ -z "$pr_url" ]]; then
            json_error "Failed to create pull request" "$gh_output"
            return 1
        fi
        pr_view_json=$(gh pr view "$pr_url" --json number,url,title,state,isDraft 2>/dev/null)
    fi

    jq -n --arg action "$action" --arg title "$(echo "$pr_view_json" | jq -r '.title')" --arg url "$(echo "$pr_view_json" | jq -r '.url')" --arg state "$(echo "$pr_view_json" | jq -r '.state')" --argjson number "$(echo "$pr_view_json" | jq '.number')" --argjson draft "$(echo "$pr_view_json" | jq '.isDraft // false')" '{status: "ok", action: $action, pr_number: $number, url: $url, title: $title, state: $state, draft: $draft}'
}

main() {
    case "$MODE" in
        preflight)
            collect_preflight
            ;;
        create)
            run_create_or_update create
            ;;
        update)
            run_create_or_update update
            ;;
        *)
            json_error "Unknown mode" "$MODE"
            return 1
            ;;
    esac
}

main