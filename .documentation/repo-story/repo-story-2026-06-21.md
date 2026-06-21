# Repository Story: UISampleSpark

> Generated 2026-06-21 | Window: 12 months | Scope: full

## Executive Summary

UISampleSpark is an educational ASP.NET Core project that demonstrates multiple front-end UI
technologies — MVC, Razor Pages, React, Vue, htmx, and Blazor — all backed by a shared
employee-management CRUD data layer. Over seven-plus years and **748 commits** from a lean
team of four contributors, the project has evolved from a simple .NET Framework MVC sample
into a modern .NET 10 multi-UI reference architecture with Docker support, GitHub Actions
CI/CD, per-IP rate limiting, and a formalized governance constitution.

The last twelve months represent the most productive sustained period in the project's
history. From July 2025 through June 2026, the repository accumulated **159 commits** —
peaking at **34 commits in March 2026** and maintaining a monthly cadence of 18–31 commits
from January through June 2026. This acceleration followed the November 2025 migration to
.NET 10, the February 2026 rebrand from "SampleMvcCRUD" to "UISampleSpark," and the
adoption of DevSpark spec-driven development tooling. June 2026 (21 commits through the
21st) is on pace to match that peak.

A landmark milestone was reached today, 2026-06-21: **v10.2.0** — the first semantically
tagged release in the project's seven-year history — was sealed, complete with a
CHANGELOG entry, ADRs, release notes, and an archived documentation set. The same day
delivered a full DevSpark governance cycle: release sealing → harvest cleanup → site audit
→ automated fix implementation. This single day resolved the audit's two highest-priority
findings — missing `.ConfigureAwait(false)` in the repository layer (ARCH1 HIGH) and
absent `<ImplicitUsings>` in a test project (QUAL1 MEDIUM) — and verified 246 tests at
93.2% line coverage.

Governance maturity is at an all-time high. A project constitution (11 principles, ratified
2026-02-05) provides authoritative standards for code quality, architecture, testing,
security, CI/CD, and documentation. DevSpark v2.6.0 enforces a specify → plan → tasks →
implement lifecycle for every feature. CodeQL and Trivy security scanning run weekly.
Dependabot keeps dependencies current. Twenty merged pull requests in the last year confirm
that the PR-based workflow is practiced, not just declared.

The contributor model reflects a healthy open-source educational project: the Lead Architect
accounts for **63.5%** of window commits, with Developer A contributing **21.4%** (primarily
automated dependency bumps), Developer B **11.9%**, and Developer C **3.1%**. Human bus
factor is effectively one — acceptable for an educational reference but worth noting for
succession planning. The project's educational charter means intentional scope constraints
(no authentication by design) that should not be read as gaps.

---

## Technical Analysis

### Development Velocity

The twelve-month window spans 2025-06-21 to 2026-06-21, covering 159 commits across 10
active months (August and October 2025 saw zero activity):

| Month | Commits | Signal |
|-------|---------|--------|
| 2025-07 | 7 | Post-.NET 9 maintenance |
| 2025-08 | 0 | Summer lull |
| 2025-09 | 1 | Minimal activity |
| 2025-10 | 0 | Quiet |
| 2025-11 | 19 | .NET 10 upgrade + changelog |
| 2025-12 | 2 | Holiday slowdown |
| 2026-01 | 21 | Post-holiday acceleration |
| 2026-02 | 31 | Rebrand sprint (UISampleSpark) |
| 2026-03 | 34 | **Peak month** — security hardening |
| 2026-04 | 5 | Post-sprint cooldown |
| 2026-05 | 18 | Steady maintenance |
| 2026-06 | 21 | Full DevSpark lifecycle day |

The trajectory shows a classic "sprint-rest-sprint" pattern. November 2025 through March
2026 delivered **108 commits in five months** (21.6/month average) — nearly triple the
project's historical baseline. The April dip (5 commits) is a predictable recovery after
an intense March. May and June 2026 confirm the project has settled into a healthy
18–21 commit/month cadence rather than falling back to maintenance mode.

