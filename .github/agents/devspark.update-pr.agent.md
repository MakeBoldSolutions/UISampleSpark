---
description: Update an existing pull request description with current branch delta, preserving linked work items and metadata
handoffs:
  - label: Review Updated PR
    agent: devspark.pr-review
    prompt: Run a re-review of the updated pull request
  - label: Create New PR
    agent: devspark.create-pr
    prompt: Create a new pull request for this branch
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.update-pr.md` (personalized override)
2. `.documentation/commands/devspark.update-pr.md` (team customization)
3. `.devspark/defaults/commands/devspark.update-pr.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
