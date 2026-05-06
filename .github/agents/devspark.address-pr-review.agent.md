---
description: Address open PR review findings with enforced commit isolation between code fixes and review-file updates
handoffs:
  - label: Re-Review Updated PR
    agent: devspark.pr-review
    prompt: Run /devspark.pr-review UPDATE for this PR after fixes are committed
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.address-pr-review.md` (personalized override)
2. `.documentation/commands/devspark.address-pr-review.md` (team customization)
3. `.devspark/defaults/commands/devspark.address-pr-review.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