**Commit category distribution** (from subject analysis across 159 commits):

| Category | Count | % |
|----------|-------|---|
| Chore (tooling, deps) | 27 | 17.0% |
| Other / unclassified | 36 | 22.6% |
| Features | 23 | 14.5% |
| Fixes | 23 | 14.5% |
| Docs | 22 | 13.8% |
| CI/Build | 13 | 8.2% |
| Tests | 9 | 5.7% |
| Refactor | 6 | 3.8% |

The balance between features (14.5%) and fixes (14.5%) is healthy. Docs commits (13.8%)
reflect deliberate investment in the project's educational mandate. CI/build commits
(8.2%) indicate active pipeline maintenance — consistent with the `.github/workflows/`
hotspot analysis below.

### Contributor Dynamics

Four contributors were active in the twelve-month window:

| Role | Commits | Share | Likely Identity |
|------|---------|-------|-----------------|
| Lead Architect | 101 | 63.5% | Primary human developer |
| Developer A | 34 | 21.4% | Dependabot (automated dependency bumps) |
| Developer B | 19 | 11.9% | Secondary contributor or CI bot |
| Developer C | 5 | 3.1% | Occasional contributor |

Developer A's commit subjects (e.g., "deps: Bump dotnet-ef from 10.0.8 to 10.0.9") confirm
automated tooling. Stripping automation, the Lead Architect's effective share rises to
approximately **80%** of human-authored commits — a strong bus-factor signal.

Across all **748 total commits** over 7.2 years, the project has been a long-running
personal investment rather than a community project. The README credits the project as part
of the MakeBoldSpark portfolio of technical demonstrations, consistent with a single-author
educational reference.

### Quality Signals

Coverage from today's test run (2026-06-21):

| Metric | Value |
|--------|-------|
| Line coverage | **93.2%** (1,185/1,271 coverable lines) |
| Branch coverage | **79.6%** (333/418 branches) |
| Method coverage | **95.3%** (185/194 methods) |
| Full method coverage | **87.1%** (169/194 methods) |
| Total tests | **246** (240 Core + 6 UI) |
| Test files | 17 |
| Test-related commits (window) | 16 |

A 93.2% line coverage figure well exceeds the constitution's 25% baseline target and is
exceptional for an evolving codebase. The 79.6% branch coverage suggests some conditional
paths in utility code remain untested — a normal state and not a concern at this coverage
level.

**Conventional commit adoption**: 65 of 159 commits (40.9%) in the window follow strict
`type(scope): subject` format. The remaining commits use semantic prefixes informally (e.g.,
"Update modal dialog JS control"). The trend is toward higher adoption — recent commits show
consistent `fix:`, `feat:`, `chore:`, `docs:`, and `refactor:` prefixes.

### Governance & Process Maturity

| Signal | Value | Assessment |
|--------|-------|------------|
| Merged PRs (window) | 20 | 12.6% of commits via PR workflow |
| Constitution | Exists (v1.0.0, 2026-02-05) | ✅ 11 principles active |
| DevSpark version | v2.6.0 | ✅ Full lifecycle tooling |
| Active specs | 0 | ✅ Clean state (all archived) |
| Tagged releases | 1 (v10.2.0, 2026-06-21) | 🎉 First ever tag — milestone |
| Governance artifacts | 1 | Constitution only |
| Security scanning | CodeQL + Trivy weekly | ✅ Proactive |
| Dependency management | Dependabot active | ✅ Automated |

The 12.6% PR-based commit rate is lower than typical for team projects but expected for a
solo educational project where many changes are exploratory and fast. The 20 merged PRs
represent larger, more deliberate changes — feature additions, upgrades, and security fixes
— while the 80%+ direct-push commits represent iterative educational refinements.

