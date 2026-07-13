---
command: bold.plan
subcommand: clarify
description: Re-run the clarification pass on the active feature's spec.
collector: none
args: []
---

# bold.plan clarify

No collector: the only input this needs is the feature's own spec, already on disk — reaching for repo-wide facts here would be scope creep.

## Definition of Done

Done when the question queue is exhausted — five asked, full coverage reached, or the human signals they're done — and every accepted answer is already folded into the spec, not just recorded in chat. A session that asks zero questions because coverage was already Clear is done just as validly as one that asks five.

## Before you begin

Load the active feature's `spec.md` and `bold-docs/backbone.md`.

## Scan for ambiguity

Ambiguity is exactly what forced Feature tier in the first place (triage signal: "contains ambiguity that clarification would need to resolve"). Scan the spec against these categories — for each, judge Clear / Partial / Missing, and only Partial/Missing categories become candidate questions:

- **Scope & behavior** — core goals, explicit out-of-scope declarations
- **Data model** — entities, relationships, lifecycle/state transitions
- **Interaction & edge cases** — critical flows, error/empty states, conflict resolution
- **Non-functional attributes** — performance, security, observability — as measurable targets, not adjectives
- **Integration** — external dependencies and their failure modes
- **Constraints & tradeoffs** — technical constraints, explicitly rejected alternatives
- **Acceptance criteria testability** — can this actually be verified as written?

Don't raise a question just because a category is imperfect — raise it only if the answer would materially change the spec, tasks, or acceptance criteria. A stylistic gap or a plan-level execution detail isn't worth a question here.

## Ask, one at a time

Cap at 5 questions. For each: propose your own best answer first (`**Recommended:** ... — <one-sentence reasoning>`), then ask — the human can accept it with "yes" or override it. This is faster than an open question and still leaves the human in control. Never reveal queued questions in advance; stop early if remaining ambiguity is resolved or the human signals they're done.

## Update after each answer, not at the end

Fold each ratified answer into the spec immediately (not batched at the end) — promote it into Acceptance Criteria or Intent, in the section it actually belongs to. If it invalidates something already written, replace that text rather than leaving both versions in the file. Leave unresolved categories open rather than inventing an answer. The tool proposes; the human ratifies.
