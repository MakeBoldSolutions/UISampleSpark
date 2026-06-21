# Web Service Risk Checklist

Applies when archetype = `web-service`. Pair with the relevant stack file (`python-fastapi.md`, `node-express.md`, etc.).

## Transport & Edge

- [ ] **CORS policy explicit and minimal** — e.g., FastAPI `CORSMiddleware`, Express `cors`, Spring `CorsConfigurationSource`, ASP.NET `UseCors`
- [ ] **HTTPS enforced end-to-end** (TLS termination + HSTS) — e.g., ingress/reverse-proxy config, `Strict-Transport-Security`
- [ ] **Security headers set** (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy) — e.g., `helmet`, Spring Security headers, ASP.NET `UseHsts`
- [ ] **Request size limits** on body and multipart — e.g., FastAPI/Starlette limits, `body-parser` limit, Spring `multipart.max-file-size`
- [ ] **Request/response logging redacts PII and secrets** — e.g., structured-log scrubbers, OTel attribute filters

## API Contract

- [ ] **Explicit API versioning strategy** (URI, header, or media-type) with deprecation policy
- [ ] **Schema-validated request bodies** at the boundary — e.g., Pydantic, Zod, Joi, FluentValidation, Bean Validation
- [ ] **Pagination/cursor model for list endpoints** (no unbounded responses) — e.g., cursor pagination, `limit`/`offset` with ceilings
- [ ] **Idempotency keys on unsafe operations exposed to clients** — e.g., POST that retries from mobile, payment intents

## Liveness, Readiness, Observability

- [ ] **Liveness and readiness signals distinct and meaningful** — e.g., k8s probes, ECS health checks, App Service health checks
- [ ] **Structured logs + trace correlation** — e.g., OpenTelemetry, Serilog, Zap, Bunyan, Logback JSON
- [ ] **RED/USE metrics on every endpoint** — e.g., Prometheus, Datadog, App Insights, CloudWatch

## Auth & Rate Limiting

- [ ] **Rate limiting on auth/credential endpoints** — e.g., slowapi, express-rate-limit, bucket4j, AspNetCoreRateLimit
- [ ] **Session/token rotation and revocation path** — e.g., refresh-token rotation, JWT denylist, opaque session store
