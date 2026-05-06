#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pre-scan repository for harvest targets: completed specs, stale docs, spec-linked code comments.

.DESCRIPTION
    This script collects inventory data for the /devspark.harvest agent:
    - Spec folders with completion status (tasks.md analysis, CHANGELOG cross-reference)
    - Documentation files categorized by staleness (reviews, audits, drafts, session notes, backups, orphans)
    - Source code comments that reference specs, plans, tasks, or FRs
    - CHANGELOG gap analysis (completed specs not yet in CHANGELOG)
    - Existing .archive/ contents to avoid duplicate archival

    Output is JSON for LLM consumption.

.PARAMETER Scope
    Optional scope filter: 'full', 'specs', 'docs', 'comments', 'changelog', 'scan'
    Default: 'full'

.PARAMETER Json
    Output raw JSON only (suppresses progress output). Useful for piping to jq or LLM context.

.PARAMETER SampleLimit
    Maximum number of items per category to include in output (default: 100).

.EXAMPLE
    .\.documentation\scripts\powershell\harvest.ps1
    .\.documentation\scripts\powershell\harvest.ps1 -Scope specs
    .\.documentation\scripts\powershell\harvest.ps1 -Scope comments
    .\.documentation\scripts\powershell\harvest.ps1 -Json
#>

param(
    [ValidateSet('full', 'specs', 'docs', 'comments', 'changelog', 'scan')]
    [string]$Scope = 'full',
    [switch]$Json,
    [int]$SampleLimit = 100
)

# Import common functions
. (Join-Path $PSScriptRoot 'common.ps1')

