---
command: bold.ship
subcommand: harvest
description: Classify feature artifacts — promote durable knowledge, archive work products, reconcile stale docs.
collector: collect-harvest-inventory
args: []
---

# bold.ship harvest

## Definition of Done

Done when every file in every feature under `active_features` has been classified, every promotion and archival that classification implied has actually happened, and `.archive/index.md` has a new entry for this pass. A classification with no corresponding move isn't done, it's an opinion.

## Classify

For each feature in `active_features`, walk its files (from `feature_files`) and classify each as:
- **Durable knowledge** — contracts, decisions, rationale that the next feature's planning would need
- **Work product** — task lists, resolved critiques, clarification Q&As, superseded revisions

The test: *would an agent planning the next feature need this, or would it mislead them?*

Present the full classification — every file, its class, its destination — in your response for ratification before moving anything, per `FORMAT.md`'s ratification contract.

## Promote

Durable knowledge moves into `bold-docs/system/` (check `system_docs` first — merge into an existing doc rather than creating a near-duplicate). Every promoted `system/` doc opens with a Product Owner TL;DR (per §8), rewritten to describe the current system rather than the change that created it — carry the original TL;DR forward and re-date it, don't leave it stale. Candidate backbone principles go to the human for ratification, not straight into `backbone.md`.

## Archive

Work products move wholesale to `.archive/` (root-level, not under `bold-docs/`). Append one row to `.archive/index.md`'s existing table (`Date | Feature | Archived | Promoted to system/`) — add a row, don't restructure it.

## Reconcile

Check whether this feature's completion invalidates anything already in `system_docs` — if so, flag those docs for archival too rather than leaving them stale alongside the new truth.

## Boundary

This is the *only* command that ever writes to `.archive/` — writing is a deliberate, human-ratified act, not incidental. No command, including this one on a future run, ever reads `.archive/` back into context: it is committed history for human consumption only, with no exception for an explicit human pointer. Nothing should be written expecting a future prompt to see it again.
