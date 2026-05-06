---
id: create-pr
name: create-pr
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.create-pr. Resolves to templates/commands/create-pr.md.
inputs: []
outputs: []
legacy_command: create-pr
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/create-pr.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
