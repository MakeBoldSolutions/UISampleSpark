````markdown
---
description: Perform comprehensive codebase audit against project constitution/standards, producing structured compliance report
handoffs:
  - label: View Audit History
    agent: devspark.site-audit
    prompt: Show me previous audit reports in .documentation/copilot/audit/
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command performs a comprehensive codebase audit against the project constitution/standards document. It scans the entire repository (or specified scope) for compliance violations, code quality issues, unused dependencies, and architectural concerns.

**IMPORTANT**: This command **only provides analysis** - it does not make any code changes.

## Prerequisites

- Project constitution at `/.documentation/memory/constitution.md` (REQUIRED)
- PowerShell 7+ (for script execution)
- pip-audit (optional, for Python security scanning)

## Scope Options

Parse `$ARGUMENTS` for scope flags:

| Flag | Description |
|------|-------------|
| `--scope=full` | Complete audit (default) - all checks |
| `--scope=constitution` | Constitution compliance only |
| `--scope=packages` | Package/dependency analysis only |
| `--scope=quality` | Code quality metrics only |
| `--scope=unused` | Unused code/dependencies detection |
| `--scope=duplicate` | Duplicate code detection |
| `--scope=comments` | Stale comments and spec references only |

If no scope specified, default to `--scope=full`.

## Outline

**Multi-app support**: If this repository uses multi-app mode (`.documentation/devspark.json` exists with `mode: "multi-app"`), check for `--app <id>` in the user input to scope this workflow to a specific application. When app context is provided, resolve artifacts from `{app.path}/.documentation/` instead of the repository root `.documentation/`. Print the resolved scope (app name, doc root) at the start of output.

### 1. Initialize Audit Context

> **Script Resolution**: Before running `.devspark/scripts/powershell/site-audit.ps1 $ARGUMENTS -Json`, apply the 2-tier override check — if `.documentation/scripts/powershell/<filename>` (PowerShell) or `.documentation/scripts/bash/<filename>` (Bash) exists on disk, run that file instead, preserving all arguments. Team overrides in `.documentation/scripts/` always take priority over `.devspark/scripts/`.

Run `.devspark/scripts/powershell/site-audit.ps1 $ARGUMENTS -Json` to gather codebase data and parse JSON output for:
- `REPO_ROOT`: Repository root path
- `CONSTITUTION_PATH`: Path to constitution file
- `FILES`: Categorized file listings
- `PACKAGES`: Dependency information
- `METRICS`: Code metrics (line counts, file counts)

Treat pre-scan JSON as summary context:
- Use `files.counts` and sampled file arrays as the primary source.
- Do not assume sampled arrays are exhaustive.
- Only request full inventories when explicitly needed and user-approved.

Execution limits (required):
- Max findings in report: 5 highest-signal items
- Max broad follow-up searches: 6
- Max file reads per finding: 3
- Stop early once evidence is sufficient for high-confidence findings
- If confidence is low, ask one clarifying question instead of broadening scope

**Error Handling**:
If the script fails:
- **Constitution missing**: Guide user to run `/devspark.constitution`
- **Script execution failed**: Provide PowerShell troubleshooting

For single quotes in args like "I'm auditing", use escape syntax: e.g 'I'\''m auditing' (or double-quote if possible: "I'm auditing").

### 2. Load Constitution

Read and parse `/.documentation/memory/constitution.md`:
- Extract all core principles with their names
- Identify MUST requirements (non-negotiable/mandatory)
- Identify SHOULD requirements (recommended)
- Note constitution version and amendment date
- Build a checklist of principles to audit against

If constitution doesn't exist:
- **STOP** and inform user that constitution is required
- Provide guidance: "Run `/devspark.constitution` to create project principles first"
- Do not proceed with audit

### 3. File Discovery and Categorization

Using script output or file system scan, categorize files:

#### Categories
- **Source Code**: `.py`, `.ts`, `.js`, `.cs`, `.java`, `.go`, `.rs`, etc.
- **Configuration**: `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.ini`, `*.env*`
- **Documentation**: `*.md`, `*.rst`, `*.txt`
- **Tests**: Files in `test*/`, `*_test.*`, `*.test.*`, `*_spec.*`
- **Scripts**: `*.sh`, `*.ps1`, `*.bash`
- **Build/CI**: `Dockerfile*`, `.github/workflows/*`, `Makefile`, `*.gradle`

