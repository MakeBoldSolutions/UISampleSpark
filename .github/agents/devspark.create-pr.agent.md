---
description: Draft or update a spec-aware pull request with task, checklist, and gate visibility before review.
handoffs:
  - label: Review Pull Request
    agent: devspark.pr-review
    prompt: Review the pull request for constitution compliance
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.create-pr.md` (personalized override)
2. `.documentation/commands/devspark.create-pr.md` (team customization)
3. `.devspark/defaults/commands/devspark.create-pr.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
