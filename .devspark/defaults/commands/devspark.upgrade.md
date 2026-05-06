---
description: Check the installed DevSpark version, identify stale framework files, and guide a safe upgrade to the latest release
---

<!-- markdownlint-disable MD040 -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). Supported options:

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would change without modifying files |
| `--force` | Skip confirmations |

---

## Overview

This command checks whether the consumer project's installed DevSpark matches the
latest available version and guides you through a safe upgrade. It:

1. Reads `.devspark/VERSION` to find the installed version (fallback: legacy `.documentation/DEVSPARK_VERSION`)
2. Detects the latest version from `CHANGELOG.md` or `pyproject.toml`
3. Classifies files under `.documentation/` as framework-owned vs. user-owned
4. Identifies stale or missing framework files
5. Runs `devspark upgrade` (or `devspark init --here --force`) to apply updates
6. Verifies the stamp file was updated after the upgrade

### Execution Modes

Use this command in one of two ways:

1. **Basic (recommended) — Remote prompt execution (no CLI required)**

- Run this prompt directly from your AI agent using:
  `https://raw.githubusercontent.com/markhazleton/devspark/main/templates/commands/upgrade.md`
- The agent performs the upgrade by refreshing stock files in `.devspark/` and preserving `.documentation/`.

1. **Advanced (optional) — CLI-assisted execution**

- Use `devspark upgrade` when you want terminal-driven automation.
- Use CLI install/update commands only if your workflow prefers local tooling.

---

## Outline

### 1. Read Installed Version

Check for `.devspark/VERSION` first:

```text
.devspark/VERSION
```

Expected format (preferred key-value):

```
version: <X.Y.Z>
installed: <YYYY-MM-DD>
method: <install-method>
migrated-from: <source>
```

Legacy fallback format (still supported):

```
<version>
installed: <YYYY-MM-DD>
agent: <agent-key>
```

**If the file is missing:**

- Check legacy `.documentation/DEVSPARK_VERSION`
- If both are missing, report: `VERSION stamp not found — version unknown`
- Proceed to Step 2 to determine what version is actually present

**If the file exists**, extract:

- `INSTALLED_VERSION` — e.g., `1.1.0` (must be semver `X.Y.Z`; otherwise treat as unknown)
- `INSTALL_DATE` — e.g., `2026-02-08`
- `INSTALL_METHOD` — e.g., `copilot-quickstart` or `devspark-cli`

### 2. Detect Latest Available Version

Read `CHANGELOG.md` at the repo root (or `.documentation/CHANGELOG.md`):

- Find the most recent `## [X.Y.Z]` heading
- That is `LATEST_VERSION`

Fallback: read `pyproject.toml` `version = "..."` if CHANGELOG is absent.

### 3. Compare Versions

| Condition | Status |
|-----------|--------|
| `INSTALLED_VERSION == LATEST_VERSION` | Up to date |
| `INSTALLED_VERSION < LATEST_VERSION` | Upgrade available |
| VERSION stamp absent or non-semver | Unknown — treat as upgrade needed |

Display the comparison result clearly:

```
Installed : 1.1.0  (2026-02-08, method: copilot-quickstart)
Latest    : 1.2.4
Status    : UPGRADE AVAILABLE
```

If up to date, skip to Step 6 (Verify Files).

### 4. Classify Files Under `.documentation/`

Separate framework-owned files (overwritten on upgrade) from user-owned files (never
touched). Use this classification:

#### Command Resolution Order

DevSpark uses a **3-tier override system** for command prompts. When an AI agent
runs a `/devspark.*` command, it resolves the prompt in this order (first match wins):

```text
1. .documentation/{git-user}/commands/   ← Per-user overrides (via /devspark.personalize)
2. .documentation/commands/              ← Team customizations (yours to edit freely)
3. .devspark/defaults/commands/     ← Stock DevSpark prompts (upgrade overwrites ONLY this)
```

**Key principle: upgrades NEVER touch `.documentation/commands/`.** They only write
to `.devspark/defaults/commands/`. Your team's customizations in
`.documentation/commands/` always take priority and are never lost.

After an upgrade, the team can compare `defaults/commands/` vs `commands/` to see
what changed and selectively merge improvements they want.

#### Framework-owned (safe to overwrite on upgrade)

