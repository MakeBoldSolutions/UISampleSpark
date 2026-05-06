---
description: Perform constitution-aware pull request review with actionable feedback for any PR in the repository
handoffs:
  - label: View Review History
    agent: devspark.pr-review
    prompt: Show me previous PR reviews in .documentation/specs/pr-review/
scripts:
  sh: .devspark/scripts/bash/get-pr-context.sh $ARGUMENTS --json
  ps: .devspark/scripts/powershell/get-pr-context.ps1 $ARGUMENTS -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command reviews GitHub Pull Requests against the project constitution. It works for **any PR in the repository** regardless of feature branch or target branch. Reviews are stored in `/.documentation/specs/pr-review/pr-{id}.md` for historical reference.

**IMPORTANT**: This command **only provides suggestions** - it does not make any code changes.

Reviews are advisory. The agent must explain constitution or lifecycle issues, recommend a disposition, and let the human decide the next action.

`/devspark.create-pr` is the preferred predecessor for spec-driven work because it collects task, checklist, and gate context before review. If the PR was created manually, continue with review but call out any missing lifecycle context.

## Prerequisites

- Project constitution at `/.documentation/memory/constitution.md` (REQUIRED)
- GitHub repository with PR context
- GitHub CLI (`gh`) installed and authenticated (required)
- **HARD RULE — Branch Sync**: The source (head) branch **MUST** be fully in sync with the target (base) branch. Do **NOT** proceed with review or approval if the source branch is behind the target. Instruct the user to rebase or merge the target branch into the source branch first.

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Initialize Review Context

> **Script Resolution**: Before running `{SCRIPT}`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `{SCRIPT}` to extract PR context and parse JSON output for:

- `PR_CONTEXT`: PR metadata (number, title, branches, commit SHA, files, diff)
- `CONSTITUTION_PATH`: Path to constitution file
- `REVIEW_DIR`: Directory where review will be saved

Treat script JSON as bounded context:

- `files_changed` may be sampled for large PRs.
- Use `files_changed_total` and `files_changed_truncated` to decide whether to zoom in further.
- Do not expand to all files unless user explicitly requests a full exhaustive review.

Execution limits (required):

- Max findings in report: 20 highest-signal items
- Max files to inspect deeply: 25
- Max follow-up searches/reads beyond provided context: 8
- Stop once evidence is sufficient for high-confidence conclusions
- If confidence is low for a specific area, ask one clarifying question

**Iteration Detection**:
Before running a full review, check whether the user's input contains iteration keywords: "update", "re-review", "check my fixes", "revised", "changes made", "addressed". If detected:

1. Load the existing review file at `/.documentation/specs/pr-review/pr-{PR_NUMBER}.md`
2. Extract all finding IDs and their last-known status
3. Diff only what changed since the last reviewed commit SHA
4. Carry forward all unresolved findings unchanged
5. Mark previously flagged findings as `✅ Resolved`, `⚠️ Partially Addressed`, or `❌ Still Present` based on the new diff
6. Append new findings (if any) introduced by the new commits
7. Update the Revision Log section with the new commit SHA and pass/fail counts
8. **Co-mingling check**: Detect whether the review file (`.documentation/specs/pr-review/pr-{PR_NUMBER}.md`) was committed in the same commit as production code changes. Compare commit SHAs from `git log main...{source_branch} --oneline -- .documentation/specs/pr-review/pr-{PR_NUMBER}.md` against `git log main...{source_branch} --oneline -- {app_path}/`. If any SHA appears in both outputs, flag it as an M-NN finding: "Review file and production code changes committed together — iteration diff may be polluted. Commit review updates separately from code fixes."

**PR Number Detection**:
The script will try to determine PR number in this order:

1. User explicitly provides PR number in arguments: `#123` or `123`
2. GitHub environment variables: `GITHUB_PR_NUMBER`, `PR_NUMBER`
3. Current branch PR detection via `gh pr view`
4. If unable to detect, the script will error with clear instructions

