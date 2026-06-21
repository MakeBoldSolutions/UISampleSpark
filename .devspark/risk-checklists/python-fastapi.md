# Python + FastAPI / Django Risk Checklist

## Async Runtime

- [ ] **No blocking I/O on async paths** (sync DB drivers, sync HTTP clients, `time.sleep`) — e.g., asyncpg vs psycopg2, httpx-async vs requests, `asyncio.sleep`
- [ ] **Async DB driver matches runtime** — e.g., asyncpg/aiomysql/motor on FastAPI; sync drivers only on Django sync views
- [ ] **CPU-bound work offloaded to executor or worker** — e.g., `run_in_executor`, Celery, RQ, Dramatiq
- [ ] **Lifespan/startup events manage pooled resources** — e.g., FastAPI `lifespan`, Django app ready hooks

## Validation & Serialization

- [ ] **Boundary models constrain types AND values** (regex, ranges, max lengths) — e.g., Pydantic `Field(..., max_length=...)`, Django form/serializer validators
- [ ] **Response models prevent over-fetching** — e.g., FastAPI `response_model`, DRF serializer field allowlists

## Configuration & Build

- [ ] **Debug/dev mode disabled in production config** — e.g., `DEBUG=False`, `--reload` only locally
- [ ] **Type-checking gate in CI** — e.g., mypy, pyright with non-zero exit on regression
- [ ] **Pinned & hashed dependencies** — e.g., `pip-tools`/`uv` lockfile, `--require-hashes`

## Operational

- [ ] **Long-running work uses a durable queue with retry semantics** — e.g., Celery, RQ, Dramatiq, arq (not `BackgroundTasks` for anything that must complete)
- [ ] **DB migrations have a rollback or forward-fix plan** — e.g., Alembic down-revisions, Django reversible migrations
