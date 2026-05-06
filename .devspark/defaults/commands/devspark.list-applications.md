---
description: Display all registered applications in the multi-app repository with metadata, dependencies, and documentation roots.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Read and display the DevSpark multi-app registry. This is a **read-only** command — no files are modified.

1. **Load the registry** from `.documentation/devspark.json`:
   - If the file does not exist, report: "No multi-app registry configured. This repository operates in single-app mode."
   - If the file is invalid JSON, report the parse error

2. **Display registered applications** in a table format:

   | ID | Path | Kind | Owner | Criticality | Profiles | Dependencies | Doc Root |
   |----|------|------|-------|-------------|----------|--------------|----------|
   | *For each app in the registry, show all columns* | | | | | | | |

3. **Display registered profiles** (summary):
   - List each profile name and description
   - Show rule count per profile

4. **Display registry summary**:
   - Total applications count
   - Total profiles count
   - Applications by kind (grouped count)
   - Dependency relationships (simple list)

## Constraints

- This command is read-only — no files may be created or modified
- If no registry exists, say so and exit cleanly
