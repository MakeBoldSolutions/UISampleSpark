---
command: bold.ship
subcommand: review
description: Review pass over the active feature's changes before or after a PR is opened.
collector: collect-ship-context
args: []
---

# bold.ship review

Reuses `collect-ship-context` — review reads the same changed-file and backbone facts `bold.ship` (default) used to draft, and checks them rather than packaging them.

## Definition of Done

Done when the branch-sync gate has passed and every file at the highest blast-radius tier has been checked, with a finding reported for each real issue found (or none, if there aren't any). Stopping before the highest tier is fully covered isn't done, regardless of budget spent elsewhere.

## Branch sync (hard gate)

If `commits_behind` is greater than 0, stop before reviewing anything: "Blocked — this branch is `N` commits behind `base_branch`; sync it first." A review against a stale base is reviewing the wrong diff. This is the one rule in this command that isn't advisory.

## Scrutiny scales with what's missing

If the work has no ratified tier (nothing in `active_features` for it) or no spec at all, apply heightened scrutiny and say so plainly: an unratified change means requirements and acceptance criteria were never formally stated, so findings here may be undercounting real issues.

## Prioritize by blast radius

Triage `changed_files` before reviewing, and spend attention accordingly rather than reviewing every file at the same depth:

| Tier | What | Depth |
|---|---|---|
| Highest | Auth, trust boundaries, data writes, anything a backbone principle touches | Full read, line by line |
| Middle | Business logic, data transformations | Read for correctness |
| Lowest | Tests, config, docs, formatting-only changes | Spot-check |

Always cover the highest tier fully, even if that means spending the whole review budget there.

## Review

For each file, check it against:
- The active feature's spec (Acceptance Criteria it should satisfy)
- `backbone_principles` — any `enforced` principle the change touches
- Anything `bold.plan critic` already flagged as a blocker

## Re-reviews

If this is a re-review of the same feature, diff only what changed since the last review rather than re-reviewing everything: carry forward unresolved findings unchanged, mark previously-flagged ones resolved/still-present based on the new diff, and append only genuinely new findings.

## Report

Open with the Product Owner TL;DR (per §8 — a review report is a generated artifact like any other, same as `bold.plan critic`/`analyze`). Then one finding per real issue — a criterion not met, a backbone violation, an unaddressed critic blocker. Don't restate what's already correct. Each finding names the file and the specific criterion or principle it fails. Stop once you have high-confidence findings for the highest-blast-radius files rather than exhaustively re-deriving what's already clear.

## Boundary

Review reports; it doesn't fix. Findings route to `bold.ship address` (or back to `bold.build` if the fix is substantial) rather than being edited in place here.
