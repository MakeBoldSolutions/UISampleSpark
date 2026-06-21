---
description: Perform adversarial, archetype-aware risk analysis across spec.md, plan.md, and tasks.md — identifying flaws, hazards, and failure modes that will derail delivery in production.
handoffs:
  - label: Fix Spec Showstoppers
    agent: devspark.specify
    prompt: Revise spec to resolve vague requirements, missing edge cases, or undefined trust boundaries
    send: true
  - label: Fix Critical Issues
    agent: devspark.plan
    prompt: Revise plan to address critical architectural risks
    send: true
  - label: Update Tasks
    agent: devspark.tasks
    prompt: Regenerate tasks with missing operational items
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

Act as a skeptical technical expert identifying risks, architectural flaws, implementation hazards, and failure scenarios that will prevent successful delivery. Focuses on **what will go wrong** rather than consistency checking.

- `/devspark.analyze` = Consistency & completeness (are artifacts aligned?)
- `/devspark.critic` = Adversarial risk analysis (what will fail in production?)

These are deliberately **non-overlapping gates**. Critic does NOT re-check:

- Internal artifact consistency, duplication, terminology drift → owned by `/devspark.analyze`
- Whether stated requirements have matching tasks (req↔task coverage) → owned by `/devspark.analyze`
- Whether requirement *wording* is precise (vague adjectives, placeholders) → owned by `/devspark.analyze`
- **Rationale Summary completeness or spec↔plan Core-Problem drift** → owned by `/devspark.analyze`

Critic DOES own: whether stated NFR targets are achievable, what operational/security/scale tasks are missing **regardless** of whether any requirement called for them, and archetype-specific production failure modes.

### What this command is NOT

Critic findings are **hypotheses**, not proven defects. This command does **not** replace SAST, DAST, profiling, dependency scanning, code review, integration testing, or formal verification. A clean critic report means "no obvious traps in the artifacts," not "the system is safe." Teams must still run real testing.

## Operating Constraints

Non-destructive. Do **not** edit `spec.md`, `plan.md`, `tasks.md`, or source files. The only allowed write is refreshing the gate artifact at `FEATURE_DIR/gates/critic.md`.

Read YAML frontmatter from `spec.md`. Treat `classification`, `risk_level`, `risk_profile`, `change_type`, `archetype`, and `required_gates` as authoritative when present.

**Mindset**: Assume **limited team experience** with the stack, **optimistic estimates**, and **incomplete edge-case understanding**.

**Constitution Authority**: `/.documentation/memory/constitution.md` is **non-negotiable**. Constitution violations are automatically SHOWSTOPPER.

## Outline

**Multi-app support**: If `.documentation/devspark.json` exists with `mode: "multi-app"`, check for `--app <id>` in user input and resolve artifacts from `{app.path}/.documentation/` instead of repo root. Print resolved scope at start.

### 1. Initialize Analysis Context

> **Script Resolution**: Before running `.devspark/scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks`, apply 2-tier override — if `.documentation/scripts/{powershell,bash}/<filename>` exists, run it instead. Team overrides in `.documentation/scripts/` take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks` once from repo root, parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md (optional)
- TASKS = FEATURE_DIR/tasks.md (optional)
- CONSTITUTION = /.documentation/memory/constitution.md

**Tiered artifact requirements** — do NOT abort on missing plan/tasks; degrade gracefully:

| Artifacts present   | Critique scope                                                                   | Degradation label |
| ------------------- | -------------------------------------------------------------------------------- | ----------------- |
| spec only           | Spec-level: rationale, requirement completeness, scope hazards, trust boundaries | `SPEC-ONLY`       |
| spec + plan         | Above + architecture, stack, data model, deployment risks                        | `SPEC+PLAN`       |
| spec + plan + tasks | Full critique including task sequencing & operational gaps                       | `FULL`            |

Abort only if `spec.md` is missing. Print the degradation label in the Executive Summary so partial reviews aren't mistaken for full ones.

For single quotes in args (e.g. "I'm Groot"), use `'I'\''m Groot'` or double-quote.

### 2. Detect Repository Archetype

Determine the repo archetype (drives which risk categories apply). Read in priority order:

1. `archetype` field in spec.md frontmatter (if present)
2. `archetype` or `platforms` declared in constitution
3. File-system signals (heuristics below)

Archetype values:
`web-service | library | cli | mobile-app | desktop-app | data-pipeline | ml-training | infrastructure | embedded | browser-extension | game | monorepo | documentation-site`

