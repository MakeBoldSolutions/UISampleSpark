---
description: Analyze git commit history patterns for contributor velocity, commit hygiene, DORA metrics, AI adoption level, and architecture maturity
handoffs:
  - label: Run Site Audit
    agent: devspark.site-audit
    prompt: Run a full codebase audit to complement commit history insights
  - label: View Harvest Report
    agent: devspark.harvest
    prompt: Review completed specs and stale documentation before archiving
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command analyzes the git commit history to surface development patterns, team velocity, commit quality, and architectural evolution. It helps teams understand how work is flowing through the codebase over time.

**IMPORTANT**: This command **only provides analysis** — it does not make any code changes.

**Privacy note**: Contributor analysis uses anonymized, role-based identifiers (Contributor A, Contributor B, etc.) — never real names or email addresses.

## Scope Options

Parse `$ARGUMENTS` for scope flags:

| Flag | Description |
|------|-------------|
| `--scope=full` | Complete commit audit (default) — all analyses |
| `--scope=velocity` | Monthly velocity tables and phase detection only |
| `--scope=hygiene` | Commit hygiene score only |
| `--scope=dora` | DORA metrics mapping only |
| `--scope=contributors` | Contributor census only (anonymized) |
| `--scope=ai` | AI adoption level classification only |
| `--scope=architecture` | Architecture maturity indicators only |
| `--since=YYYY-MM-DD` | Limit analysis to commits after this date |
| `--until=YYYY-MM-DD` | Limit analysis to commits before this date |
| `--branch=NAME` | Analyze a specific branch (default: current branch) |

Multiple scope flags may be combined: `--scope=velocity,hygiene`

## Outline

### 1. Initialize Audit Context

> **Script Resolution**: Before running `.devspark/scripts/powershell/commit-audit.ps1 $ARGUMENTS -Json`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/commit-audit.ps1 $ARGUMENTS -Json` and parse its JSON output.

Expected fields include:

- `repo_root`
- `branch`
- `total_commits`
- `date_range` (first commit date to last commit date)
- `contributors` (anonymized list with commit counts)
- `commits` (list with sha, date, author_role, message, files_changed, insertions, deletions)
- `report_path`

If the script output is unavailable, fall back to running `git log` commands directly:

```bash
git log --oneline --format="%H|%ad|%s|%an" --date=short
```

Use anonymized role-based contributor IDs consistently throughout the report (Contributor A = most commits, Contributor B = second most, etc.).

### 2. Contributor Census (Anonymized)

Analyze contributor patterns:

- Total unique contributors in the analyzed range
- Commit share per contributor (role-based ID, percentage, commit count)
- Activity periods per contributor (first commit, last commit, active months)
- Identify primary maintainer (highest commit count) and occasional contributors (<5% of commits)
- Bus factor: number of contributors responsible for 80% of commits

Present as a summary table. Do **not** include real names, email addresses, or usernames.

### 3. Monthly Velocity Tables and Phase Detection

#### Monthly Velocity Table

Calculate commits per month across the analysis window:

| Month | Commits | Files Changed | Insertions | Deletions | Net Change |
|-------|---------|---------------|-----------|-----------|------------|
| 2025-01 | 45 | 120 | +2,400 | -800 | +1,600 |
| 2025-02 | 62 | 180 | +4,100 | -1,200 | +2,900 |

#### Phase Detection with Inflection Points

Identify development phases by detecting significant velocity changes (>50% increase or decrease sustained for 2+ months). For small teams or low-volume repositories (<10 commits/month average), lower the threshold to >30% sustained for 1+ month before detecting a phase change, and note the low-volume context in the report.

| Phase | Period | Avg Monthly Commits | Characterization |
|-------|--------|---------------------|-----------------|
| Bootstrap | 2024-10 to 2024-12 | 12 | Initial setup, scaffolding |
| Rapid Build | 2025-01 to 2025-03 | 58 | Feature development sprint |
| Stabilization | 2025-04 to 2025-05 | 22 | Bug fixes, testing, cleanup |

Flag inflection points (sharp increases or drops) and hypothesize likely causes (feature freeze, release, new team member, etc.).

### 4. Commit Hygiene Score (0–100)

Score the commit history on message quality and conventional commit adherence.

#### Scoring Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **Conventional Commits** | 40% | Percentage of commits following `type(scope): description` format |
| **Subject Line Quality** | 25% | Subject lines 10–72 chars, imperative mood, no trailing period |
| **Body Usage** | 15% | Breaking changes and non-trivial commits include a body |
| **Reference Linking** | 10% | Commits referencing issues, PRs, or tickets |
| **WIP / Fix-Up Ratio** | 10% | Inverse: penalize for "WIP", "fix", "temp", "oops", "test" in subject |

#### Score Ranges

| Score | Rating | Meaning |
|-------|--------|---------|
| 85–100 | Excellent | Professional commit discipline |
| 70–84 | Good | Minor improvements available |
| 50–69 | Fair | Inconsistent conventions; worth a team conversation |
| 30–49 | Poor | Significant hygiene issues; recommend squash-merge policy |
| 0–29 | Critical | Ad-hoc messages throughout; no discernible convention |

Include up to 5 example commits that most dragged down the score and a corrected version for each.

### 5. DORA Metrics Mapping

Map available git signals to DORA (DevOps Research and Assessment) metrics.
Reference benchmarks from the DORA State of DevOps Report (latest available year).

| DORA Metric | Git Signal | Estimated Value | Elite Benchmark | Your Status |
|-------------|-----------|----------------|----------------|-------------|
| **Deployment Frequency** | Merge commits to main per month | [N/month] | On-demand (multiple/day) | [Elite/High/Medium/Low] |
| **Lead Time for Changes** | Avg PR open → merge duration (if PR data available) | [N days] | <1 day | [Status] |
| **Change Failure Rate** | Commits with "revert", "fix bug", "hotfix" / total commits | [N%] | <5% | [Status] |
| **Time to Restore** | Avg commits between a revert and its follow-up fix | [N hours est.] | <1 hour | [Status] |

Note any metrics that cannot be reliably estimated from git history alone (e.g., deployment frequency requires CI/CD data).

### 6. AI Adoption Level Classification

Classify the team's AI-assisted development maturity based on commit patterns.

#### Classification Levels

| Level | Name | Indicators |
|-------|------|-----------|
| **0** | None detected | No AI-related signals in commits or file patterns |
| **1** | Experimental | Occasional commits mentioning AI tools; no consistent pattern |
| **2** | Assisted | Consistent use of AI for code generation; human review evident from small corrections |
| **3** | Collaborative | High-volume AI-generated code with systematic human curation; AI tool config files present |
| **4** | AI-Native | Majority of code churn driven by AI agents; human commits primarily reviews and corrections |

#### Detection Signals

- Commit messages mentioning "Copilot", "Claude", "ChatGPT", "ai-generated", "co-authored-by"
- Large batch commits (>500 lines in a single commit) with minimal message context
- Presence of AI tool configuration files (`.github/copilot-instructions.md`, `CLAUDE.md`, `.cursor/`, etc.)
- Short bursts of high-insertion commits followed by correction commits

Report the detected level and the primary evidence used to classify it.

### 7. Architecture Maturity Indicators

Infer architectural evolution from commit patterns without reading full source files.

#### Indicators to Detect

| Indicator | Signal | Maturity Implication |
|-----------|--------|---------------------|
| **Modularization trend** | Increasing number of distinct directories touched per commit decreasing over time | Architecture stabilizing into modules |
| **Test investment** | Ratio of commits touching test files vs. source files | Testing culture |
| **Dependency churn** | Commits modifying `requirements.txt`, `package.json`, `go.mod`, etc. | Dependency management discipline |
| **Configuration drift** | Commits modifying `.env*`, config files without corresponding source changes | Config management issues |
| **Migration patterns** | Commits with "migrate", "schema", "alembic", "flyway" in message | Database evolution discipline |
| **Refactoring cycles** | Periods with high deletion-to-insertion ratios (>0.7) | Deliberate tech debt paydown |

Summarize findings as a brief paragraph and flag any concerning patterns (e.g., high config churn without corresponding tests).

### 8. Generate Commit Audit Report

Write a report to the script-provided `report_path` (or `/.documentation/copilot/commit-audit-YYYY-MM-DD.md` if not provided).

#### Report Structure

```markdown
# Commit Audit Report

