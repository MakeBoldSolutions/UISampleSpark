1. **Nullable reference types are mandatory** — all projects enable `<Nullable>enable</Nullable>`, no project opts back into implicit non-null.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

2. **Latest C# language version** — all projects use `<LangVersion>latest</LangVersion>`.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

3. **Full code analysis** — all projects enable `<AnalysisLevel>latest-all</AnalysisLevel>` with .NET analyzers; CA5xxx/CA3xxx security warnings are never suppressed.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

4. **Implicit usings via GlobalUsings.cs** — all projects enable `<ImplicitUsings>enable</ImplicitUsings>` with a `GlobalUsings.cs`.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

5. **Repository pattern for all data access** — data access goes through interfaces (e.g. `IEmployeeService`, `IEmployeeClient`); raw SQL (`FromSqlRaw`/`ExecuteSqlRaw`) is prohibited in favor of EF Core LINQ.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

6. **DTO/Entity separation** — DTOs (e.g. `EmployeeDto`) are always separate from EF entities (e.g. `Employee`).
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

7. **Dependency injection everywhere** — all services are registered in DI and injected via constructors; all I/O is async/await; Domain and Repository layers use `ConfigureAwait(false)`.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

8. **RFC 7807 error contracts** — a global exception handler catches unhandled exceptions; API errors return ProblemDetails; controllers return proper HTTP status codes via `ActionResult<T>`/`IActionResult`.
   <!-- source: migrated(constitution.md) -->
   **Status**: enforced

9. **Educational security scope — no authentication by design** — this is an educational reference project; auth/authorization is intentionally omitted, but README/SECURITY.md must state "not production-ready," CodeQL + Trivy scans run on every commit, HTTPS is enforced outside development, and secrets never live in code (User Secrets in dev, environment variables in prod).
   <!-- source: migrated(constitution.md) -->
   **Status**: adopting

10. **MSTest with 25% coverage baseline** — test projects use MSTest, files are named `*Test.cs`/`*Tests.cs`, and tests follow Arrange-Act-Assert; 25% coverage is a baseline goal, not a hard gate.
    <!-- source: migrated(constitution.md) -->
    **Status**: adopting

11. **Three required CI/CD workflows** — Test & Build (PRs and pushes to main), Security Scanning (CodeQL + Trivy, weekly), and Docker Build & Push (multi-stage, push to Docker Hub on main).
    <!-- source: migrated(constitution.md) -->
    **Status**: enforced

12. **Basic observability** — a `/health` endpoint and Swagger/OpenAPI docs at `/swagger` are expected; structured logging via `ILogger<T>` and Application Insights are encouraged but not required.
    <!-- source: migrated(constitution.md) -->
    **Status**: adopting

13. **Documentation upkeep** — README.md stays current with features and deployment instructions; CHANGELOG.md, XML doc comments on public APIs, and descriptive Swagger metadata are encouraged.
    <!-- source: migrated(constitution.md) -->
    **Status**: adopting

14. **.NET 10, updated quarterly** — projects target the latest .NET version (currently .NET 10) via `global.json`; NuGet packages are encouraged to update quarterly via Dependabot.
    <!-- source: migrated(constitution.md) -->
    **Status**: enforced

15. **Docker: multi-stage, Alpine, non-root, hadolint-clean** — Dockerfiles use multi-stage builds, prefer Alpine base images, run aggressive package updates, run as non-root, and pass hadolint (documented exceptions allowed).
    <!-- source: migrated(constitution.md) -->
    **Status**: enforced

16. **AI-generated artifacts stay out of source directories** — session work, drafts, and audit reports produced by AI/Copilot tooling are organized separately from source code, never mixed into the project root.
    <!-- source: migrated(constitution.md) -->
    **Status**: enforced

17. **Priority order: Security > Correctness > Educational Value > Performance > Cosmetics.**
    <!-- source: migrated(constitution.md) -->
    **Status**: enforced
