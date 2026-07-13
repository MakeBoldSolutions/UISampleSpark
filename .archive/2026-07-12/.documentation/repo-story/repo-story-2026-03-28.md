# Repository Story: UISampleSpark

> Generated 2026-03-28 | Window: 120 months (10 years requested; 7 years of actual history) | Scope: full

## Executive Summary

UISampleSpark is an educational ASP.NET Core project that demonstrates multiple front-end UI technologies — MVC, Razor Pages, React, Vue, htmx, and Blazor — all backed by a shared CRUD data layer. Over nearly seven years and **703 commits** from **8 contributors**, the project has evolved from a simple .NET Framework MVC sample into a modern .NET 10 multi-UI reference architecture with Docker support, CI/CD pipelines, and a formalized governance constitution.

The project shows sustained, long-term investment. Activity began in April 2019 and has never fully stopped, peaking at **143 commits in 2021** during a major modernization push and accelerating dramatically in early 2026 to a pace of **~28 commits per month** (85 in the first three months alone). This 2026 surge — driven by rebranding from "SampleMvcCRUD" to "UISampleSpark," security hardening, and AI-assisted development tooling — signals a project entering its most active phase yet.

Governance maturity has advanced significantly. In February 2026, a formal project constitution was ratified (v1.0.0), codifying 11 core principles covering code quality, architecture, testing, security, CI/CD, and documentation. The repository now runs **CodeQL and Trivy security scanning**, builds multi-stage Docker images on every push, and maintains automated dependency updates via Dependabot. Fifty merged pull requests demonstrate growing process discipline.

From a delivery standpoint, the project lacks tagged releases — a clear gap for a mature educational reference. However, commit history shows consistent delivery milestones: the .NET Framework-to-Core migration (2020–2021), .NET 6/7/8 upgrades (2022–2024), the .NET 10 upgrade and full rebrand (Nov 2025–Feb 2026), and a hardening sprint resolving 109 CodeQL security alerts (March 2026). The README has been updated 37 times, reflecting continuous attention to documentation as an educational asset.

The contributor model is characteristic of a maintained open-source educational project: two primary developers (Lead Architect and Developer A) account for **69.1%** of all commits, supplemented by periodic contributions from six additional developers including automated tooling (Dependabot). This pattern is sustainable for an educational project but represents a bus factor worth monitoring.

---

## Technical Analysis

### Development Velocity

The project's 703 commits span from April 25, 2019 to March 28, 2026 — **2,529 days** of continuous history. Activity follows a clear pattern of seasonal intensity:

| Year | Commits | Avg/Month | Trend |
|------|---------|-----------|-------|
| 2019 | 65 | 7.2 (9 active months) | Project inception |
| 2020 | 103 | 8.6 | Growth — April 2020 spike of **54 commits** (migration work) |
| 2021 | 143 | 11.9 | **Peak year** — Major modernization |
| 2022 | 118 | 9.8 | Sustained — Active maintenance and upgrades |
| 2023 | 95 | 7.9 | Moderate deceleration — refinement phase |
| 2024 | 57 | 4.8 | Low activity — maintenance mode |
| 2025 | 37 | 5.3 (7 active months) | Quiet first half, revival in November |
| 2026 | 85 | **28.3** (3 months, Q1 only) | **Dramatic acceleration** — rebrand and hardening |

The **April 2020 spike** (54 commits) correlates with major infrastructure work — likely the .NET Framework to .NET Core migration, given that the top hotspot files all carry the `Mwh.Sample.*` namespace prefix that was later retired. The **2021 peak** (143 commits) represents the most sustained development period, with May 2021 (26 commits) and November 2021 (33 commits) as the busiest months — both concentrated on Developer A's modernization work.

The 2024 lull (57 commits, lowest full year) represents typical maintenance-mode behavior for a mature educational project. The 2026 resurgence is striking: at 85 commits through March alone, the annualized pace would be **~340 commits/year** — 2.4× the previous peak. This acceleration is driven by the UISampleSpark rebrand, constitution ratification, AI-assisted development integration, and a comprehensive security hardening sprint.

**Commit category distribution** (estimated from subjects):

| Category | Count | % |
|----------|-------|---|
| Features | 115 | 16.4% |
| CI/Build | 84 | 11.9% |
| Documentation | 58 | 8.2% |
| Fixes | 35 | 5.0% |
| Chore | 22 | 3.1% |
| Tests | 20 | 2.8% |
| Refactor | 16 | 2.3% |
| Other/Uncategorized | 353 | 50.2% |

The high "Other" category (50.2%) reflects the era before conventional commit adoption. Feature work (16.4%) and CI/build changes (11.9%) together account for the largest intentional work categories, consistent with an evolving educational reference project.

### Contributor Dynamics

