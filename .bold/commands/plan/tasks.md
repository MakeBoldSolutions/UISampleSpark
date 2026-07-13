---
command: bold.plan
subcommand: tasks
description: Regenerate the task breakdown for the active feature's ratified spec, or merge in gate remediation on a re-run.
collector: none
args: []
---

# bold.plan tasks

No collector: the task breakdown derives entirely from the feature's own ratified spec (and, on a re-run, its `gates/` reports) — nothing outside those should influence the list.

## Definition of Done

First run: done when every Acceptance Criterion traces to at least one task, and every task traces back to a criterion — no orphans in either direction. Re-run: done when every selected gate finding has a matching remediation task appended, and nothing earlier in the file was touched.

## Before you begin

Load the active feature's `spec.md`. Refuse to proceed if Acceptance Criteria or Open Questions are still unresolved — regenerate after `clarify`, not instead of it.

## Mode detection

If the spec has no task list yet, generate (below). If it already has one, this is a re-run: go straight to gate remediation and stop there — don't regenerate from scratch.

## Generate (first run)

One task per unit of work that a single `bold.build` pass could complete and verify. Each task should trace to a specific Acceptance Criterion — if a task doesn't map to one, either the task is unnecessary or the spec is missing a criterion. Raise that, don't silently add scope.

Format every task identically so `bold.build` can parse and mark them mechanically:

```
- [ ] T001 [P?] Description with an exact file path
```

`T001` is a sequential ID. `[P]` marks it parallelizable (different files, no dependency on an incomplete task) — omit it otherwise. Order the list so gate-relevant work (anything a backbone principle touches) isn't left until last.

## Gate remediation merge (re-run only)

If `gates/critic.md` and/or `gates/analyze.md` exist with open findings, merge them into new tasks rather than asking the human to translate reports into work by hand:

1. Take only `open` findings; dedupe ones citing the same location.
2. Sort blockers before notes.
3. For each selected finding, append a task: `- [ ] T0NN [P?] Fix <one-line description> in <file path> (resolves: <finding-ref>)`.
4. Don't touch already-checked tasks or earlier sections.
5. Recommend `bold.build`, then re-running `bold.plan critic`/`analyze` afterward to confirm the finding actually cleared.

## Output

An inline task list in the spec's task section.
