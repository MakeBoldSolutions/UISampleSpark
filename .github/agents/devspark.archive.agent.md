---
description: Deprecated compatibility alias for /devspark.harvest
handoffs:
  - label: Review Release Artifacts
    agent: devspark.release
    prompt: Review completed specs and release documentation before archival
  - label: Run Documentation Audit
    agent: devspark.site-audit
    prompt: Audit documentation quality and stale references before harvest
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.archive.md` (personalized override)
2. `.documentation/commands/devspark.archive.md` (team customization)
3. `.devspark/defaults/commands/devspark.archive.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