Eight contributors have participated across the project's history, with a clear hierarchical structure:

| Role | Commits | Share | Active Period |
|------|---------|-------|---------------|
| Lead Architect | 255 | 36.3% | 2020–2026 (sustained) |
| Developer A | 231 | 32.9% | 2019–2024 (founding contributor) |
| Developer B | 82 | 11.7% | 2019–2020 (early phase) |
| Developer C | 66 | 9.4% | 2025–2026 (recent surge) |
| Developer D | 30 | 4.3% | 2019, 2024–2026 (sporadic + Dependabot-era) |
| Developer E | 19 | 2.7% | 2020 (single-year contributor) |
| Developer F | 15 | 2.1% | 2021–2023 (intermittent) |
| Developer G | 5 | 0.7% | 2026 (recent) |

**Bus Factor Assessment**: The top two contributors (Lead Architect + Developer A) account for **69.1%** of all commits. However, this concentration has shifted over time:

- **2019–2020**: Developer A and Developer B dominated (founding phase)
- **2021–2023**: Lead Architect emerged as primary driver alongside Developer A
- **2025–2026**: Developer C has become the most active contributor (59 of 85 commits in 2026), while Developer A appears to have stepped back

This succession pattern — from Developer A's early stewardship, through the Lead Architect's governance era, to Developer C's recent acceleration — demonstrates healthy project continuity. The introduction of Developer C and Developer G in 2025–2026, combined with Dependabot (Developer D), indicates the project is actively maintained by a fresh contributor base.

### Quality Signals

**Test Infrastructure**: The repository contains **13 test files** with **48 test-related commits** across the project's history. Two dedicated test projects exist:

- `UISampleSpark.Core.Tests/` — Domain logic unit tests
- `UISampleSpark.Data.Tests/` — Repository layer unit tests

Test-to-source ratio: With 13 test files against an estimated ~50+ source files, the test coverage infrastructure is present but thin. The constitution targets 25% code coverage — current coverage is estimated at ~1%, representing the project's most significant quality gap.

**Conventional Commit Adoption**: Only **40 of 703 commits** (5.7%) use conventional commit prefixes (`feat:`, `fix:`, `ci:`, etc.). However, this metric is heavily weighted toward recent history — nearly all 2026 commits use conventional prefixes, indicating a process maturity improvement. The 2026 Q1 commits show disciplined use of `feat:`, `fix:`, `ci(deps):`, `deps:`, and `docs:` prefixes.

**Commit Message Quality**: The `informal_commit_count` of 5 suggests very few one-word or empty commit messages. Most early commits used descriptive but non-standardized messages (e.g., "Update README.md", "NuGet Updates", "Code Clean-up").

**File Type Distribution** (by touch count):

| Extension | Touches | Interpretation |
|-----------|---------|----------------|
| .htm | 8,472 | Legacy HTML views (likely Razor/MVC templates in early versions) |
| .cs | 2,052 | Core C# source — active development target |
| .js | 1,340 | JavaScript frontends (React, Vue, vanilla JS) |
| .scss | 1,057 | Stylesheet work — theming and UI polish |
| .csproj | 731 | Frequent project file changes — dependency and framework upgrades |
| .cshtml | 558 | Razor views — MVC and Razor Pages implementations |
| .json | 502 | Configuration and package management |
| .md | 268 | Documentation — README, CHANGELOG, constitution |
| .yml | 158 | CI/CD workflow files |
| .razor | 72 | Blazor components — newer addition |

The heavy .htm touch count likely represents early .NET Framework era views that were later migrated. The .cs-to-.csproj ratio (2,052:731) shows significant project configuration churn, consistent with seven years of framework upgrades.

### Governance & Process Maturity

**Pull Request Workflow**: 50 merged pull requests indicate a growing but not yet fully mature PR-based workflow. Given 703 total commits, approximately **7.1%** of work flowed through PRs. However, this percentage is misleading — PR-based workflow was adopted more recently, with the majority of early commits going directly to main.

**Constitution Governance**: A formal constitution was ratified in February 2026 (v1.0.0), establishing 11 principles. This is a distinguishing feature — few educational projects formalize governance at this level. The constitution:

- Defines MUST/SHOULD/MAY language for each principle
- Covers code quality, architecture, security, testing, CI/CD, Docker, and documentation
- Explicitly documents the educational scope (no auth by design)
- Sets measurable targets (25% test coverage baseline)

**Tag Discipline**: The repository has **no tagged releases** — a significant governance gap for a project with 7 years of history. Milestone delivery is instead tracked through commit messages referencing framework upgrades (.NET Core → .NET 5 → 6 → 7 → 8 → 10) and the README evolution (37 updates).

