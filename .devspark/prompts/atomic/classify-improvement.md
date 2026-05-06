---
id: classify-improvement
name: classify-improvement
audience: intermediate
exposed: true
category: improvement
description: Decide the canonical classification and a concise issue title for an improvement proposal.
inputs:
  - context.summary
  - context.classification_hint
outputs:
  - proposal.classification
  - proposal.title
  - proposal.context
  - proposal.current_behavior
  - proposal.expected_behavior
  - proposal.suggested_fix
---

## Outline

Convert the captured context into a fully formed issue proposal that the
`create-issue` step can submit verbatim.

## Steps

1. Use `context.classification_hint` as a starting point but override when
   the summary clearly maps to a different category in the canonical set:
   `bug`, `enhancement`, `prompt-quality`, `workflow-design`,
   `documentation`.
2. Draft `proposal.title` — imperative mood, ≤ 80 chars when possible,
   ≤ 200 chars hard cap.
3. Fill the four narrative sections from `context.summary`:
   `proposal.context`, `proposal.current_behavior`,
   `proposal.expected_behavior`, and (optionally) `proposal.suggested_fix`.

## Output

```yaml
proposal:
  classification: <bug|enhancement|prompt-quality|workflow-design|documentation>
  title: <≤200 chars>
  context: <markdown>
  current_behavior: <markdown>
  expected_behavior: <markdown>
  suggested_fix: <markdown or null>
```
