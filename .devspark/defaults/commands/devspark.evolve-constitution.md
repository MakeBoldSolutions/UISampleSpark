---
description: Analyze PR review findings and codebase patterns to propose constitution amendments with change tracking
handoffs:
  - label: Apply Amendment
    agent: devspark.constitution
    prompt: Apply the approved constitution amendment
  - label: Review PRs
    agent: devspark.pr-review
    prompt: Review recent PRs to gather more data
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command facilitates constitution evolution by:

1. Analyzing PR review findings for recurring violation patterns
2. Detecting issues not mapped to existing principles
3. Generating draft amendment proposals (CAP - Constitution Amendment Proposal)
4. Tracking constitution change history
5. Managing the approval workflow

**IMPORTANT**: This command generates PROPOSALS only. Amendments must be explicitly approved before being applied via `/devspark.constitution`.

## Prerequisites

- Project constitution at `/.documentation/memory/constitution.md` (REQUIRED)
- PR review history in `/.documentation/specs/pr-review/` (recommended)
- Site audit history in `/.documentation/copilot/audit/` (optional)

## Actions

Parse `$ARGUMENTS` for action type:

| Action | Trigger | Description |
|--------|---------|-------------|
| `analyze` | Default | Analyze reviews/audits and propose amendments |
| `suggest` | `/devspark.evolve-constitution suggest "..."` | Create proposal from manual suggestion |
| `approve` | `/devspark.evolve-constitution approve CAP-YYYY-NNN` | Approve a proposal |
| `reject` | `/devspark.evolve-constitution reject CAP-YYYY-NNN "reason"` | Reject a proposal |

## Outline

### 1. Initialize Evolution Context

> **Script Resolution**: Before running `.devspark/scripts/powershell/evolution-context.ps1 $ARGUMENTS -Json`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/evolution-context.ps1 $ARGUMENTS -Json` to gather context and parse JSON output for:

- `CONSTITUTION_PATH`: Path to current constitution
- `CONSTITUTION_EXISTS`: Whether constitution exists
- `CONSTITUTION_VERSION`: Current version
- `CONSTITUTION_PRINCIPLES`: List of existing principles
- `PR_REVIEW_DIR`: Path to PR review directory
- `PR_REVIEWS`: List of recent PR review files
- `PR_REVIEW_COUNT`: Total PR reviews available
- `AUDIT_DIR`: Path to audit directory
- `AUDIT_REPORTS`: List of recent audit reports
- `AUDIT_COUNT`: Total audits available
- `PROPOSALS_DIR`: Path to proposals directory
- `PROPOSALS`: List of existing proposals
- `NEXT_CAP_ID`: Next proposal ID
- `PATTERN_SUMMARY`: Aggregated violation patterns
- `CRITICAL_COUNT`: Count of critical findings
- `HIGH_COUNT`: Count of high-priority findings
- `ACTION`: Determined action
- `CAP_ID`: Proposal ID (for approve/reject)
- `SUGGESTION`: Manual suggestion text

**Error Handling:**

If constitution doesn't exist:

- **STOP** and inform user that constitution is required
- Provide guidance: "Run `/devspark.constitution` to create project principles first"

### 2. Handle Action

#### Action: `approve`

If ACTION is "approve" and CAP_ID is provided:

1. Read proposal from `PROPOSALS_DIR/CAP_ID.md`
2. If file doesn't exist: ERROR "Proposal {CAP_ID} not found"
3. Update proposal status to "APPROVED"
4. Update `/.documentation/memory/constitution-history.md`:
   - Add entry to Amendment Log
   - Record approval date
5. Output:

```markdown
Proposal Approved: {CAP_ID}

The amendment has been approved but NOT YET APPLIED.

To apply this amendment to the constitution:
/devspark.constitution

The constitution command will detect approved proposals and offer to apply them.
```

1. Stop execution

#### Action: `reject`

If ACTION is "reject" and CAP_ID is provided:

1. Read proposal from `PROPOSALS_DIR/CAP_ID.md`
2. If file doesn't exist: ERROR "Proposal {CAP_ID} not found"
3. Update proposal status to "REJECTED"
4. Add rejection reason from arguments
5. Move to `PROPOSALS_DIR/rejected/` subdirectory
6. Update history file with rejection record
7. Output:

```markdown
Proposal Rejected: {CAP_ID}

Reason: {rejection reason}

