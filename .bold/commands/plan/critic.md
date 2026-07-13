---
command: bold.plan
subcommand: critic
description: Adversarial risk critique of the active feature's spec — what will fail in production, gated at Feature tier.
collector: collect-triage-context
args:
  - name: --strict
    description: Apply the full taxonomy even at tiers that don't require it by default.
---

# bold.plan critic

Full gate pre-flight for Feature-tier work (§6, §7). Quick and Patch don't run this by default; `--strict` forces it regardless of tier.

**Mindset**: adversarial, not neutral. Assume the team has limited experience with this stack, estimates are optimistic, and edge cases are underspecified. If it can fail, assume it will.

## Definition of Done

Done when the report is saved to `gates/critic.md` and every applicable risk category has either produced a finding or been explicitly marked inapplicable — never silently skipped. A clean report ("no findings") is only done if every category was actually evaluated against the spec, not assumed fine.

## Not `bold.plan analyze`

Critic and analyze are deliberately non-overlapping gates:

| | `bold.plan analyze` | `bold.plan critic` |
|---|---|---|
| Question | Are the artifacts internally consistent? | What will fail in production? |
| Mindset | Neutral validator | Adversarial skeptic |
| Owns | Duplication, wording ambiguity, requirement↔task coverage | Achievability of stated targets, missing operational tasks, failure modes |

A finding that fits analyze's lane (the spec contradicts itself) doesn't also get raised here — cross-reference it instead of duplicating.

## What this is NOT

Findings are hypotheses, not proven defects. This doesn't replace SAST, DAST, dependency scanning, code review, or real testing. A clean critic report means "no obvious traps in the spec," not "the system is safe."

## Risk categories

Evaluate the spec against whichever of these actually apply to the deliverable's domain — skip a category only when it's genuinely inapplicable (a chart-of-accounts spec has no concurrency category), and say so rather than silently omitting it:

- **Trust boundaries / auth** — privileged operations without enforced boundaries, ambient authority, missing isolation
- **Secrets handling** — hardcoded secrets, no rotation, secrets reaching logs
- **Data loss / continuity** — no backup/restore, destructive ops without confirmation, missing transactional boundaries
- **Input validation** — untrusted input crossing a trust boundary unvalidated, injection vectors
- **Error handling / resilience** — swallowed errors, non-idempotent retries, missing timeouts
- **Concurrency** — race conditions, resource leaks, deadlocks (where the deliverable has any concurrent execution)
- **Scale bottlenecks** — unbounded result sets, N+1 access patterns, no path to horizontal scaling
- **Observability** — can a failure in the new behavior actually be detected in production?
- **Deployment / rollback** — no safe-release strategy, no migration plan, no rollback procedure
- **Dependency supply chain** — unpinned versions, abandoned packages, unreviewed transitive risk
- **Backward compatibility** — breaking changes to a contract other work depends on
- **Regulatory / privacy** — PII handling, retention, audit logging, where applicable

## Severity

Every backbone-principle violation is automatically a **blocker** (matches the backbone's `enforced` status — see `bold-docs/backbone.md`). Beyond that, a finding is a blocker if it threatens data loss, a security breach, or a production outage; otherwise it's a note.

## Report

Open with the Product Owner TL;DR (per §8 — critique output is a generated artifact like any other). Then one finding per category that has a real risk — not one per category regardless. Each finding states the risk, the spec section it traces to, and whether it's a blocker (must be addressed before `bold.build`) or a note (acceptable with acknowledgement). The human ratifies: fix the spec, accept the risk as a `- Waiver: ...` line under the spec's `## Waivers` heading (format: `source/commands/WAIVERS.md`), or escalate.

Save the report to the feature's own `gates/critic.md`, replacing the prior run rather than appending — `bold.plan tasks` reads it to generate remediation tasks, and a stale duplicate would confuse that merge.