**Dependabot Integration**: The presence of automated dependency update commits (Developer D) from 2024 onward demonstrates proactive dependency management, aligned with Constitution Principle IX.

### Architecture & Technology

**Language & Framework Indicators**:

| Signal | Present | Notes |
|--------|---------|-------|
| C# / .NET | ✅ | Primary language; .NET 10 (latest) |
| JavaScript | ✅ | React, Vue, vanilla JS frontends |
| TypeScript | ✅ | Type-safe frontend code |
| PowerShell | ✅ | Build scripts, Docker Hub publishing |
| Dockerfile | ✅ | Multi-stage Alpine builds |
| GitHub Actions | ✅ | CI/CD, security scanning, Docker publishing |
| Razor (.cshtml) | ✅ | MVC and Razor Pages views |
| Blazor (.razor) | ✅ | Interactive web components |

**Architecture Evolution** (traced through hotspots):

The hotspot analysis reveals a complete namespace migration:

1. **`Mwh.Sample.*` era (2019–2025)**: Original namespace with separate Web, WebApi, Repository, Domain, Common, HttpClientFactory, Console, and SoapClient projects
2. **`UISampleSpark.*` era (2025–present)**: Modernized namespace with Core, Data (implicit), UI, MinimalApi, and CLI projects

The most-modified files are all under the old namespace:
- `Mwh.Sample.Web/Mwh.Sample.Web.csproj` (88 changes) — the primary web application
- `Mwh.Sample.Repository/Mwh.Sample.Repository.csproj` (52 changes) — data access layer
- `Mwh.Sample.WebApi/Mwh.Sample.WebApi.csproj` (47 changes) — API layer
- Test project .csproj files (46, 43, 38 changes) — continuous test infra maintenance

**CI/CD Maturity**: The project has GitHub Actions workflows for Docker build/push and CodeQL security scanning. The `azure-pipelines.yml` (37 changes) suggests an earlier Azure DevOps CI era that was migrated to GitHub Actions. The recent March 2026 sprint included Docker workflow fixes (PR tag generation, Buildx updates) and security scanning improvements (resolving 109 CodeQL alerts).

**Configuration Signals**: `package.json` presence indicates npm/Node.js tooling for frontend builds. The `build.js` file in the UI project suggests a custom JavaScript build pipeline. `global.json` pins the .NET SDK version. `nuget.config` manages NuGet package sources.

---

## Change Patterns

### Top Hotspot Files and Their Significance

| File | Changes | Significance |
|------|---------|-------------|
| `Mwh.Sample.Web/Mwh.Sample.Web.csproj` | 88 | Primary application — most dependency and framework upgrades |
| `Mwh.Sample.Repository/...csproj` | 52 | Data layer — frequent NuGet updates for EF Core |
| `Mwh.Sample.WebApi/...csproj` | 47 | API layer — parallel framework evolution |
| `Mwh.Sample.Domain.Tests/...csproj` | 46 | Test infrastructure — kept in sync with source |
| `Mwh.Sample.Web/Program.cs` | 39 | Application bootstrap — reflects .NET hosting model changes |
| `azure-pipelines.yml` | 37 | CI pipeline — migrated away, now historical |
| `README.md` | 37 | Living documentation — consistently maintained |
| `EmployeeDatabaseService.cs` | 33 | Core service — business logic hotspot |
| `.github/workflows/docker-image.yml` | 28 | Docker CI — active and evolving |
| `EmployeeMock.cs` | 27 | Test mock data — co-evolves with the domain model |

### Directory-Level Patterns

The overwhelming majority of historical changes fall under the retired `Mwh.Sample.*` namespace directories, reflecting the project's 5+ year history under that name. Under the current `UISampleSpark.*` namespace:

