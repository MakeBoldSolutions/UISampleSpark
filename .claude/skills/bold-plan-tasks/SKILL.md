---
name: bold-plan-tasks
description: "Bold: Regenerate the task breakdown for the active feature's ratified spec, or merge in gate remediation on a re-run."
---

# bold-plan-tasks

Resolve the effective prompt via Bold's three-tier resolution (user > team > source —
see `.bold/scripts/*/bold-which.*`):

1. `.bold-user/{your-git-user-name}/commands/plan/tasks.md` (run `bold-which` to resolve the exact slug and path)
2. `bold-docs/overrides/commands/plan/tasks.md`
3. `.bold/commands/plan/tasks.md`

Read whichever resolves first and follow it as your instructions for this invocation,
including running its declared collector (no collector for this subcommand — it reads only what's already on disk) before anything else.