# Load optional app-scoped context before scanning harvest candidates.
if (-not (Get-Command Detect-DevSparkMode -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot/common.ps1"
}

$ErrorActionPreference = 'Continue'

# Get repository root
$repoRoot = Get-RepoRoot

function Update-CountMap {
    param(
        [hashtable]$Map,
        [string]$Key
    )

    if (-not $Map.ContainsKey($Key)) {
        $Map[$Key] = 0
    }

    $Map[$Key]++
}

function Get-DocTaxon {
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $normalizedPath = $RelativePath -replace '\\', '/'
    $deprecatedPattern = 'pydantic_agent|AGENT_REGISTRY|REPO_MODE_AGENTS|data_field|function_name|display_card_id'

    if (
        $normalizedPath -match '^docs/' -or
        ($normalizedPath -match '^\.documentation/' -and $Content -match $deprecatedPattern)
    ) {
        return 'STALE_REFERENCE'
    }

    switch -Regex ($normalizedPath) {
        '^CHANGELOG\.md$' { return 'HISTORICAL_RECORD' }
        '^\.github/copilot-instructions\.md$' { return 'AUTHORITATIVE_REFERENCE' }
        '^\.documentation/memory/' { return 'AUTHORITATIVE_REFERENCE' }
        '^\.documentation/decisions/' { return 'ENGINEERING_PATTERN' }
        '^\.documentation/releases/' { return 'HISTORICAL_RECORD' }
        '^\.documentation/quickfixes/' { return 'HISTORICAL_RECORD' }
        '^\.documentation/specs/pr-review/' { return 'HISTORICAL_RECORD' }
        '^\.documentation/copilot/audit/' { return 'HISTORICAL_RECORD' }
        '^\.documentation/copilot/' { return 'RESEARCH_OR_CONTEXT' }
        '^\.documentation/reference-data/' { return 'REFERENCE_DATA' }
        '^\.documentation/templates/' { return 'ENGINEERING_PATTERN' }
        '^\.documentation/scripts/' { return 'OPERATIONS_RUNBOOK' }
        '^\.documentation/' { return 'AUTHORITATIVE_REFERENCE' }
        default { return 'AUTHORITATIVE_REFERENCE' }
    }
}

function Get-DocScoreBreakdown {
    param(
        [string]$Taxon,
        [string]$RelativePath,
        [string]$Content,
        [datetime]$LastModified,
        [string]$Category
    )

    $operational = 0
    $authority = 0
    $uniqueness = 0
    $freshness = 0

    switch ($Taxon) {
        'AUTHORITATIVE_REFERENCE' { $operational = 38; $authority = 24; $uniqueness = 18; $freshness = 13 }
        'CONSUMER_GUIDE'          { $operational = 35; $authority = 21; $uniqueness = 16; $freshness = 14 }
        'OPERATIONS_RUNBOOK'      { $operational = 34; $authority = 20; $uniqueness = 15; $freshness = 12 }
        'ENGINEERING_PATTERN'     { $operational = 31; $authority = 22; $uniqueness = 16; $freshness = 13 }
        'REFERENCE_DATA'          { $operational = 27; $authority = 16; $uniqueness = 14; $freshness = 13 }
        'ANALYTICS_ASSET'         { $operational = 28; $authority = 15; $uniqueness = 14; $freshness = 12 }
        'HISTORICAL_RECORD'       { $operational = 20; $authority = 18; $uniqueness = 10; $freshness = 10 }
        'RESEARCH_OR_CONTEXT'     { $operational = 15; $authority = 9;  $uniqueness = 12; $freshness = 10 }
        'STALE_REFERENCE'         { $operational = 10; $authority = 5;  $uniqueness = 8;  $freshness = 4 }
        default                   { $operational = 20; $authority = 10; $uniqueness = 10; $freshness = 10 }
    }

    $daysOld = ((Get-Date) - $LastModified).Days
    if ($daysOld -le 7) {
        $freshness += 2
    } elseif ($daysOld -gt 120 -and $daysOld -le 240) {
        $freshness -= 2
    } elseif ($daysOld -gt 240) {
        $freshness -= 4
    }

    if ($RelativePath -in @('CHANGELOG.md', '.github/copilot-instructions.md')) {
        $authority += 1
        $uniqueness += 2
    }

    if ($Content -match 'HEAD on the `[^`]+` branch') {
        $freshness -= 5
    }

    if ($Content -match 'pydantic_agent|AGENT_REGISTRY|REPO_MODE_AGENTS|data_field|function_name|display_card_id') {
        $authority -= 8
        $freshness -= 6
    }

    if ($Category -in @('completed_review', 'completed_audit', 'stale_draft', 'session_notes', 'backup', 'orphaned', 'legacy_root_doc')) {
        $operational = [Math]::Min($operational, 18)
        $authority = [Math]::Min($authority, 14)
    }

    $operational = [Math]::Max(0, [Math]::Min(40, $operational))
    $authority = [Math]::Max(0, [Math]::Min(25, $authority))
    $uniqueness = [Math]::Max(0, [Math]::Min(20, $uniqueness))
    $freshness = [Math]::Max(0, [Math]::Min(15, $freshness))

    return @{
        operational_relevance = $operational
        authority = $authority
        uniqueness = $uniqueness
        freshness = $freshness
        total = $operational + $authority + $uniqueness + $freshness
    }
}

function Get-DocDisposition {
    param(
        [string]$RelativePath,
        [string]$Category,
        [string]$Taxon,
        [int]$Score,
        [datetime]$LastModified
    )

    if ($Category -in @('backup', 'orphaned', 'completed_review', 'completed_audit', 'stale_draft', 'session_notes', 'legacy_root_doc')) {
        return 'archive'
    }

    if ($Taxon -eq 'STALE_REFERENCE') {
        return 'rewrite'
    }

    if ($RelativePath -match '^\.documentation/copilot/harvest-\d{4}-\d{2}-\d{2}\.md$') {
        $daysOld = ((Get-Date) - $LastModified).Days
        if ($daysOld -gt 30) {
            return 'archive'
        }
    }

    if ($Score -ge 75) {
        return 'keep'
    }
    if ($Score -ge 60) {
        return 'keep_refresh'
    }
    if ($Score -ge 40) {
        return 'consolidate'
    }

    return 'archive'
}

# Initialize result object
$result = @{
    harvest_date      = (Get-Date -Format 'yyyy-MM-dd')
    harvest_timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    repo_root         = $repoRoot
    scope             = $Scope
    report_path       = '.documentation/copilot/harvest-' + (Get-Date -Format 'yyyy-MM-dd') + '.md'
    specs             = @()
    docs              = @{
        all                = @()
        living_reference  = @()
        completed_reviews = @()
        completed_audits  = @()
        stale_drafts      = @()
        session_notes     = @()
        backup_files      = @()
        orphaned_files    = @()
        impl_plans        = @()
        release_docs      = @()
        quickfix_records  = @()
        legacy_root_docs  = @()
        taxonomy_counts   = @{}
        disposition_counts = @{}
    }
    code_comments     = @()
    changelog_gaps    = @()
    changelog_entries = @()
    bak_files         = @()
    archive_existing  = @()
    path_roots        = @{
        canonical_documentation = '.documentation/'
        legacy_roots = @()
    }
    summary           = @{
        specs_completed      = 0
        specs_in_progress    = 0
        specs_draft          = 0
        docs_to_archive      = 0
        code_comments_found  = 0
        changelog_gaps       = 0
        bak_files_found      = 0
    }
}

# ============================================================================
# PHASE 1: Spec Inventory
# ============================================================================

if ($Scope -in @('full', 'specs', 'scan')) {
    if (-not $Json) { Write-Host "[SPECS] Scanning spec folders..." -ForegroundColor Cyan }

    $specsDir = Join-Path $repoRoot '.documentation/specs'

    # Load CHANGELOG to cross-reference
    $changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
    $changelogContent = ''
    if (Test-Path $changelogPath) {
        $changelogContent = Get-Content $changelogPath -Raw -ErrorAction SilentlyContinue
    }

    # Load existing PR reviews
    $reviewsDir = Join-Path $repoRoot '.documentation/specs/pr-review'
    $existingReviews = @()
    if (Test-Path $reviewsDir) {
        $existingReviews = Get-ChildItem $reviewsDir -Filter '*.md' -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Name }
    }

    if (Test-Path $specsDir) {
        Get-ChildItem $specsDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'pr-review' } |
            ForEach-Object {
            $specFolder = $_
            $specName   = $specFolder.Name
            $specPath   = $specFolder.FullName

            # Extract spec number (e.g., 001-name → '001')
            $specNumber = ''
            if ($specName -match '^(\d{3,4})-') {
                $specNumber = $matches[1]
            }

            # --- tasks.md analysis ---
            $tasksPath       = Join-Path $specPath 'tasks.md'
            $totalTasks      = 0
            $completedTasks  = 0
            $incompleteTasks = 0
            $hasTasks        = Test-Path $tasksPath

            if ($hasTasks) {
                $tasksContent    = Get-Content $tasksPath -Raw -ErrorAction SilentlyContinue
                $totalTasks      = ([regex]::Matches($tasksContent, '(?m)^- \[([ Xx])\]')).Count
                $completedTasks  = ([regex]::Matches($tasksContent, '(?m)^- \[[Xx]\]')).Count
                $incompleteTasks = $totalTasks - $completedTasks
            }

            # --- spec.md / plan.md presence ---
            $hasSpec = Test-Path (Join-Path $specPath 'spec.md')
            $hasPlan = Test-Path (Join-Path $specPath 'plan.md')

            # --- CHANGELOG cross-reference ---
            $inChangelog = $false
            if ($specNumber -and $changelogContent) {
                $inChangelog = $changelogContent -match "\b$([regex]::Escape($specName))\b|\[Spec\s+$([int]$specNumber)\]"
            }

            # --- PR review cross-reference ---
            $prReviewFound = ''
            foreach ($review in $existingReviews) {
                $reviewContent = Get-Content (Join-Path $reviewsDir $review) -Raw -ErrorAction SilentlyContinue
                if ($reviewContent -and $reviewContent -match [regex]::Escape($specName)) {
                    $prReviewFound = $review
                    break
                }
            }
            # Also check .archive for PR reviews
            $archiveReviewsDir = Join-Path $repoRoot '.archive'
            if ($prReviewFound -eq '' -and (Test-Path $archiveReviewsDir)) {
                Get-ChildItem $archiveReviewsDir -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($prReviewFound -eq '') {
                        $archContent = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                        if ($archContent -and $archContent -match [regex]::Escape($specName)) {
                            $prReviewFound = "(archived) $($_.Name)"
                        }
                    }
                }
            }

            # --- Determine status ---
            $status = 'draft'
            if ($hasTasks -and $totalTasks -gt 0 -and $incompleteTasks -eq 0 -and $inChangelog) {
                $status = 'completed'
            } elseif ($hasTasks -and $totalTasks -gt 0 -and $incompleteTasks -eq 0) {
                $status = 'completed-needs-changelog'
            } elseif ($hasTasks -and $completedTasks -gt 0) {
                $status = 'in-progress'
            } elseif ($hasPlan -or $hasSpec) {
                $status = 'draft'
            }

            # --- File list ---
            $specFiles = Get-ChildItem $specPath -Recurse -File -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/') }

            $specEntry = @{
                name             = $specName
                number           = $specNumber
                status           = $status
                path             = $specPath.Substring($repoRoot.Length + 1).Replace('\', '/')
                has_spec         = $hasSpec
                has_plan         = $hasPlan
                has_tasks        = $hasTasks
                total_tasks      = $totalTasks
                completed_tasks  = $completedTasks
                incomplete_tasks = $incompleteTasks
                in_changelog     = $inChangelog
                pr_review        = $prReviewFound
                files            = $specFiles
            }

            $result.specs += $specEntry
            $result.changelog_entries += @{
                spec_name = $specName
                spec_number = $specNumber
                status = $status
                in_changelog = $inChangelog
                pr_review = $prReviewFound
            }

            switch ($status) {
                'completed'                 { $result.summary.specs_completed++ }
                'completed-needs-changelog' {
                    $result.summary.specs_completed++
                    $result.summary.changelog_gaps++
                    $result.changelog_gaps += @{
                        spec_name   = $specName
                        spec_number = $specNumber
                        reason      = 'All tasks complete but no CHANGELOG entry found'
                    }
                }
                'in-progress' { $result.summary.specs_in_progress++ }
                'draft'       { $result.summary.specs_draft++ }
            }

            if (-not $Json) {
                $icon  = switch ($status) { 'completed' { '✅' } 'completed-needs-changelog' { '⚠️' } 'in-progress' { '🔄' } 'draft' { '📋' } }
                $color = switch ($status) { 'completed' { 'Green' } 'completed-needs-changelog' { 'Yellow' } 'in-progress' { 'Cyan' } 'draft' { 'Gray' } }
                Write-Host "  $icon $specName ($status)" -ForegroundColor $color
            }
        }
    } else {
        if (-not $Json) { Write-Host "  No .documentation/specs/ directory found" -ForegroundColor Yellow }
    }
}