- **UISampleSpark.UI/** — Most active current directory (web application host)
- **UISampleSpark.Core/** — Domain models, interfaces, extensions
- **UISampleSpark.MinimalApi/** — Minimal API alternative host
- **UISampleSpark.CLI/** — Command-line interface (newest addition)
- **UISampleSpark.Core.Tests/** and **UISampleSpark.Data.Tests/** — Test infrastructure

### Refactoring Signals

The `.csproj` file domination of the hotspot list (6 of top 10) is characteristic of a project that has **undergone multiple major framework migrations**. Each .NET version upgrade (Framework → Core 3.1 → 5 → 6 → 7 → 8 → 10) requires project file changes for target framework, NuGet package versions, and build configuration. This churn is expected and healthy for a long-lived educational project tracking the latest .NET.

---

## Milestone Timeline

No tagged releases exist in the repository. However, the commit history and README evolution reveal clear milestone epochs:

| Period | Milestone | Evidence |
|--------|-----------|----------|
| Apr 2019 | **Project inception** | First commit: "Add .gitignore and .gitattributes" + initial README |
| Apr–Nov 2019 | **Foundation** | 65 commits — .NET Framework MVC CRUD with Entity Framework |
| Apr 2020 | **Major migration sprint** | 54 commits in a single month — .NET Core migration |
| 2021 | **Peak development year** | 143 commits — modernization, RestSharp client, Docker support |
| Sep 2022 | **README overhaul** | Multiple README updates — standardizing project identity |
| Jan 2023 | **Architecture refinement** | 21 commits — NuGet updates, naming standardization |
| Oct 2023 | **Maintenance consolidation** | 20 commits — stability improvements |
| Sep 2024 | **Pre-upgrade preparations** | 17 commits — dependencies, CI updates |
| Nov 2025 | **.NET 10 upgrade** | "Upgrade to .NET 10.0 and refactor solution" + CHANGELOG addition |
| Feb 2026 | **UISampleSpark rebrand** | "Rebrand to UISampleSpark with modernized project structure" |
| Feb 2026 | **Constitution ratification** | Formal governance with 11 principles (v1.0.0) |
| Mar 2026 | **Security hardening sprint** | 109 CodeQL alerts resolved, rate limiting added, API protection |
| Mar 2026 | **AI tooling integration** | Spec Kit Spark agents, context scripts, repo story capability |

**Velocity around milestones**: The pattern is consistent — velocity spikes precede and accompany major transitions (April 2020 migration: 54 commits, November 2021 modernization: 33 commits, February 2026 rebrand: 31 commits, March 2026 hardening: 33 commits). Post-milestone periods show natural deceleration as the project stabilizes.

---

## Constitution Alignment

The project constitution (v1.0.0, ratified February 2026) defines 11 principles. Here is how the commit history reflects adherence:

### Strong Alignment

| Principle | Evidence | Assessment |
|-----------|----------|------------|
| **I. Code Quality & Safety** | .csproj files show `<Nullable>enable</Nullable>`, `<AnalysisLevel>latest-all</AnalysisLevel>` | ✅ Strongly aligned |
| **II. Architecture & Design** | Repository pattern visible in hotspot files (`EmployeeDatabaseService.cs`, `EmployeeMock.cs`, `EmployeeRepository.cs`); DTO separation evident | ✅ Strongly aligned |
| **IV. Security Posture** | 109 CodeQL alerts resolved in March 2026; Trivy scanning active; SECURITY.md exists | ✅ Strongly aligned (educational scope respected) |
| **VI. CI/CD & DevOps** | Docker workflow (28 changes), CodeQL workflow, Azure Pipelines (historical); 50 merged PRs | ✅ Aligned (test-build workflow added recently) |
| **IX. Dependency Management** | .NET 10 (latest); Dependabot active (Developer D commits); quarterly NuGet updates evident | ✅ Strongly aligned |
| **X. Docker & Containerization** | Dockerfile exists with multi-stage builds; Alpine base; non-root user; CI smoke tests | ✅ Strongly aligned |
| **XI. AI-Assisted Development** | `/.documentation/` structure in place; session archives, constitution, audit reports organized | ✅ Strongly aligned |

### Gaps Identified

| Principle | Gap | Severity |
|-----------|-----|----------|
| **III. Error Handling** | Global `IExceptionHandler` implementation was flagged as action item in constitution sync report | 🔴 High |
| **V. Testing Standards** | 13 test files, ~1% coverage vs. 25% target; only 20 test-related commits out of 703 (2.8%) | 🔴 High |
| **VII. Observability** | `ILogger<T>` usage flagged as missing in Repository/Services; health check implementation status unclear | 🟡 Medium |
| **VIII. Documentation** | XML doc coverage estimated at ~40%; CHANGELOG added only in Nov 2025 | 🟡 Medium |
| **Milestone tagging** | Zero tagged releases across 7 years of history | 🟡 Medium |

### How Well Does the Commit History Reflect Stated Values?

The commit history tells a story of **progressive maturation toward constitutional values**. Most principles were practiced informally before being codified — repository pattern, DTO separation, async/await, Docker best practices, and CI/CD were all established patterns before the constitution existed. The constitution formalized what was already largely true.

The two significant gaps — **testing coverage** and **global exception handling** — are both acknowledged in the constitution's own sync report as action items, demonstrating honest self-assessment. The recent 2026 security hardening sprint (resolving 109 CodeQL alerts, adding rate limiting, implementing API protection) shows the project actively closing gaps identified by governance.

The absence of tagged releases is the clearest divergence between the project's maturity level and its governance artifacts. For an educational project meant to demonstrate best practices, semantic versioning and release tagging would significantly strengthen the demonstration value.

---

*Generated by /speckit.repo-story | Spec Kit Spark — Adaptive System Life Cycle Development*