These are written to `.devspark/` and should match the latest version:

- `.devspark/defaults/commands/devspark.*.md` — stock prompt templates
- `.devspark/templates/` — stock helper templates
- `.devspark/scripts/bash/*.sh`
- `.devspark/scripts/powershell/*.ps1`
- `.devspark/VERSION`
- Agent shim files:
  - `.github/agents/*.agent.md`
  - `.github/prompts/*.prompt.md`
  - `.claude/commands/devspark.*.md`
  - `.cursor/commands/devspark.*.md`
  - `.windsurf/workflows/devspark.*.md`
  - *(and equivalents for other supported agents)*

#### User-owned (NEVER overwritten)

These are written by the project team and must be preserved:

- `.documentation/commands/` — team-customized command prompts (the working copies)
- `.documentation/{git-user}/commands/` — per-user personalized prompts
- `.documentation/scripts/` — team-customized script overrides (see Script Resolution below)
- `.documentation/specs/` — all feature specifications, plans, and tasks
- `.documentation/memory/constitution.md` — project constitution
- `.documentation/devspark.json` — platform configuration (github/azdo/gitlab)
- `.documentation/copilot/` — session artifacts and audit history
- `.documentation/decisions/` — ADRs
- `.documentation/releases/` — release archives
- `.documentation/quickfixes/` — active quickfixes
- `CHANGELOG.md` (repo root)
- Any file not listed in the framework-owned category

#### Script Resolution Order

Scripts use a **2-tier override system**. When a command runs a script, it resolves
the script in this order (first match wins):

```text
1. .documentation/scripts/{bash|powershell}/   ← Team overrides (yours to edit freely)
2. .devspark/scripts/{bash|powershell}/        ← Stock scripts (upgrade overwrites ONLY this)
```

**Key principle: upgrades NEVER touch `.documentation/scripts/`.** They only write
to `.devspark/scripts/`. Your team's script customizations in
`.documentation/scripts/` always take priority and are never lost.

Common reasons to override a script:

- Platform adaptation (Azure DevOps instead of GitHub)
- Custom CI/CD integration
- Organization-specific authentication or tooling

### 5. Identify Stale Files

Check for signs that the install needs updating:

| Check | Issue | Severity |
|-------|-------|----------|
| `.devspark/VERSION` absent (and legacy stamp absent) | No version stamp | HIGH |
| VERSION stamp present but older than `LATEST_VERSION` | Out of date | MEDIUM |
| Old `devspark.*-old.md` command files in agent folder | Leftover duplicates | LOW |

Report findings before proceeding.

Also check for `.documentation/commands/` overrides that shadow commands with structural contract changes, especially `/devspark.specify`, `/devspark.plan`, `/devspark.tasks`, `/devspark.implement`, and `/devspark.create-pr`. Warn the user explicitly when an override may mask a stock routing, frontmatter, or lifecycle change and recommend a manual diff/merge.

### 6. Verify Framework Files (even if up to date)

Even when the version matches, check that all expected framework files are present.
List any that are **missing** from the expected locations.

Missing framework files should be reported as:

```
MISSING: .devspark/scripts/powershell/setup-plan.ps1
MISSING: .github/agents/devspark.specify.agent.md
```

### 7. Perform the Upgrade

**If `--dry-run`**: Display the full plan and stop. Do not modify files.

**Otherwise:**

#### 7a. Update stock defaults

Write the latest DevSpark prompt templates to `.devspark/defaults/commands/`
and stock scripts to `.devspark/scripts/`.
These directories are framework-owned and safe to overwrite completely.

**Important**: Do NOT write to `.documentation/commands/` or `.documentation/scripts/`.
Those directories belong to the team. Only `.devspark/defaults/commands/` and
`.devspark/scripts/` are updated.

If using the advanced CLI path:

```bash
devspark upgrade
```

If CLI is not installed and you still want the advanced CLI path:

```bash
uv tool install devspark-cli --force \
  --from git+https://github.com/markhazleton/devspark.git
```

#### 7b. Show what changed

After updating `defaults/commands/` and `.devspark/scripts/`, compare against the
team's working copies:

