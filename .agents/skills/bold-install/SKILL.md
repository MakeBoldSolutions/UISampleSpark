---
name: bold-install
description: "Bold: Fetch, preview, and sync Bold's payload into this repo (fresh install, upgrade, or already-current), then hand off to bold.plan init."
---

# bold-install

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/install/default.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/install/default.md`
3. `.bold/commands/install/default.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector (no collector for this subcommand — it reads only what's already on disk) before anything else.