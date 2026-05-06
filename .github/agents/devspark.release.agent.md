---
description: Archive development artifacts at release, distill key decisions into permanent documentation, and prepare for next development cycle
handoffs:
  - label: View Release History
    agent: devspark.release
    prompt: Show me previous releases in .documentation/releases/
  - label: Run Final Audit
    agent: devspark.site-audit
    prompt: Run a final site audit before release
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.release.md` (personalized override)
2. `.documentation/commands/devspark.release.md` (team customization)
3. `.devspark/defaults/commands/devspark.release.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
