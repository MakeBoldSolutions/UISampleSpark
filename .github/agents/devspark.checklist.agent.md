---
description: Generate a custom checklist for the current feature based on user requirements.
handoffs:
  - label: Implement Project
    agent: devspark.implement
    prompt: Start the implementation in phases
  - label: Run Analysis
    agent: devspark.analyze
    prompt: Analyze spec consistency after checklist review
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.checklist.md` (personalized override)
2. `.documentation/commands/devspark.checklist.md` (team customization)
3. `.devspark/defaults/commands/devspark.checklist.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