#### Exclusions
Skip these by default:
- `node_modules/`, `venv/`, `.venv/`, `__pycache__/`
- `.git/`, `.vs/`, `.idea/`
- `dist/`, `build/`, `bin/`, `obj/`
- `*.min.js`, `*.map`

### 4. DevSpark Version Check

Before auditing code, check whether the project's DevSpark installation is
current. Stale installations may have outdated command files or missing framework scripts.

#### A. Read Version Stamp

Check for `.devspark/VERSION` first (fallback: legacy `.documentation/DEVSPARK_VERSION`):

- **If both are missing**: Flag `VER1` — stamp absent, version unknown (HIGH)
- **If present**: Parse `version`, `installed`, and `method` fields (legacy stamp may use `agent`)

#### B. Detect Latest Version

Read the most recent `## [X.Y.Z]` entry in `CHANGELOG.md` (repo root) to get
`LATEST_VERSION`. Fallback: read `version = "..."` from `pyproject.toml`.

#### C. Compare and Flag

| Condition | Finding ID | Severity |
|-----------|-----------|---------|
| `.devspark/VERSION` absent and legacy stamp absent | VER1 | HIGH |
| Installed version < latest version | VER2 | MEDIUM |
| Agent command files reference `.documentation/` or root `memory/`, `scripts/`, `templates/`, or `specs/` paths | VER3 | HIGH |
| Root-level `memory/`, `scripts/`, `templates/`, or `specs/` directories exist | VER4 | HIGH |
| Old `devspark.*-old.md` files in agent folder | VER5 | LOW |

Include in the audit report under a **DevSpark Version** section:

```markdown
## DevSpark Version

| Field | Value |
|-------|-------|
| Installed Version | {version or "absent"} |
| Latest Version    | {LATEST_VERSION} |
| Install Date      | {installed field} |
| Method            | {method or agent field} |
| Status            | UP TO DATE / UPGRADE AVAILABLE / UNKNOWN |
```

If VER1 or VER2 is present, add to the Recommendations section:
> Run the remote upgrade prompt or `/devspark.upgrade` to update DevSpark.

### 5. Spec Lifecycle Audit (Anti-Pattern Detection)

Scan `/.documentation/specs/` for spec directories and flag lifecycle violations. This is critical to prevent incomplete specs from being merged to main.

#### A. Scan All Spec Directories

For each directory in `/.documentation/specs/` (excluding `pr-review/`):
1. Check if `spec.md` exists
2. Read the `**Status**:` field (valid values: `Draft`, `In Progress`, `Complete`)
3. Check if `tasks.md` exists and count completed vs incomplete tasks

#### B. Flag Anti-Patterns

| Condition | Finding ID | Severity | Description |
|-----------|-----------|----------|-------------|
| Spec with `Status: Draft` on main branch | SPEC1 | **CRITICAL** | Draft spec merged to main — must be Complete before merge |
| Spec with `Status: In Progress` on main branch | SPEC2 | **CRITICAL** | In-progress spec merged to main — implementation not finished |
| Spec with incomplete tasks (`- [ ]`) on main branch | SPEC3 | **HIGH** | Tasks not all checked off but spec is on main |
| Spec exists but `tasks.md` missing | SPEC4 | **MEDIUM** | Spec has no task breakdown — may be abandoned or pre-planning |
| Spec marked `Complete` but has incomplete tasks | SPEC5 | **HIGH** | Status/task mismatch — spec says Complete but tasks disagree |

#### C. Include in Report

Add a **Spec Lifecycle** section to the audit report:

```markdown
## Spec Lifecycle

### Spec Status Summary

| Spec Directory | Status | Tasks | Complete | Incomplete | Finding |
|----------------|--------|-------|----------|------------|---------|
| 001-feature-x  | Complete | 12  | 12       | 0          | ✅ OK   |
| 002-feature-y  | In Progress | 8 | 5     | 3          | ❌ SPEC2, SPEC3 |
| 003-feature-z  | Draft   | 0   | 0        | 0          | ❌ SPEC1, SPEC4 |

### Spec Lifecycle Findings

| ID | Spec | Issue | Severity | Recommendation |
|----|------|-------|----------|----------------|
| SPEC1 | 003-feature-z | Draft spec on main branch | CRITICAL | Complete implementation or remove spec |
| SPEC2 | 002-feature-y | In-progress spec on main branch | CRITICAL | Complete all tasks and mark spec Complete |
```

