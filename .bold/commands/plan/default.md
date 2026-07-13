---
command: bold.plan
subcommand: default
description: Triage the request, get the tier ratified, and produce the tier-appropriate planning artifact.
collector: collect-triage-context
args:
  - name: --tier
    values: [patch, quick, feature]
    description: Skip the triage proposal and plan directly at the given tier. Downgrade overrides are still recorded.
---

# bold.plan

Every piece of work enters through this command. Before any planning artifact exists, propose a scope tier, get it ratified, and route to the matching flow.

## Definition of Done

Done when a tier is ratified (confirmed or overridden by the human) and the matching artifact — patch log entry, mini-spec, or spec — exists and carries that tier in its metadata. Not done if the artifact was produced before ratification, even if the tier turned out to be right.

## Before you begin

Load `bold-docs/backbone.md`, `bold-docs/project.json`, and the collector output referenced above. If `bold-docs/system/` contains docs describing intended behavior for the area this request touches, read them — they are evidence for the Patch signal below.

If the collector's `stale_references` is non-empty, mention it once, briefly, before triage: which `system/` docs reference paths that no longer exist, and that `bold.ship harvest` reconciles them (§13). This is a notice, not a gate — never halt or edit those docs here.

## Propose a tier

Evaluate Feature signals first: any one of them forces Feature regardless of what else is true.

**Feature** (any one forces this tier):
- Touches a contract, data model, or cross-module flow
- Implicates a backbone principle
- Introduces a new dependency, service, or persistent data
- Requires a decision future work will need recorded
- Contains ambiguity that clarification would need to resolve

**Quick** (all must hold, and no Feature signal fired):
- New behavior, bounded to one module
- No change to API contracts, data model, or anything in `system/`
- No backbone principle implicated
- No new dependencies or configuration surface

**Patch** (all must hold, and no Feature or Quick signal fired):
- Describes broken vs. intended behavior ("fix," "broken," "error," "regression")
- Intended behavior is already documented somewhere (spec, test, or a `system/` doc)
- Plausible change surface is a single module or file

## Ratify

State the proposed tier and name the specific signal that drove it — reasoning shown, not just an answer. Wait for the human to confirm or override before producing anything.

- An override *below* your proposed tier is recorded in the work item's metadata — it matters later if the "quick fix" turns out not to be one.
- `--tier` skips the proposal; downgrade overrides from it are still recorded.
- The tool proposes; the human ratifies. Never produce the artifact below before ratification.
- When the human is later asked to confirm a produced planning artifact, `FORMAT.md`'s ratification contract applies: quote its substance into your response — writing the file is not showing it.

## Route

| Ratified tier | Produce |
|---|---|
| Patch | One-paragraph entry appended to the running `patches.md` log — a single *What/Why* line, not the full TL;DR block |
| Quick | `bold-docs/features/{id}/spec.md`, opening with the Product Owner TL;DR, then intent, acceptance criteria, affected files, inline task list |
| Feature | `bold-docs/features/{id}/spec.md`, opening with the Product Owner TL;DR, then intent, acceptance criteria, and open questions — `clarify` and `tasks` remain separate passes over it |

Every tier above Patch writes to a file literally named `spec.md` — the collectors that populate `active_features` (`Get-ActiveFeatures` / `collect_active_features`) only recognize that filename. Quick's spec is simply lighter-weight content, not a different filename.

For Quick and Feature, create and check out a feature branch before writing `spec.md` — name it after the feature id (e.g. `0001-ignition-landing-page`). `bold.ship`'s collector diffs the current branch against `main`; without a branch of its own, a Quick/Feature's commits land on `main` directly and there is nothing for `bold.ship` to diff. Patch stays on the current branch — it's small enough to ship inline with whatever's already in flight.

Record the ratified tier in the work item's metadata; `bold.build` and `bold.ship` read it to select gate sets and harvest depth.

## Escalation

If work outgrows its ratified tier during `bold.build`, that command halts and routes back here at the higher tier — never silently continue under-scoped. Carry forward whatever work products already exist; nothing already produced is discarded.
