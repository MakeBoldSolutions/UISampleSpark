---
description: "Bold: Check the active feature's spec for internal consistency, duplication, ambiguity, and requirement/task coverage."
---

# bold-plan-analyze

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/analyze.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/analyze.md`
3. `.bold/commands/plan/analyze.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-triage-context.{sh,ps1}` before anything else.