---
id: list-applications
name: list-applications
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.list-applications. Resolves to templates/commands/list-applications.md.
inputs: []
outputs: []
legacy_command: list-applications
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/list-applications.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