```
Changed prompts (defaults/ vs commands/):
  devspark.specify.md   — 12 lines differ
  devspark.release.md   — new prompt (not in commands/ yet)
  devspark.critic.md    — identical (no action needed)

Changed scripts (.devspark/scripts/ vs .documentation/scripts/):
  get-pr-context.ps1    — 8 lines differ (team has custom override)
  platform.ps1          — new script (not in team overrides)
  common.ps1            — no team override (stock version used)
```

Offer to show diffs for any changed files so the team can decide what to merge.

**Script merge guidance:**

- If the team has overridden a script that changed upstream, show the diff
  and let the team decide whether to merge the upstream improvements
- If a new stock script was added, inform the team — no action needed unless
  they want to customize it
- Never silently overwrite `.documentation/scripts/`

**Legacy migration collision guidance:**

- If legacy `.documentation/`, root `scripts/`, root `templates/`, or root `specs/` content is migrated and an equivalent file already exists under `.documentation/`, keep the existing `.documentation/` file.
- Report the skipped legacy file and preserve it in the corresponding `.old/` backup for manual review.
- Never silently replace active `.documentation/` overrides with legacy content during upgrade.

### 8. Post-Upgrade Verification

After the upgrade completes:

1. **Read `.devspark/VERSION` again** — confirm version updated
2. **Verify `.devspark/defaults/commands/` has latest prompts**
3. **Confirm `.documentation/commands/` is untouched** — team customizations preserved
4. **Confirm `constitution.md` is intact** (never touched by upgrades)

Report a post-upgrade summary:

```
Post-Upgrade Verification
  VERSION stamp      : 1.2.4  (was 1.1.0)
  defaults/commands/ : updated (27 prompts)
  commands/          : unchanged (team customizations preserved)
  stock scripts/     : updated (15 scripts)
  team scripts/      : unchanged (overrides preserved)
  constitution.md    : untouched (never modified by upgrades)
```

### 9. Output Final Summary

#### Upgrade performed

```
DevSpark Upgrade Summary
  Previous Version : <INSTALLED_VERSION>
  New Version      : <LATEST_VERSION>
  Install Method   : <INSTALL_METHOD>
  Date             : <TODAY>

Stock prompts updated in .devspark/defaults/commands/.
Stock scripts updated in .devspark/scripts/.
Team customizations in .documentation/commands/ and .documentation/scripts/ are untouched.

To merge specific improvements into your team prompts:
  Compare .devspark/defaults/commands/ vs .documentation/commands/
To merge script improvements:
  Compare .devspark/scripts/ vs .documentation/scripts/

Next steps:
  1. Review changes: git diff
  2. Test: run a slash command in your AI assistant (e.g., /devspark.specify)
  3. Commit: git add -A && git commit -m "chore: upgrade devspark to vX.Y.Z"
```

#### Already up to date

```
DevSpark is up to date.
  Version : <INSTALLED_VERSION>
  Method  : <INSTALL_METHOD>
  Date    : <INSTALL_DATE>
```

#### Dry run

```
Dry Run — No changes made.

Would upgrade: <INSTALLED_VERSION> -> <LATEST_VERSION>
Framework files to update: <N>
User files preserved: .documentation/specs/, constitution.md, session artifacts

To apply:
  devspark upgrade
```

---

## Guidelines

### User Data is Sacred

Never modify or delete:

- `.documentation/commands/` — team-customized prompts
- `.documentation/{git-user}/commands/` — per-user personalized prompts
- `.documentation/scripts/` — team-customized script overrides
- `.documentation/specs/` and all contents
- `.documentation/devspark.json` — platform configuration
- `constitution.md`
- `.documentation/copilot/`
- `.documentation/decisions/`
- `.documentation/releases/`
- Any file the user created that is not in `.devspark/`

### Non-Destructive by Default

Always check before replacing framework files. If `--dry-run` is specified,
produce only the plan — never modify files.

### Version Stamp is Authoritative

`.devspark/VERSION` is the primary source of truth for the installed version in a
consumer project. Legacy `.documentation/DEVSPARK_VERSION` may appear in older
installs and should be read only as a fallback. After any successful upgrade,
verify `.devspark/VERSION` was updated. If the stamp is absent after an upgrade,
warn the user and suggest re-running `devspark upgrade`.

### Constitution is Never Touched

The constitution (`constitution.md`) is user-owned and NEVER modified by upgrades.
No backup is needed because the upgrade process does not touch it.

## Context

$ARGUMENTS
