---
description: "Bold: Draft a PR (or finalize the deliverable, for non-code domains) for the active feature."
---

# bold-ship

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/ship/default.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/ship/default.md`
3. `.bold/commands/ship/default.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-ship-context.{sh,ps1}` before anything else.