---
description: Perform adversarial risk analysis identifying technical flaws, implementation hazards, and failure modes across spec.md, plan.md, and tasks.md.
handoffs:
  - label: Fix Critical Issues
    agent: devspark.plan
    prompt: Revise plan to address critical architectural risks
    send: true
  - label: Update Tasks
    agent: devspark.tasks
    prompt: Regenerate tasks with missing operational items
    send: true
scripts:
  sh: .devspark/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: .devspark/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

Act as a skeptical technical expert identifying risks, architectural flaws, implementation hazards, and failure scenarios that will prevent successful delivery. This command assumes `/devspark.tasks` has completed and focuses on **what will go wrong** rather than consistency checking.

**Key Distinction from `/devspark.analyze`:**

- `/devspark.analyze` = Consistency & completeness checking (are artifacts aligned?)
- `/devspark.critic` = Adversarial risk analysis (what will fail in production?)

## Operating Constraints

The risk review itself is non-destructive. Do **not** edit `spec.md`, `plan.md`, `tasks.md`, or source files. The only file write allowed is refreshing the persisted gate artifact at `FEATURE_DIR/gates/critic.md` with the final report from this command.

Read the YAML frontmatter in `spec.md` before evaluating risk. Treat `classification`, `risk_level`, and `required_gates` as authoritative metadata.

**Critical Mindset**: Assume the team has **limited experience** with the proposed stack, **optimistic estimates**, and **incomplete understanding** of edge cases. Your job is to identify where the plan will fail in production.

**Constitution Authority**: The project constitution (`/.documentation/memory/constitution.md`) is **non-negotiable**. Constitution violations are automatically SHOWSTOPPER severity.

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Initialize Analysis Context

> **Script Resolution**: Before running `{SCRIPT}`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md
- CONSTITUTION = /.documentation/memory/constitution.md

Abort with an error message if any required file is missing (instruct the user to run the appropriate prerequisite command).

For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Detect Technology Stack

Before applying risk heuristics, extract the technology stack from plan.md:

- **Language**: Python, TypeScript, Go, Rust, Java, C#, etc.
- **Framework**: FastAPI, Django, Express, Next.js, Spring Boot, ASP.NET, etc.
- **Database**: PostgreSQL, MySQL, MongoDB, Redis, etc.
- **Infrastructure**: Docker, Kubernetes, AWS, Azure, GCP, etc.
- **Async Model**: Sync-only, async/await, event-driven, etc.

This informs which framework-specific risks to prioritize.

### 3. Load Artifacts with Risk Lens

Extract failure-prone elements from each artifact:

**From spec.md:**

- Performance/scale requirements (look for unrealistic targets)
- Security requirements (look for vague or incomplete coverage)
- Third-party integrations (look for vendor lock-in, API limits)
- Edge cases (look for missing critical scenarios)
- Data consistency requirements (look for distributed system naivety)

**From plan.md:**

- Technology stack (look for bleeding-edge/unproven choices)
- Architecture patterns (look for over-engineering or under-engineering)
- Data models (look for normalization issues, missing indexes, scale bottlenecks)
- Deployment strategy (look for missing observability, rollback plans)
- Testing strategy (look for inadequate coverage of failure modes)

**From tasks.md:**

- Task sequencing (look for missing dependencies, circular deps)
- Effort estimates (look for optimistic scheduling)
- Parallelization assumptions (look for hidden bottlenecks)
- Missing operational tasks (monitoring, alerting, backups, disaster recovery)

### 4. Risk Detection Framework

Analyze across these critical dimensions, applying stack-specific knowledge:

#### A. Architectural Risks

**ASYNC/CONCURRENCY RISKS** (Python async, Node.js, Go goroutines, etc.):

- Blocking I/O in async contexts (wrong driver, sync calls in async functions)
- Connection pool exhaustion
- Missing timeout configuration
- Race conditions and deadlocks
- Improper resource cleanup

**SCALE NAIVETY:**

- N+1 query patterns in ORM usage
- Missing pagination on list endpoints (or offset pagination at scale)
- No caching strategy for hot paths
- Database schema without proper indexes
- Single-instance deployment without scaling strategy
- Large file operations without streaming

