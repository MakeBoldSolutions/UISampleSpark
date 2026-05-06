---
id: commit-audit
name: commit-audit
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.commit-audit. Resolves to templates/commands/commit-audit.md.
inputs: []
outputs: []
legacy_command: commit-audit
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/commit-audit.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