**Error Handling**:
If the script fails:

- **Constitution missing**: Guide user to run `/devspark.constitution`
- **GitHub CLI not installed**: Provide installation instructions
- **PR not found**: Ask user to verify PR number and `gh auth status`
- **No PR number**: Ask user to provide PR number explicitly
- **Branch out of sync** (`is_behind_target: true`): **STOP immediately.** Do not review or approve. Inform the user:
  > "BLOCKED: The source branch `{source_branch}` is behind target branch `{target_branch}`. Sync it first before this PR can be reviewed or approved."
  > Suggested fix: `gh pr update-branch {PR_NUMBER}` or `git fetch origin && git rebase origin/{target_branch}`

For single quotes in args like "I'm reviewing", use escape syntax: e.g 'I'\''m reviewing' (or double-quote if possible: "I'm reviewing").

### 2. Load Constitution

Read and parse `/.documentation/memory/constitution.md`:

- Extract all core principles with their names
- Identify MUST requirements (non-negotiable/mandatory)
- Identify SHOULD requirements (recommended)
- Note constitution version and amendment date
- Build a checklist of principles to evaluate

If constitution doesn't exist:

- **STOP** and inform user that constitution is required
- Provide guidance: "Run `/devspark.constitution` to create project principles first"
- Do not proceed with review

### 3. Analyze PR Changes

Using the PR_CONTEXT data from the script:

#### A. Risk-Tiered File Triage

Assign each changed file a priority tier before reviewing, and apply the corresponding review depth:

| Tier | File Types | Review Depth |
|------|-----------|--------------|
| **P0 — Critical** | Route handlers, middleware, auth, database clients, payment processing, security utilities | Full line-by-line review |
| **P1 — Important** | Business logic, domain models, utilities, data transformations, API integrations | Function-level review |
| **P2 — Standard** | Tests, configuration files, templates, migration scripts, build files | Spot-check only |
| **P3 — Low** | Documentation, markdown, comments, formatting-only changes | Scan for obvious errors |

For each file in `files_changed`:

- Assign tier based on file path and purpose
- Read the diff to understand what changed
- Apply the corresponding review depth for that tier
- Identify the type of change (new file, modified, deleted)
- Note the scope of changes (lines added/removed)
- Extract code snippets for analysis (depth depends on tier)

Prioritization policy:

- Always start with P0 files regardless of context budget
- If `files_changed_truncated` is true, skip P3 files and limit P2 to a quick scan before expanding scope to P0/P1 only.
- Expand beyond sampled files only if necessary to validate a top-severity finding.

#### B. Examine PR Diff

Parse the full diff to:

- Identify new functionality added
- Check for removed functionality
- Look for modified behavior
- Note refactoring vs. feature changes

**Collect code churn stats** via `git diff --numstat` (or from `PR_CONTEXT` totals) and record them in the Stats section of the report. Re-collect on every revision for trend tracking.

#### C. Review Commit Messages

- Check if commits follow conventions
- Identify the intent behind changes
- Look for breaking change indicators

### 4. Perform Constitution-Based Review

Start the review with a gate result block:

```yaml
gate: pr-review
status: pass | warn | fail
blocking: true | false
severity: info | warning | error | showstopper
summary: "<concise outcome>"
```

For **each principle** in the constitution:

#### A. Compliance Check

- Review changed files against this specific principle
- Determine if the PR violates, partially complies, or fully complies
- Collect specific evidence (file names, line numbers, code snippets)

#### B. Severity Classification

Based on the principle's importance and violation type:

- **CRITICAL**: Violates mandatory (MUST) principle - blocks merge
- **HIGH**: Violates recommended (SHOULD) principle significantly
- **MEDIUM**: Partial compliance, improvement opportunity
- **LOW**: Style suggestions or minor improvements

For each finding:

- Quote the specific code that demonstrates the issue
- Reference the exact constitution section violated
- Explain clearly why this is an issue
- Provide a specific, actionable recommendation

