---
description: Analyze existing codebase to discover implicit patterns and conventions, then guide user through crafting a constitution via interactive questioning.
handoffs: 
  - label: Create Constitution
    agent: devspark.constitution
    prompt: Formalize the discovered principles into the constitution template
  - label: Run Site Audit
    agent: devspark.site-audit
    prompt: Audit the codebase against the new constitution
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.discover-constitution.md` (personalized override)
2. `.documentation/commands/devspark.discover-constitution.md` (team customization)
3. `.devspark/defaults/commands/devspark.discover-constitution.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