## Audit Metadata

- **Audit Date**: [YYYY-MM-DD HH:MM:SS UTC]
- **Branch**: [BRANCH_NAME]
- **Date Range**: [FIRST_COMMIT_DATE] to [LAST_COMMIT_DATE]
- **Total Commits Analyzed**: [N]
- **Auditor**: devspark.commit-audit

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total Commits | [N] | — |
| Active Contributors | [N] | — |
| Bus Factor | [N] | [⚠️ Low / ✅ Healthy] |
| Commit Hygiene Score | [N]/100 | [Rating] |
| AI Adoption Level | Level [N] – [Name] | — |
| Deployment Frequency (est.) | [N/month] | [Elite/High/Medium/Low] |
| Change Failure Rate (est.) | [N%] | [Status] |

## Contributor Census (Anonymized)

[Table from step 2]

## Monthly Velocity

[Table from step 3]

## Development Phases

[Table from step 3 phase detection]

## Commit Hygiene Score: [N]/100 — [Rating]

[Score breakdown table and example commits from step 4]

## DORA Metrics

[Table from step 5]

## AI Adoption Level

**Level [N] — [Name]**

[Evidence and explanation from step 6]

## Architecture Maturity Indicators

[Summary from step 7]

## Recommendations

[Up to 5 actionable recommendations ranked by impact]

1. [Recommendation 1]
2. [Recommendation 2]
```

### 9. Output Summary to User

Display a concise summary:

```text
✅ Commit Audit Complete!

📄 Report saved: /.documentation/copilot/commit-audit-{DATE}.md
📅 Range: {FIRST_DATE} to {LAST_DATE}
🔢 {N} commits analyzed across {N} contributors

Highlights:
- Commit Hygiene: {SCORE}/100 ({RATING})
- AI Adoption: Level {N} – {NAME}
- Deployment Frequency: {N}/month ({STATUS})
- Bus Factor: {N} ({STATUS})

View full report: /.documentation/copilot/commit-audit-{DATE}.md
```

## Guidelines

### Privacy

- Never include real contributor names, usernames, or email addresses in the report
- Use stable role-based identifiers (Contributor A, B, C, ...) assigned by commit count descending
- If git log includes author info, anonymize it before including any output in the report

### Estimation Transparency

- Clearly label all DORA metric values as estimates derived from git signals
- Note which metrics require CI/CD data for accurate measurement
- Do not overstate confidence in inferred values

### Actionable Output

- Keep the Recommendations section to ≤5 items, ordered by impact
- Each recommendation should reference specific findings from the report
- Focus on patterns, not individual commits or contributors

## Context

$ARGUMENTS
