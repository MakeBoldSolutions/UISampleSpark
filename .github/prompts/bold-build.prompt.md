---
description: "Bold: Apply the ratified tier's gate set, execute, then keep artifacts continuously in sync."
---

# bold-build

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/build/default.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/build/default.md`
3. `.bold/commands/build/default.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-gate-status.{sh,ps1}` before anything else.