#### C. Generate Findings

Create structured findings with **stable IDs** that persist across re-reviews. Use zero-padded identifiers so status changes across revisions instead of being deleted:

- **ID**: Stable identifier with zero-padded number. The prefix maps to severity tier:
  - `C-NN` = Critical (blocking)
  - `H-NN` = High priority
  - `M-NN` = Medium priority
  - `L-NN` = Low priority
  - `CON-NN` = Constitution (code may be correct; governance needs updating)
- **Status**: `🔴 Open` | `✅ Resolved` | `⚠️ Partial` | `➡️ Carried` (for re-reviews)
- **Principle**: Name of constitution principle
- **File:Line**: Exact location in code
- **Issue**: Specific description of the problem, including broken code snippet for CRITICAL/HIGH
- **Fix**: Concrete code fix for CRITICAL/HIGH findings (required); recommendation for others

### 5. Additional Review Dimensions

#### Security Analysis

- **Hardcoded Secrets**: Scan for API keys, passwords, tokens in code
- **Input Validation**: Check if user inputs are validated
- **Authentication**: Review auth/authz changes for correctness
- **SQL Injection**: Look for unsafe database queries
- **XSS**: Check for unescaped output in web contexts
- **Dependency Vulnerabilities**: Note if new dependencies added

Create checklist:

- [ ] No hardcoded secrets or credentials
- [ ] Input validation present where needed
- [ ] Authentication/authorization checks appropriate
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Dependencies reviewed for vulnerabilities

#### Behavioral Regression Detection

Scan the diff for silent behavioral changes that may break callers or remove safety guarantees:

**Default Value Changes in Function Signatures**:

- Detect changed default parameter values in function/method definitions
- Flag when a previously-required argument gains a default (could mask missing args)
- Flag when a default changes in a way that silently alters behavior

**Return Type Changes**:

- Detect when a function's return type annotation changes (e.g., `str` → `Optional[str]`, `List` → `None`)
- Flag implicit return type changes where `None` may now be returned without a type annotation update
- Note downstream callers that may be broken

**Removed Defensive Code (4-Step Verification)**:
Before flagging a removed safety guard, complete all 4 steps:

1. **Identify the guard**: Quote the removed code and describe what it was protecting against
2. **Check if condition can still occur**: Determine whether the protected scenario is still possible based on what is observable in the PR diff and the PR context script output — do not speculate about runtime state not visible in the provided context
3. **Check if protection moved elsewhere**: Search the PR diff for equivalent protection at a different layer (middleware, validator, caller site)
4. **Flag only if genuinely removed**: Only create a finding if steps 2 and 3 confirm the protection is missing and the risk remains real

Include behavioral regression findings in the Critical or High section as appropriate.

If constitution has code quality principles:

- **Naming Conventions**: Verify names follow standards
- **Code Organization**: Check structure matches guidelines
- **Error Handling**: Review exception handling patterns
- **Duplication**: Identify code duplication issues
- **Complexity**: Note overly complex code

Identify:

- **Strengths**: What the PR does well
- **Areas for Improvement**: Specific suggestions

#### Testing Validation

**Mandatory test execution** (default behavior — opt out only if constitution explicitly marks test execution as impractical):

1. **Detect the test command**: Identify the project's test runner from project files (`pytest.ini`, `pyproject.toml`, `package.json`, `go.mod`, etc.). If re-reviewing, use the command recorded in the first Revision Log row to maintain a consistent baseline.
2. **Scope to changed test files**: Run the test suite scoped to test files changed in this PR. Only run the full suite if a scoped run is not possible.
3. **Record result in Revision Log**: Write the test command and pass/fail result into the Revision Log row for this review.
4. **Test failures are automatic HIGH findings**: If tests fail, create an H-NN finding citing the failure output. Do not classify test failures as MEDIUM or lower.

Additionally:

- Check if tests exist for new/modified code
- Verify test quality and coverage
- Confirm tests were written appropriately
- Review test naming and organization