**DISTRIBUTED SYSTEM BLINDNESS:**

- Missing handling of network partitions
- No strategy for eventual consistency
- Assuming atomic cross-service operations
- Missing circuit breakers or retry logic
- No plan for handling stale data
- Missing distributed tracing

**DEPENDENCY RISKS:**

- Expensive operations without caching
- Circular dependencies
- Missing proper dependency injection for testability
- Hard-coded configuration values

#### F. Rationale & Traceability Risks

**RATIONALE COMPLETENESS:**

- Missing or incomplete Rationale Summary in spec.md → HIGH
- Missing or incomplete Rationale Summary in plan.md → HIGH
- Missing or incomplete Rationale Summary in tasks.md → HIGH
- Rationale drift between spec and plan (Core Problem mismatch) → CRITICAL
- Tradeoffs not documented for major architecture decisions → HIGH

#### B. Security & Compliance Risks

**AUTHENTICATION/AUTHORIZATION:**

- Missing or incomplete auth middleware
- No API key/token validation on protected endpoints
- Overly permissive CORS configuration
- Missing rate limiting on auth endpoints
- Secrets hardcoded or in environment without vault

**INPUT VALIDATION:**

- Unvalidated path parameters
- Missing input sanitization
- No request size limits
- SQL injection vectors
- XSS vulnerabilities

**REGULATORY BLINDNESS:**

- No mention of GDPR/data residency if handling user data
- Missing data retention policies
- No backup/restore procedures
- Inadequate PII handling strategy
- Missing audit logging for sensitive operations

#### C. Operational Hazards

**OBSERVABILITY GAPS:**

- No structured logging strategy
- Missing metrics/monitoring configuration
- No alerting thresholds defined
- Inadequate error tracking plan
- Missing health check endpoints
- No distributed tracing

**DEPLOYMENT RISKS:**

- Zero-downtime deployment not addressed
- Missing database migration strategy
- No rollback procedure
- Inadequate staging/production parity
- Missing feature flags for risky changes
- No graceful shutdown handling

**TESTING GAPS:**

- Missing integration test strategy
- No database fixtures for tests
- Missing API contract testing
- No load/performance testing
- Missing test coverage requirements

#### D. Implementation Traps

**OPTIMISTIC ESTIMATES:**

- Integration tasks without buffer for API issues
- No time for debugging race conditions
- Missing tasks for performance optimization
- Inadequate testing time allocation

**MISSING DEPENDENCIES:**

- Tasks referencing undefined data models
- Parallel tasks with hidden shared resources
- No infrastructure provisioning tasks
- Missing CI/CD pipeline setup

**TECHNICAL DEBT SEEDS:**

- "Quick and dirty" approaches without refactor tasks
- Hardcoded values without configuration management
- Missing documentation tasks
- No code review or quality gate tasks

#### E. Business Continuity Risks

**DATA LOSS SCENARIOS:**

- No backup strategy
- Missing validation before destructive operations
- Inadequate testing of restore procedures
- No transaction management in complex operations
- Missing soft delete strategy

**AVAILABILITY RISKS:**

- Single point of failure in architecture
- No rate limiting strategy
- Missing DDoS mitigation considerations
- Inadequate capacity planning
- No horizontal scaling strategy

### 5. Framework-Specific Risk Checklists

Start the output with a gate result block:

```yaml
gate: critic
status: pass | warn | fail
blocking: true | false
severity: info | warning | error | showstopper
summary: "<concise outcome>"
```

Based on detected stack, apply relevant checklist:

**Python + FastAPI/Django:**

- [ ] Blocking I/O in async endpoints
- [ ] Missing async database driver (psycopg2 vs asyncpg)
- [ ] No Pydantic validation constraints
- [ ] Missing lifespan events for resource management
- [ ] BackgroundTasks for long operations (should use Celery)
- [ ] Debug mode in production config
- [ ] Missing mypy type checking in CI

**Node.js + Express/Next.js:**

