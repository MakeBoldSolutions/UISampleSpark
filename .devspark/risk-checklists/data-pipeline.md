# Data Pipeline Risk Checklist

## Delivery Semantics

- [ ] **Idempotency strategy declared per task** (natural key, dedup window, upsert)
- [ ] **At-least-once vs exactly-once explicit and enforced** — e.g., Kafka transactions, Spark checkpointing, Beam Dataflow shuffle
- [ ] **Late / out-of-order data handling** — watermarks, allowed lateness, side outputs

## Schema & Data Quality

- [ ] **Schema evolution policy** (add-only, with default; backfill plan for renames/drops) — e.g., Avro/Protobuf compat checks, dbt contracts
- [ ] **Validation gates between stages** — e.g., Great Expectations, dbt tests, Soda
- [ ] **PII tagged at ingestion** and downstream access controlled

## Backfill & Recovery

- [ ] **Backfill is deterministic and bounded** (parameterized window, capped concurrency)
- [ ] **Failed-batch retry strategy** with poison-message handling — DLQ, side-output, manual replay tooling
- [ ] **Watermark/checkpoint state durable across restarts**

## Operations

- [ ] **Per-stage SLA + latency metrics** — freshness, completeness, accuracy
- [ ] **Cost guardrails on read-heavy / compute-heavy steps** — partition pruning, columnar pushdown
- [ ] **Lineage captured** — e.g., OpenLineage, dbt docs, Marquez
