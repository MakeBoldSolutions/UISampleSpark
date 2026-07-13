# Constitution History (migrated from `.documentation/memory/constitution.md`)

<!-- source: migrated(constitution.md) — non-principle content, moved out of bold-docs/backbone.md per the migration report -->

The 11 core principles from this document were restated tersely in `bold-docs/backbone.md`. This doc preserves the surrounding material that isn't itself a principle.

## Origin

Formalized 2026-02-05 via `/speckit.discover-constitution` → `/speckit.constitution` (the tooling's predecessor name, before it was renamed to DevSpark). Source: analysis of 94 C# files, 10 project files, 5 workflows, 4 documentation files. Ratified as Constitution v1.0.0.

## Additional Patterns (Observed, not formalized as hard requirements)

**Build Configuration**
- Deterministic builds disabled (`<Deterministic>false</Deterministic>`) for timestamp-based versioning
- Assembly versioning auto-generated from build timestamp: `10.YYMM.DDHH.MMSS`
- Trim analysis enabled for performance (`<EnableTrimAnalyzer>true</EnableTrimAnalyzer>`)

**Web Configuration**
- Configuration Binding Generator enabled for source generation performance
- Request Delegate Generator enabled for minimal API performance
- Optimization preference set to `Speed` for ASP.NET projects

**Editor Configuration**
- `dotnet_sort_system_directives_first = true`
- CA1707 suppressed (underscores allowed in test method names)
- Nullable warnings set to `suggestion` rather than `error`, for incremental adoption

## Governance (as it stood under DevSpark)

- Amendments required discussion and PR review; breaking changes required updating affected code; major principle changes were tagged in git (e.g. `constitution-v2.0`)
- All PRs were reviewed against constitution principles; CI/CD enforced MUST requirements automatically; SHOULD requirements were encouraged but non-blocking
- When MUST requirements conflicted with educational clarity, the trade-off was documented rather than silently resolved
- Priority order: Security > Correctness > Educational Value > Performance > Cosmetics (carried forward into `bold-docs/backbone.md` item 17)

## Version History

- **v1.0.0** (2026-02-05): Initial constitution ratified based on codebase discovery — 11 core principles formalized, educational security scope documented, 25% test-coverage baseline established, CI/CD workflows (test, security, Docker) mandated, AI-assisted development documentation structure defined.
- **2026-07-12**: Migrated from DevSpark v2.6.0 to Bold. See `.archive/index.md` for the full migration record.