If no spec lifecycle issues found, note: "All specs on main branch have Complete status with all tasks checked off."

### 6. Constitution Compliance Audit

For **each principle** in the constitution:

#### A. Pattern Detection
Based on principle type, scan for violations:

**Security Principles**:
- Hardcoded secrets (API keys, passwords, tokens)
- Insecure patterns (`eval()`, `exec()`, SQL string concatenation)
- Missing input validation patterns
- Exposed sensitive data in logs

**Code Quality Principles**:
- Naming convention violations
- Missing type hints/annotations
- Excessive function length (>50 lines)
- Deep nesting (>4 levels)
- Magic numbers/strings

**Architecture Principles**:
- Circular dependencies
- Layer violations (e.g., UI calling DB directly)
- Missing abstractions
- Coupling issues

**Testing Principles**:
- Source files without corresponding tests
- Test coverage patterns
- Missing test fixtures

**Documentation Principles**:
- Missing docstrings/comments
- Outdated README references
- Missing API documentation

#### B. Generate Findings
For each violation found:
- **ID**: Unique identifier (SEC1, QUAL1, ARCH1, TEST1, DOC1, etc.)
- **Principle**: Name of constitution principle violated
- **File:Line**: Exact location
- **Issue**: Specific description
- **Recommendation**: Concrete fix

### 7. Package/Dependency Audit

#### A. Detect Package Manager
Identify from files present:
- `requirements.txt`, `pyproject.toml`, `setup.py` → Python/pip
- `package.json`, `package-lock.json` → Node/npm
- `Cargo.toml` → Rust/cargo
- `go.mod` → Go modules
- `*.csproj`, `packages.config` → .NET/NuGet

#### B. Dependency Analysis
For each detected package manager:
- **Outdated packages**: Compare versions to latest
- **Security vulnerabilities**: Run `pip-audit`, `npm audit`, etc.
- **Unused dependencies**: Detect imported but unused
- **Missing dependencies**: Used but not declared
- **License compliance**: Check for incompatible licenses

#### C. Dependency Graph
- Identify direct vs transitive dependencies
- Flag heavy transitive chains
- Note conflicting version requirements

### 8. Code Quality Metrics

Calculate and report:

#### Size Metrics
- Total lines of code (excluding blanks/comments)
- Lines per file (average, max)
- Files per directory (average, max)

#### Complexity Indicators
- Files with excessive length (>500 lines)
- Functions with high cyclomatic complexity
- Deep nesting occurrences
- Large classes/modules

#### Maintainability Signals
- Code duplication percentage
- TODO/FIXME/HACK comment count
- Commented-out code blocks
- Inconsistent formatting patterns

### 9. Stale Comments and Spec References Audit

Scan source files for code comments that have lost their value or reference completed work.

#### A. Completed Spec References

Search for comments that reference specs, phases, or tasks that are now complete:

```text
# spec 026
# FR-013
# T006
# Phase 5
# TODO(spec-018)
# See spec-032
```

For each match:
- Verify whether the referenced spec/task is actually complete (check `/.documentation/specs/`)
- Flag as stale if the spec is archived or marked `Complete`
- Include file:line and the matched comment in the finding

#### B. Old-Behavior Comments

Detect comments that describe behavior that no longer matches the code:

- Comments with past tense ("previously", "used to", "was changed in")
- Comments referencing removed functions, classes, or variables that no longer exist in the file
- Inline explanations that contradict the current logic in the same block

#### C. Commented-Out Code Blocks

Flag commented-out code blocks exceeding 3 consecutive lines. These accumulate technical debt and should either be deleted in a dedicated commit or restored as active code — use `git blame` to understand the original intent before removing.

#### D. Version Migration Comments

Flag comments of the form "Added in v2.8.0", "Deprecated since v3.0", "TODO: remove after upgrade" when the referenced version is already past. These provide no value over `git blame` and clutter the codebase.

#### False-Positive Suppression Policy

