# {Repo Name} — DevSpark → Bold Migration Report

> **TL;DR for the Product Owner**
> *What*: {one or two sentences — what this repo is, and the scale of what's converting: constitution principle count, shipped/in-flight feature count, legacy per-host file count, anything unusual the inventory turned up}
> *Why*: {why this repo, why now — e.g. "crucible Track 1, repo {n} of ~30" or "requested migration ahead of a new feature"}
> *Status*: Draft — awaiting your ratification. Nothing in {repo} has been touched yet.
> *Decision needed*: Confirm the mapping below{, especially the items flagged "needs your call" if any}.

## Inventory (via `collect-devspark-inventory`, cross-checked by hand)

| Artifact | Found |
|---|---|
| `.devspark/` | {file count, version, install method/date if known} |
| `.documentation/memory/constitution.md` | {principle count, MANDATORY vs. non-MANDATORY split, any extra sections like "Additional Standards" or "Implementation Gaps"} |
| `.documentation/scripts/` (team overrides) | {file count, bash/PowerShell/both; wired vs. orphaned split from the collector's `team_scripts` — a script is wired only if `resolves_against_bold` is true, i.e. three-tier resolution would actually serve it} |
| `.documentation/specs/*` | {one row per spec dir — status: Complete / In-flight, what artifacts it has} |
| `devspark.json` (multi-app) | {found or not found — single-app vs. multi-app} |
| Waivers / Gate Acknowledgements | {found or none} |
| Stack (discovered, not from any config file) | {language/framework/build-tool/monorepo evidence actually observed} |

**Found beyond the standard mapping table** (list only if the catch-all inventory or manual cross-check turned up more than the named fields above — real repos usually have accumulated more than a clean install):

| Artifact | What it is |
|---|---|
| {e.g. `.claude/commands/devspark.*.md` (N files)} | {legacy per-host adapter format, superseded by which Bold adapter} |
| {e.g. `.claude/settings.local.json` / `.vscode/settings.json`} | {mixed file — some entries DevSpark-specific, some genuinely project-useful; call out the split, don't assume} |
| {e.g. pre-existing root `.archive/`} | {describe what's there and whether its policy already resembles Bold's} |
| {any generic `.documentation/` catch-all entry the collector couldn't classify} | {name it — durable candidate or historical, and why} |

## Proposed mapping

| DevSpark artifact | Bold equivalent | Action |
|---|---|---|
| `.devspark/` | `.bold/` (installed via manifest) | Delete — **last step**, after everything else is verified |
| `.documentation/memory/constitution.md` | `bold-docs/backbone.md` | Restate each principle tersely, `source: migrated(constitution.md)`, MANDATORY → `enforced` else `adopting`. Non-principle sections (e.g. "Implementation Gaps") → a `bold-docs/system/` doc, not the backbone |
| `.documentation/scripts/` | `bold-docs/overrides/` + generated `README.md` | Carry wired scripts as-is; every orphaned script (`resolves_against_bold: false` — nothing in Bold's command surface will ever call it) is an item needing a call below: carry flagged, or `.archive/`. The README lists every carried file with its wired/orphaned status — dead scripts must never sit indistinguishable from live overrides (issue #2). Flag missing bash/PowerShell parity as a maintainer note, not a blocker |
| `.documentation/specs/{name}/` (Complete) | Harvest-on-entry | Durable knowledge → `bold-docs/system/`; work products → `.archive/`; one `.archive/index.md` entry |
| `.documentation/specs/{name}/` (In-flight) | `bold-docs/features/{id}/` | Carry forward as an active feature, tier inferred from its existing artifacts |
| {any general `.documentation/*.md` reference doc, e.g. Guide/Architecture/Deployment} | `bold-docs/system/` | **Read it first.** Rewrite any "how to use the commands" section, directory diagram, or instruction naming `.devspark/`/`.documentation/`/`/devspark.*` to reflect Bold's current reality, or mark it explicitly superseded — relocating the file unedited is not a completed mapping |
| {legacy per-host adapter files, one row per host format found} | *(deleted)* | Superseded by Bold-generated adapters (only after Bold's own install step has produced the replacements) |
| `agents-registry.json` | *(deleted)* | Superseded by generated `AGENTS.md` + adapters |
| {pre-existing root `.archive/`, if found} | `.archive/` (Bold's, same location) | Adopt in place if its policy already matches; call out any wording to reconcile rather than silently overwriting |
| Stack evidence (discovered) | `bold-docs/project.json` | `core.*`/`layer.*` populated with `source: discovered` |
| {anything the sweep found that isn't a DevSpark artifact} | N/A | Untouched — name it so the report shows it was seen, not missed |

## Items needing your call before I execute anything

{List only genuine judgment calls — ambiguous ownership, mixed-content files, wording choices on adopted conventions. Omit this section if there are none. Number them; each should be answerable in one sentence.}

1. {}

## Acceptance bar (bold-tool-plan.md §10.4, verbatim)

*"After migration, the repo must be indistinguishable from one born on Bold — nothing in the finished repo carries legacy DevSpark naming or structure."* Re-run the collector's tracked-file text sweep after execution — list every hit outside `.archive/` here with a one-line reason it's fine (real, non-DevSpark project content, or a genuinely historical mention), not a bare "N hits, all legitimate" summary. A hit inside a `bold-docs/system/` doc needs the same individual check as anywhere else — being classified durable doesn't pre-clear its contents.

## Execution order once ratified (collect → reason → ratify → execute, destructive last)

1. Write `bold-docs/backbone.md`, `bold-docs/project.json`, seed `bold-docs/system/`
2. Harvest each completed spec: promote durable docs to `system/`, archive work products, one `.archive/index.md` entry per feature
3. Carry forward in-flight specs to `bold-docs/features/`
4. Carry `.documentation/scripts/` → `bold-docs/overrides/` per the ratified per-script disposition; write the `bold-docs/overrides/README.md` wired/orphaned listing
5. Install Bold proper (`.bold/`, generated adapters, `AGENTS.md`) — this produces the real adapter files that make step 6 safe
6. Delete the legacy per-host files and `agents-registry.json`
7. Verify: re-run the inventory collector's text sweep, confirm the acceptance bar
8. **Last**: delete `.devspark/`, `.documentation/`
