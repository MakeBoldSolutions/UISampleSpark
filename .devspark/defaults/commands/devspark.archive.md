---
description: Deprecated alias for /devspark.harvest — redirects to the canonical cleanup workflow
handoffs:
  - label: Review Release Artifacts
    agent: devspark.release
    prompt: Review completed specs and release documentation before archival
  - label: Run Documentation Audit
    agent: devspark.site-audit
    prompt: Audit documentation quality and stale references before harvest
---

## User Input

```text
$ARGUMENTS
```

## Deprecation Notice

`/devspark.archive` is deprecated. Use `/devspark.harvest` instead.

Mention this once to the user, then follow the `/devspark.harvest` workflow exactly — same steps, same outputs, same confirmation gates. All arguments passed here are forwarded to harvest unchanged.
