---
id: upgrade
name: upgrade
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.upgrade. Resolves to templates/commands/upgrade.md.
inputs: []
outputs: []
legacy_command: upgrade
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/upgrade.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
