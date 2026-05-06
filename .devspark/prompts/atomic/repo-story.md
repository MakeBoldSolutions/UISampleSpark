---
id: repo-story
name: repo-story
audience: expert
exposed: false
category: legacy-command
description: Atomic shim for /devspark.repo-story. Resolves to templates/commands/repo-story.md.
inputs: []
outputs: []
legacy_command: repo-story
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at `templates/commands/repo-story.md`.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