#### Documentation Review

If constitution requires documentation:

- Check if README updated if needed
- Verify code comments for complex logic
- Confirm API documentation updated
- Check if CHANGELOG updated

### 6. Spec Lifecycle Validation (Required for Feature Branches)

Determine if this PR maps to a feature spec and validate spec lifecycle status:

1. **Detect feature spec**: Extract feature identifier from the source branch name pattern (e.g., `001-feature-name`). Check if `/.documentation/specs/{feature}/spec.md` exists. Also check `SPEC_STATUS` from the PR context script output (if available).

2. **If spec exists**, validate lifecycle completeness:

   a. **Spec Status Check**: Read the `**Status**:` field in spec.md. Valid values are: `Draft`, `In Progress`, `Complete`.
      - If status is `Draft` or `In Progress`: **flag as CRITICAL finding** — spec must be `Complete` before merge.

   b. **Task Completion Check**: Read `/.documentation/specs/{feature}/tasks.md` (if it exists).
      - Count total tasks (lines matching `- [ ]` or `- [x]` or `- [X]`)
      - Count completed tasks (lines matching `- [x]` or `- [X]`)
      - If any tasks are incomplete (`- [ ]`): **flag as CRITICAL finding** — all tasks must be checked off before merge.
      - If tasks.md does not exist but spec.md does: **flag as HIGH finding** — tasks should be generated.

   c. **Cross-reference implementation**:
      - Does implementation match spec requirements?
      - Are acceptance criteria being addressed?
      - Is scope appropriate for the spec?

3. **If no spec exists** for a feature branch (branch name matches `\d+-.*` pattern):
   - **Flag as CRITICAL finding**: Constitution requires features to be spec-driven (Constitution §Development Workflow: "Features must be spec-driven: specify first, plan second, implement third").
   - Block APPROVE recommendation.

4. **If branch is NOT a feature branch** (e.g., hotfix, chore, docs-only): Spec validation is not required. Note this in the review.

5. **Include Spec Lifecycle Summary** in the Executive Summary section:
   - **Spec Status**: [Complete | In Progress | Draft | Missing]
   - **Task Completion**: [X/Y tasks complete | No tasks file | N/A]
   - If spec is not `Complete` or tasks are incomplete, the **Approval Recommendation MUST be ⚠️ REQUEST CHANGES or ❌ REJECT** — never ✅ APPROVE.

### 6b. PR Scope Validation (Multi-App Mode)

If the repository operates in multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), perform scope validation on the PR:

#### A. Check for Scope Declaration

Look for a PR scope declaration in the PR description or in `.documentation/specs/` artifacts. A scope declaration specifies:

- **mode**: `single-app`, `cross-app`, or `repo-scope`
- **primary_app**: The primary application being changed
- **affected_apps**: All applications intentionally touched by this PR

If no scope declaration is present, infer scope from the changed files:

- If all changed files belong to a single app (plus approved shared paths), infer `single-app` mode.
- If changed files span multiple apps, infer `cross-app` mode.
- If changes are purely in shared/repo-level paths, infer `repo-scope`.

#### B. Validate Scope Against Changed Paths

Using the PR's changed file list and the registry from `.documentation/devspark.json`:

1. Map each changed file to its owning application (by matching `app.path` prefixes).
2. Identify shared paths (`.documentation/`, `.github/`, `.devspark/`, root-level config files).
3. Validate that the changed paths are consistent with the declared (or inferred) scope:
   - **single-app**: Only the declared app's path and approved shared paths should be touched. Flag files in other apps as scope mismatches.
   - **cross-app**: All touched app paths must be listed in `affected_apps`. Flag undeclared app paths.
   - **repo-scope**: All paths are allowed.

#### C. Report Scope Findings

Include scope validation results in the review output:

- If scope is valid, note it in the Executive Summary as a passing check.
- If scope mismatches are detected, report them as **HIGH** severity findings:
  - List which files violate the declared scope.
  - Recommend updating the scope declaration or splitting the PR.
