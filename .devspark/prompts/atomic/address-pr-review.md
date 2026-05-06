---
id: address-pr-review
name: address-pr-review
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.address-pr-review. Resolves to templates/commands/address-pr-review.md.
inputs: []
outputs: []
legacy_command: address-pr-review
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/address-pr-review.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
