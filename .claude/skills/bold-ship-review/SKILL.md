---
name: bold-ship-review
description: "Bold: Review pass over the active feature's changes before or after a PR is opened."
---

# bold-ship-review

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/ship/review.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/ship/review.md`
3. `.bold/commands/ship/review.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-ship-context.{sh,ps1}` before anything else.