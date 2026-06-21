---
name: write-spec
description: Draft feature specifications, requirements documents, user stories, acceptance criteria, and validation-ready specs from a feature request. Use this skill when you need to write a spec, define requirements, capture user stories, or produce a structured specification document.
metadata:
  version: "0.1.0"
---

# write-spec

Draft a structured feature specification from a user's feature request. This
skill works in any skills-compatible client with or without DevSpark installed.

---

## Context Loading

Before drafting, run the context-gathering script for your platform:

- **PowerShell**: `scripts/gather-context.ps1`
- **Bash/macOS/Linux**: `bash scripts/gather-context.sh`

Parse the JSON output. If the script exits non-zero, produces empty output, or
produces non-JSON output, use this fallback and continue without blocking:

```json
{
  "constitution_summary": null,
  "prior_specs": [],
  "skipped_context": ["script-error"]
}
```

The JSON output contains:

- `constitution_summary` — key constraints from the repo constitution, or null
- `prior_specs` — list of prior spec summaries for naming and scope awareness
- `skipped_context` — list of context items that could not be gathered

If `constitution_summary` is non-null, apply the listed constraints to the spec.
If `prior_specs` is non-empty, use the existing numbering pattern for the new
spec and avoid duplicating solved problems.

---

## Drafting Procedure

Use the spec template in `references/spec-template.md`.

1. Set `name` from the feature request. Generate a sequential number if prior
   specs are available (e.g., if the last spec was `004-...`, use `005-`).
2. Set `status: Draft` always. Do not set any other lifecycle state.
3. Write the **Rationale Summary** — core problem, decision summary, key
   drivers, tradeoffs considered.
4. Write **User Stories** — at least one per priority tier in the request.
   Each story must have: actor, capability, business value, and acceptance
   scenarios.
5. Write **Requirements** — MUST-level functional requirements as the minimum
   viable set. Do not add requirements the user has not implied.
6. Write **Success Criteria** — measurable outcomes. Each criterion must be
   verifiable without DevSpark installed.
7. Add an **Assumptions** section listing anything the spec takes for granted,
   including any context items listed in `skipped_context`.
8. Add an **Out of Scope** section. Capture anything explicitly not covered by
   this spec.

Do NOT include implementation details (frameworks, library versions, file
paths). Keep the spec technology-agnostic.

Limit `[NEEDS CLARIFICATION]` markers to three. Use them only for genuine
blocking ambiguities that would prevent drafting a section.

---

## Clarification Format

When a `[NEEDS CLARIFICATION]` marker is needed, follow this format:

```text
[NEEDS CLARIFICATION]: <question>
Context: <why this matters for the spec>
Options: <list 2-3 concrete options when possible>
```

Consolidate related ambiguities into one marker. Do not add markers for
stylistic preferences or implementation decisions.

---

## Output

Produce a single `spec.md` file in the current working directory (or the path
provided by the host client). The file must:

- Pass the shared spec validation contract (see `references/spec-template.md`)
- Have valid YAML frontmatter with `status: Draft`
- Contain the four mandatory sections: Rationale Summary, User Stories,
  Requirements, and Success Criteria
- Contain no more than three `[NEEDS CLARIFICATION]` markers
- Contain no implementation details (no language choices, no library versions)

Do not perform branch creation, file moves to governed paths, checklist
generation, or gate enforcement. Those are DevSpark-command responsibilities.

---

## Assumptions Section

In the produced `spec.md`, always include an Assumptions section that lists:

- Any context gathered or not gathered (from `skipped_context`)
- Any decisions made without user input
- Any scope boundaries inferred rather than stated
