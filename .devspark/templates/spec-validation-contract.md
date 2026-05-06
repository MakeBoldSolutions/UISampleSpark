# Specification Validation Contract

Use this contract whenever a workflow creates, updates, clarifies, or evaluates `spec.md`.

Installed repos should resolve this file from `/.devspark/templates/spec-validation-contract.md`.
Source repos should resolve it from `templates/spec-validation-contract.md`.

## 1. Frontmatter Contract

Every feature spec MUST begin with YAML frontmatter containing these keys:

```yaml
classification: quick-spec | full-spec
risk_level: low | medium | high
target_workflow: specify-light | specify-full
required_artifacts: intent, action-plan | spec, plan, tasks
recommended_next_step: plan | clarify | implement
required_gates: checklist | checklist, analyze, critic
```

Validation rules:

- `classification`, `target_workflow`, and `required_artifacts` MUST agree with each other.
- `quick-spec` maps to `specify-light` and `intent, action-plan`.
- `full-spec` maps to `specify-full` and `spec, plan, tasks`.
- `required_gates` MUST match the chosen route unless the spec explicitly documents why additional gates were added.
- If frontmatter conflicts with body prose, treat frontmatter as authoritative and either repair the prose or flag the inconsistency.

## 2. Lifecycle State Contract

The spec body MUST include a status line using this format:

```markdown
**Status**: Draft
```

Allowed states: `Draft`, `In Progress`, `Complete`.

Validation rules:

- Newly created specs MUST start in `Draft`.
- Clarification updates MUST preserve the current lifecycle state unless the user explicitly changes it.

## 3. Required Sections By Route

### Quick Spec Required Structure

Quick specs MUST preserve this heading order:

1. `## Intent`
2. `## Scope`
3. `## Constraints`
4. `## Action Plan`
5. `## Validation Notes`

### Full Spec Required Structure

Full specs MUST preserve this heading order:

1. `## Rationale Summary`
2. `## User Scenarios & Testing`
3. `## Requirements`
4. `## Success Criteria`

Additional allowed headings:

- `## Clarifications`
- Route-specific subsections already present in the canonical templates
- New subsections only when they fit under an existing required heading and do not replace it

Validation rules:

- Required headings MUST exist exactly once.
- Headings may contain additional subsections, but required top-level sections must remain intact.
- Workflows may add `## Clarifications` when needed, but must not reorder unrelated required sections.

## 4. Required Content Quality

All specs MUST satisfy these content requirements:

- No unresolved placeholder text from the stock templates remains unless it is an explicit `[NEEDS CLARIFICATION: ...]` marker.
- No more than 3 `[NEEDS CLARIFICATION: ...]` markers may exist at one time.
- Requirements and validation notes must be testable and specific.
- Success criteria must be measurable and technology-agnostic.
- Scope boundaries must be explicit enough to distinguish in-scope vs out-of-scope behavior.
- Edge cases, assumptions, or constraints must be documented in the route-appropriate sections.

### Full Spec Required Content

Full specs MUST contain all of the following:

- At least one user story with acceptance scenarios
- At least one edge case bullet
- At least one functional requirement
- At least one measurable success criterion

### Quick Spec Required Content

Quick specs MUST contain all of the following:

- At least one in-scope bullet and one out-of-scope bullet
- At least one constraint bullet
- At least three action plan steps
- At least one validation note

## 5. Clarification Session Rules

If a workflow adds clarifications, it MUST use this structure:

```markdown
## Clarifications

### Session YYYY-MM-DD

- Q: <question> → A: <answer>
```

Validation rules:

- Add `## Clarifications` only once.
- Add exactly one bullet per accepted clarification answer.
- Integrate the clarified answer into the relevant required section; do not leave it only in the clarification log.
- Remove or replace now-contradictory text instead of duplicating it.

## 6. Repair Rules

When validation fails:

- Prefer minimal repairs that restore the canonical structure without rewriting unrelated content.
- If a missing or malformed item can be repaired directly from route metadata or obvious existing content, repair it.
- If classification or required section intent cannot be inferred safely, stop and ask the user to rerun `/devspark.specify` or repair the spec manually.
- Never silently drop user-authored requirements to make the document fit the contract.
