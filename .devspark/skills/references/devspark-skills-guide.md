# DevSpark Skills Guide

Source standard: <https://agentskills.io/specification>  
Last reviewed: 2026-05-19

This guide defines how DevSpark uses portable Agent Skills inside this
repository. The upstream Agent Skills specification remains authoritative for
portable skill package format. DevSpark adds repository conventions for
validation, command integration, context engineering, and lifecycle governance.

## DevSpark Position

DevSpark is not a replacement for the Agent Skills ecosystem. DevSpark treats
skills as portable capability packages inside a governed lifecycle orchestration
system.

The intended boundary is:

```text
command -> adapter -> skill -> context scripts -> agent reasoning -> artifact
```

Commands own DevSpark-specific lifecycle behavior. Skills own portable
capability instructions. The adapter contract defines how a command invokes a
skill without leaking DevSpark-only behavior into `SKILL.md`.

## Repository Layout

DevSpark skills live under `templates/skills/`:

```text
templates/skills/
├── README.md
├── ADAPTER-contract.md
├── SKILL-validation-contract.md
├── references/
│   └── devspark-skills-guide.md
└── <skill-name>/
    ├── SKILL.md
    ├── scripts/
    ├── references/
    └── assets/
```

Shared guidance belongs under `templates/skills/references/`. Skill-specific
guidance belongs under `templates/skills/<skill-name>/references/`.

The first pilot skill is `templates/skills/write-spec/`. It proves that
`/devspark.specify` can keep the same user-facing command behavior while
delegating portable spec-drafting instructions to a standalone skill.

## Commands vs Skills

Use this split when designing or reviewing skill work:

| Concern | Owner |
| ------- | ----- |
| Slash-command UX | Command |
| Route classification | Command |
| Branch creation | Command |
| Multi-app scope resolution | Command |
| Artifact path placement | Command |
| Checklist and gate orchestration | Command |
| Portable task instructions | Skill |
| Skill discovery metadata | Skill |
| Capability-specific reasoning workflow | Skill |
| Context-gathering helper scripts | Skill |
| Command-to-skill input and output mapping | Adapter contract |

A skill must be useful outside DevSpark. It must not require branch creation,
multi-app registry resolution, DevSpark gate execution, or any installed
DevSpark CLI behavior to perform its core task.

## Skill Package Shape

An Agent Skill is a directory with a required `SKILL.md` file at its root.
Optional sibling directories can provide supporting resources:

- `scripts/` for executable helper code.
- `references/` for on-demand documentation.
- `assets/` for templates, static resources, images, or data files.

Only `SKILL.md` is required by the upstream spec. DevSpark may require
additional directories for specific skills when the feature spec calls for them.
For `write-spec`, DevSpark requires `scripts/` because the pilot must
demonstrate deterministic context gathering.

## SKILL.md Format

`SKILL.md` must start with YAML frontmatter followed by Markdown instructions.
The frontmatter is the discovery surface loaded by clients before activation.
The body is loaded only after the agent decides to use the skill.

Minimal DevSpark-managed form:

```yaml
---
name: write-spec
description: Draft feature specifications, requirements documents, user stories, acceptance criteria, and validation-ready specs from a feature request.
metadata:
  version: "0.1.0"
---
```

DevSpark-managed skills must not use DevSpark command frontmatter keys such as
`handoffs`, `scripts` in the command-prompt sense, `classification`,
`required_gates`, or `recommended_next_step`.

## Frontmatter Rules

### Required Upstream Fields

- `name`: Required. Maximum 64 characters. Use lowercase letters, numbers, and
  hyphens only. It must not start or end with a hyphen, must not contain
  consecutive hyphens, and must match the parent directory name.
- `description`: Required. Maximum 1024 characters. It must be non-empty and
  should say both what the skill does and when to use it.

### Optional Upstream Fields

- `license`: Optional. Short license name or reference to a bundled license
  file.
- `compatibility`: Optional. Maximum 500 characters when present. Use only when
  the skill has meaningful environment requirements.
- `metadata`: Optional in the upstream spec. Arbitrary string key-value mapping
  for additional metadata.
- `allowed-tools`: Optional and experimental. Space-separated tool approval
  string. Support varies by client.

### DevSpark Addendum

- DevSpark skills must declare `metadata.version` as a quoted semantic-version
  string.
- DevSpark skills must not use a top-level `version` field.
- DevSpark skills must not include DevSpark command-only frontmatter keys.
- Skill descriptions must be discovery-rich. Include phrases users are likely
  to use when asking for the capability.
- `allowed-tools` is deferred for the pilot unless the feature spec is amended.

DevSpark uses `metadata.version` because the upstream spec reserves `metadata`
for additional key-value properties while keeping the top-level frontmatter
dialect portable.

## Body Guidance

The skill body contains task instructions. The upstream spec does not impose a
strict body schema, but recommends keeping `SKILL.md` small and moving detailed
material into referenced files.

For DevSpark:

- Keep the body at or below 500 lines and roughly 5000 tokens.
- Put reusable details in `references/` instead of expanding `SKILL.md`.
- Reference supporting files with relative paths from the skill root.
- Avoid deep reference chains; keep references one level from `SKILL.md` when
  practical.
- State what the skill does when repository context is unavailable.
- Keep DevSpark lifecycle behavior out of the skill body unless framed as host
  context supplied by an adapter.