# ============================================================================
# PHASE 2: Documentation Inventory
# ============================================================================

if ($Scope -in @('full', 'docs', 'scan', 'changelog')) {
    if (-not $Json) { Write-Host "[DOCS] Scanning documentation..." -ForegroundColor Cyan }

    $docRoots = @()
    $canonicalDocDir = Join-Path $repoRoot '.documentation'
    $legacyDocsDir = Join-Path $repoRoot 'docs'

    if (Test-Path $canonicalDocDir) {
        $docRoots += @{ path = $canonicalDocDir; mode = 'canonical' }
    }

    if (Test-Path $legacyDocsDir) {
        $docRoots += @{ path = $legacyDocsDir; mode = 'legacy' }
        $result.path_roots.legacy_roots += 'docs/'
    }

    foreach ($docRoot in $docRoots) {
        Get-ChildItem $docRoot.path -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch [regex]::Escape('.archive') } |
            Select-Object -First $SampleLimit |
            ForEach-Object {
            $file         = $_
            $relativePath = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
            $category     = 'living_reference'
            $content = if ($file.Extension -in @('.md', '.txt', '.json', '.yml', '.yaml', '.toml', '.ps1', '.sh')) {
                Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            } else {
                ''
            }

            if ($file.Extension -in @('.bak', '.backup', '.old')) {
                $category = 'backup'
                $result.bak_files += $relativePath
                $result.summary.bak_files_found++
            } elseif ($docRoot.mode -eq 'legacy') {
                $category = 'legacy_root_doc'
            } elseif ($relativePath -match '\.documentation/specs/pr-review/') {
                $category = 'completed_review'
            } elseif ($relativePath -match '\.documentation/copilot/audit/') {
                $category = 'completed_audit'
            } elseif ($relativePath -match '\.documentation/drafts/') {
                $category = 'stale_draft'
            } elseif ($relativePath -match '\.documentation/copilot/session') {
                $category = 'session_notes'
            } elseif ($relativePath -match '-implementation-plan\.md$' -or
                      ($relativePath -match '-plan\.md$' -and $relativePath -notmatch '/Guide')) {
                $category = 'impl_plan'
            } elseif ($relativePath -match '\.documentation/releases/') {
                $category = 'release_doc'
            } elseif ($relativePath -match '\.documentation/quickfixes/') {
                $category = 'quickfix_record'
            } elseif ($file.Extension -in @('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.svg')) {
                # Check if referenced in any .md file
                $isReferenced = $false
                $fileName = $file.Name
                Get-ChildItem $docRoot.path -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
                    if (-not $isReferenced) {
                        $mdContent = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                        if ($mdContent -and $mdContent -match [regex]::Escape($fileName)) {
                            $isReferenced = $true
                        }
                    }
                }
                if (-not $isReferenced) { $category = 'orphaned' }
            }

            $taxon = Get-DocTaxon -RelativePath $relativePath -Content $content
            $scoreBreakdown = Get-DocScoreBreakdown -Taxon $taxon -RelativePath $relativePath -Content $content -LastModified $file.LastWriteTime -Category $category
            $disposition = Get-DocDisposition -RelativePath $relativePath -Category $category -Taxon $taxon -Score $scoreBreakdown.total -LastModified $file.LastWriteTime

            $docEntry = @{
                path          = $relativePath
                name          = $file.Name
                extension     = $file.Extension
                size_bytes    = $file.Length
                last_modified = $file.LastWriteTime.ToString('yyyy-MM-dd')
                category      = $category
                taxon         = $taxon
                usefulness_score = $scoreBreakdown.total
                score_breakdown = $scoreBreakdown
                disposition   = $disposition
            }

            $result.docs.all += $docEntry
            Update-CountMap -Map $result.docs.taxonomy_counts -Key $taxon
            Update-CountMap -Map $result.docs.disposition_counts -Key $disposition

            switch ($category) {
                'backup'           { $result.docs.backup_files += $docEntry;      $result.summary.docs_to_archive++ }
                'orphaned'         { $result.docs.orphaned_files += $docEntry;    $result.summary.docs_to_archive++ }
                'completed_review' { $result.docs.completed_reviews += $docEntry; $result.summary.docs_to_archive++ }
                'completed_audit'  { $result.docs.completed_audits += $docEntry;  $result.summary.docs_to_archive++ }
                'stale_draft'      { $result.docs.stale_drafts += $docEntry;      $result.summary.docs_to_archive++ }
                'session_notes'    { $result.docs.session_notes += $docEntry;     $result.summary.docs_to_archive++ }
                'impl_plan'        { $result.docs.impl_plans += $docEntry;        $result.summary.docs_to_archive++ }
                'release_doc'      { $result.docs.release_docs += $docEntry;      $result.summary.docs_to_archive++ }
                'quickfix_record'  { $result.docs.quickfix_records += $docEntry;  $result.summary.docs_to_archive++ }
                'legacy_root_doc'  { $result.docs.legacy_root_docs += $docEntry;  $result.summary.docs_to_archive++ }
                default            { $result.docs.living_reference += $docEntry }
            }
        }
    }

    if (-not $Json) {
        Write-Host "  Living reference: $($result.docs.living_reference.Count) files" -ForegroundColor Green
        $archColor = if ($result.summary.docs_to_archive -gt 0) { 'Yellow' } else { 'Green' }
        Write-Host "  To archive: $($result.summary.docs_to_archive) files" -ForegroundColor $archColor
        Write-Host "  Taxonomy buckets: $($result.docs.taxonomy_counts.Keys.Count)" -ForegroundColor Gray
    }
}

