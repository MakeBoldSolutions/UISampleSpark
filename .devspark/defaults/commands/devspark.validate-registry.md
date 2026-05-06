---
description: Validate the multi-app registry schema, references, cycles, path existence, and app-local manifest consistency.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Run comprehensive validation on the DevSpark multi-app registry. This is a **read-only** command — no files are modified.

1. **Load the registry** from `.documentation/devspark.json`:
   - If the file does not exist, report: "No multi-app registry found."
   - If the file is invalid JSON, report the parse error and stop

2. **Schema validation**:
   - Check `version` is 1
   - Check `mode` is "multi-app"
   - Check `profiles` is an object
   - Check `apps` is an array

3. **Identity validation**:
   - Check all app `id` values are unique, lowercase, and path-safe
   - Check all app `path` values point to existing directories

4. **Reference validation**:
   - Check all `inherits` entries reference declared profiles
   - Check all `dependsOn` entries reference declared app IDs
   - Detect cyclic dependencies and report the cycle path

5. **App-local manifest validation** (`app.json`):
   - For each app, check if `{path}/app.json` exists
   - If present, validate schema (only `tags`, `hints`, `rules` allowed)
   - Warn if identity fields are present (they will be ignored)
   - Check rules for weakening of mandatory repo-wide rules

6. **Constitution validation**:
   - Check that `.documentation/memory/constitution.md` exists
   - For each app with a local constitution, run weakening detection

7. **Report results**:
   - List all errors (blocking issues)
   - List all warnings (non-blocking advisories)
   - Print pass/fail status
   - Structured output suitable for CI pipeline consumption

## Output Format

```text
DevSpark Registry Validation
=============================
Registry: .documentation/devspark.json
Apps: N | Profiles: N

Errors:
  (none or itemized list)

Warnings:
  (none or itemized list)

Status: PASS / FAIL
```

## Constraints

- This command is read-only — no files may be created or modified
- Usable in CI pipelines as a pre-merge check
