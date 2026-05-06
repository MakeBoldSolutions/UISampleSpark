---
id: validate-registry
name: validate-registry
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.validate-registry. Resolves to templates/commands/validate-registry.md.
inputs: []
outputs: []
legacy_command: validate-registry
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/validate-registry.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