**Heuristic signals** (non-exhaustive):

- `web-service`: Dockerfile + framework imports (FastAPI/Express/Spring/ASP.NET/Rails), `openapi.*`, k8s manifests
- `library`: `pyproject.toml` without `[project.scripts]`, npm `"main"`/`"exports"` without server entry, `Cargo.toml` `[lib]`, published-package metadata
- `cli`: `[project.scripts]`, `bin` in `package.json`, `Cargo.toml` `[[bin]]`, Cobra/Click/Typer imports
- `mobile-app`: `android/`, `ios/`, `pubspec.yaml`, `*.xcodeproj`, React Native/Expo, MAUI
- `desktop-app`: Electron, Tauri, WPF, Qt, GTK, Avalonia
- `data-pipeline`: Airflow/Dagster/Prefect/Luigi/dbt, Spark/Beam jobs, `dags/` dir
- `ml-training`: PyTorch/TF/JAX training loops, `train.py`, MLflow/W&B, notebooks under `experiments/`
- `infrastructure`: Terraform/Pulumi/Bicep/CloudFormation/Ansible without app code
- `embedded`: PlatformIO, Zephyr, ESP-IDF, `*.ino`, linker scripts, `no_std` Rust
- `browser-extension`: `manifest.json` with `manifest_version`
- `game`: Unity/Unreal/Godot project files
- `monorepo`: Nx/Turborepo/Lerna/pnpm workspaces/Bazel with ≥3 sibling packages
- `documentation-site`: MkDocs/Docusaurus/Hugo/Jekyll without runtime code

Print detected archetype in the report header. If undetectable, default to `web-service` AND emit a HIGH finding (`archetype-ambiguity`) noting the missing metadata.

### 3. Detect Technology Stack

From plan.md (or repo manifests if plan absent): Language, Framework, Storage, Infra/Runtime, Concurrency model. Used to load matching checklists in §7.

### 4. Detect Context Mode & Risk Profile

**Context mode** (drives emphasis): `greenfield | brownfield | migration | hotfix`

Read `change_type` from spec.md frontmatter. If missing, infer from file deltas (mostly-new = greenfield; modified existing = brownfield; "migrate"/"port"/"cutover" language = migration; tiny scope + bug ID = hotfix).

| Mode       | Emphasis                                                                    |
| ---------- | --------------------------------------------------------------------------- |
| greenfield | Full adversarial baseline                                                   |
| brownfield | Regression risk, backward compat, blast radius, rollback ease               |
| migration  | Dual-write hazards, cutover, data parity, idempotent replay                 |
| hotfix     | Minimum-viable scrutiny: "fix without making it worse"; preserve invariants |

**Risk profile** (drives severity scaling): `experimental | internal | customer-facing | revenue-critical | safety-critical | regulated`

Read `risk_profile` from spec.md frontmatter; fall back to constitution; default to `internal`.

**Severity scaling rule** (deterministic). Each finding has a *base severity* from the category registry. Apply this shift to derive *effective severity*:

| Profile          | Shift                                                                  |
| ---------------- | ---------------------------------------------------------------------- |
| experimental     | −1 (CRITICAL → HIGH; HIGH → MEDIUM; floor at LOW)                      |
| internal         | 0                                                                      |
| customer-facing  | 0                                                                      |
| revenue-critical | +1 (HIGH → CRITICAL; CRITICAL → SHOWSTOPPER)                           |
| safety-critical  | +1 AND treated as constitution violation → SHOWSTOPPER floor           |
| regulated        | +1 for any finding touching data handling, audit, retention, or access |

If `risk_profile` is missing, default to `internal` AND emit a HIGH finding (`missing-risk-profile`).

Print mode and profile in the report header.

### 5. Load Artifacts with Risk Lens

Extract failure-prone elements (skip sections whose artifact is absent):

**spec.md**: unrealistic perf/scale targets; vague security requirements; third-party lock-in / API limits; missing edge cases; data-consistency naivety; undefined trust boundaries.

**plan.md**: bleeding-edge stack choices; over/under-engineering; persistent-storage access patterns without performance analysis; safe-release strategy gaps; testing strategy gaps.

**tasks.md**: sequencing/dependency gaps; optimistic estimates; hidden contention in parallel tasks; missing operational tasks (monitoring, alerting, backups, DR, runbooks).

### 6. Risk Category Registry (archetype-gated)

