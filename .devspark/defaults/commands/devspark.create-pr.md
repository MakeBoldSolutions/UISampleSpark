---
description: Draft or update a spec-aware pull request with task, checklist, and gate visibility before review.
handoffs:
  - label: Review Pull Request
    agent: devspark.pr-review
    prompt: Review the pull request for constitution compliance
scripts:
  sh: .devspark/scripts/bash/create-pr.sh --mode preflight --json $ARGUMENTS
  ps: .devspark/scripts/powershell/create-pr.ps1 -Mode Preflight -Json $ARGUMENTS
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Routing Contract

If a spec exists for the active branch, read the YAML frontmatter in `spec.md` before drafting the PR. Treat `classification`, `risk_level`, and `required_gates` as authoritative metadata.

If no spec exists but a quickfix record exists for the current branch under `/.documentation/quickfixes/`, use that quickfix record as the lifecycle source of truth.

If the spec body and frontmatter disagree, surface the inconsistency to the user rather than overriding the metadata.

## Overview

`/devspark.create-pr` is the default post-implementation step for quick-spec and full-spec routes. It gathers PR context, checks task and checklist completion, summarizes any gate artifacts it can find, drafts a PR title/body, and asks the user to confirm before creating or updating the pull request.

This command is advisory. Dirty trees, missing specs, incomplete tasks, unresolved gates, and explicit gate acknowledgements are warnings that the agent must explain, not hard blocks. The user decides whether to proceed, adjust the draft, or stop.

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Run Preflight Context

> **Script Resolution**: Before running `{SCRIPT}`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `{SCRIPT}` once from the repository root and parse the returned JSON.

Use the script output as the source of truth for:

- current branch, target branch, dirty tree status, and push status
- authentication status and creation support
- existing PR (number, URL, title, state, draft flag)
- spec and quickfix detection (paths, classification, risk, required gates)
- task completion counts and checklist summaries
- gate artifact scan results and severities
- gate acknowledgements from tasks or quickfix records
- `diff.lines_summary`, `diff.commit_log` (hash/subject/author/date), `diff.file_changes` (status/path)

If auth is unavailable or the platform does not support automated PR creation, report that clearly and stop before any create/update action.

### 2. Surface Warnings Before Drafting

Present any relevant warnings before drafting the PR:

- dirty working tree
- existing PR already open for this branch
- missing spec
- incomplete tasks
- incomplete checklists
- unresolved blocking gate artifacts
- explicit gate acknowledgements already recorded in tasks or quickfix artifacts
- no gate artifacts found

Use recommendation language, not hard-block language.

### 3. Draft the PR Title and Description

Derive the title: spec title → branch name → most recent `diff.commit_log` subject.

Build the body from the preflight JSON (keep total under 4,000 characters):

- **Summary** — spec intent/summary, quickfix problem statement, or inferred from `diff.commit_log` subjects
- **Changes** — file list from `diff.file_changes` (status + path) and `diff.lines_summary`
- **Task Completion** — `N/M tasks complete`; checklist summary if present
- **Quality Gates** — gate artifact statuses, or "No gate artifacts found"
- **Gate Acknowledgements** — explicit decisions to proceed (omit section if none)
- **Spec/Quickfix Reference** — path to spec or quickfix record, or N/A
- **Notes** — warnings, reviewer hints, user-supplied notes

### 4. Ask for Explicit Confirmation

Before creating or updating the PR, show the user:

- proposed title
- proposed body
- whether this will create a new PR or update an existing one
- any flags inferred or requested (`--draft`, `--reviewer`, `--label`, `--assignee`)

Ask explicitly whether to:

- create the PR
- update the existing PR
- adjust the draft first
- stop without changing anything

Do **not** call the create/update script mode until the user confirms.

### 5. Create or Update the PR

When the user confirms, run the platform script in create or update mode.

Supported flags:

- `--draft`
- `--reviewer <name>`
- `--label <label>`
- `--assignee <name>`
- `--base <branch>`
- `--issue <ref>`

Use create mode when no PR exists. Use update mode when a PR already exists for the branch or the user explicitly chooses update.

### 6. Report Result

After creation or update, report:

- PR number
- PR URL
- PR title
- whether it is draft or ready for review
- any warnings that still remain unresolved

## Guidelines

- Branches with no spec are valid. Use a quickfix record if found; otherwise derive context from `diff.commit_log` and branch name.
- If task or checklist artifacts are missing, report that plainly and continue with a lighter draft.
- If gate artifacts are absent, recommend `/devspark.analyze` or `/devspark.critic` before merge.
- Surface gate acknowledgements plainly in the draft body rather than burying them in prose.
