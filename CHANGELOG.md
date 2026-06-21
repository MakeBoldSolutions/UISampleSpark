# Changelog

This document captures notable milestones extracted from the git history of `UISampleSpark`. For visual commit-density analytics generated with the Mark Hazleton `git-spark` npm package, open `reports/git-spark-report.html` in a browser.

## 2026

### v10.2.0 — Consolidation & Vanilla JS Expansion *(Tag: v10.2.0, Jun 21 2026)*

A consolidation and feature-expansion release delivering Data-Core project merge, OpenAPI
tooling modernisation, Minimal API migration, and a new Vanilla JS employee CRUD demo.

#### Added

- **Vanilla JS Employee CRUD** (`/EmployeeVanilla`): Pure vanilla JavaScript implementation
  with native Fetch API, DOM manipulation, and Bootstrap 5 modals — no framework dependencies.
- **Make Bold Solutions Branding**: Updated site-wide branding and identity.
- **Sync-Upstream Script**: `sync-upstream.ps1` helper for fork contributors to rebase against upstream.

#### Changed

- **Data-Core Consolidation**: Merged `UISampleSpark.Data` project into `UISampleSpark.Core`,
  reducing the solution from 5 to 4 projects (see [ADR-001](.documentation/decisions/ADR-001.md)).
- **OpenAPI Tooling**: Replaced `Swashbuckle.AspNetCore` with `Microsoft.AspNetCore.OpenApi`
  (built-in) and `ApiTestSpark` — eliminates CVE-flagged dependency
  (see [ADR-002](.documentation/decisions/ADR-002.md)).
- **Minimal API Migration**: Replaced `[ApiController]` MVC controllers in `UISampleSpark.UI`
  with Minimal API endpoint registrations (see [ADR-003](.documentation/decisions/ADR-003.md)).
- **Paging Parameters**: Made nullable with sensible default fallbacks.
- **API Documentation**: Enhanced endpoint descriptions and OpenAPI metadata.
- **Code Refactoring**: Improved readability; resolved all `latest-all` analyzer warnings.

#### Fixed

- **noindex Policy**: Enforced and hardened SEO noindex verification.
- **API Filters/Endpoints**: Hardened endpoint validation and filter logic.
- **React/Babel CDN Pins**: Pinned versions to prevent silent upstream CDN breakage.

#### Architectural Decisions

- **ADR-001**: Data-Core Project Consolidation
- **ADR-002**: OpenAPI Tooling Migration — Swashbuckle to ApiTestSpark
- **ADR-003**: Minimal API Migration in UISampleSpark.UI Host

#### Dependencies

- `Microsoft.EntityFrameworkCore.*` → 10.0.9
- `coverlet.collector` → 10.0.0
- `Westwind.AspNetCore.Markdown` → 3.41.0
- `datatables.net-bs5` → 2.3.8
- `actions/checkout` → v6 · `actions/github-script` → v9

#### Contributors

- Mark Hazleton
- dependabot[bot]

---

### v10.0.1 — .NET 10 Refresh *(Tag: v10.0.1, Mar 28 2026)*

A comprehensive hardening, governance, and multi-UI expansion release building on the .NET 10 migration.

#### Security & Hardening

- Resolved **109 CodeQL security alerts** across the codebase
- Added **per-IP rate limiting** (100 req/min) to both MVC/API and Minimal API hosts
- Added **feature-flagged multi-key API protection** on Minimal API endpoints
- Hardened controller request validation (path traversal, input sanitization)
- Fixed path-join handling in BaseController upload helper
- Added `IExceptionHandler` with RFC 7807 `ProblemDetails` to Minimal API host

#### Architecture & Quality

- Added `/health` endpoint and always-on Swagger to Minimal API (Principle VII compliance)
- Elevated `AnalysisLevel` to `latest-all` across all projects including test projects (Principle I compliance)
- Resolved stale TODO in EmployeeMock and improved mock implementation comments
- Full constitution compliance audit — 82% → all 5 findings remediated

#### Multi-UI Front-Ends

