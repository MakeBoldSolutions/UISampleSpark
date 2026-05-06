---
id: capture-context
name: capture-context
audience: intermediate
exposed: true
category: improvement
description: Capture the current context (files, recent commits, intent) and produce a structured summary for downstream classification.
inputs: []
outputs:
  - context.summary
  - context.classification_hint
---

## Outline

Summarize the current improvement context in a way the next step
(`classify-improvement`) can act on without further user input.

## Steps

1. Read recent git history (`git log -n 20 --oneline`) and the current
   working-tree status.
2. Identify the user's stated intent from the invoking message.
3. Produce `context.summary` (2-5 sentences) describing what the user wants
   improved and the surrounding code or workflow it touches.
4. Produce `context.classification_hint` — one of `bug`, `enhancement`,
   `prompt-quality`, `workflow-design`, `documentation` — based on the cues
   in the summary. The next step is allowed to override this hint.

## Output

```yaml
context:
  summary: <2-5 sentence summary>
  classification_hint: <bug|enhancement|prompt-quality|workflow-design|documentation>
```
