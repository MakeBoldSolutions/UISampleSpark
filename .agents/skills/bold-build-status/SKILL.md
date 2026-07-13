---
name: bold-build-status
description: "Bold: Report task/gate/artifact status for the active feature."
---

# bold-build-status

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/build/status.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/build/status.md`
3. `.bold/commands/build/status.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-gate-status.{sh,ps1}` before anything else.