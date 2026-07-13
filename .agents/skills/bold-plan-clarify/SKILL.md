---
name: bold-plan-clarify
description: "Bold: Re-run the clarification pass on the active feature's spec."
---

# bold-plan-clarify

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/clarify.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/clarify.md`
3. `.bold/commands/plan/clarify.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector (no collector for this subcommand — it reads only what's already on disk) before anything else.