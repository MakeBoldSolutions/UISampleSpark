---
description: Validate the multi-app registry schema, references, cycles, path existence, and app-local manifest consistency.
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.validate-registry.md` (personalized override)
2. `.documentation/commands/devspark.validate-registry.md` (team customization)
3. `.devspark/defaults/commands/devspark.validate-registry.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
