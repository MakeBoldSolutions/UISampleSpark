---
id: personalize
name: personalize
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.personalize. Resolves to templates/commands/personalize.md.
inputs: []
outputs: []
legacy_command: personalize
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/personalize.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