Apply only categories whose `archetypes` set includes the detected archetype (or `*`). Each category has a *base severity ceiling*; the §4 profile shift adjusts findings up or down.

| Category                    | Archetypes                                                               | Base ceiling |
| --------------------------- | ------------------------------------------------------------------------ | ------------ |
| `dependency_supply_chain`   | \*                                                                       | CRITICAL     |
| `testing_strategy`          | \*                                                                       | CRITICAL     |
| `documentation`             | \*                                                                       | HIGH         |
| `secrets_handling`          | \*                                                                       | SHOWSTOPPER  |
| `trust_boundaries`          | \*                                                                       | SHOWSTOPPER  |
| `error_handling_resilience` | \*                                                                       | CRITICAL     |
| `concurrency_async`         | web-service, cli, desktop-app, mobile-app, data-pipeline, game, embedded | CRITICAL     |
| `scale_bottlenecks`         | web-service, data-pipeline, ml-training                                  | CRITICAL     |
| `auth_authz`                | web-service, mobile-app, desktop-app, browser-extension, infrastructure  | SHOWSTOPPER  |
| `input_validation`          | web-service, cli, mobile-app, desktop-app, browser-extension             | SHOWSTOPPER  |
| `observability`             | web-service, data-pipeline, infrastructure, mobile-app                   | CRITICAL     |
| `deployment_rollback`       | web-service, mobile-app, desktop-app, infrastructure, browser-extension  | CRITICAL     |
| `data_loss_continuity`      | web-service, data-pipeline, infrastructure, mobile-app, desktop-app      | SHOWSTOPPER  |
| `regulatory_privacy`        | web-service, mobile-app, data-pipeline                                   | SHOWSTOPPER  |
| `api_compatibility`         | library, cli                                                             | CRITICAL     |
| `cli_ergonomics`            | cli                                                                      | HIGH         |
| `mobile_platform`           | mobile-app                                                               | CRITICAL     |
| `pipeline_semantics`        | data-pipeline                                                            | SHOWSTOPPER  |
| `ml_reproducibility`        | ml-training                                                              | CRITICAL     |
| `iac_blast_radius`          | infrastructure                                                           | SHOWSTOPPER  |
| `embedded_safety`           | embedded                                                                 | SHOWSTOPPER  |
| `binary_size_perf`          | mobile-app, embedded, browser-extension, game                            | HIGH         |
| `offline_sync`              | mobile-app, desktop-app                                                  | CRITICAL     |
| `monorepo_coupling`         | monorepo                                                                 | HIGH         |

**Category cue sheets** (capability-level, stack-agnostic):

- `dependency_supply_chain`: unpinned versions; transitive vulns unmonitored; abandoned packages; license incompatibility; build reproducibility.
- `testing_strategy`: no failure-mode tests; missing fixtures; no contract tests at boundaries; no load/perf tests where scale matters.
- `secrets_handling`: hardcoded secrets; secrets in env without vault/KMS; no rotation; secrets in logs.
- `trust_boundaries`: enforcement on privileged operations missing or implicit; ambient authority; missing tenant isolation.
- `error_handling_resilience`: swallowed errors; non-idempotent retries; missing timeouts/backoff; no circuit-breaker equivalent where appropriate.
- `concurrency_async`: blocking I/O on async runtimes; pool exhaustion; race conditions; deadlocks; task/thread/goroutine leaks; resource cleanup paths.
- `scale_bottlenecks`: unbounded result sets (endpoints, queries, iterators, streams); N+1 access patterns; no caching on hot paths; persistent-storage access patterns without index/partition analysis; no horizontal-scaling path.
- `auth_authz`: trust boundary enforcement on privileged operations; rate limiting on auth surfaces; session/credential lifecycle.
- `input_validation`: untrusted input crossing trust boundaries unvalidated; injection vectors (SQL, command, template, deserialization); size/shape limits.
- `observability`: no structured logs/metrics/traces; no liveness/readiness signal appropriate to the runtime; no alert thresholds; no error tracking.
- `deployment_rollback`: no safe-release strategy for this artifact type; no migration plan; no rollback procedure; no staging/prod parity; no graceful shutdown.
- `data_loss_continuity`: no backup/restore; destructive ops without confirmation; missing transactional boundaries; no DR plan.
- `regulatory_privacy`: PII handling unspecified; retention/residency unaddressed; missing audit logging.
- `api_compatibility`: undocumented public surface; missing semver discipline; no deprecation policy; breaking-change detection absent in CI.
- `cli_ergonomics`: undefined exit codes; ignored signals (SIGINT/SIGTERM/SIGPIPE); stdout/stderr/stdin discipline; non-portable paths/encoding; no `--help`/`--version` contract.
- `mobile_platform`: battery / background-execution limits; store-policy compliance; OS-version fragmentation; permissions model; deep-link/intent handling.
- `pipeline_semantics`: idempotency; exactly-once vs at-least-once semantics; backfill strategy; schema evolution; late/out-of-order data; watermark policy.
- `ml_reproducibility`: seeds; env/data pinning; train/serve skew; data leakage; eval contamination; model/artifact versioning.
- `iac_blast_radius`: drift detection; state file locking & backups; secret rotation; cost runaway; change scope review; destroy guards.
- `embedded_safety`: memory bounds; watchdog; OTA safety & rollback; power-loss recovery; real-time deadlines; flash wear.
- `binary_size_perf`: artifact size budgets; cold-start; startup memory; asset compression.
- `offline_sync`: conflict resolution; offline queue durability; clock skew; partial-sync recovery.
- `monorepo_coupling`: cross-package import violations; version skew; CI graph correctness; release coordination.

