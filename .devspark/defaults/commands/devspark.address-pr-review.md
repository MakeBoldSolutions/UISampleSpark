---
description: Address open PR review findings with enforced commit isolation between code fixes and review-file updates
handoffs:
  - label: Re-Review Updated PR
    agent: devspark.pr-review
    prompt: Run /devspark.pr-review UPDATE for this PR after fixes are committed
scripts:
  sh: pwsh -File .devspark/scripts/powershell/address-pr-review.ps1 -PrId $ARGUMENTS -Json
  ps: .devspark/scripts/powershell/address-pr-review.ps1 -PrId $ARGUMENTS -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command is the **author-side companion** to `/devspark.pr-review`. It helps you address open findings in `/.documentation/specs/pr-review/pr-{PR_ID}.md` while enforcing commit isolation:

1. Commit code fixes first.
2. Commit review-file updates second.

**IMPORTANT**: The staging gates are mechanical and mandatory. Do not bypass them.

## Prerequisites

- Existing PR review file at `/.documentation/specs/pr-review/pr-{PR_ID}.md`
- Git repository with the PR source branch checked out
- PowerShell 7+ (`pwsh`) available for the gate helper script

## Outline

### Phase 0 — Load context

> **Script Resolution**: Before running `{SCRIPT}`, apply the 2-tier override check for PowerShell only — if `.documentation/scripts/powershell/address-pr-review.ps1` exists on disk, run that file instead, preserving all arguments. Team override in `.documentation/scripts/powershell/` takes priority over `.devspark/scripts/powershell/`.

1. Run `{SCRIPT}` with `-PrId {PR_ID} -Json`.
2. Fail fast if `/.documentation/specs/pr-review/pr-{PR_ID}.md` is missing.
3. Parse open findings from checklist lines matching:
   - `- [ ] **C-##**`
   - `- [ ] **H-##**`
   - `- [ ] **M-##**`
   - `- [ ] **L-##**`
   - `- [ ] **CON-##**`
4. Confirm current branch equals the PR source branch. Refuse if mismatched.
5. Capture `git status --short`.
6. **Refuse to proceed** if any staged path matches `.documentation/specs/pr-review/pr-*.md`.

If no open findings remain, print: `Nothing to address.` and stop.

### Phase 1 — Plan

1. Render open findings as a checklist with severity badges.
2. Ask which findings to address this iteration (`all` allowed).
3. Build an internal todo list with one item per selected finding.

### Phase 2 — Fix loop (per finding)

For each selected finding:

1. Read the cited file/lines and confirm the issue.
2. Apply the recommended fix, or propose an alternative and show the diff.
3. Stage **only** code paths touched by that fix.
4. Never run `git add .`.
5. Never stage `/.documentation/specs/pr-review/pr-{PR_ID}.md` during this phase.

### Phase 3 — Validate

1. Re-run the **locked pytest scope** from the review file `Stats` table (reuse the same command; do not pick a new scope).
2. Re-run project-specific validators explicitly recorded in the review file.
3. If any validation fails, return to Phase 2.
4. Do not continue until validations pass.

### Phase 4 — Commit code fixes (isolation gate #1)

1. Run gate script with `-Gate code-only` before commit.
2. If the gate fails, **abort** and print offending staged paths.
3. Review staged diff and commit with:

```text
fix(pr-{PR_ID}): address {M-02,M-04,M-05}
```

1. Capture the resulting short hash as `{FIX_SHA}`.

### Phase 5 — Update the review file

For each fixed finding:

1. Flip `- [ ]` to `- [x]`.
2. Append `— *Fixed in {FIX_SHA}: {one-line how}*` to the finding heading line.
3. Do **not** change finding IDs, descriptions, or broken/fix code blocks.

Then update metadata:

1. Bump revision in the header table (`Rev N -> Rev N+1`).
2. Update `Stats` with current churn/test counts/commit snapshot.
3. Append a new row to `Revision Log` for this iteration.
4. Stage only `/.documentation/specs/pr-review/pr-{PR_ID}.md`.

### Phase 6 — Commit review file (isolation gate #2)

1. Run gate script with `-Gate review-only` before commit.
2. If the gate fails, **abort** and print offending staged paths.
3. Commit with:

```text
review(pr-{PR_ID}): rev {N} — {X} fixed, {Y} remaining
```

1. Verify commit disjointness:

```bash
git log HEAD~2..HEAD --name-only
```

Parse the two commits and assert they share zero file paths.

### Phase 7 — Handoff

1. Print both new commit hashes (`fix` and `review`).
2. Suggest focused re-review:

```text
Run `/devspark.pr-review UPDATE {PR_URL}` to trigger a focused re-review.
```

## Guidelines

### Commit Discipline (MUST)

- A commit touching `/.documentation/specs/pr-review/pr-{PR_ID}.md` MUST NOT include any other path.
- Code fixes and review-file updates MUST be separate commits.
- Do not amend/squash these two commits together.

### Gate Execution (MUST)

- Use the helper script as the source of truth for staging gates.
- If a gate exits non-zero, stop and resolve staging before retrying.

### Edit Scope (MUST)

In review files, limit edits to:

- finding checkbox state
- heading-line fixed-in suffix
- revision metadata (`Revision`, `Stats`, `Revision Log`)

Everything else is immutable during addressing.

## Context

$ARGUMENTS

## Shared Review Resolution Contract Output

When emitting findings (review observations, issues, recommendations), structure each entry to include the shared resolution contract fields so downstream tools (/devspark.address-pr-review, telemetry, harvest) can act on them deterministically:

```yaml
findings:
  - finding_id: <stable-id-unique-within-this-command-output>   # e.g., analyze-001, clarify-002
    severity: critical | high | medium | low
    description: <1-3 sentence problem statement>
    recommended_action: <machine-actionable next step>
    execution_mode: auto | selective | manual
    status: open                                                  # set to `resolved` after remediation
    outcome: ""                                                  # populated post-resolution by address-pr-review
```

inding_id MUST be stable across re-runs when the underlying issue is unchanged. xecution_mode MUST be one of: `auto` (safe to apply automatically), `selective` (apply with reviewer approval), `manual` (requires human implementation). The `status` and `outcome` fields are written by `/devspark.address-pr-review` (FR-028).
