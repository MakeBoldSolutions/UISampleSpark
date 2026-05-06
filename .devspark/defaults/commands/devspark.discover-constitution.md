---
description: Analyze existing codebase to discover implicit patterns and conventions, then guide user through crafting a constitution via interactive questioning.
handoffs: 
  - label: Create Constitution
    agent: devspark.constitution
    prompt: Formalize the discovered principles into the constitution template
  - label: Run Site Audit
    agent: devspark.site-audit
    prompt: Audit the codebase against the new constitution
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). User may provide focus areas (e.g., "focus on security and testing") or specific directories to analyze.

## Overview

Help brownfield projects reverse-engineer a project constitution by analyzing existing source code patterns, identifying implicit conventions, and guiding the user through interactive questions to formalize principles.

This command is designed for teams adopting DevSpark on **existing codebases** where principles exist implicitly in the code but have never been documented.

## Guidelines

- **Discovery-first**: Analyze code before asking questions—ground questions in actual patterns found
- **Interactive refinement**: Use targeted questions to validate discoveries and fill gaps
- **Draft output**: Produce a draft constitution for user review, not a final document
- **Respect existing work**: Treat discovered patterns as valuable—the team chose them for reasons

## Outline

### 1. Initialize Discovery Context

Identify the codebase structure:

- Detect primary language(s) and frameworks
- Identify source directories (src/, lib/, app/, etc.)
- Locate test directories and patterns
- Find configuration files (.eslintrc, tsconfig, .editorconfig, etc.)
- Check for existing documentation (README, CONTRIBUTING, .documentation/)
- Look for existing AI instruction files (.github/copilot-instructions.md, CLAUDE.md, etc.)

If `/.documentation/memory/constitution.md` already exists:

- Warn user: "A constitution already exists. This will create a draft to compare/merge."
- Proceed with analysis to identify gaps or conflicts

### 2. Automated Pattern Discovery

Scan the codebase for patterns across these categories. For each, note:

- **Consistency**: What % of files follow this pattern?
- **Examples**: 2-3 specific file paths demonstrating the pattern
- **Confidence**: HIGH (>80% consistent), MEDIUM (50-80%), LOW (<50% or unclear)

#### A. Code Quality Patterns

| Pattern | Detection Method |
|---------|------------------|
| TypeScript strict mode | Check tsconfig.json for strict: true |
| ESLint/linting rules | Parse .eslintrc* for enabled rules |
| Formatting tools | Presence of .prettierrc, .editorconfig |
| Maximum file length | Analyze distribution of file sizes |
| Naming conventions | Analyze function/class/file naming patterns |
| Comment density | Ratio of comments to code |
| JSDoc/documentation | Presence of doc comments on exports |

#### B. Testing Patterns

| Pattern | Detection Method |
|---------|------------------|
| Test framework | Detect jest, vitest, mocha, pytest, etc. |
| Test file location | Co-located vs. separate test directory |
| Test file naming | *.test.ts, *.spec.ts, test_*.py patterns |
| Coverage configuration | Presence of coverage config, thresholds |
| Test types present | Unit, integration, e2e directories |

#### C. Security Patterns

| Pattern | Detection Method |
|---------|------------------|
| Secret management | Environment variable usage vs. hardcoded values |
| Input validation | Presence of validation libraries (Zod, Joi, etc.) |
| Auth patterns | Authentication library usage |
| SQL patterns | Parameterized queries vs. string concatenation |
| Dependency scanning | Security audit in package.json scripts |

#### D. Architecture Patterns

| Pattern | Detection Method |
|---------|------------------|
| Directory structure | Analyze folder organization |
| Layer separation | Presence of routes/, services/, models/ etc. |
| API patterns | REST conventions, GraphQL, tRPC usage |
| Database access | ORM usage (Prisma, TypeORM, SQLAlchemy) |
| Error handling | Custom error classes, try/catch patterns |

#### E. Observability Patterns

