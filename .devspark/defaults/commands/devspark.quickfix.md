---
description: Rapid lightweight fix workflow that bypasses full spec creation while maintaining constitution compliance validation
handoffs:
  - label: View Quickfix History
    agent: devspark.quickfix
    prompt: Show me previous quickfixes with /devspark.quickfix list
  - label: Upgrade to Full Spec
    agent: devspark.specify
    prompt: Create a full specification for this change
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command enables rapid fixes for bug fixes, small features, and production issues without the overhead of full specification workflows. It validates changes against relevant constitution sections and generates a lightweight change record.

**Use Cases:**

- Bug fixes (runtime errors, UI glitches, data issues)
- Small features (< 4 hours estimated work)
- Production hotfixes requiring rapid deployment
- Configuration changes
- Documentation updates

**IMPORTANT**: This command creates minimal documentation and still performs constitution-aware gate checks.

Gate results from this workflow are advisory. The agent must surface blocking concerns and recommend a next action, but the user decides whether to fix first, escalate, or accept the risk.

## Prerequisites

- Project constitution at `/.documentation/memory/constitution.md` (REQUIRED)
- Git repository with working branch

## Actions

Parse `$ARGUMENTS` for action type:

| Action | Trigger | Description |
|--------|---------|-------------|
| `create` | Default (description provided) | Create new quickfix record |
| `complete` | `/devspark.quickfix complete QF-YYYY-NNN` | Mark quickfix as completed |
| `list` | `/devspark.quickfix list` | Show recent quickfixes |

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Initialize Quickfix Context

> **Script Resolution**: Before running `.devspark/scripts/powershell/quickfix-context.ps1 $ARGUMENTS -Json`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/quickfix-context.ps1 $ARGUMENTS -Json` to gather context and parse JSON output for:

- `REPO_ROOT`: Repository root path
- `CONSTITUTION_PATH`: Path to constitution file
- `CONSTITUTION_EXISTS`: Whether constitution exists
- `QUICKFIX_DIR`: Directory for quickfix records
- `CURRENT_BRANCH`: Current git branch
- `NEXT_ID`: Next quickfix ID (QF-YYYY-NNN format)
- `GIT_USER`: Git username for attribution
- `TIMESTAMP`: Current UTC timestamp
- `ACTION`: Determined action (create/complete/list)
- `CLASSIFICATION`: Auto-detected classification
- `RISK_LEVEL`: Assessed risk level
- `MAX_EFFORT`: Maximum recommended effort

**Error Handling:**

If constitution doesn't exist:

- **STOP** and inform user that constitution is required
- Provide guidance: "Run `/devspark.constitution` to create project principles first"
- Do not proceed with quickfix creation

### 2. Handle Action

#### Action: `list`

If ACTION is "list":

1. Read all files from QUICKFIX_DIR
2. Parse metadata from each file
3. Display summary table:

```markdown
## Recent Quickfixes

| ID | Date | Classification | Status | Description |
|----|------|----------------|--------|-------------|
| QF-2026-003 | 2026-02-01 | bug-fix | Completed | Fix null pointer in UserService |
| QF-2026-002 | 2026-01-28 | hotfix | Completed | Payment timeout fix |
| QF-2026-001 | 2026-01-25 | config-change | Completed | Update rate limits |
```

1. Stop execution (no record creation)

#### Action: `complete`

If ACTION is "complete" and QUICKFIX_ID is provided:

1. Read the quickfix record from `QUICKFIX_DIR/QUICKFIX_ID.md`
2. If file doesn't exist: ERROR "Quickfix {ID} not found"
3. Update the record:
   - Set `Completed` timestamp
   - Get current commit SHA: `git rev-parse HEAD`
   - Check for associated PR: `gh pr view --json number 2>/dev/null`
4. Write updated record
5. Display completion summary
6. Stop execution

#### Action: `create` (Default)

Continue to step 3 for creating new quickfix record.

### 3. Validate Scope

Based on CLASSIFICATION from script:

| Classification | Keywords Detected | Max Effort | Risk |
|---------------|-------------------|------------|------|
| `hotfix` | urgent, critical, emergency, production | 2 hours | HIGH |
| `bug-fix` | fix, bug, error, crash, broken, issue | 4 hours | MEDIUM |
| `config-change` | config, setting, environment, flag | 1 hour | LOW |
| `docs-update` | doc, readme, comment, documentation | 2 hours | LOW |
| `minor-feature` | (default) | 4 hours | LOW |

**Scope Warning:**

If the description suggests work beyond the classification limits, warn:

```markdown
Scope Warning: This appears to be a larger change than a typical {CLASSIFICATION}.

Consider upgrading to a full specification:
- Run `/devspark.specify {description}` for proper planning
- Or continue with quickfix if you're confident it's small
```

### 4. Load Constitution (Targeted)

Read `/.documentation/memory/constitution.md` and extract only principles relevant to the change type:

| Classification | Relevant Principles |
|---------------|---------------------|
| `hotfix` | Security, Observability, Deployment |
| `bug-fix` | Testing, Code Quality, Security |
| `config-change` | Security, Documentation |
| `docs-update` | Documentation |
| `minor-feature` | All MUST principles |

Build a targeted validation checklist from these principles only.

### 5. Constitution Compliance Check

For each relevant principle:

- **PASS**: Proposed solution complies or principle not applicable
- **CONDITIONAL**: Needs specific action to comply (document the action)
- **FAIL**: Cannot proceed without violating principle

**Compliance Decision:**

- If any FAIL: Surface the blocking concern, explain why it matters, recommend `/devspark.specify` or escalation, and ask whether to continue anyway, switch workflows, or stop.
- If CONDITIONAL: Document required actions in the quickfix record.
- If all PASS: Proceed with quickfix creation.

If the user chooses to continue despite FAIL or CONDITIONAL findings, record that explicit override in the quickfix record under `## Gate Acknowledgements`.