- **React 18** Employee CRUD (`/EmployeeReact`) with hooks, Fetch API, sortable columns, pagination, modal forms, and toast notifications
- **htmx** Employee CRUD with server-driven partial updates
- **Vue 3** Employee CRUD with reactive data binding
- **Blazor** interactive Employee CRUD components

#### Governance & Documentation

- Ratified **project constitution v1.0.0** (11 core principles, Feb 2026)
- Rebranded from SampleMvcCRUD to **UISampleSpark** with modernized project structure
- Added repository story narrative (703 commits, 7 years of history)
- Added Docker Hub README and publishing script
- Integrated Spec Kit Spark agent workflows (archive, harvest, upgrade, site-audit, repo-story)

#### Dependencies & CI/CD

- `Swashbuckle.AspNetCore` → 10.1.7
- `WebSpark.HttpClientUtility` → 2.5.0
- `coverlet.collector` → 8.0.1
- `dotnet-ef` → 10.0.5
- `SkiaSharp` and Azure container tooling refreshed
- GitHub Actions: `docker/build-push-action` v7, `docker/login-action` v4, `docker/setup-qemu-action` v4, `docker/metadata-action` v6, `actions/upload-artifact` v7
- Fixed Docker PR tag generation and Buildx action updates
- Made Application Insights telemetry optional

#### Tests

- **240 tests passing** (0 failures) across Core.Tests and Data.Tests
- Sampled coverage: StringExtensions 100%, EmployeeDto 91%, EmployeeDatabaseService 93.5%

---

- **Mar 24-28** – Hardened API surfaces with per-IP rate limiting in both MVC/API and Minimal API hosts, added feature-flagged multi-key API protection, and reduced CodeQL findings with targeted source fixes. Also refreshed key dependencies (`Swashbuckle.AspNetCore` 10.1.7, `coverlet.collector` 8.0.1, `WebSpark.HttpClientUtility` 2.5.0) and added Speckit archive/harvest/upgrade agent workflow assets.
- **Feb 6** – Added a React 18 Employee CRUD implementation (`/EmployeeReact`) with functional components, hooks, and Fetch API. Introduced a dedicated `_LayoutReact.cshtml` layout loading React/Babel via CDN to isolate from jQuery-based pages. Features include sortable columns, search/filter, pagination, modal forms with Bootstrap 5 validation, delete confirmation dialog, and toast notifications.

## 2025

- **Nov 16** *(Tag: net10-ga)* – Migrated the solution to .NET 10.0, refactored project structure, hardened Docker and GitHub Actions workflows, and replaced `System.Drawing` with SkiaSharp for cross-platform image processing.
- **Sep 7** – Performed a dependency refresh across all projects to prepare for the upcoming .NET 10 upgrade window.
- **Jul 28** *(Tag: docker-hardening-2025)* – Tuned Docker linting with a `.hadolint.yaml`, strengthened Dockerfile scripting, refreshed breadcrumb/navigation UX, and expanded SEO and favicon assets.
- **May 24-25** *(Tag: ui-bootswatch-switcher)* – Delivered the Bootswatch-powered runtime theme switcher, extended HTTP client utilities, polished README deployment guidance, and finalized the theming experience.
- **Apr 17-22** *(Tag: azure-workflows-2025)* – Added Azure App Service deploy workflows with explicit permissions, enabled npm inside the Docker image build pipeline, and realigned UI elements for consistency.
- **Jan 20** – Updated project documentation to reflect architecture changes heading into the 2025 roadmap.

## 2024

- **Sep 20-24** *(Tag: net9-ga)* – Upgraded the application stack to .NET 9.0, refreshed Razor Pages, tuned Docker/GitHub workflows, and synchronized versioning across projects.
- **Aug 3-27** – Iterated on CI configuration while applying scheduled NuGet maintenance for solution stability.
- **May 2-29** – Removed Aspire hosting artifacts, reorganized project structure, merged Dependabot dependency bumps, and simplified deployment workflows.
- **Apr 11-12** – Accepted OpenTelemetry instrumentation updates via Dependabot to maintain observability parity.
- **Mar 12-28** – Introduced the minimal API sample project, added new endpoints, synchronized documentation for MarkHazleton.com, and reconciled long-running branches.
- **Feb 12-Mar 6** – Modernized LibMan/NuGet dependencies while experimenting with Azure App Service workflows.
- **Jan 24-Feb 13** – Added the AspireHost project and continued dependency maintenance to support future cloud scenarios.

