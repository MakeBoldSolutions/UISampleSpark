---
command: bold.build
subcommand: default
description: Apply the ratified tier's gate set, execute, then keep artifacts continuously in sync.
collector: collect-gate-status
args:
  - name: --strict
    description: Apply the full Feature-tier gate set even at Patch or Quick.
---

# bold.build

## Definition of Done

Done when every task is `[X]`, the spec's `**Status**` reflects that (`In Progress` or `Complete`), and the ratified tier's gate set has passed — or every gap it didn't clear has a recorded waiver. A build that stops with tasks still `[ ]` and no halt/escalation reported isn't done, it's abandoned.

## Before you begin

Read the collector output. Find the active feature's ratified tier in `active_features`. If none is ratified, halt and route to `bold.plan` — build never guesses a tier.

## Apply the tier's gate set

| Tier | Gate |
|---|---|
| Patch | Tests must pass |
| Quick | Backbone check only |
| Feature | Full pre-flight: `bold.plan analyze`, `bold.plan critic`, `bold.plan checklist`, and coverage of every `enforced` backbone principle |

`--strict` applies the Feature gate set regardless of ratified tier.

Check `backbone_principles` from the collector: an `enforced` principle blocks the build on violation; an `adopting` principle flags but doesn't halt — new code must comply, legacy is grandfathered.

## Execute

Implement the ratified spec, mini-spec, or patch entry — the task list's IDs and `[P]` markers already carry the ordering and parallelism, so follow those rather than re-deriving an order. Keep `bold-docs/system/` in sync as you go — sync is continuous, not a step tacked on at the end:

If the collector's `stale_references` is non-empty, note it once at a checkpoint: which `system/` docs reference paths that no longer exist. Surface it, don't fix it here — that's `bold.ship harvest`'s job (§13), and this build may be the very change that made the reference stale.

- Mark each task `[X]` the moment it's done — never batch checkbox updates for later. A partially-done task stays `[ ]` with a short inline note, not half-checked.
- Flip the spec's `**Status**` the first time a task completes: `Draft` → `In Progress`. Flip it to `Complete` only once every task is `[X]`.
- If a task's completion resolves an open item in `gates/critic.md` or `gates/analyze.md`, mark that finding `resolved` in the gate file with a one-line outcome — this is what lets a re-run of `critic`/`analyze` converge instead of re-reporting the same thing.
- If implementation diverges from the spec (a different approach than what was written), update the spec inline rather than silently drifting from it.

## Report progress at checkpoints, not per task

In chat, report one line per phase/checkpoint, not one line per task — the task file itself carries full detail. Halt and report immediately if a non-parallel task fails; don't wait for a checkpoint to surface a failure.

## Escalate if the work outgrows its tier

If mid-build the change turns out to need more than its ratified tier allows — the "patch" is actually a data-model change — halt immediately. Report what you found and route back to `bold.plan` at the higher tier. Carry forward whatever work already exists; nothing already produced is discarded. Never silently continue under-scoped.

## Waivers

If an `enforced` principle is violated deliberately, add a `- Waiver: ...` line under the spec's `## Waivers` heading (format: `source/commands/WAIVERS.md`). Don't route around the gate silently.
