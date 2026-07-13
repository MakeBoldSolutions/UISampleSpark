---
command: bold.build
subcommand: status
description: Report task/gate/artifact status for the active feature.
collector: collect-gate-status
args: []
---

# bold.build status

Reuses `collect-gate-status` — this subcommand reports the same facts `bold.build` (default) uses to decide gates, formatted as a status report instead of acted on.

## Definition of Done

Done when all four report fields (tier, gates, backbone, repo state) are stated from the collector's current output — not when something changed, since nothing here should change anything.

## Report

For the active feature, state:
- **Tier** — the ratified tier from `active_features`, and whether it still looks right given what's been built so far
- **Gates** — which apply at this tier, and which have and haven't been satisfied yet
- **Backbone** — any `enforced` principle violations (blocking) or `adopting` flags (non-blocking) found in `backbone_principles`
- **Repo state** — `has_uncommitted_changes`, and whether test config was detected in `test_config_present`. A build claiming "tests pass" with no detected test config is itself worth flagging

## Boundary

This is a read-only report. Never modify the build, gates, or spec from `status` — that's `bold.build` (default)'s job.
