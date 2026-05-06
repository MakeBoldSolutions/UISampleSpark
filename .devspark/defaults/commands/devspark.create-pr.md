---
description: Draft or update a spec-aware pull request with task, checklist, and gate visibility before review.
handoffs:
  - label: Review Pull Request
    agent: devspark.pr-review
    prompt: Review the pull request for constitution compliance
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

> **Script Resolution**: Before running `.devspark/scripts/powershell/create-pr.ps1 -Mode Preflight -Json $ARGUMENTS`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/create-pr.ps1 -Mode Preflight -Json $ARGUMENTS` once from the repository root and parse the returned JSON.

Use the script output as the source of truth for:

- current branch
- target branch
- dirty tree status
- authentication status
- existing PR detection
- spec detection
- task completion counts
- checklist completion summary
- gate artifact scan results
- gate summaries and severities
- explicit gate acknowledgements captured in tasks or quickfix records
- diff stats and recent commit subjects

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

Use recommendation language, not hard-block language. Example:

> "3 of 8 tasks are incomplete. I recommend either finishing them first or creating the PR as a draft."

### 3. Draft the PR Title and Description

Derive the title in this order:

1. spec title
2. branch name
3. recent commit subjects

Draft the body using this structure:

```markdown
## Summary
{From spec intent/summary, or inferred from commits if no spec}

## Changes
{From diff stats and changed file analysis}

## Task Completion
{N/M tasks complete, plus checklist summary if present}

## Quality Gates
{Gate summary, or "No gate artifacts found"}

## Gate Acknowledgements
{Explicit user decisions to proceed despite unresolved findings, if any}

## Spec Reference
{Path to spec directory or N/A}

## Quickfix Reference
{Path to quickfix record or N/A}

## Notes
{Warnings, reviewer hints, or user-supplied notes}
```

Keep the draft concise and under 4,000 characters.

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

- Branches with no spec are valid. If a quickfix record exists for the current branch, use it before falling back to branch name, diff stats, and commit subjects.
- If task or checklist artifacts are missing, report that plainly and continue with a lighter draft.
- If gate artifacts are absent, recommend `/devspark.analyze` or `/devspark.critic` before merge.
- If gate acknowledgements exist, surface them plainly in the draft instead of burying them in prose.
