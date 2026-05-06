---
description: Perform constitution-aware pull request review with actionable feedback for any PR in the repository
handoffs:
  - label: View Review History
    agent: devspark.pr-review
    prompt: Show me previous PR reviews in .documentation/specs/pr-review/
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.pr-review.md` (personalized override)
2. `.documentation/commands/devspark.pr-review.md` (team customization)
3. `.devspark/defaults/commands/devspark.pr-review.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
