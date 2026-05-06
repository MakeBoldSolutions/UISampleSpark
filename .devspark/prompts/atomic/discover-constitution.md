---
id: discover-constitution
name: discover-constitution
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.discover-constitution. Resolves to templates/commands/discover-constitution.md.
inputs: []
outputs: []
legacy_command: discover-constitution
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/discover-constitution.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
