---
description: Perform adversarial, archetype-aware risk analysis across spec.md, plan.md, and tasks.md — identifying flaws, hazards, and failure modes that will derail delivery in production.
handoffs:
  - label: Fix Spec Showstoppers
    agent: devspark.specify
    prompt: Revise spec to resolve vague requirements, missing edge cases, or undefined trust boundaries
    send: true
  - label: Fix Critical Issues
    agent: devspark.plan
    prompt: Revise plan to address critical architectural risks
    send: true
  - label: Update Tasks
    agent: devspark.tasks
    prompt: Regenerate tasks with missing operational items
    send: true
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.critic.md` (personalized override)
2. `.documentation/commands/devspark.critic.md` (team customization)
3. `.devspark/defaults/commands/devspark.critic.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