- Add a row to the Constitution Alignment Details table for scope compliance.

### 7. Generate Review Report

Create comprehensive report at `/.documentation/specs/pr-review/pr-{PR_NUMBER}.md`:

#### Handle Existing Reviews

If file already exists:

1. Read the existing file
2. Extract the previous commit SHA from metadata
3. Compare with current commit SHA from PR_CONTEXT
4. **If commit SHA is the same**:
   - Replace the entire file with updated review
   - Keep the original review date, update "Last Updated" date
5. **If commit SHA is different (PR was updated)**:
   - Load all existing finding IDs and their statuses
   - Diff only what changed since the previous reviewed commit
   - Carry forward unresolved findings with status `➡️ Carried`
   - Update findings resolved by the new commits to `✅ Resolved`
   - Add new findings with `🔴 Open` status
   - Append a new row to the Revision Log table
   - Move previous review content to "Previous Review History" section at bottom

#### Report Structure

Use this exact format:

```markdown
# Pull Request Review: [PR_TITLE]

## Review Metadata

- **PR Number**: #[NUMBER]
- **Source Branch**: [HEAD_BRANCH]
- **Target Branch**: [BASE_BRANCH]
- **Review Date**: [YYYY-MM-DD HH:MM:SS UTC]
- **Last Updated**: [YYYY-MM-DD HH:MM:SS UTC]
- **Reviewed Commit**: [COMMIT_SHA]
- **Reviewer**: devspark.pr-review
- **Constitution Version**: [VERSION from constitution]

## Revision Log

| Rev | Commit | Date | Critical | High | Medium | Low | CON | Test Command | Result |
|-----|--------|------|----------|------|--------|-----|-----|--------------|--------|
| 1 | [SHA_SHORT] | [DATE] | [N] | [N] | [N] | [N] | [N] | [pytest scoped / skip if opted-out] | [pass/fail/skipped] |

*Add a row for each re-review. Keep the same test command across all revisions to prevent flaky baselines.*

## PR Summary

- **Author**: [@AUTHOR]
- **Created**: [CREATED_DATE]
- **Status**: [OPEN/CLOSED/MERGED]
- **Files Changed**: [COUNT]
- **Commits**: [COUNT]
- **Lines**: +[ADDITIONS] -[DELETIONS]

## Stats

| Metric | Value |
|--------|-------|
| Files changed | [COUNT] |
| Lines added | +[ADDITIONS] |
| Lines removed | −[DELETIONS] |
| Net lines | [±NET] |
| Commit snapshot | `[SHA_SHORT]` |

*Collected via `git diff --numstat`. Re-collect on every revision for trend tracking.*

## Executive Summary

- ✅ **Constitution Compliance**: [PASS/FAIL] ([X]/[Y] principles checked)
- 📋 **Spec Lifecycle**: [Complete | In Progress | Draft | Missing | N/A (not a feature branch)]
- 📝 **Task Completion**: [X/Y tasks complete | No tasks file | N/A]
- 🔒 **Security**: [X] issues found
- 📊 **Code Quality**: [X] recommendations
- 🧪 **Testing**: [PASS/FAIL/skipped (opted-out)]
- 📝 **Documentation**: [PASS/FAIL/N/A]
- 🏛️ **Constitution Improvements**: [X] CON findings

**Overall Assessment**: [1-2 sentence summary]

**Approval Recommendation**: [✅ APPROVE | ⚠️ REQUEST CHANGES | ❌ REJECT]
*Note: APPROVE is blocked if Spec Lifecycle is not Complete or tasks are incomplete for feature branches.*

## Action Items

*All findings ordered by severity. CRITICAL and HIGH items include broken code and the fix.*

### Immediate Actions (Blocking — must resolve before merge)

[If none, write "None found."]

- [ ] **C-01** `path/file.ext:45` — [One-line description]
  - **Broken code**: `[code snippet]`
  - **Fix**: `[corrected code snippet]`
- [ ] **H-01** `path/file.ext:67` — [One-line description]
  - **Broken code**: `[code snippet]`
  - **Fix**: `[corrected code snippet]`

### Recommended Improvements

- [ ] **M-01** `path/file.ext:89` — [One-line description]
- [ ] **L-01** `path/file.ext:123` — [Optional improvement]

### Constitution Improvements (Non-blocking — feed into `/devspark.evolve-constitution`)

- [ ] **CON-01** — [Constitution section that needs updating]

## What's Good

*Skip this section if there is nothing noteworthy. Maximum 5 bullets.*

- [Positive aspect 1 with specific file/pattern reference]
- [Positive aspect 2]

## Findings Detail

*Stable IDs persist across re-reviews. Status updates instead of deleting.*

### Critical Issues (Blocking)

[If none, write "None found."]

| ID | Status | Principle | File:Line | Issue | Fix |
|----|--------|-----------|-----------|-------|-----|
| C-01 | 🔴 Open | [Name] | path/file.ext:45 | [Specific violation] | [Specific fix] |

### High Priority Issues

[If none, write "None found."]

| ID | Status | Principle | File:Line | Issue | Fix |
|----|--------|-----------|-----------|-------|-----|
| H-01 | 🔴 Open | [Name] | path/file.ext:67 | [Issue description] | [Fix] |

### Medium Priority Suggestions

[If none, write "None found."]

| ID | Status | Principle | File:Line | Issue | Recommendation |
|----|--------|-----------|-----------|-------|----------------|
| M-01 | 🔴 Open | [Name] | path/file.ext:89 | [Suggestion] | [Improvement] |

### Low Priority Improvements

[If none, write "None found."]

| ID | Status | Principle | File:Line | Issue | Recommendation |
|----|--------|-----------|-----------|-------|----------------|
| L-01 | 🔴 Open | [Name] | path/file.ext:123 | [Minor suggestion] | [Optional improvement] |

### Constitution Improvements

*Findings where the code may be correct but the constitution needs updating. Feed these into `/devspark.evolve-constitution`.*

[If none, write "None found."]

| ID | Status | Section | Observation | Suggested Amendment |
|----|--------|---------|-------------|---------------------|
| CON-01 | 🔴 Open | §[Section] | [What the code does that is better than what the constitution prescribes] | [Suggested wording for the constitution] |

## Constitution Alignment Details

| Principle | Status | Evidence | Notes |
|-----------|--------|----------|-------|
| [Principle 1] | ✅ Pass | Files comply | [Brief explanation] |
| [Principle 2] | ❌ Fail | src/api.ts:45 | [Why it fails] |
| [Principle 3] | ⚠️ Partial | Multiple files | [Partial compliance details] |
| [Principle 4] | ⏭️ N/A | - | Not applicable to this PR |

## Security Checklist

- [ ] No hardcoded secrets or credentials
- [ ] Input validation present where needed
- [ ] Authentication/authorization checks appropriate
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Dependencies reviewed for vulnerabilities

[Add notes for any checked/unchecked items]

## Testing Coverage

**Status**: [ADEQUATE | INADEQUATE | N/A]

[Details about test coverage, or reasons why test execution was skipped per constitution opt-out]

## Test Inventory

*Count of test functions per changed test file. Unjustified removals are MEDIUM findings.*

| File | Main | Branch | Delta | Justification |
|------|------|--------|-------|---------------|
| `tests/[test_file].py` | [N] | [N] | [±N] | N/A |
| **Total** | [N] | [N] | [±N] | |

Removed tests (if any):

- `[test_name]` — **[Justified/Unjustified]**: [reason] → [finding ID if unjustified]

*If no test files changed, write "No test files changed in this PR."*

## Documentation Status

**Status**: [ADEQUATE | INADEQUATE | N/A]

[Details about documentation, or "N/A - No documentation principle in constitution"]

## Changed Files Summary

| File | Tier | Changes | Type | Findings |
|------|------|---------|------|---------|
| src/auth/handler.py | P0 | +45 -12 | Modified | C-01, H-01 |
| src/models/user.py | P1 | +22 -5 | Modified | M-01 |
| tests/test_auth.py | P2 | +120 -0 | Added | None |
| README.md | P3 | +8 -2 | Modified | None |

## Behavioral Changes

*Silent behavioral changes detectable from diff analysis. Callers may break without test failures.*

[If none detected, write "None detected."]

| Change | Before | After | Intentional? | Risk |
|--------|--------|-------|-------------|------|
| `[function()]` [what changed] | [before value/type] | [after value/type] | [Yes (PR description) / Unclear] | [Impact on callers] |

## Approval Decision

**Recommendation**: [✅ APPROVE | ⚠️ REQUEST CHANGES | ❌ REJECT]

**Reasoning**:
[Provide clear reasoning based on findings. Examples:

- "PR violates mandatory Test-First principle (C-01). Must add tests before merge."
- "No critical issues found. Minor suggestions provided but not blocking."
- "Excellent PR - follows all constitution principles and includes comprehensive tests."]

**Estimated Rework Time**: [X hours | X days | N/A]

---

*Review generated by devspark.pr-review v1.2*
*Constitution-driven code review for [PROJECT_NAME]*
*To re-review after fixes: `/devspark.pr-review #[PR_NUMBER] re-review`*
*When addressing these findings, run `/devspark.address-pr-review {PR_ID}`. The review file must be committed on its own — this rule is enforced by the prompt and can also be enforced by the optional pre-commit hook.*