The most significant governance event of the window: **v10.2.0 is the first semantically
tagged release** in the project's seven-year history. The March 2026 repo story explicitly
identified the absence of tagged releases as a gap. That gap has now been closed, complete
with a CHANGELOG, release notes, ADRs, and an archived documentation set — a full delivery
record.

### Architecture & Technology

The project is a polyglot .NET 10 solution with these primary layers:

| Component | Technology | Notes |
|-----------|------------|-------|
| Core library | C# (.NET 10), EF Core 10 | Repository pattern, DTO/Entity separation |
| Web UI | ASP.NET Core MVC, Razor Pages | Multi-UI showcase |
| Frontend demos | React, Vue, htmx, Blazor | Educational front-end variety |
| Minimal API | ASP.NET Core Minimal API | Migrated from controller-based today |
| Automation | PowerShell 7+ | DevSpark scripts, Docker Hub update |
| CI/CD | GitHub Actions | 3 required workflows per constitution |
| Containerization | Docker (Alpine, multi-stage) | Non-root user, port 8080 |

**Today's architectural consolidation** (2026-06-21) merged the `UISampleSpark.Data`
project into `UISampleSpark.Core`, eliminating a redundant project layer and simplifying
the dependency graph. This is the type of pragmatic refactoring that keeps an educational
project maintainable without over-engineering.

The file-type distribution in the window (`.md`=499 touches, `.cs`=354, `.csproj`=113,
`.cshtml`=112, `.ps1`=86) reveals a documentation-first culture: Markdown files are touched
more than any other type, consistent with an educational project that treats docs as a
first-class deliverable.

---

## Change Patterns

**Top 10 most-modified files** (all-time, from hotspot analysis):

| Rank | File | Changes | Interpretation |
|------|------|---------|----------------|
| 1 | `.github/workflows/docker-image.yml` | 26 | Active CI/CD tuning — most-evolved pipeline |
| 2 | `UISampleSpark.UI/UISampleSpark.UI.csproj` | 14 | Main app — frequent dependency and SDK updates |
| 3 | `UISampleSpark.MinimalApi/Program.cs` | 12 | Active API development hotspot |
| 4 | `UISampleSpark.Data.Tests/UISampleSpark.Data.Tests.csproj` | 12 | Test project evolution (now merged into Core.Tests) |
| 5 | `Mwh.Sample.Web/Mwh.Sample.Web.csproj` | 11 | Pre-rebrand project (legacy — retired) |
| 6 | `UISampleSpark.MinimalApi/UISampleSpark.MinimalApi.csproj` | 10 | SDK/dependency churn |
| 7 | `UISampleSpark.UI/Program.cs` | 10 | Application entry-point iteration |
| 8 | `UISampleSpark.Core.Tests/UISampleSpark.Core.Tests.csproj` | 10 | Test project evolution |
| 9 | `.github/workflows/test-build.yml` | 9 | CI build pipeline maintenance |
| 10 | `.github/workflows/main_samplecrud.yml` | 9 | Legacy Azure deployment workflow |

**Key observations**:

1. **CI/CD workflows dominate the top hotspot** (`.github/workflows/docker-image.yml`
   at 26 changes) — the Docker pipeline has been the most actively refined artifact in
   the repository. This reflects the educational project's emphasis on containerization
   as a teachable pattern.

2. **Project files are disproportionately hot** (`.csproj` files appear 5 times in the
   top 10) — expected given SDK upgrades (.NET 7→8→9→10), NuGet package churn via
   Dependabot, and the recent project consolidation.

3. **Legacy `Mwh.Sample.*` files in the hotspot list** confirm the transition from the
   pre-rebrand architecture. These files are now retired or renamed, meaning their
   historical change counts inflate the hotspot list but represent resolved complexity,
   not ongoing churn.

4. **`UISampleSpark.MinimalApi/Program.cs` (12 changes)** signals this file is a current
   active development zone. The Minimal API layer was refactored today (2026-06-21) as
   part of the controller-to-minimal migration — expect this count to continue rising.

