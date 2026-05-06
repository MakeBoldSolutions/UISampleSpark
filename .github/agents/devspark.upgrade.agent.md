---
description: Check the installed DevSpark version, identify stale framework files, and guide a safe upgrade to the latest release
---

## Prompt Resolution

Determine the current git user by running `git config user.name`.
Normalize to a folder-safe slug: lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars.

Read and execute the instructions from the **first file that exists**:
1. `.documentation/{git-user}/commands/devspark.upgrade.md` (personalized override)
2. `.documentation/commands/devspark.upgrade.md` (team customization)
3. `.devspark/defaults/commands/devspark.upgrade.md` (stock default)

Where `{git-user}` is the normalized slug from step above.

## User Input

```text
$ARGUMENTS
```

Pass the user input above to the resolved prompt.
