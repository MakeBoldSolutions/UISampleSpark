---
description: Rapid lightweight fix workflow that bypasses full spec creation while maintaining constitution compliance validation
handoffs:
  - label: View Quickfix History
    agent: devspark.quickfix
    prompt: Show me previous quickfixes with /devspark.quickfix list
  - label: Upgrade to Full Spec
    agent: devspark.specify
    prompt: Create a full specification for this change
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.quickfix.md` (personalized override)
2. `.documentation/commands/devspark.quickfix.md` (team customization)
3. `.devspark/defaults/commands/devspark.quickfix.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