---

## Previous Review History

[If this is an updated review, previous reviews go here]

### Review 2: 2026-01-24 10:30:00 UTC

**Commit**: abc123def

[Summary of previous review or full previous review content]

### Review 1: 2026-01-23 14:15:00 UTC

**Commit**: 789xyz012

[Summary of first review]

```text
End of report template
```

### 8. Create Review Directory

Ensure `/.documentation/specs/pr-review/` directory exists:

- Check if directory exists
- Create it if it doesn't (including parent `/.documentation/specs/` if needed)
- Set appropriate permissions

### 9. Write Review File

Write the generated report to `/.documentation/specs/pr-review/pr-{PR_NUMBER}.md`:

- Use UTF-8 encoding
- Ensure proper line endings
- Make file readable

### 10. Output Summary to User

Display concise summary to the user:

```text
✅ PR Review Complete!

📄 Review saved: /.documentation/specs/pr-review/pr-{NUMBER}.md
🔍 Reviewed commit: {COMMIT_SHA}
📅 Review date: {DATETIME}

Executive Summary:
- [Status emoji] {COUNT} Critical issues
- [Status emoji] {COUNT} High priority
- [Status emoji] {COUNT} Medium priority
- [Status emoji] {COUNT} Low priority
- 🏛️ {COUNT} Constitution improvements

Recommendation: {APPROVE/REQUEST CHANGES/REJECT}

{If critical issues:}
Critical issues must be resolved before merge:
- C-01: {Brief description}
- C-02: {Brief description}

View full review: /.documentation/specs/pr-review/pr-{NUMBER}.md
```