Before flagging any finding in sections 9–11, apply these suppression rules to avoid false positives:

**DO NOT flag**:

1. **Unused imports that are re-exports**: If an import appears in an `__init__.py` or barrel file (e.g., `index.ts`) and is explicitly re-exported with `__all__`, `export`, or a wildcard, suppress the "unused import" finding.

2. **Dead code reachable via dynamic dispatch**: If a function or class appears uncalled but the file registers plugins, uses `getattr`, metaclasses, `importlib`, or decorator-based registries, do not flag it as dead code. Note the dynamic dispatch pattern instead.

3. **Test-only utilities appearing unused from production**: Functions in `test*/`, `conftest.py`, `fixtures/`, or `*_helpers.py` that have no callers in the production source tree are not dead code — they serve test infrastructure. Only flag if the file has no test callers either.

Include findings from this phase in the audit report under **Stale Code Comments**:

```markdown
## Stale Code Comments

### Completed Spec References

| ID | File:Line | Comment | Referenced Spec Status | Action |
|----|-----------|---------|----------------------|--------|
| CMT1 | src/handler.py:45 | `# spec 026` | Archived | Remove comment |

### Commented-Out Code Blocks

| ID | File:Lines | Size | Action |
|----|-----------|------|--------|
| CMT2 | src/utils.py:89-95 | 7 lines | Delete or restore |

### Version Migration Comments

| ID | File:Line | Comment | Action |
|----|-----------|---------|--------|
| CMT3 | src/api.py:12 | `# Added in v2.0` | Remove — no value over git blame |
```

### 10. Unused Code Detection

Scan for potentially unused:

#### Dead Code
- Functions/methods never called
- Classes never instantiated
- Variables assigned but never read
- Imports never used

Apply the false-positive suppression policy from section 9 before flagging any unused code.

#### Dead Files
- Source files not imported anywhere
- Test files for non-existent sources
- Config files not referenced

#### Dead Dependencies
- Packages in requirements but never imported
- DevDependencies in package.json unused

### 11. Duplicate Code Detection

Identify copy-paste patterns:

#### Detection Criteria
- Exact duplicate blocks (>10 lines)
- Near-duplicate blocks (>80% similarity, >15 lines)
- Repeated patterns across files

#### Report Format
For each duplicate:
- Locations (file:line ranges)
- Similarity percentage
- Suggested consolidation approach

### 12. Severity Classification

Apply consistent severity across all findings:

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Security vulnerability, constitution MUST violation, blocking issue |
| **HIGH** | Constitution SHOULD violation, significant quality issue, outdated security packages |
| **MEDIUM** | Code quality concern, maintainability issue, missing tests |
| **LOW** | Style suggestion, minor improvement, optimization opportunity |

### 13. Generate Audit Report

Create comprehensive report at `/.documentation/copilot/audit/YYYY-MM-DD_results.md`:

#### Ensure Directory Exists
- Check if `/.documentation/copilot/audit/` exists
- Create directory structure if missing

#### Report Structure

Use this format:

```markdown
# Codebase Audit Report

## Audit Metadata

- **Audit Date**: [YYYY-MM-DD HH:MM:SS UTC]
- **Scope**: [full|constitution|packages|quality|unused|duplicate]
- **Auditor**: devspark.site-audit
- **Constitution Version**: [VERSION from constitution]
- **Repository**: [REPO_NAME]

## Executive Summary

### Compliance Score

| Category | Score | Status |
|----------|-------|--------|
| DevSpark Version | [UP TO DATE / UPGRADE AVAILABLE / UNKNOWN] | [Status] |
| Spec Lifecycle | [X] specs on main | [✅ All Complete / ❌ Incomplete specs found] |
| Constitution Compliance | [X]% | [✅ PASS / ⚠️ PARTIAL / ❌ FAIL] |
| Security | [X]% | [Status] |
| Code Quality | [X]% | [Status] |
| Test Coverage | [X]% | [Status] |
| Documentation | [X]% | [Status] |
| Dependencies | [X]% | [Status] |

**Overall Health**: [HEALTHY / NEEDS ATTENTION / CRITICAL ISSUES]

### Issue Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | [X] |
| 🟠 HIGH | [X] |
| 🟡 MEDIUM | [X] |
| 🔵 LOW | [X] |

## Constitution Compliance

