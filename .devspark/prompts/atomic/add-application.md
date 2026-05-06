---
id: add-application
name: add-application
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.add-application. Resolves to templates/commands/add-application.md.
inputs: []
outputs: []
legacy_command: add-application
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/add-application.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
