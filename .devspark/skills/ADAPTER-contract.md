# Adapter Contract

This document defines how a DevSpark command invokes an Agent Skill. It covers
skill discovery, input mapping, output mapping, responsibility split, and
backward-compatibility rules.

---

## Purpose

A DevSpark command owns lifecycle governance. A skill owns portable capability.
The adapter contract is the boundary between them. Following this contract
ensures the skill remains portable — usable in any skills-compatible client
without DevSpark installed — while the command preserves full governance
behavior for DevSpark users.

---

## Skill Discovery

A DevSpark command resolves a skill by path:

```text
templates/skills/<skill-name>/SKILL.md
```

Path resolution is relative to the repository root. The command is responsible
for resolving the absolute path before invoking the skill. The skill does not
know its own installation location.

`devspark skills list` enumerates all sibling directories under
`templates/skills/` that contain a `SKILL.md`. Clients load only `name` and
`description` for indexing; the full body is loaded only on activation.

---

## Responsibility Split

This table is authoritative. Any concern not listed here requires a contract
amendment.

| Concern | Owner |
| ------- | ----- |
| Route classification | Command |
| Branch creation | Command |
| Multi-app scope resolution | Command |
| Artifact path placement | Command |
| Checklist generation | Command |
| Gate enforcement | Command |
| Portable task instructions | Skill |
| Skill discovery metadata (`name`, `description`) | Skill |
| Capability-specific reasoning workflow | Skill |
| Context-gathering helper scripts | Skill |
| Command-to-skill input mapping | Adapter contract (this document) |
| Skill-to-command output mapping | Adapter contract (this document) |

Multi-app scoping is always a command responsibility. The skill must not receive
app registry data, multi-app resolution paths, or any DevSpark-specific
governance state. The command resolves scope first, then passes only the
resolved context variables listed below.

---

## Input Mapping

The command passes context to the skill through named input variables. These
variable names are part of the versioned contract surface. Renaming any of them
requires a `metadata.version` bump in `SKILL.md`.

| Command input | Skill context variable | Notes |
| ------------- | ---------------------- | ----- |
| User feature description | `$FEATURE_DESCRIPTION` | Raw user text or resolved summary |
| Resolved constitution path | `$CONSTITUTION_PATH` | Absolute path; null when not found |
| Prior-spec summary (from context script) | `$PRIOR_SPEC_SUMMARY` | JSON summary; null when unavailable |

`$FEATURE_DESCRIPTION`, `$CONSTITUTION_PATH`, and `$PRIOR_SPEC_SUMMARY` must
appear in both the command's delegation block and in this document. They are
machine-verifiable by the adapter contract test.

Multi-app scope (`$APP_SCOPE`) is resolved by the command and is NOT passed
into the skill. It is a DevSpark-specific governance concern that does not
belong in a portable skill body.

---

## Output Mapping

The skill produces a draft artifact. The command places it into the
DevSpark-governed path.

| Skill output | Command action |
| ------------ | -------------- |
| Draft `spec.md` body | Written to `SPEC_FILE` resolved by the command |
| `[NEEDS CLARIFICATION]` markers | Preserved; command may invoke `/devspark.clarify` |
| `Assumptions` section | Preserved verbatim in the placed spec |

The skill must not write directly to `SPEC_FILE` or any `.documentation/` path.
Writing to DevSpark-governed paths is always a command responsibility.

---

## Backward-Compatibility Rules

1. When the skill body is updated, the command's delegation block must be
   reviewed to confirm the named input variables and output contract are still
   satisfied.
2. When a new input variable is added to the skill, add it to the input mapping
   table above and bump `metadata.version` in `SKILL.md`.
3. When the skill is removed or renamed, the command must be updated in the same
   PR. No command may reference a skill that does not exist.
4. The adapter contract test (`tests/test_adapter_contract.py`) verifies that
   the named input variables appear in both the command's delegation block and
   this document. Any contract change that breaks these assertions requires a
   corresponding test update.

---

## Example: `write-spec` Adapter

The `write-spec` skill is the pilot implementation of this contract.

**Skill path**: `templates/skills/write-spec/SKILL.md`

**Command that delegates**: `templates/commands/specify.md`

**Delegation block** (what the command puts in its body to invoke the skill):

```text
Resolve the write-spec skill at templates/skills/write-spec/SKILL.md.
Pass the following named inputs to the skill:
  $FEATURE_DESCRIPTION — the user's feature request text
  $CONSTITUTION_PATH — the resolved path to .documentation/memory/constitution.md
  $PRIOR_SPEC_SUMMARY — the JSON output from the skill's gather-context script

The skill will produce a draft spec body. Place the draft into SPEC_FILE
as resolved by the command's artifact placement logic.
```

The command retains all DevSpark lifecycle steps (route classification, branch
creation, multi-app scoping, artifact placement, checklist generation, gate
enforcement) and delegates only the spec-drafting reasoning to the skill.
