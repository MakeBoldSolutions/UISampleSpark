# .NET + ASP.NET Core Risk Checklist

## Async & Threading

- [ ] **`async` all the way down** — no `.Result` / `.Wait()` on async calls; no `async void` outside event handlers
- [ ] **`ConfigureAwait(false)` on library code** to avoid sync-context capture
- [ ] **`CancellationToken` plumbed through controllers, handlers, and EF queries**

## Persistence

- [ ] **EF Core query audit** — `AsNoTracking()` on reads, projection to DTOs, no client-side evaluation surprises
- [ ] **DbContext pooling configured** — `AddDbContextPool` with reviewed pool size
- [ ] **Migrations have rollback or forward-fix plan**

## Pipeline & Errors

- [ ] **Centralized exception middleware** — e.g., `UseExceptionHandler` with problem-detail responses
- [ ] **Options validated at startup** — `ValidateOnStart`, `IValidateOptions`
- [ ] **Health checks distinct for liveness vs readiness** — `MapHealthChecks` with tags

## Security & Build

- [ ] **Antiforgery on cookie-auth POST endpoints**
- [ ] **Secrets in user-secrets/Key Vault**, not `appsettings.json`
- [ ] **NuGet audit gate** — `dotnet list package --vulnerable`, Dependabot