## Guidelines

### Constitution Authority

The constitution is **non-negotiable** and the **authoritative source** for all review criteria.

All findings must:

- Reference the specific constitution section (by principle name)
- Quote the exact constitution language (MUST/SHOULD/etc.)
- Explain how the code violates or complies with the principle
- Use the constitution's own terminology and standards

### Evidence-Based Feedback

Every issue must include:

- **Specific location**: File path and line number (not "multiple files" or "various places")
- **Code quote**: Actual code snippet showing the issue (2-5 lines of context)
- **Constitution reference**: Which principle is violated and why
- **Actionable recommendation**: Specific fix with example if possible

**Bad example**: "Code has issues with naming"
**Good example**: "src/api.ts:45 - Variable `x` violates naming principle 'Use descriptive names'. Rename to `userApiKey`."

### Review Objectivity

- Focus on facts, not opinions or style preferences
- Base all feedback on constitution principles
- Avoid subjective language ("ugly code", "bad design")
- If not in constitution, don't flag it (or mark as LOW priority observation)

### Severity Guidelines

Use this scenario-to-severity mapping table to anchor classification. When two tiers are plausible, prefer the higher one. Projects may extend this table via their constitution's anti-pattern appendix.

| Finding Type | Severity | Rationale |
|---|---|---|
| Runtime crash on production path | CRITICAL | Immediate user impact |
| Data corruption / silent data loss | CRITICAL | Breaks data contracts |
| Auth bypass / credential exposure | CRITICAL | Compliance + security |
| Schema violation (frozen fields) | CRITICAL | Pipeline breakage |
| Spec lifecycle not complete (feature branches) | CRITICAL | Process requirement |
| Runtime error on edge path | HIGH | Affects subset of users |
| Silent behavior change (defaults, types) | HIGH | Invisible regression |
| API contract violation (wrong status codes) | HIGH | Breaks consumers |
| Broken test infrastructure | HIGH | Blocks developer workflow |
| Test suite failures on changed test files | HIGH | Runtime errors missed by diff |
| Missing tests for new code | MEDIUM | Tech debt, not production risk |
| Unjustified test removal | MEDIUM | Coverage regression |
| Dead code introduced in PR | MEDIUM | Maintenance burden |
| Performance inefficiency | MEDIUM | Latency, not correctness |
| Review file co-mingled with code fixes | MEDIUM | Pollutes iteration diff |
| Stale TODO referencing merged work | LOW | Clutter |
| Style / naming / docs | LOW | Optional improvement |
| Constitution needs updating (not code) | CON | Governance improvement |

