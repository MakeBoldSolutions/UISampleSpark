---
description: Archive development artifacts at release, distill key decisions into permanent documentation, and prepare for next development cycle
handoffs:
  - label: View Release History
    agent: devspark.release
    prompt: Show me previous releases in .documentation/releases/
  - label: Run Final Audit
    agent: devspark.site-audit
    prompt: Run a final site audit before release
scripts:
  sh: .devspark/scripts/bash/release-context.sh $ARGUMENTS --json
  ps: .devspark/scripts/powershell/release-context.ps1 $ARGUMENTS -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command performs release documentation by:

1. Archiving completed development artifacts (specs, plans, tasks)
2. Distilling key architectural decisions into ADRs (Architecture Decision Records)
3. Generating CHANGELOG entries
4. Creating release notes
5. Preparing a clean slate for the next development cycle

**IMPORTANT**: This command modifies documentation files. Use `--dry-run` to preview changes before committing.

## Prerequisites

- Git repository with version tags (recommended)
- Completed feature specs in `/.documentation/specs/`
- Quickfixes in `/.documentation/quickfixes/` (optional)

## Options

Parse `$ARGUMENTS` for options:

| Option | Description |
|--------|-------------|
| `{version}` | Explicit version (e.g., `2.0.0` or `v2.0.0`) |
| `--from <date>` | Override the release window start date (`YYYY-MM-DD`) |
| `--dry-run` | Preview changes without writing files |

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Initialize Release Context

> **Script Resolution**: Before running `{SCRIPT}`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `{SCRIPT}` to gather context and parse JSON output for:

- `REPO_ROOT`: Repository root path
- `SPECS_DIR`: Path to specs directory
- `RELEASES_DIR`: Path to releases archive
- `QUICKFIX_DIR`: Path to quickfixes directory
- `DECISIONS_DIR`: Path to ADR directory
- `CURRENT_VERSION`: Current version from package file
- `VERSION_SOURCE`: Where version was read from
- `NEXT_VERSION`: Proposed next version
- `VERSION_BUMP`: Type of bump (major/minor/patch)
- `RELEASE_FROM`: Start date for the release window
- `RELEASE_TO`: End date for the release window
- `COMPLETED_SPECS`: List of specs ready for archival
- `PENDING_SPECS`: List of incomplete specs
- `QUICKFIXES`: List of quickfixes since last release
- `LAST_TAG`: Most recent git tag
- `LAST_RELEASE_DATE`: Date of last release
- `COMMITS_SINCE_RELEASE`: Commit count since last release
- `CONTRIBUTORS`: List of contributors
- `MERGED_PR_NUMBERS`: Pull request numbers detected in the release window
- `MERGED_PR_COUNT`: Number of merged PRs detected in the release window
- `PR_REVIEW_SUMMARY`: Aggregated PR review stats (`files_changed`, `tests_added`, `breaking_changes`, `resolved_high_findings`)
- `DRY_RUN`: Whether this is a preview run
- `DEVSPARK_VERSION_PATH`: Path to `.devspark/VERSION`
- `INSTALLED_VERSION`: Version recorded in the stamp file (blank if absent)

The release context should be built from the full release window, not only the specs archived during the current command run. Prefer the following sources in order:

1. Active `.documentation/` artifacts
2. `.archive/<date>/` batches whose dates fall within `{RELEASE_FROM}..{RELEASE_TO}`
3. Git history and PR review metadata within the same window

### 2. Version Confirmation

Display proposed version:

```markdown
## Release Version

- **Current Version**: {CURRENT_VERSION} (from {VERSION_SOURCE})
- **Proposed Version**: {NEXT_VERSION} ({VERSION_BUMP} bump)
- **Release Window**: {RELEASE_FROM} → {RELEASE_TO}
- **Reason**: {N} completed specs, {M} quickfixes

Confirm this version or provide explicit version:
- To accept: continue
- To change: `/devspark.release {version}`
```

**Version Bump Logic:**

| Content | Bump Type | Example |
|---------|-----------|---------|
| Completed feature specs | Minor | 1.2.4 → 1.3.0 |
| Quickfixes only | Patch | 1.2.4 → 1.2.5 |
| Breaking changes in specs | Major | 1.2.4 → 2.0.0 |

### 3. Classify Artifacts

#### A. Completed Specs (Ready for Archive)

For each spec in COMPLETED_SPECS:

- Verify the `**Status**:` field in `spec.md` is `Complete` (not `Draft` or `In Progress`)
- Verify all tasks are checked in `tasks.md`
- Confirm associated PR merged (if trackable)
- If spec status is NOT `Complete` but tasks are all checked, **flag as inconsistency** — update spec status to `Complete` before archiving
- If spec status is `Draft` or `In Progress` and tasks are incomplete, move to Pending Specs (section B)
- Mark for archival only when both status is `Complete` AND all tasks are checked

