---
id: plan
name: plan
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.plan. Resolves to templates/commands/plan.md.
inputs: []
outputs: []
legacy_command: plan
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/plan.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