5. **`README.md` appears at rank 13 (8 changes)** — eight deliberate updates to the
   project's front door reflect the educational mandate to keep documentation current.

**Directory-level patterns**: Approximately 30% of hotspot files sit under
`.github/workflows/` (CI), 45% under `UISampleSpark.*` projects (active code), and 25%
under legacy `Mwh.Sample.*` paths (retired). The ratio of active-to-retired hotspots
indicates successful architectural modernization.

---

## Milestone Timeline

| Date | Tag | Description |
|------|-----|-------------|
| 2026-06-21 | `v10.2.0` | First tagged release — Minimal API migration, Data/Core consolidation, DevSpark governance cycle complete |

**Context**: Prior to 2026-06-21, the repository had no tagged releases despite seven years
of commits. The March 2026 repo story flagged this absence as the project's most visible
governance gap. The v10.2.0 release closes that gap with a full delivery record:
CHANGELOG entry, ADRs (ADR-001 Data-Core consolidation, ADR-002 Swashbuckle→ApiTestSpark,
ADR-003 Minimal API migration), release notes, and a metrics snapshot.

Velocity surrounding the release: June 2026 opened with an intense single-day burst
(21 commits on 2026-06-21 alone) that compressed a full release lifecycle — consolidation,
packaging, audit, and remediation — into one session. This accelerated delivery pattern
is consistent with the March 2026 peak (34 commits) that preceded the rebrand milestone.

---

## Constitution Alignment

Constitution: `/.documentation/memory/constitution.md` v1.0.0 (2026-02-05), 11 principles.

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Code Quality & Safety | ✅ Strong | `Nullable=enable`, `AnalysisLevel=latest-all`; QUAL1 fixed today |
| II. Architecture & Design Patterns | ✅ Strong | Repository pattern enforced; ARCH1 ConfigureAwait fixed today |
| III. Error Handling & API Contracts | ✅ Strong | RFC 7807 ProblemDetails, global exception handler present |
| IV. Security Posture | ✅ Strong | No auth (educational intent); CodeQL + Trivy weekly; API key feature-flagged |
| V. Testing Standards | ✅ Exceptional | 246 tests, 93.2% line coverage (vs. 25% goal) |
| VI. CI/CD & DevOps | ✅ Strong | 3 workflows active; Docker image builds on every push |
| VII. Observability & Health | ✅ Strong | `/health`, `/status`, Swagger at `/swagger` |
| VIII. Documentation Standards | ✅ Strong | README updated 8× in window; CHANGELOG present; XML docs in place |
| IX. Dependency Management | ✅ Strong | Dependabot active; .NET 10 current; EF Core 10.0.9 |
| X. Docker & Containerization | ✅ Strong | Multi-stage Alpine builds, non-root user, port 8080, hadolint clean |
| XI. AI-Assisted Development | ✅ Strong | DevSpark v2.6.0; full lifecycle executed today |

**Alignment summary**: All 11 principles show active compliance signals in the commit
history. The two audit findings resolved today (ARCH1 + QUAL1) were the last known MUST
violations. The project enters v10.2.0 post-release in a fully compliant state against its
own constitution — a rare and significant governance milestone.

**Gap to watch**: The conventional commit adoption rate (40.9%) is below the ideal 80%+
for projects intending to use semantic versioning automation. As tagged releases become
more frequent, increasing adoption will reduce manual CHANGELOG maintenance effort.

---

## Developer FAQ

### What does this project do?

