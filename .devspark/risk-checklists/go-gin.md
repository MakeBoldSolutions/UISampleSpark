# Go (Gin / Fiber / chi / Echo) Risk Checklist

## Concurrency

- [ ] **No goroutine leaks** — e.g., bounded with `errgroup`, lifecycle tied to `context.Context`
- [ ] **`context.Context` plumbed through call chains** for cancellation and deadlines
- [ ] **Channels have explicit close ownership** and selects handle `<-ctx.Done()`

## Resources

- [ ] **DB connection pool tuned** — e.g., `sql.DB.SetMaxOpenConns/MaxIdleConns/ConnMaxLifetime`
- [ ] **HTTP client has timeout AND transport configured** (no `http.DefaultClient` for external calls)
- [ ] **`defer rows.Close()` / `defer resp.Body.Close()` on every error path**

## Errors & Logging

- [ ] **Errors wrapped with `%w` and inspected with `errors.Is/As`**, not stringly-compared
- [ ] **Structured logging** — e.g., zap, zerolog, slog
- [ ] **No silent error returns** at handler boundary (every non-nil error reaches a logger or response)

## Build

- [ ] **Race detector run in CI** (`go test -race`)
- [ ] **`govulncheck` or equivalent supply-chain scan in CI**