# ============================================================================
# PHASE 3: Source Code Comment Scan
# ============================================================================

if ($Scope -in @('full', 'comments', 'scan')) {
    if (-not $Json) { Write-Host "[COMMENTS] Scanning source code for spec references..." -ForegroundColor Cyan }

    # Patterns applicable across Python, TypeScript, C#, Go, etc.
    $commentPatterns = @(
        @{ pattern = '(?:#|//|<!--)\s*[Ss]pec\s+\d+';            label = 'spec-reference' }
        @{ pattern = '(?:#|//|<!--)\s*FR-\d+';                    label = 'functional-requirement' }
        @{ pattern = '(?:#|//|<!--)\s*Phase\s+\d+';               label = 'phase-reference' }
        @{ pattern = '(?:#|//)\s*TODO\s*\(\s*spec';               label = 'spec-todo' }
        @{ pattern = '(?:#|//)\s*plan\s+\d{3}';                   label = 'plan-reference' }
        @{ pattern = '(?:#|//)\s*T\d{3}\s*[\[:(-]';               label = 'task-reference' }
        @{ pattern = '(?:#|//)\s*SC-\d+';                         label = 'success-criteria-ref' }
    )

    # Scan common source extensions, skip .archive/, node_modules/, and docs/.
    # docs/ is excluded because it is commonly used as a GitHub Pages or other
    # static-site publish folder containing minified JS bundles. Scanning those
    # files produces false-positive matches and can generate lines that are
    # hundreds of KB long, causing ConvertTo-Json to produce malformed JSON.
    $docsDir = Join-Path $repoRoot 'docs'
    $sourceExtensions = @('*.py', '*.ts', '*.tsx', '*.js', '*.jsx', '*.cs', '*.go', '*.rs')
    foreach ($ext in $sourceExtensions) {
        Get-ChildItem $repoRoot -Recurse -Filter $ext -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch [regex]::Escape('.archive') -and
                           $_.FullName -notmatch [regex]::Escape('node_modules') -and
                           $_.FullName -notmatch [regex]::Escape($docsDir) } |
            Select-Object -First $SampleLimit |
            ForEach-Object {
            $srcFile      = $_
            $relativePath = $srcFile.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
            $lineNumber   = 0

            Get-Content $srcFile.FullName -ErrorAction SilentlyContinue | ForEach-Object {
                $lineNumber++
                $line = $_
                foreach ($p in $commentPatterns) {
                    if ($line -match $p.pattern) {
                        $result.code_comments += @{
                            file    = $relativePath
                            line    = $lineNumber
                            text    = ($line.Trim() -replace '(?s)(.{200}).*', '$1…')
                            type    = $p.label
                            pattern = $p.pattern
                        }
                        $result.summary.code_comments_found++
                    }
                }
            }
        }
    }

    if (-not $Json) {
        $commentColor = if ($result.summary.code_comments_found -gt 0) { 'Yellow' } else { 'Green' }
        Write-Host "  Found $($result.summary.code_comments_found) spec-linked comments" -ForegroundColor $commentColor
    }
}