The proposal has been archived in:
/.documentation/memory/proposals/rejected/{CAP_ID}.md
```

1. Stop execution

#### Action: `suggest`

If ACTION is "suggest" and SUGGESTION is provided:

1. Skip pattern analysis
2. Go directly to step 5 (Proposal Generation)
3. Create proposal based on manual suggestion

#### Action: `analyze` (Default)

Continue to step 3 for full analysis.

### 3. Pattern Analysis

#### A. PR Review Analysis

Scan PR reviews in `PR_REVIEW_DIR`:

For each PR review file:

1. Extract all findings (CRITICAL, HIGH, MEDIUM)
2. Map findings to constitution principles
3. Track which principles have violations
4. Identify findings that don't map to any principle

**Build Pattern Summary:**

```markdown
| Principle | Violations | PRs Affected | Trend |
|-----------|------------|--------------|-------|
| Security | 15 | pr-45, pr-67, pr-89 | ↑ Increasing |
| Testing | 8 | pr-23, pr-56 | → Stable |
| (Uncategorized) | 5 | pr-12, pr-34 | New |
```

**Identify Uncategorized Issues:**

Issues not matching any existing principle:

- Missing error boundaries
- Inconsistent API versioning
- No accessibility considerations
- Hardcoded configuration values

#### B. Audit Analysis (if available)

Scan audit reports in `AUDIT_DIR`:

1. Extract compliance scores by category
2. Track score trends across audits
3. Identify persistent issues (appearing in 2+ audits)
4. Note categories with declining scores

#### C. Gap Detection

Compare findings against constitution:

| Finding | Status |
|---------|--------|
| Issues with no matching principle | **Potential new principle** |
| Principles with zero violations | Potentially redundant or well-followed |
| Principles with 5+ violations | May need clarification |
| New violation categories emerging | Evolution trigger |

### 4. Evolution Threshold Check

Generate proposals only when patterns meet thresholds:

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Recurring violations | 3+ PRs with same issue | Propose clarification |
| Uncategorized issues | 3+ instances | Propose new principle |
| Critical findings | Any uncovered critical | High-priority proposal |
| Manual suggestion | Always | Create proposal |

If no patterns meet thresholds:

```markdown
## Evolution Analysis Complete

No constitution amendments recommended at this time.

**Analysis Summary:**
- PR Reviews Analyzed: {N}
- Audit Reports Analyzed: {M}
- Patterns Meeting Threshold: 0

**Current State:**
- Constitution compliance appears healthy
- No recurring uncategorized issues detected
- Existing principles cover observed patterns

**Recommendations:**
- Continue monitoring with regular PR reviews
- Run `/devspark.site-audit` for comprehensive compliance check
- Revisit evolution analysis after 10+ more PR reviews

To force a proposal from manual observation:
/devspark.evolve-constitution suggest "Your observed pattern or needed principle"
```

Stop execution if no proposals warranted.

### 5. Proposal Generation

For each identified evolution need, create proposal at `PROPOSALS_DIR/NEXT_CAP_ID.md`:

Ensure directory exists: Create `/.documentation/memory/proposals/` if missing.

```markdown
# Constitution Amendment Proposal: {NEXT_CAP_ID}

## Proposal Metadata

- **Proposal ID**: {NEXT_CAP_ID}
- **Created**: {TIMESTAMP}
- **Status**: DRAFT
- **Proposer**: /devspark.evolve-constitution
- **Source**: {analyze | suggest | from-pr | from-audit}

## Amendment Type

Select one:
- [ ] **ADD** - New principle
- [ ] **MODIFY** - Update existing principle
- [ ] **DEPRECATE** - Remove or soften principle
- [ ] **CLARIFY** - Add examples/guidance without changing rules

## Current State

{If modifying: Quote current principle text}
{If adding: "No existing principle covers this area"}

## Evidence

### Pattern Analysis

{Summary of findings that triggered this proposal}

| Source | Finding | Count |
|--------|---------|-------|
| PR Reviews | {issue description} | {N} occurrences |
| Audits | {finding} | {M} reports |

### Specific Examples

{List 2-3 specific PR numbers or audit dates with issue details}

1. **PR #{N}**: {Issue found}
2. **PR #{M}**: {Similar issue}
3. **Audit {date}**: {Related finding}

## Proposed Change

### Principle: {Principle Name}

{Full proposed principle text}

**Rationale**: {Why this principle is needed based on evidence}

**MUST Requirements:**
- {Specific requirement 1}
- {Specific requirement 2}

**SHOULD Recommendations:**
- {Recommended practice}

## Impact Assessment

### Affected Areas

- **Existing Code**: {Estimate of files/modules affected}
- **Future Development**: {How this changes workflow}
- **Tooling**: {Any tool updates needed}

### Compliance Effort

| Current Compliance | Remediation Effort | Timeline |
|--------------------|-------------------|----------|
| ~{X}% | {LOW/MEDIUM/HIGH} | {estimate} |

### Risk Analysis

| If Adopted | If Rejected |
|------------|-------------|
| {Potential downsides} | {Continued issues} |

## Adoption Plan

### Phase 1: Soft Introduction (Recommended)

1. Add principle as SHOULD (recommended, not blocking)
2. Monitor compliance in PR reviews for 2 weeks
3. Gather team feedback

### Phase 2: Full Enforcement

1. Elevate to MUST (required, blocking)
2. Address remaining violations
3. Update CI/CD if applicable

## Review Checklist

