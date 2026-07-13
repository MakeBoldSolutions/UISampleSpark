# Waiver Format

How a deliberate, ratified exception to an `enforced` backbone principle gets recorded. Read this before writing or parsing a waiver.

## Where it lives

Waivers are recorded in the work item's own artifact — the feature's `spec.md` (or the mini-spec / patch log entry for lower tiers) — under a `## Waivers` heading. They travel with the work, not in a separate ledger, so they're visible wherever the feature is visible.

## Format

One line per waiver, under `## Waivers`:

```
- Waiver: principle=<N> reason="<why the exception is acceptable>" ratified_by="<human name or role>" date=<YYYY-MM-DD>
```

- `principle` — the backbone principle's number (matches its position in `backbone.md`'s `## Principles` list)
- `reason` — why the violation is accepted, not what was violated (the principle number already says that)
- `ratified_by` — a human accepted this; the tool never waives on its own (backbone principle: the tool proposes, the human ratifies)
- `date` — when it was ratified

## Who writes and reads it

- `bold.plan critic` and `bold.build` (default) write a waiver when a human accepts a flagged risk instead of fixing it.
- `bold.ship` (default) surfaces every open waiver in the PR body — a waiver is a visible tradeoff, not a way to make a gate quietly disappear.
- Collectors parse `- Waiver: ...` lines from each feature's `spec.md` into `active_features[].waivers` (see `source/scripts/{bash,powershell}/lib/`).