### Principle Compliance Matrix

| Principle | Status | Violations | Key Issues |
|-----------|--------|------------|------------|
| [Principle 1] | ✅ PASS | 0 | - |
| [Principle 2] | ⚠️ PARTIAL | 3 | Missing tests for 3 modules |
| [Principle 3] | ❌ FAIL | 12 | Hardcoded credentials found |

### Detailed Violations

| ID | Principle | File:Line | Issue | Severity | Recommendation |
|----|-----------|-----------|-------|----------|----------------|
| SEC1 | Security | src/config.py:45 | Hardcoded API key | CRITICAL | Use environment variable |

## DevSpark Version

| Field | Value |
|-------|-------|
| Installed Version | [version from `.devspark/VERSION`, or "absent"] |
| Latest Version | [LATEST_VERSION] |
| Install Date | [installed field] |
| Agent | [agent field] |
| Status | [UP TO DATE / UPGRADE AVAILABLE / UNKNOWN] |

### Version Findings

| ID | Issue | Severity | Recommendation |
|----|-------|----------|----------------|
| VER1 | VERSION stamp absent | HIGH | Run the remote upgrade prompt to install or refresh the version stamp |
| VER2 | Version X.Y.Z installed, X.Y.Z available | MEDIUM | Run `/devspark.upgrade` to update |

## Security Findings

### Vulnerability Summary

| Type | Count | Severity |
|------|-------|----------|
| Hardcoded Secrets | [X] | CRITICAL |
| Insecure Patterns | [X] | HIGH |
| Missing Validation | [X] | MEDIUM |

### Security Checklist

- [ ] No hardcoded secrets or credentials
- [ ] Input validation present where needed
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Dependencies free of known vulnerabilities
- [ ] Secure configuration practices

### Detailed Security Issues

[List each security finding with file, line, issue, recommendation]

## Package/Dependency Analysis

### Package Manager: [pip/npm/cargo/etc.]

#### Dependency Summary

| Metric | Value |
|--------|-------|
| Total Dependencies | [X] |
| Direct Dependencies | [X] |
| Transitive Dependencies | [X] |
| Outdated | [X] |
| Vulnerable | [X] |
| Unused | [X] |

#### Vulnerable Packages

| Package | Current | Fixed In | Vulnerability | Severity |
|---------|---------|----------|---------------|----------|
| [package] | 1.0.0 | 1.0.1 | CVE-XXXX-XXXX | CRITICAL |

#### Outdated Packages

| Package | Current | Latest | Type |
|---------|---------|--------|------|
| [package] | 1.0.0 | 2.0.0 | Major |

#### Unused Dependencies

| Package | Declared In | Notes |
|---------|-------------|-------|
| [package] | requirements.txt | No imports found |

## Code Quality Analysis

### Metrics Overview

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Total Lines of Code | [X] | - | - |
| Average Lines per File | [X] | <300 | [Status] |
| Max Lines per File | [X] | <500 | [Status] |
| High Complexity Functions | [X] | 0 | [Status] |
| Deep Nesting Occurrences | [X] | 0 | [Status] |
| TODO Comments | [X] | - | INFO |

### Files Requiring Attention

| File | Issue | Metric | Recommendation |
|------|-------|--------|----------------|
| src/large_module.py | Excessive length | 850 lines | Split into smaller modules |

### Quality Issues

| ID | Category | File:Line | Issue | Severity |
|----|----------|-----------|-------|----------|
| QUAL1 | Complexity | src/handler.py:120 | Function exceeds 50 lines | MEDIUM |

## Test Coverage Analysis

### Coverage Summary

| Category | Files | With Tests | Coverage |
|----------|-------|------------|----------|
| Source Files | [X] | [Y] | [Z]% |
| Critical Paths | [X] | [Y] | [Z]% |

### Untested Files

| File | Importance | Recommendation |
|------|------------|----------------|
| src/auth.py | HIGH | Add unit tests for authentication logic |

## Documentation Status

### Documentation Coverage

| Type | Present | Quality |
|------|---------|---------|
| README.md | ✅ | Good |
| API Documentation | ⚠️ | Incomplete |
| Code Comments | ✅ | Adequate |
| Inline Docstrings | ⚠️ | Partial |

### Missing Documentation

