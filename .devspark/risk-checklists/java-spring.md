# Java + Spring Boot Risk Checklist

## Persistence

- [ ] **Explicit `@Transactional` boundaries** on service methods; default propagation reviewed
- [ ] **N+1 query audit on JPA/Hibernate associations** — e.g., `@EntityGraph`, fetch joins, Hibernate stats in tests
- [ ] **Connection pool tuned for load** — e.g., HikariCP `maximumPoolSize`, `connectionTimeout`, `leakDetectionThreshold`

## Async & Threading

- [ ] **Custom `TaskExecutor` for `@Async`** (no shared default pool)
- [ ] **Reactor schedulers chosen per workload** (parallel vs boundedElastic) when using WebFlux
- [ ] **Blocking calls isolated from event-loop threads** in WebFlux

## Operations

- [ ] **Actuator endpoints exposed and secured** — health, info, metrics, prometheus
- [ ] **Centralized exception handling** — e.g., `@ControllerAdvice` with problem-detail responses
- [ ] **Configuration externalized via Spring Config / vault**, not bundled in JAR

## Build

- [ ] **Dependency vulnerability gate** — e.g., OWASP dependency-check, Snyk, Dependabot
- [ ] **Reproducible build** — e.g., `maven-enforcer` lock, pinned plugin versions