#### B. Pending Specs (Keep Active)

For each spec in PENDING_SPECS:

- Keep in `/.documentation/specs/`
- Note as "Deferred to next release"
- Include in release notes as "Coming Soon"

#### C. Quickfixes

All quickfixes in QUICKFIXES:

- Archive to release directory
- Include in CHANGELOG under "Fixed"

### 4. Extract Architectural Decisions

For each completed spec, analyze `research.md` and `plan.md` for ADR-worthy decisions:

**ADR Criteria:**

- Technology stack choices (frameworks, databases, libraries)
- Architecture pattern decisions (microservices, event-driven, etc.)
- Security or compliance decisions
- Performance trade-offs
- Integration approaches

**Skip:**

- Implementation details
- Bug fixes
- Minor configuration choices

For each identified decision, create ADR at `/.documentation/decisions/ADR-{NNN}.md`:

```markdown
# ADR-{NNN}: {Decision Title}

## Status

Accepted

## Context

{Why this decision was needed - extracted from spec/research}

## Decision

{What was decided - extracted from plan}

## Consequences

### Positive

- {Benefit 1}
- {Benefit 2}

### Negative

- {Trade-off 1}

## Source

- **Spec**: {spec-name}
- **Release**: v{NEXT_VERSION}
- **Date**: {RELEASE_DATE}
```

### 5. Generate CHANGELOG Entry

Create or update `CHANGELOG.md` at repository root:

```markdown
## [v{NEXT_VERSION}] - {RELEASE_DATE}

### Added

{For each completed spec with new features:}
- **{Feature Name}**: {Brief description from spec}

### Changed

{For each completed spec with modifications:}
- **{Change Name}**: {Brief description}

### Fixed

{For each quickfix:}
- **{QF-ID}**: {Problem fixed}

### Architectural Decisions

{For each ADR created:}
- **ADR-{NNN}**: {Decision title}

### Contributors

{List each contributor from CONTRIBUTORS}
```

**If CHANGELOG.md exists:**

- Insert new entry at the top (after header)
- Preserve existing entries

**If CHANGELOG.md doesn't exist:**

- Create with header and first entry

### 6. Create Release Archive

Create directory structure at `/.documentation/releases/v{NEXT_VERSION}/`:

```text
releases/v{NEXT_VERSION}/
├── release-notes.md      # Human-readable release summary
├── specs/                # Archived specs
│   ├── {spec-001}/
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   └── research.md
│   └── {spec-002}/
├── quickfixes/           # Archived quickfixes
│   ├── QF-{YYYY}-{NNN}.md
│   └── ...
└── metrics.json          # Release statistics
```

### 7. Generate Release Notes

Create `/.documentation/releases/v{NEXT_VERSION}/release-notes.md`:

```markdown
# Release Notes: v{NEXT_VERSION}

## Release Metadata

- **Version**: v{NEXT_VERSION}
- **Release Date**: {RELEASE_DATE}
- **Release Window**: {RELEASE_FROM} → {RELEASE_TO}
- **Previous Version**: {LAST_TAG}
- **Commits**: {COMMITS_SINCE_RELEASE}
- **Contributors**: {CONTRIBUTORS count}
- **Merged PRs**: {MERGED_PR_COUNT}

## Highlights

{Executive summary - 2-3 paragraphs summarizing major changes}

## New Features

{For each completed spec:}

### {Feature Name}

{Description from spec summary}

**Spec**: [View archived spec](specs/{spec-name}/spec.md)

## Bug Fixes

{For each quickfix:}

- **{QF-ID}**: {Description}

## Breaking Changes

{If any specs marked as breaking:}

- {Breaking change description with migration guide}

## Deprecations

{If any features deprecated:}

- {Deprecated feature with replacement guidance}

## Architectural Decisions

{For each ADR:}

- **ADR-{NNN}**: {Title} - [View](../../decisions/ADR-{NNN}.md)

## Deferred Features

{For each pending spec:}

- **{Feature Name}**: Planned for future release

## Upgrade Guide

{Steps to upgrade from previous version - auto-generate based on breaking changes}

## Metrics

| Metric | Value |
|--------|-------|
| Features Delivered | {completed specs count} |
| Bugs Fixed | {quickfixes count} |
| PRs Merged | {MERGED_PR_COUNT} |
| Files Changed | {PR_REVIEW_SUMMARY.files_changed} |
| Tests Added | {PR_REVIEW_SUMMARY.tests_added} |
| Breaking Changes | {PR_REVIEW_SUMMARY.breaking_changes} |
| ADRs Created | {ADR count} |
| Contributors | {contributors count} |
| Commits | {commits count} |

---

*Release documentation generated by /devspark.release v1.0*
```