## 2023

- **Oct 22** *(Tag: net8-ga)* – Completed the .NET 8 migration, streamlined Swagger integration, and modernized Docker automation.
- **Oct 9** – Established Azure Pipelines CI, reconciled `global.json`, addressed EF Core unit test regressions, and harmonized GitHub workflows.
- **Sep 8-25** – Improved employee data integrity (gender fixes), refreshed dependencies, and standardized Razor Page experiences.
- **Jul 26-30** – Expanded domain models with gender metadata, updated packages, and refined JavaScript clients alongside preview .NET 8 changes.
- **May-Jun** – Continued sweeping dependency updates while expanding unit tests for repository and domain layers.
- **Mar-Apr** – Introduced Swagger styling, merged iterative NuGet updates, and documented new HTTP request samples for API testing.

## 2022

- **Nov 8** *(Tag: net7-ga)* – Upgraded the solution to .NET 7, refreshed publish profiles, and tuned Docker support for Linux-based hosting.
- **Oct 1-26** – Added the `TreeNode` hierarchy helpers, hardened guard clauses, and continued documentation and README improvements.
- **Sep 17-22** – Strengthened DTO validation, resolved nullability warnings, increased unit test coverage, and refined Ajax workflows.
- **Aug 14-23** – Delivered PivotTable.js reporting demos, refined Swagger configuration, and added Azure Linux App Service deployment automation.
- **May 11-18** – Added Docker support, introduced database client logic for container scenarios, and iterated on issue templates and CI pipelines.
- **Apr 22-30** – Standardized naming conventions, fixed navigation issues, and created Docker image workflows for repeatable builds.

- **Nov 10-16** *(Tag: net6-ga)* – Migrated to .NET 6, restructured solutions, introduced Azure Key Vault integration, and activated CI/CD across GitHub Actions and Azure Pipelines.
- **Jun 2-27** – Upgraded to Bootstrap 5 with dynamic versioning, streamlined pipelines, and updated telemetry configuration.
- **May 27-29** – Consolidated the .NET 5 modernization work, strengthened Azure Pipeline automation, and expanded automated test coverage.
- **Mar 23-24** – Established multi-solution CI pipelines, added Code Analysis tooling, and increased controller-level tests.
- **Jan 9-26** – Refined publishing to Azure, standardized versioning, and continued NuGet maintenance as the solution stabilized on .NET 5.

- **Oct 1-20** – Enhanced code analysis, added employee API unit tests, and synchronized Azure pipeline definitions across solutions.
- **Jul 28-30** – Upgraded legacy projects to .NET 4.8, introduced CodeQL analysis, and strengthened REST client abstractions and documentation.
- **May 1-3** – Added the React sample application, kicked off a modernized employee CRUD flow, and refreshed dependencies.
- **Apr 4-13** – Expanded repository/service layers, added Blazor demos, standardized SOAP/REST implementations, and addressed cross-project linting.
- **Apr 5-7** – Established Azure App Service deployment automation, unified API usage across solutions, and refactored shared components.
- **Mar 23-Apr 3** – Added MVC automation tests, increased code coverage, and refactored pipeline scripts following early CI/CD experiments.

- **Nov 10-13** *(Tag: swagger-ci-foundation)* – Enabled Swagger-driven APIs, wired Azure Pipelines CI, and broadened automated testing baselines.
- **Jul 11** – Introduced the React front-end, added security documentation, and harmonized `develop` and `master` branches.
- **Apr 25-27** – Implemented the initial MVC CRUD experience with AJAX-powered forms, navigation scaffolding, and early README guidance.
- **Apr 25** – Seeded the repository with the original ASP.NET MVC CRUD sample, contributor docs, and solution metadata.
