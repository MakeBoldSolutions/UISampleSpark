#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    Deprecated compatibility wrapper for the legacy archive-context pre-scan.

.DESCRIPTION
    /devspark.archive has been merged into /devspark.harvest. This script now
    delegates to harvest with docs scope and reshapes the response back into the
    legacy archive-context contract for one migration window.
#>

param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Arguments,
    [switch]$Json,
    [switch]$IncludeFullInventory,
    [int]$SampleLimit = 50
)

. (Join-Path $PSScriptRoot 'common.ps1')

function Get-SampledItems {
    param(
        [array]$Items,
        [int]$Limit
    )

    if (-not $Items) {
        return @()
    }

    return @($Items | Select-Object -First $Limit)
}

if ($SampleLimit -lt 1) {
    $SampleLimit = 50
}

$repoRoot = Get-RepoRoot
$archiveBase = Join-Path $repoRoot '.archive'
$archiveExists = Test-Path $archiveBase
$guidePath = '.documentation/Guide.md'
$changelogPath = 'CHANGELOG.md'
$guideExists = Test-Path (Join-Path $repoRoot $guidePath)
$changelogExists = Test-Path (Join-Path $repoRoot $changelogPath)

$effectiveSampleLimit = if ($IncludeFullInventory) {
    [Math]::Max($SampleLimit, 10000)
} else {
    $SampleLimit
}

$harvestScript = Join-Path $PSScriptRoot 'harvest.ps1'
$harvest = & $harvestScript -Scope docs -Json -SampleLimit $effectiveSampleLimit | ConvertFrom-Json

$drafts = @($harvest.docs.stale_drafts | ForEach-Object { $_.path })
$sessionDocs = @($harvest.docs.session_notes | ForEach-Object { $_.path })
$implPlans = @($harvest.docs.impl_plans | ForEach-Object { $_.path })
$releaseDocs = @($harvest.docs.release_docs | ForEach-Object { $_.path })
$quickfixRecords = @($harvest.docs.quickfix_records | ForEach-Object { $_.path })
$prReviews = @($harvest.docs.completed_reviews | ForEach-Object { $_.path })
$currentDocs = @($harvest.docs.living_reference | ForEach-Object { $_.path })

$existingArchives = @()
$existingArchivesCount = 0
if ($archiveExists) {
    $allExistingArchives = @(Get-ChildItem -Path $archiveBase -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/') } |
        Sort-Object)
    $existingArchivesCount = $allExistingArchives.Count
    $existingArchives = Get-SampledItems -Items $allExistingArchives -Limit $SampleLimit
} else {
    $allExistingArchives = @()
}

$result = [ordered]@{
    REPO_ROOT = $harvest.repo_root
    TIMESTAMP = $harvest.harvest_timestamp
    ARCHIVE_DIR = ".archive/$($harvest.harvest_date)"
    ARCHIVE_EXISTS = $archiveExists
    EXISTING_ARCHIVES = $existingArchives
    EXISTING_ARCHIVES_COUNT = $existingArchivesCount
    GUIDE_PATH = $guidePath
    GUIDE_EXISTS = $guideExists
    CHANGELOG_PATH = $changelogPath
    CHANGELOG_EXISTS = $changelogExists
    SAMPLE_LIMIT = $SampleLimit
    INCLUDE_FULL_INVENTORY = [bool]$IncludeFullInventory
    CANDIDATE_COUNTS = [ordered]@{
        drafts = $drafts.Count
        session_docs = $sessionDocs.Count
        implementation_plans = $implPlans.Count
        release_docs = $releaseDocs.Count
        quickfix_records = $quickfixRecords.Count
        pr_reviews = $prReviews.Count
    }
    CANDIDATES = [ordered]@{
        drafts = Get-SampledItems -Items $drafts -Limit $SampleLimit
        session_docs = Get-SampledItems -Items $sessionDocs -Limit $SampleLimit
        implementation_plans = Get-SampledItems -Items $implPlans -Limit $SampleLimit
        release_docs = Get-SampledItems -Items $releaseDocs -Limit $SampleLimit
        quickfix_records = Get-SampledItems -Items $quickfixRecords -Limit $SampleLimit
        pr_reviews = Get-SampledItems -Items $prReviews -Limit $SampleLimit
    }
    CURRENT_DOCS = Get-SampledItems -Items $currentDocs -Limit $SampleLimit
    CURRENT_DOCS_COUNT = $currentDocs.Count
    FULL_INVENTORY = if ($IncludeFullInventory) {
        [ordered]@{
            existing_archives = $allExistingArchives
            candidates = [ordered]@{
                drafts = $drafts
                session_docs = $sessionDocs
                implementation_plans = $implPlans
                release_docs = $releaseDocs
                quickfix_records = $quickfixRecords
                pr_reviews = $prReviews
            }
            current_docs = $currentDocs
        }
    } else {
        $null
    }
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Output 'Archive Context'
    Write-Output '==============='
    Write-Output "Repository:    $($result.REPO_ROOT)"
    Write-Output "Archive dir:   $($result.ARCHIVE_DIR) (exists: $($result.ARCHIVE_EXISTS))"
    Write-Output "Guide.md:      $($result.GUIDE_PATH) (exists: $($result.GUIDE_EXISTS))"
    Write-Output "CHANGELOG.md:  $($result.CHANGELOG_PATH) (exists: $($result.CHANGELOG_EXISTS))"
    Write-Output ''
    Write-Output 'Candidates:'
    Write-Output "  Drafts:               $($result.CANDIDATE_COUNTS.drafts)"
    Write-Output "  Session docs:         $($result.CANDIDATE_COUNTS.session_docs)"
    Write-Output "  Implementation plans: $($result.CANDIDATE_COUNTS.implementation_plans)"
    Write-Output "  Release docs:         $($result.CANDIDATE_COUNTS.release_docs)"
    Write-Output "  Quickfix records:     $($result.CANDIDATE_COUNTS.quickfix_records)"
    Write-Output "  PR reviews:           $($result.CANDIDATE_COUNTS.pr_reviews)"
}
