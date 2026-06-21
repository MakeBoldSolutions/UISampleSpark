# Harness Strict Template

Use this template when you want delivery-integrity defaults that fail fast on missing implementation evidence.

## Defaults

- Execution mode: act
- Hands-off capable: yes (requires write-capable non-interactive adapter)
- Delivery evidence: at least one changed file under src/ or test/
- Create-pr gate: blocked when delivery status is unmet
- Re-validation loop: analyze and critic, maximum 3 passes

## Recommended CLI Invocation

```bash
devspark harness run sample.harness.yaml --hands-off --adapter claude_code
```

## Expected Artifacts

- adapter-doctor.json
- decision-packet.json
- no-change-explainer.md (only when delivery status is unmet)
- max-pass-failure-report.md (only when convergence max pass is reached)
