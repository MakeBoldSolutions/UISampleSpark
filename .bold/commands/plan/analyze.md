---
command: bold.plan
subcommand: analyze
description: Check the active feature's spec for internal consistency, duplication, ambiguity, and requirement/task coverage.
collector: collect-triage-context
args: []
---

# bold.plan analyze

Reuses the triage collector — the same system-doc inventory, backbone principle list, and genome that triage used to decide the tier are the ground truth to check the spec against.

## Definition of Done

Done when the report is saved to `gates/analyze.md` and every check below has actually been run against the current spec — not when a plausible-sounding set of findings has been produced. A report that says "no findings" after genuinely checking all six categories is done; one that skips a category isn't.

## Not `bold.plan critic`

Analyze and critic are deliberately non-overlapping gates: analyze is a **neutral validator** asking "are the artifacts aligned?"; critic is an **adversarial skeptic** asking "what will fail in production?" When a finding could land in either, prefer the one that owns it below and cross-reference rather than duplicate.

## Check

- **Duplication** — near-duplicate Acceptance Criteria; mark the lower-quality phrasing for consolidation, don't just flag both.
- **Ambiguity (wording only)** — vague adjectives ("fast," "secure," "robust") with no measurable criteria, unresolved placeholders (TODO, TBD, `<placeholder>`). Whether a stated target is *achievable* is critic's job, not this one's — this pass only checks whether it's worded precisely enough to act on.
- **Underspecification** — an Acceptance Criterion with a verb but no measurable outcome; a task (once `bold.plan tasks` has run) referencing a file or component the spec never defined.
- **Coverage gaps** — every Acceptance Criterion should trace to something in Intent, and (once tasks exist) to at least one task. Zero-coverage in either direction is a finding. Whether the spec is *missing* an entire category of task (observability, rollback) that nothing called for is critic's job, not this one's.
- **Backbone consistency** — does the spec implicate a principle (per the collector's `backbone_principles`) that it doesn't acknowledge, or conflict with one that's `enforced`?
- **System consistency** — does the spec assume behavior that a `system/` doc (per the collector's `system_docs`) already documents differently?

## Report

Open with the Product Owner TL;DR (per §8 — analysis output is a generated artifact like any other). Then list findings as a flat set: duplication, ambiguity, underspecification, coverage gap, or backbone/system conflict — each with the spec line and the conflicting source. No finding is auto-fixed; `analyze` reports, it doesn't edit. The human decides whether to fix the spec, update `system/`, or waive.

Save the report to the feature's own `gates/analyze.md`, replacing the prior run rather than appending — `bold.plan tasks` reads it to generate remediation tasks, and a stale duplicate would confuse that merge.
