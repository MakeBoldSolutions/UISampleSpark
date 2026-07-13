---
description: "Bold: Generate or verify a checklist that tests the quality of the spec's requirements, not the implementation."
---

# bold-plan-checklist

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/checklist.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/checklist.md`
3. `.bold/commands/plan/checklist.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector (no collector for this subcommand — it reads only what's already on disk) before anything else.