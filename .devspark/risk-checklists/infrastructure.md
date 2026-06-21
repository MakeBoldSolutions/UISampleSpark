# Infrastructure-as-Code Risk Checklist

## Blast Radius

- [ ] **`plan` reviewed before `apply`** in CI; no auto-apply on protected envs
- [ ] **Destroy / replace operations gated** — explicit approval; `prevent_destroy` / lifecycle guards on stateful resources
- [ ] **Stack/module scope keeps blast radius small** (per-service or per-env, not monolith)

## State

- [ ] **Remote state with locking** — e.g., S3+DynamoDB, Azure Storage+blob lease, Terraform Cloud, Pulumi service
- [ ] **State backed up and versioned**; recovery procedure tested
- [ ] **Drift detection scheduled** — e.g., periodic `plan`, AWS Config, Azure Policy

## Secrets & Identity

- [ ] **No secrets in state or repo** — managed via vault/KMS with references
- [ ] **Rotation plan for credentials, certs, signing keys**
- [ ] **Least-privilege IAM** per module/pipeline; no wildcard admin

## Cost & Change Safety

- [ ] **Cost-estimation in PR** — e.g., Infracost, native cloud estimators
- [ ] **Tagging policy enforced** (owner, env, cost-center)
- [ ] **Module versions pinned**; registry source verified
