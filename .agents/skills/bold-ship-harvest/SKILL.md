---
name: bold-ship-harvest
description: "Bold: Classify feature artifacts — promote durable knowledge, archive work products, reconcile stale docs."
---

# bold-ship-harvest

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/ship/harvest.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/ship/harvest.md`
3. `.bold/commands/ship/harvest.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-harvest-inventory.{sh,ps1}` before anything else.