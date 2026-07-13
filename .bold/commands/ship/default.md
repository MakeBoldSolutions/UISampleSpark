---
command: bold.ship
subcommand: default
description: Draft a PR (or finalize the deliverable, for non-code domains) for the active feature.
collector: collect-ship-context
args:
  - name: --draft
    description: Open as a draft PR regardless of readiness.
---

# bold.ship

This command is advisory, not a gate. A dirty working tree, an unresolved `bold.plan checklist` item, or an open waiver is something to surface and explain — never a hard block. The human decides whether to ship anyway, fix first, or stop. (Exception: this doesn't override `bold.build`'s own gates — see Boundary below.)

## Definition of Done

Done when the human has explicitly chosen create, update, adjust, or stop — and, for create/update, the PR actually reflects the confirmed draft. Drafting a body and never asking, or acting before confirmation, is not done.

## Before you begin

Read the collector output. If `has_uncommitted_changes` is true, say so as a warning, not a refusal — `bold.ship` drafts from committed history, so an uncommitted change simply won't be in the PR yet.

## Draft

Open the PR body with the Product Owner TL;DR (per §8) — a PR is a generated artifact like any other. Then:

- **Summary** — the TL;DR's *What*, expanded to a paragraph if needed
- **Changes** — from `changed_files` and `commits_ahead`; scope to what actually changed, don't re-describe the whole feature if this is the third PR against it
- **Task completion** — N/M tasks done
- **Quality gates** — `bold.plan checklist`/`analyze`/`critic` status, or "no gate artifacts found" if the tier didn't require them
- **Waivers** — every entry in `active_features[].waivers`, plainly stated (a waiver is a visible tradeoff, not a way to make a gate quietly disappear) — omit the section if there are none
- **Reference** — path to the feature's spec

For non-code domains, "draft a PR" means finalize the deliverable document instead — same content bar (what changed, why, what's still open), different container.

## Confirm before acting

Show the drafted title and body and ask explicitly: create, update the existing PR, adjust the draft, or stop. Don't open or update anything until the human confirms.

## Boundary

This step packages what's already been built. It doesn't re-run `bold.build`'s gates itself — if `bold.build` hasn't been run at all, route back to it rather than shipping ungated work.