| Pattern | Detection Method |
|---------|------------------|
| Logging | Logger library usage, console.log presence |
| Structured logging | JSON logging patterns |
| Error tracking | Sentry, Rollbar, etc. integration |
| Health checks | /health or /healthz endpoints |

#### F. Workflow Patterns

| Pattern | Detection Method |
|---------|------------------|
| Git workflow | Branch naming in .git, protected branches |
| CI/CD | Presence of .github/workflows, .gitlab-ci.yml |
| Pre-commit hooks | .husky/, .pre-commit-config.yaml |
| Changelog maintenance | CHANGELOG.md updates |

### 3. Generate Discovery Report

Produce an internal discovery summary (shown to user before questions):

```markdown
## Codebase Analysis Summary

**Stack Detected**: [Language] + [Framework] + [Database]
**Files Analyzed**: [count] source files, [count] test files

### High-Confidence Patterns (>80% consistent)

| Pattern | Evidence | Recommendation |
|---------|----------|----------------|
| TypeScript strict mode | tsconfig.json strict: true | → MUST principle |
| Jest testing | All 47 test files use Jest | → MUST principle |
| Prisma ORM | No raw SQL found | → SHOULD principle |

### Medium-Confidence Patterns (50-80% consistent)

| Pattern | Evidence | Needs Decision |
|---------|----------|----------------|
| JSDoc on exports | 73% of exported functions | Formalize or relax? |
| Error classes | 60% use CustomError | Standardize pattern? |

### Inconsistent Areas (Needs Discussion)

| Area | Observation | Question |
|------|-------------|----------|
| Logging | Mixed console.log and winston | Which to standardize? |
| Test coverage | /api has tests, /utils doesn't | Coverage requirement? |

### Gaps Detected (No Clear Pattern)

- No input validation library detected
- No rate limiting implementation found
- No structured error response format
```

### 4. Interactive Question Loop

Based on discovery findings, generate targeted questions. Use the same interaction pattern as `/devspark.clarify`:

**Question Categories** (prioritized):

1. **Validation Questions**: Confirm high-confidence patterns should become MUST principles
2. **Decision Questions**: Resolve medium-confidence patterns (formalize or relax?)
3. **Gap Questions**: Determine if missing patterns should be added as requirements
4. **Priority Questions**: Which principles matter most to the team?

**Maximum Questions**: 8-10 total (more than clarify since this is foundational)

**Question Format**:

Present ONE question at a time with recommendation:

```markdown
## Question 1 of 8: Testing Standards

I found that **100% of test files use Jest** and tests are co-located with source files.

**Recommended:** Formalize as MUST principle

| Option | Description |
|--------|-------------|
| A | MUST: All code must have Jest tests in co-located *.test.ts files |
| B | SHOULD: Tests strongly encouraged but not blocking |
| C | No principle: Leave testing as informal convention |
| D | Different approach (describe in <=10 words) |

Reply with option letter, "yes"/"recommended" to accept, or your own answer.
```

**Question Sequencing**:

1. Start with high-confidence patterns (easy wins, builds momentum)
2. Move to decision points for medium-confidence patterns
3. Address critical gaps (security, testing if not covered)
4. Ask about priority/severity levels for borderline items
5. End with governance questions (how to handle amendments)

**Early Termination Signals**: "done", "enough", "that's good", "proceed"

### 5. Synthesize Draft Constitution

After questions complete (or user terminates early), generate a draft constitution:

```markdown
# [Project Name] Constitution (DRAFT)

> ⚠️ **DRAFT**: Generated by /devspark.discover-constitution on YYYY-MM-DD
> Review carefully before finalizing. Run /devspark.constitution to formalize.

## Discovery Context

- **Source**: Analyzed [X] files in [repository]
- **Patterns Found**: [Y] high-confidence, [Z] formalized via questions
- **Coverage**: [categories covered]

## Core Principles

### I. [Principle Name] (MANDATORY)

[Description based on discovered pattern + user confirmation]

- [Specific rule] (MUST)
- [Specific rule] (MUST)

**Evidence**: [Examples from codebase that demonstrate this pattern]

### II. [Principle Name]

[Description...]

## Governance

- Constitution amendments require [user input or default: team discussion]
- Reviews should occur [user input or default: quarterly]

**Version**: 2.0.0-draft | **Generated**: YYYY-MM-DD
```

