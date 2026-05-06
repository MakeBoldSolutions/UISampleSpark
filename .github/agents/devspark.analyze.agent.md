---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation.
handoffs:
  - label: Implement Project
    agent: devspark.implement
    prompt: Start the implementation in phases
  - label: Revise Plan
    agent: devspark.plan
    prompt: Revise plan to address analysis findings
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.analyze.md` (personalized override)
2. `.documentation/commands/devspark.analyze.md` (team customization)
3. `.devspark/defaults/commands/devspark.analyze.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
