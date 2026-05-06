---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs:
  - label: Create Tasks
    agent: devspark.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: devspark.checklist
    prompt: Create a checklist for the following domain...
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.plan.md` (personalized override)
2. `.documentation/commands/devspark.plan.md` (team customization)
3. `.devspark/defaults/commands/devspark.plan.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