- [ ] Unhandled promise rejections
- [ ] Missing async error middleware
- [ ] No connection pool management
- [ ] Callback hell without proper structure
- [ ] Missing TypeScript strict mode
- [ ] No proper process management (PM2, cluster)

**Go + Gin/Fiber:**

- [ ] Goroutine leaks
- [ ] Missing context cancellation
- [ ] No connection pooling configuration
- [ ] Improper error handling (silent failures)
- [ ] Missing structured logging

**Java + Spring Boot:**

- [ ] Missing @Transactional boundaries
- [ ] N+1 queries in JPA/Hibernate
- [ ] No connection pool tuning (HikariCP)
- [ ] Missing actuator endpoints for monitoring
- [ ] Improper exception handling

**General Web:**

- [ ] Missing CORS configuration
- [ ] No HTTPS enforcement
- [ ] Missing security headers
- [ ] No API versioning strategy
- [ ] Missing request/response logging

### 6. Severity Classification

**SHOWSTOPPER**: Will cause production outage, data loss, or security breach

- Examples: No authentication, blocking I/O causing event loop starvation, missing connection pooling, SQL injection vectors, constitution violations

**CRITICAL**: Will cause major user-facing issues or costly rework

- Examples: Missing pagination, no error handling strategy, missing health checks, inadequate monitoring, no migration strategy

**HIGH**: Will cause technical debt or operational burden

- Examples: Missing structured logging, hardcoded configs, no rollback plan, missing type checking, no pre-commit hooks

**MEDIUM**: Will slow development or cause minor issues

- Examples: Suboptimal query patterns, missing edge case handling, inconsistent code style

### 7. Produce Risk Assessment Report

Output Markdown report with this structure:

```markdown
## Technical Risk Assessment

**Analysis Date:** [timestamp]
**Risk Posture:** [RED/YELLOW/GREEN based on showstopper count]
**Detected Stack:** [Language] + [Framework] + [Database]

### Executive Summary
[2-3 sentence verdict on whether this should proceed to implementation]

### Showstopper Risks (Must Fix Before Implementation)

| ID | Category | Location | Risk Description | Likely Impact | Mitigation Required |
|----|----------|----------|------------------|---------------|---------------------|

### Critical Risks (High Probability of Costly Issues)

| ID | Category | Location | Risk Description | Likely Impact | Recommended Action |
|----|----------|----------|------------------|---------------|--------------------|

### 8. Persist Gate Artifact

After producing the report:

- Ensure `FEATURE_DIR/gates/` exists
- Save the report as `FEATURE_DIR/gates/critic.md`
- Treat the YAML gate block as authoritative for downstream commands such as `/devspark.tasks`, `/devspark.implement`, `/devspark.create-pr`, and `/devspark.pr-review`
- When rerun, replace the previous `critic.md` artifact instead of appending duplicate reports

### High-Priority Concerns

| ID | Category | Location | Issue | Impact | Suggestion |
|----|----------|----------|-------|--------|------------|

### Framework-Specific Red Flags

[Checklist based on detected technology stack]

### Architecture Red Flags

- [ ] Over-engineered for stated requirements
- [ ] Under-engineered for implied scale
- [ ] Single point of failure without redundancy
- [ ] Missing standard patterns for problem domain
- [ ] Inadequate async/concurrency handling

### Missing Critical Tasks

- **Observability:** [list missing monitoring/logging/alerting tasks]
- **Operations:** [list missing deployment/backup/DR tasks]
- **Testing:** [list missing integration/load testing]
- **Documentation:** [list missing runbooks/architecture docs]
- **Security:** [list missing auth/validation/rate limiting]

### Questionable Assumptions

1. **[Assumption from spec/plan]** → Why this will fail: [specific failure mode]
2. **[Another assumption]** → Why this will fail: [specific failure mode]

### Dependencies Risk Assessment

| Dependency | Concern | Alternative to Consider |
|------------|---------|-------------------------|

### Estimated Technical Debt at Launch

- **Code Debt:** [areas requiring refactor post-launch]
- **Operational Debt:** [missing automation, manual processes]
- **Documentation Debt:** [undocumented systems]
- **Testing Debt:** [missing test coverage areas]

### Metrics

- Showstopper Count: [N]
- Critical Risk Count: [N]
- Missing Operational Tasks: [N]
- Underspecified Security Requirements: [N]
- Scale Bottlenecks Identified: [N]
```

