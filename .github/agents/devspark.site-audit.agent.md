---
description: Perform comprehensive codebase audit against project constitution/standards, producing structured compliance report
handoffs:
  - label: View Audit History
    agent: devspark.site-audit
    prompt: Show me previous audit reports in .documentation/copilot/audit/
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.site-audit.md` (personalized override)
2. `.documentation/commands/devspark.site-audit.md` (team customization)
3. `.devspark/defaults/commands/devspark.site-audit.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
