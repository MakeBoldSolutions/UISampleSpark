---
command: bold.plan
subcommand: checklist
description: Generate or verify a checklist that tests the quality of the spec's requirements, not the implementation.
collector: none
args:
  - name: --verify
    description: Check off items against the current spec/build state instead of generating a fresh checklist.
---

# bold.plan checklist

No collector: the checklist's source of truth is the active feature's own spec (and its starter, if one applies) — not repo-wide facts.

## Definition of Done

Generate: done when every item is numbered, categorized, and traces to a spec section or a `[Gap]`, and none of them test implementation behavior (see below). Verify: done when every existing item has been marked done, not done, or not applicable against current state — none left unjudged.

## Unit tests for English

A checklist item tests whether a **requirement is well-written** — complete, unambiguous, consistent, measurable — not whether the implementation works. If the spec is code written in English, this checklist is its test suite.

**Wrong** (tests the implementation):
- "Verify the button navigates to the home page"
- "Test that the API returns 200"
- "Confirm hover states work on desktop"

**Right** (tests the requirement):
- "Is the button's destination explicitly specified? [Completeness]"
- "Are error-response formats specified for every failure mode? [Completeness]"
- "Is 'fast' quantified with a specific latency target? [Clarity]"
- "Are hover-state requirements defined consistently across every interactive element? [Consistency]"

If an item would start with "Verify," "Test," "Confirm," or "Check" followed by a behavior — or names a click, render, load, or execute — it's testing the wrong thing. Rewrite it as a question about whether the requirement exists and is precise enough to act on.

## Generate (default)

If the feature has a starter (`project.json`'s `composition.starter`), pull its checklist template for domain-relevant categories; otherwise derive categories directly from the spec. Either way, every item falls under one of:

- **Completeness** — is a necessary requirement documented at all?
- **Clarity** — is a vague term ("robust," "prominent," "fast") quantified?
- **Consistency** — do related requirements agree with each other?
- **Measurability** — can this requirement be objectively verified once built?
- **Coverage** — are edge cases and non-functional attributes (performance, security, accessibility) addressed, where relevant to this deliverable's domain?

Number items sequentially (`CHK001`, `CHK002`, ...) and cite the spec section each checks, or mark `[Gap]` when checking for something the spec doesn't have at all. Open the checklist file with a one-line Product Owner TL;DR (per §8) — what it's checking and why — the same as any other generated artifact, just shorter.

## Verify (`--verify`)

Check each item against the spec: done, not done, or not applicable. Don't mark an item done on inference — only when the spec text demonstrably satisfies it.

## Output

The checklist lives alongside the feature's spec. Unchecked items are visible in the `bold.ship` PR body, not hidden.