Summary tiers:

- **CRITICAL**: Violates MUST principle, blocks functionality, security risk, breaks production
- **HIGH**: Violates SHOULD principle significantly, quality concerns, technical debt
- **MEDIUM**: Partial compliance, improvement opportunity, maintainability concern
- **LOW**: Style preference, minor optimization, optional enhancement
- **CON**: Constitution needs updating — the code may be correct but governance is lagging behind

### Graceful Error Handling

**If constitution missing**:

```text
❌ Cannot perform PR review - Constitution required

The project constitution defines the review criteria. Create one first:

1. Run: /devspark.constitution
2. Define your project's core principles
3. Then retry: /devspark.pr-review #{PR_NUMBER}

Learn more: <https://github.com/MarkHazleton/devspark>
```

**If PR not found**:

```text
❌ PR #{NUMBER} not found

Troubleshooting:
1. Check the PR number is correct
2. Verify GitHub CLI authentication: gh auth status
3. Confirm you have repository access

If issue persists, provide PR number explicitly:
/devspark.pr-review #123
```

**If GitHub CLI not installed**:

```text
❌ GitHub CLI (gh) required but not installed

Install GitHub CLI:
- macOS: brew install gh
- Windows: winget install --id GitHub.cli
- Linux: <https://github.com/cli/cli#installation>

After installation, authenticate:
gh auth login

Then retry: /devspark.pr-review
```

### Positive Feedback

If PR is excellent:

- Acknowledge good practices
- Call out strengths specifically
- Provide enthusiastic approval
- Example: "Excellent PR! Comprehensive tests, clear documentation, follows all constitution principles. Strong work! ✅"

### Review Updates

When re-reviewing an updated PR:

- Load existing finding IDs and their statuses before running the new review
- Carry forward all unresolved findings unchanged with status `➡️ Carried`
- Mark resolved findings as `✅ Resolved` with a brief note (e.g., "✅ Resolved: C-01 (tests added in commit abc123)")
- Flag partially addressed findings as `⚠️ Partial` with explanation
- Note any new findings introduced since last review with `🔴 Open`
- Append a new row to the Revision Log table with the new commit SHA
- Keep the same test command from the first review row to maintain a consistent baseline

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