### 8. Generate Metrics JSON

Create `/.documentation/releases/v{NEXT_VERSION}/metrics.json`:

```json
{
  "version": "{NEXT_VERSION}",
  "releaseDate": "{RELEASE_DATE}",
   "release": {
      "from": "{RELEASE_FROM}",
      "to": "{RELEASE_TO}"
   },
  "previousVersion": "{LAST_TAG}",
  "features": {
    "completed": {count},
    "deferred": {count}
  },
  "quickfixes": {count},
   "pullRequests": {
      "merged": {MERGED_PR_COUNT},
      "numbers": [{MERGED_PR_NUMBERS}],
      "filesChanged": {PR_REVIEW_SUMMARY.files_changed},
      "testsAdded": {PR_REVIEW_SUMMARY.tests_added},
      "breakingChanges": {PR_REVIEW_SUMMARY.breaking_changes},
      "resolvedHighFindings": {PR_REVIEW_SUMMARY.resolved_high_findings}
   },
  "adrs": {count},
  "commits": {count},
  "contributors": {count},
  "specs": [{list of spec names}],
  "timestamp": "{TIMESTAMP}"
}
```

### 9. Bump Version in Source Files

After generating the CHANGELOG entry and release archive, and **before** committing,
update the canonical version number so the next `devspark upgrade` stamps the new
version into consumer projects.

**Skip if DRY_RUN.**

#### A. Bump `pyproject.toml` (DevSpark source repo)

Edit `pyproject.toml` at the repository root:

```toml
[project]
version = "{NEXT_VERSION}"   # was {CURRENT_VERSION}
```

Make this edit now if {NEXT_VERSION} differs from {CURRENT_VERSION}.

#### B. Confirm `.devspark/VERSION` (consumer repos)

`.devspark/VERSION` is **written automatically** by quickstart, `devspark init`, and
upgrade flows. Maintainers do not need to update it manually in the source repo — it is
a per-consumer-project stamp. Legacy installs may still contain `.documentation/DEVSPARK_VERSION`.

After bumping `pyproject.toml` and publishing the new release, consumer projects
will receive the correct version stamp the next time they run `devspark upgrade`.

#### C. Verify version consistency

Confirm these three sources agree on {NEXT_VERSION}:

| Source | Expected Value |
|--------|----------------|
| `pyproject.toml` → `version` | {NEXT_VERSION} |
| `CHANGELOG.md` top entry | `## [{NEXT_VERSION}]` |
| Git tag (to be created) | `v{NEXT_VERSION}` |

If any are out of sync, fix before tagging.

#### D. Manual workflow dispatch version (recommended)

When running **Create Release** via `workflow_dispatch`, set `release_version` to
`{NEXT_VERSION}` (or `v{NEXT_VERSION}`) so the workflow publishes the intended tag
instead of auto-incrementing from the latest existing tag.

### 10. Update Public-Facing Version References

After bumping `pyproject.toml` (Step 9), update **all** public documents that mention the current release version so they stay in sync. **Skip if DRY_RUN** — but list the files that would change.

#### A. Roadmap files

Update **both** roadmap files to reflect the new current release:

| File | Field to update |
|------|-----------------|
| `README.md` → `## 🗺️ Roadmap` | `### Current Release (v{NEXT_VERSION})` — add any new capabilities to the checked list |
| `/.documentation/roadmap.md` | `## Current Release: v{NEXT_VERSION}` — move newly shipped items from Near-Term into Current, update version example |

Ensure future roadmap section version ranges (`Near-Term`, `Medium-Term`, `Long-Term`) are **ahead** of `{NEXT_VERSION}`. If any future section uses a version number ≤ `{NEXT_VERSION}`, bump it forward.

#### B. Release notes / index page

| File | Field to update |
|------|-----------------|
| `release_notes.md` | Update highlights and "What's New" to `{NEXT_VERSION}` |
| `/.documentation/index.md` | Update any version badges or "latest" references |

#### C. Verify — no stale version strings

Run a quick search for the **old** version string (`{CURRENT_VERSION}`) across `README.md`, `release_notes.md`, `.documentation/*.md`, and confirm every remaining reference is intentional (e.g., CHANGELOG history). Flag any stale occurrences for manual review.

### 11. Markdownlint Preflight (Required)

Before finalizing release output, run a full markdown lint pass and fail closed on any violations.

#### A. Run markdownlint-cli2

Execute from repository root:

```bash
npx markdownlint-cli2 "**/*.md" "#node_modules"
```

If local policy requires a different invocation, use the repository-standard equivalent but keep full-repo coverage.

#### B. Produce a detailed findings report

If lint fails, parse and print a structured report with:

- Rule ID (e.g., `MD036`, `MD050`)
- File path
- Line number
- Short message