**Universal failure-mode lens** (apply if no specific cue fires):

`resource_leaks | error_swallowing | race_conditions | unbounded_growth | missing_timeouts | missing_input_validation | trust_boundary_violations | non_idempotent_retries | silent_data_corruption`

### 7. Load Stack/Archetype Checklists (Externalized)

Load all matching checklists from disk:

- `.devspark/risk-checklists/{stack}.md` (e.g., `python-fastapi.md`, `node-express.md`, `go-gin.md`, `java-spring.md`, `dotnet-aspnet.md`)
- `.devspark/risk-checklists/{archetype}.md` (e.g., `library.md`, `cli.md`, `data-pipeline.md`)

If none exist, derive risks from first principles using the universal failure-mode lens above. Note in the report output: *"No stack/archetype checklists found at `.devspark/risk-checklists/` — consider seeding from prior critic runs."* Stock seeds ship with DevSpark; teams override by placing files of the same name in `.documentation/risk-checklists/`.

Every named tool in a checklist must be paired with the underlying capability so the model can translate across ecosystems. Pattern:

> "[Capability needed] — e.g., [Tool A in stack X], [Tool B in stack Y], [Tool C in stack Z]"

Example: "Long-running work without a durable queue with retry semantics (e.g., Celery, RQ, Sidekiq, BullMQ, Hangfire)."

### 8. Severity Classification (base, before §4 shift)

- **SHOWSTOPPER**: production outage, data loss, security breach, safety incident, or constitution violation.
- **CRITICAL**: major user-facing issue or costly rework (no rollback, no observability, unbounded growth, broken backward compat for a published library).
- **HIGH**: technical debt or operational burden (missing structured logging, hardcoded configs, missing type checks).
- **MEDIUM**: development friction or minor issues.

Both base and effective severity must appear in each finding.

### 9. Produce Risk Assessment Report

Output Markdown with this structure (omit empty sections — do not emit empty headers):

````markdown
```yaml
gate: critic
status: pass | warn | fail
blocking: true | false
severity: info | warning | error | showstopper
summary: "<concise outcome>"
```

## Technical Risk Assessment

**Analysis Date:** [ISO timestamp]
**Scope:** [SPEC-ONLY | SPEC+PLAN | FULL]
**Detected Archetype:** [archetype]
**Detected Stack:** [language] + [framework] + [storage]
**Context Mode:** [greenfield | brownfield | migration | hotfix]
**Risk Profile:** [experimental | internal | customer-facing | revenue-critical | safety-critical | regulated]
**Risk Posture:** [RED | YELLOW | GREEN]

### Executive Summary

[2–3 sentences: verdict + degradation note if not FULL]

### Findings (source of truth)

```yaml
findings:
  - finding_id: critic-001
    category: <registry-category>
    archetype_applicable: true
    location: <spec.md#section | plan.md#L42 | tasks.md#T07>
    description: <1–3 sentences>
    base_severity: showstopper | critical | high | medium | low
    effective_severity: showstopper | critical | high | medium | low
    recommended_action: <machine-actionable next step>
    execution_mode: auto | selective | manual
    status: open
    outcome: ""
```

### Showstoppers

_(Render rows from findings where `effective_severity: showstopper`. Drop section if none.)_

