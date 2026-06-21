# SKILL Validation Contract

This document defines the rules that every `SKILL.md` and skill folder under
`templates/skills/` must satisfy. Rules are layered: upstream Agent Skills rules
first, then DevSpark addendum rules.

Source standard: <https://agentskills.io/specification>
Reviewed: 2026-05-19

---

## Upstream Agent Skills Rules

These rules come directly from the open Agent Skills specification. They apply
to every skill package regardless of host.

### Required Frontmatter Fields

- `name`: Required. Lowercase letters, numbers, and hyphens only.
  No leading, trailing, or consecutive hyphens. Maximum 64 characters.
  Must match the parent directory name exactly.
- `description`: Required. Non-empty string. Maximum 1024 characters.
  Must describe both what the skill does and when to invoke it.

### Optional Upstream Fields

- `license`: Optional. Short license identifier or reference to a bundled file.
- `compatibility`: Optional. Maximum 500 characters when present.
- `metadata`: Optional in the upstream spec. Arbitrary string key-value map.
- `allowed-tools`: Optional. Experimental. Space-separated tool string.

---

## DevSpark Addendum Rules

These rules apply to all DevSpark-managed skills. They supplement, not replace,
the upstream rules.

### Required Additions

- `metadata.version`: Required for every DevSpark skill. Must be a quoted
  semantic-version string in `MAJOR.MINOR.PATCH` format (e.g., `"0.1.0"`).
  Partial semver strings (e.g., `"1.0"` missing patch) are rejected.
  Unquoted values (e.g., `1.0` parsed as a float) are rejected.
- `metadata.version` must be of type string when parsed with
  `yaml.safe_load()`. An integer or float type indicates the value is unquoted.

### Prohibited Frontmatter Keys

The following keys are DevSpark command-prompt keys. They must not appear in
`SKILL.md` frontmatter. Their presence signals a portability violation:

- `handoffs`
- `scripts` (in the command-prompt sense — not to be confused with the
  `scripts/` directory inside the skill folder)
- `classification`
- `required_gates`
- `recommended_next_step`
- `version` (bare top-level — use `metadata.version` instead)

### Body Rules

- Body line count must not exceed 500 lines. Exceeding this limit is a `fail`.
- Body line count exceeding 400 lines but not 500 is a `warn` (advisory). CI
  does not block on warnings.
- Longer material must be moved into `references/` and linked with relative
  paths from the skill root.
- The body must not contain any of the following DevSpark-specific strings.
  Their presence indicates DevSpark lifecycle behavior leaked into a portable
  skill:
  - `.devspark/`
  - `{SCRIPT}`
  - `FEATURE_DIR`
  - `{AGENT_SCRIPT}`
  - `handoffs:`

### Required Body Sections

The body must guide an agent through the core capability without requiring
DevSpark to be installed. Required sections for spec-drafting skills:

- A context-loading section (what context to gather and how to proceed when
  unavailable).
- A drafting procedure section (the workflow the agent executes).
- An assumptions section (where skipped context is recorded).

### Graceful Degradation

Skills must describe what the agent should do when context-gathering fails.
Document the fallback explicitly in the body context-loading section.

---

## Three-Tier Exit-Code Table

The `devspark skills validate` command and CI validation tests use this
exit-code contract:

| Tier | Exit Code | Stdout | Stderr | Meaning |
| ---- | --------- | ------ | ------ | ------- |
| `pass` | `0` | One-line summary: name and version | — | All rules satisfied |
| `warn` | `0` | — | Warning count + advisory details | Body budget pressure (> 400 lines). Does not block CI. |
| `fail` | `1` | — | Diagnostic per violated rule (see below) | Any frontmatter, prohibited-key, or body-scan rule violated |

### Diagnostic Format for Failures

Each failure diagnostic must use this format:

```text
[RULE] [OFFENDING-VALUE] message
```

Examples:

```text
[name-mismatch] [WriteSpec] name "WriteSpec" does not match directory "write-spec"
[description-length] [1100] description length 1100 exceeds limit of 1024 characters
[prohibited-key] [handoffs] frontmatter key "handoffs" is not permitted in SKILL.md
[version-type] [1.0] metadata.version must be a quoted string; got float
[version-format] ["1.0"] metadata.version "1.0" does not match MAJOR.MINOR.PATCH
[body-scan] [.devspark/] body contains DevSpark-specific string ".devspark/"
[body-length] [512] body line count 512 exceeds maximum of 500
```

---

## Repair Rules

These rules describe how to correct common violations. They are consistent with
the style used in `templates/spec-validation-contract.md`.

| Violation | Repair |
| --------- | ------ |
| `name` does not match directory | Rename the directory or update `name` to match |
| `description` over 1024 chars | Shorten; move detail into `references/` |
| `metadata.version` missing | Add `metadata:\n  version: "0.1.0"` to frontmatter |
| `metadata.version` is a float | Quote the value: `version: "1.0.0"` |
| `metadata.version` is partial semver | Add patch component: `"1.0"` → `"1.0.0"` |
| Prohibited key present | Remove the key from `SKILL.md` frontmatter |
| DevSpark string in body | Remove or replace with portable equivalent |
| Body > 500 lines | Move sections to `references/` files |
| Body > 400 lines | Advisory — consider moving content to `references/` |
