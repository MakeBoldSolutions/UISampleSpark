---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
handoffs:
  - label: Analyze For Consistency
    agent: devspark.analyze
    prompt: Run a project analysis for consistency
    send: true
  - label: Implement Project
    agent: devspark.implement
    prompt: Start the implementation in phases
    send: true
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.tasks.md` (personalized override)
2. `.documentation/commands/devspark.tasks.md` (team customization)
3. `.devspark/defaults/commands/devspark.tasks.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
