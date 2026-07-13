---
name: bold-plan-discover
description: "Bold: Read-only brownfield archaeology — mine configs and history, infer conventions, play back findings for ratification."
---

# bold-plan-discover

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/discover.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/discover.md`
3. `.bold/commands/plan/discover.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-brownfield-signals.{sh,ps1}` before anything else.