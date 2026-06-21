---
description: Post-release cleanup — preserve knowledge into living docs, rewrite spec-linked code comments, and move stale artifacts to /.archive/
handoffs:
  - label: Run Documentation Audit
    agent: devspark.site-audit
    prompt: Audit documentation quality and stale references after harvest
  - label: Run Release First
    agent: devspark.release
    prompt: Seal the release and archive completed specs before running harvest
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.harvest.md` (personalized override)
2. `.documentation/commands/devspark.harvest.md` (team customization)
3. `.devspark/defaults/commands/devspark.harvest.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
