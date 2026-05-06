---
id: create-issue
name: create-issue
audience: intermediate
exposed: true
category: improvement
description: File the proposed improvement as a GitHub issue in markhazleton/devspark via the typed gh adapter.
inputs:
  - proposal.title
  - proposal.classification
  - proposal.context
  - proposal.current_behavior
  - proposal.expected_behavior
  - proposal.suggested_fix
outputs:
  - proposal.issue_url
---

## Outline

Invoke the issue adapter (`src/devspark_cli/issues.py::file_issue`) to create
a new issue in `markhazleton/devspark`. The adapter constructs the payload
as a Python dict and pipes JSON to `gh api` via stdin — model-generated
content is never passed through argv.

## Steps

1. Display the resolved repo, title, classification, and labels for
   confirmation. In non-interactive mode without `--yes`, abort with
   `EXIT_AUTONOMY_REQUIRED` (20).
2. Call `file_issue(proposal, assume_yes=<--yes>, non_interactive=<--non-interactive>)`.
3. Surface the returned URL as `proposal.issue_url` and emit a `completed`
   telemetry event.

## Failure exit codes

| Condition | Exit code |
|-----------|-----------|
| `gh` not installed | 10 (`EXIT_GH_UNAVAILABLE`) |
| `gh` not authenticated | 11 (`EXIT_GH_UNAUTHENTICATED`) |
| GitHub API error | 12 (`EXIT_GH_API`) |
| Network unreachable | 13 (`EXIT_GH_NETWORK`) |
| User declined / non-interactive | 20 (`EXIT_AUTONOMY_REQUIRED`) |

## Output

```yaml
proposal:
  issue_url: https://github.com/markhazleton/devspark/issues/<n>
```
