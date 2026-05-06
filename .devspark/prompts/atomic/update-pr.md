---
id: update-pr
name: update-pr
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.update-pr. Resolves to templates/commands/update-pr.md.
inputs: []
outputs: []
legacy_command: update-pr
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/update-pr.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