| Item | Location | Priority |
|------|----------|----------|
| Function docstring | src/utils.py:45 | MEDIUM |

## Unused Code Analysis

### Potentially Unused Items

| Type | Item | Location | Confidence |
|------|------|----------|------------|
| Function | `deprecated_helper` | src/utils.py:89 | HIGH |
| Import | `unused_module` | src/main.py:5 | HIGH |
| Variable | `old_config` | src/config.py:23 | MEDIUM |

## Duplicate Code Analysis

### Duplicate Blocks Found

| ID | Locations | Lines | Similarity | Recommendation |
|----|-----------|-------|------------|----------------|
| DUP1 | src/a.py:10-25, src/b.py:45-60 | 15 | 100% | Extract to shared function |

## Recommendations

### Immediate Actions (CRITICAL)

1. **[Issue ID]**: [Brief description and fix]
2. **[Issue ID]**: [Brief description and fix]

### High Priority (This Sprint)

1. **[Issue ID]**: [Description and approach]

### Medium Priority (Next Sprint)

1. **[Issue ID]**: [Description]

### Low Priority (Backlog)

1. **[Issue ID]**: [Description]

## Comparative Analysis

[If previous audit exists, show trends]

| Metric | Previous | Current | Trend |
|--------|----------|---------|-------|
| Critical Issues | [X] | [Y] | [↑/↓/→] |
| Code Quality Score | [X]% | [Y]% | [Trend] |

## Next Steps

1. Address all CRITICAL issues before next deployment
2. Schedule HIGH priority items for current sprint
3. Add MEDIUM items to backlog
4. Re-run audit weekly to track progress

---

*Audit generated by devspark.site-audit v1.0*
*Constitution-driven codebase audit for [PROJECT_NAME]*
*Next audit recommended: [DATE + 7 days]*
*To re-run: `/devspark.site-audit` or `/devspark.site-audit --scope=constitution`*
```

### 13. Output Summary to User

Display concise summary:

```
✅ Site Audit Complete!

📄 Report saved: /.documentation/copilot/audit/YYYY-MM-DD_results.md
📅 Audit date: {DATETIME}
🎯 Scope: {SCOPE}

Health Summary:
- 🔴 {COUNT} Critical issues
- 🟠 {COUNT} High priority
- 🟡 {COUNT} Medium priority
- 🔵 {COUNT} Low priority

Constitution Compliance: {X}%
Overall Health: {HEALTHY/NEEDS ATTENTION/CRITICAL}

{If critical issues:}
⚠️ Critical issues require immediate attention:
- {ID}: {Brief description}

View full report: /.documentation/copilot/audit/YYYY-MM-DD_results.md
```

## Guidelines

### Constitution Authority

The constitution is **non-negotiable** and the **authoritative source** for all audit criteria.

All findings must:
- Reference the specific constitution section (by principle name)
- Quote the exact constitution language (MUST/SHOULD/etc.)
- Explain how the code violates the principle
- Use the constitution's own terminology

### Evidence-Based Findings

Every issue must include:
- **Specific location**: File path and line number
- **Code evidence**: Actual code snippet showing the issue
- **Constitution reference**: Which principle is violated
- **Actionable fix**: Specific remediation with example

### Audit Objectivity

- Focus on facts, not opinions
- Base all findings on constitution principles
- Avoid subjective language
- If not in constitution, classify as LOW or skip

### Graceful Error Handling

**If constitution missing**:
```
❌ Cannot perform site audit - Constitution required

The project constitution defines audit criteria. Create one first:

1. Run: /devspark.constitution
2. Define your project's core principles
3. Then retry: /devspark.site-audit

Learn more: https://github.com/MarkHazleton/devspark
```

**If no issues found**:
```
✅ Site Audit Complete - No Issues Found!

Your codebase is fully compliant with the project constitution.

Constitution Compliance: 100%
Overall Health: HEALTHY

Keep up the great work! 🎉

Report saved: /.documentation/copilot/audit/YYYY-MM-DD_results.md
```

### Historical Comparison

When previous audits exist:
- Load most recent audit from `/.documentation/copilot/audit/`
- Compare issue counts by severity
- Show improvement/regression trends
- Highlight newly introduced vs. fixed issues

## Context

$ARGUMENTS
````
