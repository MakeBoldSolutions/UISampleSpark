---
description: Analyze git commit history patterns for contributor velocity, commit hygiene, DORA metrics, AI adoption level, and architecture maturity
handoffs:
  - label: Run Site Audit
    agent: devspark.site-audit
    prompt: Run a full codebase audit to complement commit history insights
  - label: View Harvest Report
    agent: devspark.harvest
    prompt: Review completed specs and stale documentation before archiving
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.commit-audit.md` (personalized override)
2. `.documentation/commands/devspark.commit-audit.md` (team customization)
3. `.devspark/defaults/commands/devspark.commit-audit.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