## Context Engineering

DevSpark skills should demonstrate that a capability is more than prompt text.
When a skill needs repository knowledge, prefer deterministic context gathering
over freeform exploration.

Context scripts should:

- Produce structured, compact output.
- Work without mutating the repository.
- Degrade gracefully outside a DevSpark-enabled repository.
- Report skipped context explicitly.
- Avoid blocking the skill when non-critical context cannot be collected.

For `write-spec`, required context includes constitution loading and prior-spec
summary at minimum. A failure to gather either should be recorded in the
generated spec assumptions.

## Script Parity

The DevSpark constitution requires platform parity. If a skill bundles
executable scripts, provide equivalent PowerShell and Bash variants for each
capability.

Script guidance:

- Keep scripts self-contained.
- Prefer JSON or another structured format for output.
- Include clear diagnostics for missing tools, missing files, or non-repository
  execution.
- Do not write under `.documentation/` unless the specific workflow and
  constitution permit it.
- Do not make script success mandatory unless the feature spec explicitly says
  the skill cannot proceed without that context.

## References

Shared references under `templates/skills/references/` apply to all DevSpark
skills. Skill-local references under `templates/skills/<skill-name>/references/`
apply only to that skill.

Use shared references for:

- DevSpark skills conventions.
- Upstream Agent Skills rules.
- Cross-skill validation guidance.
- Adapter and lifecycle concepts that future skills should reuse.

Use skill-local references for:

- Examples for one capability.
- Domain-specific instructions.
- Output templates specific to one skill.
- Long procedural details that would bloat one `SKILL.md`.

## Assets

The upstream spec allows `assets/` for templates, static resources, images, and
data files. Add assets only when a reusable artifact is clearer than inline
Markdown or a reference file.

For DevSpark, assets should be portable with the skill folder. Do not place
skill assets in `.documentation/`, because `.documentation/` is repository-owned
work product and must not be installed or modified by framework operations.

## Progressive Disclosure

Agent Skills are designed for staged loading:

1. Clients load `name` and `description` for discovery.
2. Clients load the full `SKILL.md` body on activation.
3. Clients load files in `scripts/`, `references/`, or `assets/` only when the
   task needs them.

This means the `description` must be specific enough to trigger the skill, and
the body must tell the agent exactly which references or scripts to load for the
current task.

## Validation Surface

DevSpark skills are validated at three layers:

1. Upstream Agent Skills package rules.
2. DevSpark skill-validation contract rules.
3. Adapter contract rules when a DevSpark command invokes the skill.

Expected validation surfaces:

- `templates/skills/SKILL-validation-contract.md` documents the local rules.
- `devspark skills list` enumerates skills under `templates/skills/`.
- `devspark skills validate [path]` validates all skills or one skill path.
- Tests under `tests/` gate skill and adapter contract behavior in CI.
- Markdownlint gates all committed Markdown.

Validation failures should name the violated rule and offending value. Warnings
are acceptable for body budget pressure, but portability and frontmatter errors
must fail validation.

## Adding a Skill

Use this workflow for future DevSpark skills:

1. Start from a spec that justifies why the capability should be a skill.
2. Confirm the skill has a portable core that can work outside DevSpark.
3. Define the command-to-skill adapter boundary if a command will invoke it.
4. Create `templates/skills/<skill-name>/SKILL.md`.
5. Add skill-local `references/`, `scripts/`, or `assets/` only when needed.
6. Keep command lifecycle behavior in `templates/commands/`.
7. Add validation tests before wiring command behavior to the skill.
8. Run markdownlint and skill validation before review.

Do not auto-convert existing commands into skills without a spec. Avoid tiny
skills that only wrap one sentence of prompt text; a DevSpark skill should
package a durable capability with clear context and validation boundaries.

## Pilot Skill: write-spec

The `write-spec` pilot is intentionally narrow:

- It drafts specs only.
- It does not orchestrate planning or task generation.
- It must run in a skills-compatible client without DevSpark installed.
- It must produce a valid `spec.md` against the shared spec validation
  contract.
- It must start specs in `Draft` status.
- It must limit `[NEEDS CLARIFICATION]` markers to three.
- It must bundle paired PowerShell and Bash context scripts for constitution
  loading and prior-spec summary.
- It must degrade gracefully when those scripts cannot gather context.
- It must not perform branch creation, multi-app scoping, checklist generation,
  or gate enforcement.

## Review Checklist

Use this checklist while implementing or reviewing DevSpark skills:

- `SKILL.md` exists at the skill root.
- Frontmatter parses as YAML.
- `name` matches the parent directory.
- `name` uses only lowercase letters, numbers, and hyphens.
- `description` is non-empty, within 1024 characters, and discovery-rich.
- `metadata.version` exists and is quoted.
- No top-level `version` field exists.
- No DevSpark command-only frontmatter keys exist.
- Body is within the DevSpark budget.
- Body can guide a non-DevSpark client through the core task.
- Body references support files using relative paths from the skill root.
- Shared references are not duplicated in skill-local references.
- Required scripts have paired PowerShell and Bash implementations.
- Script failures degrade gracefully.
- Command lifecycle responsibilities stay in commands or adapters.
- Markdown passes the repository markdownlint configuration.