| ID  | Category | Location | Risk | Likely Impact | Mitigation |
| --- | -------- | -------- | ---- | ------------- | ---------- |

### Critical

_(Render from `critical`. Drop if empty.)_

| ID  | Category | Location | Risk | Likely Impact | Action |
| --- | -------- | -------- | ---- | ------------- | ------ |

### High

_(Render from `high`. Drop if empty.)_

| ID  | Category | Location | Issue | Impact | Suggestion |
| --- | -------- | -------- | ----- | ------ | ---------- |

### Missing Critical Tasks

_(FULL scope only. Omit empty buckets.)_

- **Observability / Operations / Testing / Documentation / Security:** […]

### Questionable Assumptions

1. **[Assumption]** → Failure mode: […]

### Dependency Risk Assessment

| Dependency | Concern | Alternative |
| ---------- | ------- | ----------- |

### Estimated Technical Debt at Launch

- **Code / Operational / Documentation / Testing Debt:** […]

### Metrics

- Showstopper / Critical / High counts (effective severity)
- Findings by category
- Missing operational tasks (FULL scope only)

**VERDICT:** STOP | CONDITIONAL | PROCEED

**Required Actions Before Implementation:**

1. […]

**Recommended Risk Mitigations:**

- […]
````

Every table row MUST correspond to a `finding_id` in the YAML `findings:` list — the YAML list is the single source of truth. Tables are projections, never additive.

### 10. Persist Gate Artifact

After producing the report:

- Ensure `FEATURE_DIR/gates/` exists.
- Save report as `FEATURE_DIR/gates/critic.md` (replace, do not append).
- The gate YAML block is authoritative for downstream commands (`/devspark.tasks`, `/devspark.implement`, `/devspark.create-pr`, `/devspark.pr-review`, `/devspark.address-pr-review`).

## Guidelines

### Adversarial Mindset

- **Murphy's Law**: If it can fail, it will fail.
- **Challenge optimism**: Estimates are optimistic; dependencies hide.
- **Real-world bias**: Prioritize incidents you've seen in production.
- **No benefit of doubt**: Vague = wrong; missing = will bite you.
- **Be brutally honest**: Sugar-coating helps nobody.

### Focus Areas (priority order, modulated by archetype)

1. Constitution violations (always SHOWSTOPPER)
2. Trust boundary / authz / secrets exposure
3. Data loss & non-idempotent / silent corruption
4. Concurrency / resource leaks / unbounded growth
5. Missing observability appropriate to runtime
6. Stack/archetype-specific traps from loaded checklists
7. Missing operational tasks (FULL scope only)

### Ignore

- Code style preferences (if linter configured)
- Minor documentation-format inconsistencies
- **Low-probability AND low-impact** issues *(low-probability/high-impact events must still be surfaced)*
- Micro-optimizations without proven bottlenecks

### Output Quality

- **Be specific**: "Blocking sync DB driver on async runtime starves the event loop" — not "database concerns."
- **Cite locations**: spec/plan/task section or line.
- **Quantify impact**: "N+1 access in list path → 1000+ round trips per 1000 items."
- **Suggest fixes**: Concrete remediation, not complaints.
- **Translate across stacks**: Pair every named tool with its capability.

### Context Efficiency

- Minimal high-signal tokens; progressive disclosure.
- Limit each table to ≤30 rows; summarize overflow into a `findings_overflow` count.
- Deterministic: same inputs → same `finding_id`s and counts.

### Analysis Rules

- **NEVER modify files** other than the gate artifact.
- **NEVER hallucinate missing sections**; report absence accurately.
- Prioritize showstoppers.
- Report zero issues gracefully with a positive summary.

## Key Differences from /devspark.analyze

| Aspect       | /devspark.analyze          | /devspark.critic         |
| ------------ | -------------------------- | ------------------------ |
| Purpose      | Consistency checking       | Risk identification      |
| Mindset      | Neutral validator          | Adversarial skeptic      |
| Focus        | Alignment across artifacts | Production failure modes |
| Severity     | Quality issues             | Business impact          |
| Output       | Remediation suggestions    | Go/No-Go recommendation  |
| Constitution | CRITICAL violations        | SHOWSTOPPER violations   |

## Backward Compatibility

If spec.md lacks `archetype`, `risk_profile`, or `change_type` frontmatter, the command still runs with sensible defaults (`web-service`, `internal`, `greenfield`) AND emits HIGH findings (`archetype-ambiguity`, `missing-risk-profile`, `missing-change-type`) so the metadata gap is visible without blocking the review.