### 6. Gap Analysis

After draft generation, identify what's NOT covered:

```markdown
## Principles NOT Included (Consider Adding)

Based on common best practices, these areas have no discovered pattern or explicit decision:

| Area | Common Principle | Why Consider |
|------|------------------|--------------|
| Input Validation | All user input MUST be validated | Security best practice |
| Rate Limiting | Public APIs SHOULD have rate limits | DDoS protection |
| Accessibility | UI SHOULD meet WCAG AA | Legal/ethical requirement |

Would you like to add any of these? (Reply with area names, or "none")
```

### 7. Output Draft and Next Steps

Write draft to `/.documentation/memory/constitution-draft.md` (not overwriting existing constitution if present).

```markdown
## Discovery Complete

**Draft saved to**: `/.documentation/memory/constitution-draft.md`

### Summary

- Questions asked: [X]
- Principles formalized: [Y]
- Categories covered: [list]
- Gaps identified: [Z]

### Recommended Next Steps

1. **Review the draft**: Open `/.documentation/memory/constitution-draft.md` and refine wording
2. **Team discussion**: Share draft with team for feedback
3. **Finalize**: Run `/devspark.constitution` to create the official constitution
4. **Validate**: Run `/devspark.site-audit` to check codebase against new principles

### Comparison (if existing constitution found)

| Principle | Existing | Discovered | Conflict? |
|-----------|----------|------------|-----------|
| ... | ... | ... | ... |
```

## Question Templates

### Pattern Validation Questions

```markdown
I found that **[pattern description]** with **[X]% consistency** across [Y] files.

Examples:
- `src/api/users.ts` - [specific example]
- `src/services/auth.ts` - [specific example]

**Recommended:** [MUST/SHOULD/No principle] - [brief reasoning]

Should this become a formal principle?
```

### Gap Questions

```markdown
I did **not find** a clear pattern for **[category]**.

Common approaches include:
| Option | Description |
|--------|-------------|
| A | [Approach 1] |
| B | [Approach 2] |
| C | Not needed for this project |

What's your preference?
```

### Priority Questions

```markdown
For **[principle]**, what severity should violations have?

| Option | Meaning |
|--------|---------|
| A | **MUST** - Violations are blocking (CRITICAL in PR review) |
| B | **SHOULD** - Strongly recommended (HIGH in PR review) |
| C | **MAY** - Optional guideline (LOW in PR review) |
```

### Governance Questions

```markdown
How should constitution amendments be handled?

| Option | Description |
|--------|-------------|
| A | Any team member can propose; requires team approval |
| B | Tech lead approval required |
| C | Documented but informal process |
| D | Other (describe briefly) |
```

## Edge Cases

### Empty/Minimal Codebase

If fewer than 10 source files found:

- Skip automated discovery
- Switch to aspirational mode: "What principles do you WANT to establish?"
- Provide common principle templates to choose from

### Highly Inconsistent Codebase

If no patterns reach >50% consistency:

- Report honestly: "No strong patterns detected—codebase may have evolved organically"
- Focus questions on: "What SHOULD the standard be going forward?"
- Recommend running site-audit after constitution to identify cleanup areas

### Existing Constitution Present

If an existing constitution is found:

- Complete discovery anyway
- Compare discovered patterns vs. documented principles
- Highlight gaps and conflicts
- Suggest constitution updates if code has drifted

### User Skips All Questions

If user says "done" before any questions:

- Generate constitution from high-confidence patterns only
- Mark all medium/low patterns as "SUGGESTED" not MUST/SHOULD
- Strongly recommend reviewing draft

## Context

$ARGUMENTS