UISampleSpark is an educational reference implementation showing how to build the same
CRUD feature — an employee management system — across multiple front-end UI technologies
(MVC, Razor Pages, React, Vue, htmx, Blazor) in a single ASP.NET Core application. It is
not a production system; it deliberately omits authentication to keep the focus on UI
patterns. Live at [ui.makeboldspark.com](https://ui.makeboldspark.com).

### What tech stack does it use?

The primary language is **C# on .NET 10** (SDK pinned in `global.json`). The backend uses
ASP.NET Core with EF Core 10.0.9 (in-memory database for demos) and a Minimal API layer.
Front-end demos embed **React**, **Vue**, **htmx**, and **Blazor** within the same host.
**JavaScript** and **TypeScript** appear in front-end bundles. **PowerShell** drives
DevSpark automation scripts. **Docker** packages the app for deployment; **GitHub Actions**
handles CI/CD.

### Where do I start?

Open `UISampleSpark.UI/Program.cs` — it is the application entry point and has 10 hotspot
changes, making it the most actively iterated file in the main project. The solution file
`UISampleSpark.sln` ties together Core, UI, MinimalApi, CLI, and test projects. Read
`README.md` for feature orientation and `/.documentation/memory/constitution.md` for
architectural ground rules.

### How do I run it locally?

```bash
git clone https://github.com/markhazleton/UISampleSpark.git
cd UISampleSpark
dotnet run --project UISampleSpark.UI
```

Visit `https://localhost:5001`. Requires .NET 10 SDK (see `global.json` for exact version).
Alternatively: `docker build -t uisamplespark ./UISampleSpark.UI && docker run -p 8080:80 uisamplespark`.

### How do I run the tests?

```bash
dotnet test UISampleSpark.sln
```

The test suite has **246 tests** across two projects (`UISampleSpark.Core.Tests/`,
`UISampleSpark.UI.Tests/`) using **MSTest**. All tests follow the Arrange-Act-Assert
pattern. Test files are named `*Test.cs` or `*Tests.cs`. Line coverage is 93.2%.

### What is the branching/PR workflow?

The project pushes most commits directly to `main` — appropriate for a solo educational
project. Larger changes go through PRs: 20 merged PRs in the last 12 months represent
dependency upgrades, feature additions, and security fixes. Conventional commit prefixes
(`feat:`, `fix:`, `chore:`, `docs:`) are used for ~41% of commits; the trend is toward
higher adoption. Direct pushes bypass the branch-protection rule warning visible in `git push`
output ("Bypassed rule violations for refs/heads/main").

### Who do I ask when I'm stuck?

The **Lead Architect** authored 101 of 159 window commits (63.5%) and drives all
architectural decisions. The README credits [Mark Hazleton](https://markhazleton.com) as
the project's Technical Solutions Architect. For questions, open a GitHub issue or PR on
`markhazleton/UISampleSpark`.

### What areas of the code change most often?

Top three hotspots: **`.github/workflows/docker-image.yml`** (26 all-time changes) is the
most-evolved CI artifact — expect it to reflect the current Docker/deployment strategy.
**`UISampleSpark.UI/UISampleSpark.UI.csproj`** (14 changes) and **`UISampleSpark.MinimalApi/Program.cs`** (12 changes) are the active code hotspots. The `UISampleSpark.MinimalApi/`
directory is a current development zone following today's controller-to-minimal migration.

### Are there coding standards I must follow?

Yes — see `/.documentation/memory/constitution.md` for the authoritative 11-principle
standard. Key rules: `Nullable=enable` and `AnalysisLevel=latest-all` in all projects;
repository pattern with interfaces; no raw SQL (EF Core LINQ only); `.ConfigureAwait(false)`
on all async calls in library code; MSTest with Arrange-Act-Assert; Alpine Docker images
with non-root user; conventional commits encouraged. Security warnings (CA5xxx, CA3xxx) must
never be suppressed.

### What version is currently released?

**v10.2.0**, tagged 2026-06-21. This is the project's first semantically versioned release
in its seven-year history. It captures the Minimal API migration, Data-Core project
consolidation, EF Core 10.0.9 dependency update, and DevSpark governance compliance fixes.
Release notes at `.documentation/releases/v10.2.0/release-notes.md`.

---

*Generated by `/devspark.repo-story` | DevSpark v2.6.0*
