---
description: Register a new application in the multi-app repository registry with guided metadata collection and automatic scaffolding.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Register a new application in the DevSpark multi-app registry at `.documentation/devspark.json`.

1. **Collect application metadata** from the user input or interactively:
   - `id`: Unique, lowercase, path-safe identifier (e.g., `payments-api`)
   - `name`: Human-readable application name
   - `path`: Relative path from repo root (e.g., `apps/payments-api`)
   - `kind`: Application type (e.g., `runtime-api`, `web-client`, `web-admin`, `library`, `qa-harness`)
   - `purpose`: One-line description of the application's role
   - `runtime`: Technology/framework (e.g., `dotnet`, `react`, `node`)
   - `owner`: Team or individual responsible
   - `criticality`: `high`, `medium`, or `low`
   - `inherits`: List of profile names to inherit (must exist in registry)
   - `dependsOn`: List of app IDs this app depends on (must exist in registry)

2. **Validate inputs**:
   - Check that the `id` is not already registered (fail with duplicate error if so)
   - Check that all `inherits` profile references exist in the registry
   - Check that all `dependsOn` app references exist in the registry
   - Check that the `path` does not conflict with existing registered app paths

3. **Update the registry**:
   - Add the new application entry to the `apps` array in `.documentation/devspark.json`
   - Ensure the registry passes full validation after the addition

4. **Scaffold the application documentation** (always performed):
   - Create `{path}/.documentation/` with standard subdirectories:
     - `memory/` — for app-specific constitution
     - `commands/` — for app-specific command overrides
     - `scripts/` — for app-specific script overrides
     - `templates/` — for app-specific template overrides
     - `specs/` — for app-scoped feature specifications
   - Do NOT create or modify `.devspark/`

5. **Report results**:
   - Show the new registry entry
   - Confirm scaffolded directories
   - Print scope summary

## Constraints

- If the registry file does not exist, create it with `version: 1`, `mode: "multi-app"`, empty `profiles`, and the new app as the first entry
- If the `id` already exists, fail with a clear duplicate error and do not modify the registry
- The command MUST NOT modify `.devspark/` (ownership boundary)
