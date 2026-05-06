---
description: Analyze PR review findings and codebase patterns to propose constitution amendments with change tracking
handoffs:
  - label: Apply Amendment
    agent: devspark.constitution
    prompt: Apply the approved constitution amendment
  - label: Review PRs
    agent: devspark.pr-review
    prompt: Review recent PRs to gather more data
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.evolve-constitution.md` (personalized override)
2. `.documentation/commands/devspark.evolve-constitution.md` (team customization)
3. `.devspark/defaults/commands/devspark.evolve-constitution.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