### 8. Provide Verdict

End report with:

**GO/NO-GO RECOMMENDATION:**

```text
[ ] STOP - Showstoppers present, cannot proceed to implementation
[ ] CONDITIONAL - Fix critical risks first, then reassess
[ ] PROCEED WITH CAUTION - Document acknowledged risks, add mitigation tasks
```

**Required Actions Before Implementation:**

1. [Specific fix for showstopper #1]
2. [Specific fix for showstopper #2]
...

**Recommended Risk Mitigations:**

- Add tasks for: [specific missing tasks]
- Revise plan to address: [architectural concerns]
- Clarify spec requirements for: [ambiguous areas]

## Guidelines

### Adversarial Mindset

- **Assume Murphy's Law**: If it can fail, it will fail
- **Challenge optimism**: Estimates are always optimistic; dependencies always hide
- **Real-world bias**: Prioritize issues you've seen cause production incidents
- **No benefit of doubt**: Vague = wrong; missing = will bite you

### Focus Areas

**Prioritize finding:**

1. Security vulnerabilities (no auth, input validation, misconfiguration)
2. Async/concurrency bugs (blocking I/O, race conditions, deadlocks)
3. Scale bottlenecks (N+1 queries, missing pagination, no caching)
4. Missing operational tasks (monitoring, health checks, graceful shutdown)
5. Database risks (missing migrations, no indexes, improper drivers)
6. Missing testing strategy (no integration tests, no async test support)
7. Constitution violations (always SHOWSTOPPER)

**Ignore:**

- Code style preferences (if linter configured)
- Minor inconsistencies in documentation format
- Theoretical edge cases with <1% probability
- Micro-optimizations without proven bottlenecks

### Output Quality

- **Be specific**: "Missing async database driver - using psycopg2 blocks event loop" not "database concerns"
- **Cite locations**: Reference spec/plan/task sections or line numbers
- **Quantify impact**: "N+1 query in GET /users causes 1000+ DB calls for 1000 users"
- **Suggest fixes**: Don't just complain, propose concrete solutions
  - Bad: "Authentication is incomplete"
  - Good: "No JWT validation middleware - add auth dependency to protected routes"

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 30 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize showstoppers** (these block implementation)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with risk summary)
- **Be brutally honest**: This is adversarial review - sugar-coating helps nobody

## Key Differences from /devspark.analyze

This command produces a **"pre-mortem"** analysis - imagining the project has failed in production and explaining why.

| Aspect | /devspark.analyze | /devspark.critic |
|--------|------------------|-----------------|
| **Purpose** | Consistency checking | Risk identification |
| **Mindset** | Neutral validator | Adversarial skeptic |
| **Focus** | Alignment across artifacts | Production failure modes |
| **Severity** | Quality issues | Business impact |
| **Output** | Remediation suggestions | Go/No-Go recommendation |
| **Constitution** | CRITICAL violations | SHOWSTOPPER violations |

## Context

{ARGS}

## Shared Review Resolution Contract Output

When emitting findings (review observations, issues, recommendations), structure each entry to include the shared resolution contract fields so downstream tools (/devspark.address-pr-review, telemetry, harvest) can act on them deterministically:

```yaml
findings:
  - finding_id: <stable-id-unique-within-this-command-output>   # e.g., analyze-001, clarify-002
    severity: critical | high | medium | low
    description: <1-3 sentence problem statement>
    recommended_action: <machine-actionable next step>
    execution_mode: auto | selective | manual
    status: open                                                  # set to `resolved` after remediation
    outcome: ""                                                  # populated post-resolution by address-pr-review
```

inding_id MUST be stable across re-runs when the underlying issue is unchanged. xecution_mode MUST be one of: `auto` (safe to apply automatically), `selective` (apply with reviewer approval), `manual` (requires human implementation). The `status` and `outcome` fields are written by `/devspark.address-pr-review` (FR-028).
