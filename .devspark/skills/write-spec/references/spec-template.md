# Spec Template Reference

Use this template as the structural guide when drafting a `spec.md` with the
`write-spec` skill.

---

## Frontmatter

```yaml
---
classification: full-spec
risk_level: low|medium|high
status: Draft
---
```

`status` must always be `Draft` when produced by this skill.

---

## Required Sections (in canonical order)

### 1. Feature Name and Header Block

```markdown
# Feature Specification: <Feature Name>

**Feature Branch**: `<NNN>-<slug>`
**Created**: YYYY-MM-DD
**Status**: Draft
**Input**: <one-sentence description of what the user asked for>
```

### 2. Rationale Summary

Sub-sections:

- **Core Problem** — What is broken, missing, or suboptimal?
- **Decision Summary** — What approach is selected and why?
- **Key Drivers** — Bullet list of motivating factors.
- **Tradeoffs Considered** — Rejected options with reasons (Option A, Option B,
  Selected Option).

### 3. User Stories

Each story follows:

```markdown
### User Story N - <Title> (Priority: P1|P2|P3)

<Actor and goal narrative>

**Why this priority**: <business reason>

**Acceptance Scenarios**:

1. **Given** <precondition>, **When** <action>, **Then** <expected result>.
2. ...
```

At least one P1 story is required.

### 4. Requirements

Sub-sections by phase or concern. Each requirement uses MUST or SHOULD:

```markdown
- **FR-001**: The system MUST...
- **FR-002**: The system SHOULD...
```

Do not mix implementation decisions into requirements. Keep requirements
technology-agnostic.

### 5. Success Criteria

Measurable outcomes keyed to user stories:

```markdown
- **SC-001**: <Measurable outcome for US1>
- **SC-002**: <Measurable outcome for US2>
```

Each criterion must be verifiable without DevSpark.

### 6. Assumptions

```markdown
## Assumptions

- <Each assumption on its own line>
- Skipped context: <list items from skipped_context, or "none">
```

### 7. Out of Scope

```markdown
## Out of Scope

- <Each out-of-scope item on its own line>
```

---

## Validation Rules Summary

A `spec.md` passes the shared validation contract when:

- YAML frontmatter is present and parseable.
- `status: Draft` is present.
- All four mandatory sections are present: Rationale Summary, User Stories,
  Requirements, Success Criteria.
- No more than three `[NEEDS CLARIFICATION]` markers.
- No implementation details (no framework names, no library versions, no file
  paths in requirements).