- [ ] Principle is testable in code review
- [ ] Principle is actionable for developers
- [ ] Evidence justifies the change
- [ ] Impact assessment is realistic
- [ ] Adoption plan is achievable

## Voting Record

| Reviewer | Vote | Date | Comments |
|----------|------|------|----------|
| (pending review) | | | |

## Resolution

- **Decision**: PENDING
- **Decision Date**:
- **Applied in Version**:

---

*Generated by /devspark.evolve-constitution v1.0*
*Review period: 14 days from creation*
```

### 6. Update History File

Create or update `/.documentation/memory/constitution-history.md`:

```markdown
# Constitution Change History

## Current Version

**Version**: {CONSTITUTION_VERSION}
**Last Updated**: {date of last amendment}

## Pending Proposals

| CAP ID | Created | Type | Principle | Status | Review Due |
|--------|---------|------|-----------|--------|------------|
| {NEXT_CAP_ID} | {date} | {ADD/MODIFY} | {name} | DRAFT | {date + 14 days} |

## Amendment Log

| Version | Date | Type | Principle | CAP ID | Status |
|---------|------|------|-----------|--------|--------|
| (entries added as amendments are approved) |

## Rejected Proposals

| CAP ID | Date | Principle | Reason |
|--------|------|-----------|--------|
| (entries added as proposals are rejected) |

---

*Maintained by /devspark.evolve-constitution*
```

### 7. Output Summary

```markdown
## Constitution Evolution Analysis Complete

**Analysis Period**: {earliest PR date} to {latest PR date}
**Data Sources**:
- PR Reviews: {N} analyzed
- Audit Reports: {M} analyzed
- Constitution Version: {VERSION}

### Findings Summary

| Category | Count | Trend |
|----------|-------|-------|
| Critical Issues | {N} | {trend} |
| High Issues | {M} | {trend} |
| Uncategorized | {P} | {trend} |

### Proposals Generated

| CAP ID | Type | Principle | Priority |
|--------|------|-----------|----------|
| {NEXT_CAP_ID} | ADD | {name} | HIGH |

### Proposal Details

**{NEXT_CAP_ID}**: {Brief description}

- **Evidence**: {N} occurrences across {M} PRs
- **Impact**: {LOW/MEDIUM/HIGH}
- **Review Due**: {date + 14 days}

### Next Steps

1. **Review Proposals**:
   `/.documentation/memory/proposals/{NEXT_CAP_ID}.md`

2. **Gather Team Feedback**:
   Share proposals with team for discussion

3. **Approve or Reject**:
   - Approve: `/devspark.evolve-constitution approve {NEXT_CAP_ID}`
   - Reject: `/devspark.evolve-constitution reject {NEXT_CAP_ID} "reason"`

4. **Apply Approved Amendments**:
   `/devspark.constitution`

### Additional Analysis Options

- From specific PR: `/devspark.evolve-constitution --from-pr #123`
- From specific audit: `/devspark.evolve-constitution --from-audit 2026-01-15`
- Manual suggestion: `/devspark.evolve-constitution suggest "description"`
```

## Guidelines

### Proposal Quality

Proposals should be:

- **Evidence-based**: Supported by PR/audit findings
- **Testable**: Can be verified in code review
- **Actionable**: Developers know how to comply
- **Justified**: Clear rationale with specific examples
- **Scoped**: Not overly broad or narrow

### Amendment Types

| Type | Use When | Example |
|------|----------|---------|
| ADD | New area needs coverage | "API Versioning" principle |
| MODIFY | Existing principle unclear | Clarify testing requirements |
| DEPRECATE | Principle no longer relevant | Remove outdated standard |
| CLARIFY | Add examples only | Add code examples to existing |

### Voting Process

Default governance (can be customized in constitution):

- Review period: 14 days
- Approval: Majority of reviewers
- Veto: Any critical concern blocks until resolved

### Integration Points

**PR Review Integration:**

When PR review finds uncategorized issues:

```markdown
**Note**: This issue doesn't map to current constitution principles.
Consider running `/devspark.evolve-constitution` to propose amendments.
```

**Site Audit Integration:**

When audit finds patterns without principles:

```markdown
**Gap Detected**: {N} issues found without constitutional coverage.
Recommendation: Run `/devspark.evolve-constitution --scope=audit`
```

### Error Handling

**No PR Reviews Available:**

```markdown
Insufficient Data for Evolution Analysis

No PR reviews found in /.documentation/specs/pr-review/

To build analysis data:
1. Run `/devspark.pr-review` on recent PRs
2. Accumulate 5+ reviews for meaningful patterns
3. Retry `/devspark.evolve-constitution`

Or create manual proposal:
/devspark.evolve-constitution suggest "Your observed pattern"
```

**No Constitution:**

```markdown
Cannot perform evolution analysis - Constitution required

Create a constitution first:
1. Run: /devspark.constitution
2. Define your project's core principles
3. Run PR reviews to build compliance data
4. Then retry: /devspark.evolve-constitution
```

## Context

$ARGUMENTS