# ============================================================================
# PHASE 4: Existing Archive Inventory
# ============================================================================

if (-not $Json) { Write-Host "[ARCHIVE] Checking existing .archive/ contents..." -ForegroundColor Cyan }

$archiveDir = Join-Path $repoRoot '.archive'
if (Test-Path $archiveDir) {
    $archiveFiles = Get-ChildItem $archiveDir -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First $SampleLimit
    foreach ($af in $archiveFiles) {
        $result.archive_existing += $af.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
    }
    if (-not $Json) { Write-Host "  Existing archive: $($archiveFiles.Count) files" -ForegroundColor Gray }
} else {
    if (-not $Json) { Write-Host "  No .archive/ directory found (will be created during harvest)" -ForegroundColor Gray }
}

# ============================================================================
# OUTPUT
# ============================================================================

if (-not $Json) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  HARVEST PRE-SCAN SUMMARY" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Specs completed:      $($result.summary.specs_completed)" -ForegroundColor $(if ($result.summary.specs_completed -gt 0) { 'Green' } else { 'Gray' })
    Write-Host "  Specs in-progress:    $($result.summary.specs_in_progress)" -ForegroundColor $(if ($result.summary.specs_in_progress -gt 0) { 'Cyan' } else { 'Gray' })
    Write-Host "  Specs draft:          $($result.summary.specs_draft)" -ForegroundColor Gray
    Write-Host "  CHANGELOG gaps:       $($result.summary.changelog_gaps)" -ForegroundColor $(if ($result.summary.changelog_gaps -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Docs to archive:      $($result.summary.docs_to_archive)" -ForegroundColor $(if ($result.summary.docs_to_archive -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Code comment refs:    $($result.summary.code_comments_found)" -ForegroundColor $(if ($result.summary.code_comments_found -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Backup files:         $($result.summary.bak_files_found)" -ForegroundColor $(if ($result.summary.bak_files_found -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

$result | ConvertTo-Json -Depth 10
