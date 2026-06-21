# Node.js + Express / Next.js / NestJS Risk Checklist

## Promise & Error Handling

- [ ] **No unhandled promise rejections** — e.g., async error middleware, `express-async-errors`, NestJS exception filters
- [ ] **Process-level handlers for `unhandledRejection` / `uncaughtException`** that log and exit
- [ ] **Errors propagate with structured cause** (no swallowed `.catch(() => {})`)

## Concurrency & Resources

- [ ] **Connection pool size configured for runtime** — e.g., `pg` Pool, `mysql2/promise`, MongoDB driver `maxPoolSize`
- [ ] **HTTP client timeouts AND keepAlive agent** — e.g., `undici`/`axios` timeout, `http.Agent({ keepAlive: true })`
- [ ] **Streaming for large payloads** (no full buffering) — e.g., `pipeline()`, response streaming

## Build & Type Safety

- [ ] **TypeScript `strict: true`** with `noUncheckedIndexedAccess` where feasible
- [ ] **Pinned lockfile, audit gate in CI** — e.g., `npm ci`, `npm audit --audit-level=high`, Snyk/Dependabot

## Runtime

- [ ] **Process supervisor / clustering** — e.g., PM2 cluster mode, Node.js `cluster`, container orchestrator replicas
- [ ] **Graceful shutdown** drains in-flight requests on SIGTERM
- [ ] **CORS configured per route**, not globally wide-open
