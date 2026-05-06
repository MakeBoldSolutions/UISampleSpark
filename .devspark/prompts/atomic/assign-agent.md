---
id: assign-agent
name: assign-agent
audience: intermediate
exposed: true
category: improvement
description: Assign the filed improvement issue to a coding agent so it can begin work.
inputs:
  - proposal.issue_url
outputs:
  - proposal.assigned_agent
---

## Outline

Optional follow-up step gated by `context.assign_agent == true`. Tags the
freshly created issue with the appropriate agent assignment so an automated
worker (or coding agent like GitHub Copilot) can pick it up.

## Steps

1. Verify `proposal.issue_url` is populated; abort the step (do not abort
   the workflow) if not.
2. Apply the configured `assignee` — by default the GitHub username stored
   in the user's git config — using `gh issue edit <url> --add-assignee
   <user>`.
3. Record `proposal.assigned_agent`.

## When

This step only runs when the workflow context contains
`context.assign_agent == true`.

## Output

```yaml
proposal:
  assigned_agent: <github-handle>
```