### 6. Extract Quickfix Details

From user description, extract:

- **Problem Statement**: What's broken or missing (1-2 sentences)
- **Proposed Solution**: How to fix it (1-2 sentences)
- **Affected Components**: Files/modules likely impacted (infer from context)

### 7. Generate Quickfix Record

Ensure directory exists: Create `/.documentation/quickfixes/` if missing.

Create record at `QUICKFIX_DIR/NEXT_ID.md`:

```markdown
---
classification: one-off-fix
risk_level: {RISK_LEVEL}
target_workflow: quickfix
required_artifacts: quickfix-record
recommended_next_step: implement
required_gates: {Leave blank for low risk; otherwise checklist}
---

# Quickfix Record: {NEXT_ID}

## Metadata

- **ID**: {NEXT_ID}
- **Created**: {TIMESTAMP}
- **Author**: {GIT_USER}
- **Branch**: {CURRENT_BRANCH}
- **Classification**: {CLASSIFICATION}
- **Risk Level**: {RISK_LEVEL}
- **Max Effort**: {MAX_EFFORT}

## Problem Statement

{Extracted from user description - 1-2 sentences describing what's broken or missing}

## Proposed Solution

{Extracted from user description - 1-2 sentences describing the fix approach}

## Affected Components

- {Inferred file/module 1}
- {Inferred file/module 2}

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| {Relevant Principle 1} | PASS/CONDITIONAL | {Notes if conditional} |
| {Relevant Principle 2} | PASS/CONDITIONAL | {Notes} |

## Validation Checklist

- [ ] Change addresses stated problem
- [ ] No unintended side effects identified
- [ ] Relevant tests updated/added (if applicable)
- [ ] Documentation updated (if applicable)

## Gate Acknowledgements

{Leave blank unless the user explicitly proceeds past a blocking or conditional concern}

## Implementation Notes

{Space for developer notes during implementation - leave blank initially}

## Completion

- **Completed**: {Leave blank - filled by complete action}
- **Commit**: {Leave blank - filled by complete action}
- **PR**: {Leave blank - filled by complete action}

---

*Generated by /devspark.quickfix v1.0*
```

### 8. Output Summary

Display to user:

````markdown
Quickfix Record Created: {NEXT_ID}

- **Classification**: {CLASSIFICATION}
- **Risk Level**: {RISK_LEVEL}
- **Constitution Check**: PASS ({N} principles validated)

Record saved: /.documentation/quickfixes/{NEXT_ID}.md

## Gate Result

```yaml
gate: quickfix
status: pass | warn | fail
blocking: true | false
severity: info | warning | error | showstopper
summary: "Targeted constitution check complete"
```

## Next Steps

1. Implement the fix on your current branch
2. Run tests to verify the fix
3. Mark record complete: `/devspark.quickfix complete {NEXT_ID}`
4. Create PR (optional) — prefer `/devspark.create-pr` so the PR reflects quickfix context and any recorded gate acknowledgements
5. If creating manually, verify the current branch is in sync with the target branch (usually `main`) before opening the PR

If scope expands beyond {MAX_EFFORT}:

- Upgrade to full spec: `/devspark.specify {problem statement}`
````

## Guidelines

### Scope Creep Detection

If during implementation the user mentions scope expansion:

- "Also need to change..."
- "This is more complex than expected..."
- "Need to refactor..."
- Multiple files/modules affected

Recommend upgrading:

```markdown
Scope Expansion Detected

Your quickfix may be growing beyond the {CLASSIFICATION} classification.
Consider upgrading to a full specification for better tracking:

/devspark.specify {original problem statement}

This ensures proper planning and documentation for larger changes.
```

### Quickfix vs Full Spec Decision Guide

| Scenario | Recommendation |
|----------|----------------|
| Single file change, < 50 lines | Quickfix |
| Bug with clear root cause | Quickfix |
| Production issue needing rapid fix | Quickfix (hotfix) |
| Multiple files, architectural impact | Full Spec |
| New user-facing feature | Full Spec |
| Database schema changes | Full Spec |
| API contract changes | Full Spec |

### Error Handling

**Constitution missing:**

```markdown
Cannot perform quickfix - Constitution required

The project constitution defines validation criteria. Create one first:

1. Run: /devspark.constitution
2. Define your project's core principles
3. Then retry: /devspark.quickfix {description}

Learn more: https://github.com/MarkHazleton/devspark
```

**High Risk Classification:**

For `hotfix` classification with HIGH risk:

```markdown
High-Risk Quickfix Warning

This has been classified as a hotfix with HIGH risk level.

Before proceeding:
- [ ] Confirm this is truly urgent
- [ ] Identify rollback plan if fix fails
- [ ] Notify team of incoming production change

Proceed with caution. Consider pair review for critical fixes.
```

### ID Format

Quickfix IDs follow the format: `QF-YYYY-NNN`

- `QF`: Quickfix prefix
- `YYYY`: Year (e.g., 2026)
- `NNN`: Sequential number, zero-padded (001, 002, ... 999)

Resets annually. Example: QF-2026-001, QF-2026-002

## Context

$ARGUMENTS
