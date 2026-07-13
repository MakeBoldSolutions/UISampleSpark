---
description: "Bold: Respond to review findings on the active feature's open PR."
---

# bold-ship-address

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/ship/address.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/ship/address.md`
3. `.bold/commands/ship/address.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-pr-review-context.{sh,ps1}` before anything else.