---
command: bold.plan
subcommand: discover
description: Read-only brownfield archaeology — mine configs and history, infer conventions, play back findings for ratification.
collector: collect-brownfield-signals
args: []
---

# bold.plan discover

Read-only archaeology, then playback. Nothing here writes to the repo until the human ratifies in the final step.

## Definition of Done

Done when every candidate principle has been ratified, marked `adopting`, or dropped by the human — not merely proposed — and `project.json` reflects the discovered answers plus whatever the residual questionnaire resolved.

## Mine

1. **Config mining** — every config file the collector found (linters, CI workflows, test config, editorconfig, Dockerfiles, dependency manifests) is a codified decision someone already made. Translate each into a candidate backbone principle with `source: discovered(<path>)`.
2. **Convention inference** — sample code for naming, structure, error-handling, and logging patterns. Only state a rule where the sample is actually consistent; note where it isn't.
3. **History signals** — cite existing `CONTRIBUTING.md`, PR templates, and commit conventions rather than restating them as new principles.

## Play back

Open with the Product Owner TL;DR (per §8) — this playback is a generated artifact like any other, and it's the one a non-technical stakeholder is most likely to actually read. The playback is ratified content: per `FORMAT.md`'s ratification contract, its full text goes into your response — never a file on disk plus a summary. Then present findings as counted evidence: "N practices consistently followed (proposed); M inconsistent." The inconsistent ones are the highest-value output — they're conversations the team never had. For each candidate principle: ratify as `enforced`, mark `adopting` (new code complies, legacy grandfathered), or drop.

## Write

Discovered answers go into `project.json` with `source: discovered`. Whatever the mining pass didn't cover becomes a short residual questionnaire, same shape as greenfield's.