## Context

$ARGUMENTS

## Shared Review Resolution Contract

Findings use the shared resolution contract so downstream tools (`/devspark.address-pr-review`, telemetry, harvest) can act deterministically.

- `finding_id` MUST be stable across re-runs when the underlying issue is unchanged.
- `execution_mode` MUST be one of: `auto` (safe to apply automatically), `selective` (apply with reviewer approval), `manual` (requires human implementation).
- `status` and `outcome` are written by `/devspark.address-pr-review` (FR-028).

---

## Changelog (this refactor)

- Added archetype detection (§2) with frontmatter → constitution → heuristics priority; defaults to `web-service` plus HIGH `archetype-ambiguity` finding.
- Added context-mode and risk-profile switches (§4) with a deterministic severity-shift table; missing metadata emits visible HIGH findings rather than blocking.
- Replaced the out-of-order A→F→B→C→D→E sections with a single archetype-gated **Risk Category Registry** (§6). Added new categories: `api_compatibility`, `cli_ergonomics`, `mobile_platform`, `pipeline_semantics`, `ml_reproducibility`, `iac_blast_radius`, `embedded_safety`, `binary_size_perf`, `offline_sync`, `monorepo_coupling`, plus always-applicable `trust_boundaries`, `error_handling_resilience`, `dependency_supply_chain`, `secrets_handling`.
- Externalized framework checklists to `.devspark/risk-checklists/{stack,archetype}.md` (§7) with a first-principles fallback list (`resource_leaks | error_swallowing | …`). The previously inline FastAPI/Express/Spring/Go/Web checklists should be seeded into that folder as a follow-up (noted in report output and below).
- Generalized HTTP-centric phrasing: "pagination on list endpoints" → "unbounded result sets (endpoints, queries, iterators, streams)"; "health check endpoints" → "liveness/readiness signal appropriate to the runtime"; "zero-downtime deployment" → "safe-release strategy for this artifact type"; "DB indexes" → "persistent-storage access patterns without performance analysis"; "API key/token on protected endpoints" → "trust boundary enforcement on privileged operations." CORS, HTTPS, security headers, and API versioning moved to the web-service checklist (externalized).
- Paired every named tool with capability (e.g., "durable queue with retry semantics — Celery/RQ/Sidekiq/BullMQ/Hangfire").
- Tiered artifact requirements (§1): runs on spec-only, spec+plan, or full; prints `SPEC-ONLY | SPEC+PLAN | FULL`; only aborts if spec.md missing. Updated `scripts:` frontmatter to drop `--require-tasks`.
- Fixed structural bugs: registry replaces the A→F→B→C→D→E ordering; removed the duplicate "Section 8"; moved the gate YAML block to the top of the §9 report template; fixed typos (`inding_id`→`finding_id`, `xecution_mode`→`execution_mode`); converted the verdict checkbox triple to a single `**VERDICT:**` line.
- Made YAML `findings:` the single source of truth; tables are projections that drop when empty; every row maps to a `finding_id`.
- Added the "What this command is NOT" scope-limits disclosure near the top.
- Added third handoff `devspark.specify` for spec-level showstoppers.
- Tightened the "Ignore" list: removed the "<1% probability" exemption; replaced with "low-probability AND low-impact."
- Added explicit Backward Compatibility section so missing frontmatter never blocks the run.

**Dual-gate cleanup (subsequent pass):** moved `rationale_traceability` out of the critic registry (table row + cue sheet bullet) and into `/devspark.analyze` §4G. Added an explicit non-overlap clause near the top of critic so the gate's scope is unambiguous; mirrored cross-references in `analyze.md`. Spec↔plan Core-Problem drift, Rationale Summary completeness, requirement↔task coverage, and wording-ambiguity findings are now exclusively analyze's responsibility.

**Checklists seeded:** `.devspark/risk-checklists/` now ships with stock files for `web-service`, `python-fastapi`, `node-express`, `go-gin`, `java-spring`, `dotnet-aspnet`, `library`, `cli`, `data-pipeline`, `ml-training`, `infrastructure`, `mobile-app`, `embedded`, and `browser-extension`, plus a README documenting the capability-paired entry format. Teams override via `.documentation/risk-checklists/`.

**Deviations from instructions:** None material. Token count stays within the ~10% ceiling — growth from the new registry/cue sheets is offset by deleting the duplicated Section 8, the inline framework checklists, and the redundant report scaffolding.
