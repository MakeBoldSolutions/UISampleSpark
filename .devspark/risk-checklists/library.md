# Library / SDK Risk Checklist

## Public API Surface

- [ ] **Public surface is documented and intentional** — internal symbols are non-exported / `internal` / `pub(crate)`
- [ ] **Semver discipline declared** (what counts as breaking, what counts as additive)
- [ ] **Breaking-change detection in CI** — e.g., `cargo semver-checks`, `api-extractor`, `mypy --strict` public-API snapshot, `revapi`

## Compatibility

- [ ] **Supported runtime/language versions declared and tested in CI matrix**
- [ ] **Optional/peer dependencies declared correctly** — no implicit transitive expectations
- [ ] **No leaked logging configuration** (libraries do not configure root loggers)

## Distribution

- [ ] **Reproducible build with signed artifacts** — e.g., sigstore, npm provenance, PyPI trusted publishing
- [ ] **License headers + SPDX present**; dependency licenses surveyed
- [ ] **Deprecation policy with timelines** for any planned removals

## Consumer Safety

- [ ] **No global mutable state** that surprises concurrent callers
- [ ] **Errors are typed and inspectable** (not opaque strings)
- [ ] **Sample/quickstart code compiled in CI** to catch silent breakage
