---
id: specify
name: specify
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.specify. Resolves to templates/commands/specify.md.
inputs: []
outputs: []
legacy_command: specify
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/specify.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
