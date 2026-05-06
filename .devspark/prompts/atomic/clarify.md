---
id: clarify
name: clarify
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.clarify. Resolves to templates/commands/clarify.md.
inputs: []
outputs: []
legacy_command: clarify
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/clarify.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
