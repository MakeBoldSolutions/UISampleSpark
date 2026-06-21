# Browser Extension Risk Checklist

## Manifest & Permissions

- [ ] **MV3-compliant manifest** (service worker, no remote code execution)
- [ ] **Permissions minimal and justified** — host_permissions narrowed; optional_permissions for opt-in features
- [ ] **Content Security Policy locked down** — no `unsafe-eval`, no remote script tags

## Trust Boundaries

- [ ] **Content scripts treated as untrusted** by background — message validation at the boundary
- [ ] **No direct DOM access to page secrets** (isolated world used correctly)
- [ ] **External message senders allowlisted** (`externally_connectable`)

## Storage & Sync

- [ ] **Sensitive data not in `storage.sync`** (size-limited, cross-device leak surface)
- [ ] **Migration path for storage schema changes** across update
- [ ] **Quota handled gracefully** (storage full, message size limits)

## Performance & Size

- [ ] **Bundle size budgeted** (cold-start of service worker matters)
- [ ] **No long-lived listeners that prevent worker termination**
- [ ] **Per-tab CPU/memory impact measured**

## Distribution

- [ ] **Store review checklist tracked** — Chrome Web Store, Edge Add-ons, Firefox AMO
- [ ] **Update channel and rollback plan** for forced updates
- [ ] **Telemetry opt-in and disclosed in privacy policy**
