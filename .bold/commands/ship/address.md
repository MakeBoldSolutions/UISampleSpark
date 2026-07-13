---
command: bold.ship
subcommand: address
description: Respond to review findings on the active feature's open PR.
collector: collect-pr-review-context
args: []
---

# bold.ship address

## Definition of Done

Done when every selected comment is either resolved in its own commit or explicitly deferred with a stated reason, and the two commit-isolation rules held for every resolution — no shared file paths between a fix commit and its tracking-update commit.

## Before you begin

Read the collector output. If `gh_available` is false or `pr_number` is null, there's no PR to address yet — ask the human to paste the feedback directly rather than guessing at it.

## Address

For each entry in `review_comments`, either:
- Make the change it asks for, and note which comment it resolves, or
- Explain why it isn't being addressed (out of scope, disagreement, needs a decision) and let the human ratify that response before it's posted

Don't silently address a comment out of order if a later one depends on it — resolve in the order that keeps intermediate states coherent.

## Commit isolation (mandatory)

Code fixes and the record of what was fixed are two different kinds of change — commit them separately:

1. Stage and commit only the code paths touched by the fixes. Never a broad `git add .`.
2. Separately, update whatever tracks the review (the PR description, a review note in the spec) to mark resolved comments — and commit that on its own.
3. The two commits must not share a single file path. If a fix and its own tracking update land in the same commit, a future re-review can't tell which commit actually changed behavior versus which just recorded that it did.

## Boundary

This subcommand responds to feedback already given. It doesn't re-review the whole diff — that's `bold.ship review`'s job.
