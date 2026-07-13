---
description: "Bold: Adversarial risk critique of the active feature's spec — what will fail in production, gated at Feature tier."
---

# bold-plan-critic

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/critic.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/critic.md`
3. `.bold/commands/plan/critic.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector `.bold/scripts/{bash,powershell}/collect-triage-context.{sh,ps1}` before anything else.