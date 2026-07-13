# UISampleSpark

**Live Site**: [ui.makeboldspark.com](https://ui.makeboldspark.com)

A .NET 10 (ASP.NET Core) application exploring multiple front-end technologies for building modern web user interfaces. This repository is an educational reference that compares UI patterns — MVC, Razor Pages, React, Vue, htmx, Blazor, and vanilla JavaScript SPA — using a common Employee/Department domain, with theming, containerization, and deployment examples.

[![Docker Image](https://github.com/markhazleton/UISampleSpark/actions/workflows/docker-image.yml/badge.svg)](https://github.com/markhazleton/UISampleSpark/actions/workflows/docker-image.yml)
[![CodeQL](https://github.com/markhazleton/UISampleSpark/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/markhazleton/UISampleSpark/actions/workflows/codeql-analysis.yml)

---
## About

UISampleSpark demonstrates how the same Employee/Department CRUD domain can be implemented across seven distinct front-end UI patterns — MVC, Razor Pages, jQuery AJAX, React, Vue, htmx, and Blazor — within a single ASP.NET Core application. It covers theming, containerization, REST APIs, and CI/CD.

Live site: [ui.makeboldspark.com](https://ui.makeboldspark.com)

> Built by [Mark Hazleton](https://markhazleton.com) — Technical Solutions Architect
> Part of the [MakeBoldSpark](https://makeboldspark.com) portfolio of technical demonstrations.

---
## Project History
- **2019** – Launched the repository with the first MVC walkthrough using AJAX partials, and set the contributor/code-of-conduct foundation.
- **2020** – Experimented with React and Blazor front ends, standardized REST/SOAP client abstractions, and stood up Azure Pipelines plus App Service deployments.
- **2021** – Completed the .NET 5→6 modernization, layered in Bootstrap 5 theming, hardened CI/CD (GitHub Actions + Azure Pipelines), and increased automated tests.
- **2022-2023** – Adopted .NET 7 then .NET 8, added TreeView/PivotTable demos, refined guard clauses and validation, and expanded Docker/Azure Linux automation.
- **2024-2025** – Introduced the minimal API sample, Aspire experiments, Bootswatch theme switching, extensive workflow tuning, and the .NET 9 then .NET 10 migrations.
- **Tagging** – Milestones in the [CHANGELOG](CHANGELOG.md) include suggested tags (e.g., `net10-ga`, `ui-bootswatch-switcher`) you can apply in git for quick navigation.

See the [CHANGELOG](CHANGELOG.md) for the full milestone timeline, and open `reports/git-spark-report.html` to explore commit velocity visualized by Mark Hazleton's `git-spark` npm package.

---
## Live Deployments
- Live Site: https://ui.makeboldspark.com
- Docker Hub Image: https://hub.docker.com/r/markhazleton/uisamplespark

---
## Goals
- Compare multiple front-end UI technologies side-by-side
- Showcase clean architecture, DI, and unit testing
- Provide examples of theming and UX enhancements
- Show Azure deployment and containerization approaches

---
## Features & Architecture
- UI Patterns:
  - MVC Controllers & Views — traditional multi-view pattern (`/MvcEmployee`)
  - jQuery AJAX + Partial Views — modal-based UI without full page reloads (`/Employee`)
  - Razor Pages — page-centric model (`/EmployeeRazor`)
  - Single Page Application (SPA) — JavaScript/AJAX with DataTables and REST API (`/EmployeeSinglePage`)
  - React SPA — component-based UI with React 18, hooks, and Fetch API (`/EmployeeReact`)
  - Vue SPA — reactive UI with Vue 3 Composition API (`/EmployeeVue`)
  - htmx — server-driven hypermedia with HTML-over-the-wire (`/EmployeeHtmx`)
  - Blazor Server — real-time C# components via SignalR (`/EmployeeBlazor`)
  - Pivot Table reporting — data analysis with PivotTable.js (`/EmployeePivot`)
- API Endpoints:
  - REST endpoints for Employees & Departments (Swagger/OpenAPI enabled)
- Theming & UX:
  - Bootswatch theme switcher (light/dark, instant swap)
  - Bootstrap 5 + Bootstrap Icons
  - Modal-based forms
- Data Layer:
  - In-memory EF Core database (EmployeeContext)
  - Repository/service pattern via `IEmployeeService` & `EmployeeDatabaseService`
- Observability & Health:
  - Application Insights telemetry
  - Health checks at `/health`
- DevOps & CI/CD:
  - GitHub Actions: build, test, Docker image push
  - Dockerfile for container builds
- Testing:
  - Domain & Repository unit test projects

---
## Technology Stack
- .NET 10 / C#
- ASP.NET Core MVC & Razor Pages
- React 18 (CDN + Babel standalone for in-browser JSX)
- Entity Framework Core (InMemory & SqlServer packages referenced for future use)
- Swashbuckle (Swagger/OpenAPI)
- Bootswatch theming (WebSpark.Bootswatch & WebSpark.HttpClientUtility)
- Markdown rendering (Westwind.AspNetCore.Markdown)

---
## HttpClient Usage
HttpClient is utilized via `WebSpark.HttpClientUtility` package which provides `IHttpRequestResultService` for making HTTP requests. This is actively used by `WebSpark.Bootswatch` to fetch Bootswatch theme data from CDN sources, enabling the dynamic theme switcher functionality. The base `AddHttpClient()` factory registration is also available for future external API integrations.

---
## Getting Started
### Prerequisites
- .NET 10 SDK
- (Optional) Docker

### Run Locally
```pwsh
git clone https://github.com/markhazleton/UISampleSpark.git
cd UISampleSpark
 dotnet restore
 cd UISampleSpark.UI
 dotnet run
```
Visit https://localhost:5001

### Run with Docker
```pwsh
docker build -t uisamplespark ./UISampleSpark.UI
docker run -p 8080:80 uisamplespark
```

---
## Project Structure
```
UISampleSpark.UI/              Web application (MVC, Razor Pages, React, Vue, htmx, Blazor)
UISampleSpark.Core/           Domain models (Employee/Department DTOs, responses)
UISampleSpark.Data/       EF Core context, service implementations, mock generator
UISampleSpark.Core.Tests/     Unit tests for domain logic
UISampleSpark.Data.Tests/ Unit tests for repository/service layer
UISampleSpark.CLI/          Console app seeding & demonstration (SQLite EF example)
```
(There is no HttpClientFactory sample project; previous reference removed.)

---
## Data Model
Employees belong to Departments. Each UI pattern implements the same operations — create, read, update, delete — demonstrating validation, paging (`PagingParameterModel`), and simple relationships.

---
## Swagger/OpenAPI
Interactive API docs available at `/swagger` when running locally or deployed.

---
## API Access Keys
API endpoints are protected by a lightweight API key check.

- Contact Mark Hazleton if you would like an API key for access.
- Send the key using header `X-API-Key`.
- Configuration supports multiple keys via `ApiSecurity:ApiKeys`.
- The repository starts with 10 configured key slots (`ApiKeys[0]` through `ApiKeys[9]`).

Example request:
```pwsh
curl -H "X-API-Key: <your-key>" https://localhost:5001/api/employee
```

---
## Theme Switching
Implemented via Bootswatch services and `<bootswatch-theme-switcher />` integration.

---
## Health & Status
- `/health` returns liveness status
- `/status` provides application metadata

---

## Repo Story

An evidence-based narrative of this repository's development history, contributor patterns,
and architecture:
[Repo Story (2026-06-21)](.archive/2026-07-12/.documentation/repo-story/repo-story-2026-06-21.md)

---
## Contributing
Contributions welcome. Submit issues or PRs.

---
## License
MIT License © 2018-2025 Mark Hazleton
See `LICENSE` for details.