Include grouped counts by rule and by file so the author can fix quickly.

#### C. Block release completion on lint errors

If any markdownlint violations remain:

- Mark release as **BLOCKED**
- Do **not** proceed to completion messaging
- Return explicit remediation guidance with the failing file/line/rule list

Continue only when markdownlint exits cleanly.

### 12. Clean Slate Preparation

After archival (skip if DRY_RUN):

#### A. Archive Specs

For each spec in COMPLETED_SPECS:

1. Copy entire spec directory to `releases/v{NEXT_VERSION}/specs/`
2. Remove from `/.documentation/specs/`

#### B. Archive Quickfixes

For each quickfix in QUICKFIXES:

1. Copy to `releases/v{NEXT_VERSION}/quickfixes/`
2. Remove from `/.documentation/quickfixes/`

#### C. Reset State

1. Create `/.documentation/specs/.gitkeep` if directory is empty
2. Create `/.documentation/quickfixes/.gitkeep` if directory is empty

### 13. Output Summary

#### Dry Run Output

If DRY_RUN is true:

```markdown
## Release Preview: v{NEXT_VERSION}

**This is a dry run - no changes will be made**

### Proposed Changes

#### Archive to releases/v{NEXT_VERSION}/

- **Specs**: {list of completed specs}
- **Quickfixes**: {list of quickfixes}

#### Files to Create

- `/.documentation/releases/v{NEXT_VERSION}/release-notes.md`
- `/.documentation/releases/v{NEXT_VERSION}/metrics.json`
- `CHANGELOG.md` entry

#### ADRs to Generate

{List of ADRs with titles}

#### Specs to Keep (Deferred)

{List of pending specs}

---

To execute this release:
`/devspark.release {NEXT_VERSION}`
```

#### Actual Release Output

```markdown
## Release Complete: v{NEXT_VERSION}

### Archive Created

`/.documentation/releases/v{NEXT_VERSION}/`

- Specs archived: {N}
- Quickfixes archived: {M}
- ADRs created: {P}

### Documentation Updated

- CHANGELOG.md: New entry added
- Release notes: Created
- Metrics: Recorded

### Clean Slate

- Specs directory: {Cleared / {N} deferred specs remain}
- Quickfixes directory: Cleared

### Next Steps

1. Confirm `pyproject.toml` has been bumped to `{NEXT_VERSION}` (Step 9A above).

2. Confirm roadmap and public docs reference `{NEXT_VERSION}` (Step 10 above).

3. Review generated documentation:
   - `/.documentation/releases/v{NEXT_VERSION}/release-notes.md`
   - `CHANGELOG.md`

3. Commit changes:

   ```bash
   git add -A
   git commit -m "docs: release v{NEXT_VERSION}"
   ```

1. Tag release:

   ```bash
   git tag -a v{NEXT_VERSION} -m "Release v{NEXT_VERSION}"
   ```

2. Push to remote:

   ```bash
   git push origin main --tags
   ```

3. Create GitHub Release (optional):

   ```bash
   gh release create v{NEXT_VERSION} --notes-file .documentation/releases/v{NEXT_VERSION}/release-notes.md
   ```

4. Consumer projects will receive the new version stamp the next time they run:

   ```bash
   devspark upgrade
   ```

## Guidelines

### Spec Completion Validation

A spec is considered complete when:

- The `**Status**:` field in `spec.md` is `Complete`
- All tasks in `tasks.md` are checked (`[x]`)
- At least one task exists (not an empty file)
- `spec.md` exists in the directory

If tasks are all checked but status is not `Complete`, this is a lifecycle inconsistency — update the status field to `Complete` before proceeding with archival.

### ADR Quality

ADRs should be:

- **Concise**: 1-2 paragraphs per section
- **Factual**: Based on documented decisions in specs
- **Actionable**: Help future developers understand context
- **Numbered**: Sequential ADR-001, ADR-002, etc.

### Version Numbering

Follow semantic versioning:

- **MAJOR**: Breaking changes, removed features
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, documentation updates

### Handling Edge Cases

**No completed specs:**

- Generate release with quickfixes only
- Note: "Maintenance release - bug fixes only"

**No quickfixes:**

- Generate release with features only
- Standard release notes

**No artifacts to archive:**

```markdown
No Release Artifacts

No completed specs or quickfixes found since last release.

To create a release:
1. Complete pending features or
2. Add quickfixes for bug fixes

Run `/devspark.release` again when ready.
```

**Pending specs warning:**

```markdown
Pending Specs Detected

The following specs are incomplete and will NOT be archived:

{List of pending specs with status}

These will remain active for the next development cycle.
Continue with release? The above specs will be noted as "Deferred".
```

## Context

$ARGUMENTS
