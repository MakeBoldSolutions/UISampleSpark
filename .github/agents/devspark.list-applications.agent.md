---
description: Display all registered applications in the multi-app repository with metadata, dependencies, and documentation roots.
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.list-applications.md` (personalized override)
2. `.documentation/commands/devspark.list-applications.md` (team customization)
3. `.devspark/defaults/commands/devspark.list-applications.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
