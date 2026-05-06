#!/usr/bin/env pwsh
# Release context gathering script
# Supports archiving development artifacts and generating release documentation

param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Arguments,
    [switch]$Json,
    [switch]$DryRun
)

. (Join-Path $PSScriptRoot 'common.ps1')

# Multi-app support (T086)
if (-not (Get-Command Detect-DevSparkMode -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot/common.ps1"
}

function Test-CompletedTasks {
    param([string]$Content)

    if (-not $Content) {
        return $false
    }

    $unchecked = ([regex]::Matches($Content, '^\s*- \[ \]', 'Multiline')).Count
    $checked = ([regex]::Matches($Content, '^\s*- \[[xX]\]', 'Multiline')).Count
    return ($unchecked -eq 0 -and $checked -gt 0)
}

function Get-ArchiveRecovery {
    param(
        [string]$RepoRoot,
        [string]$FromDate,
        [string]$ToDate
    )

    $archiveRoot = Join-Path $RepoRoot '.archive'
    $completedSpecs = @()
    $quickfixes = @()
    $fromCutoffDate = $null
    $toCutoffDate = $null

    if ($FromDate) {
        try {
            $fromCutoffDate = ([datetime]$FromDate).Date
        } catch {
            $fromCutoffDate = $null
        }
    }

    if ($ToDate) {
        try {
            $toCutoffDate = ([datetime]$ToDate).Date
        } catch {
            $toCutoffDate = $null
        }
    }

    if (-not (Test-Path $archiveRoot)) {
        return @{
            Specs = @()
            Quickfixes = @()
        }
    }

    Get-ChildItem -Path $archiveRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $batchDate = $null
        if ($_.Name -match '^\d{4}-\d{2}-\d{2}$') {
            try {
                $batchDate = ([datetime]::ParseExact($_.Name, 'yyyy-MM-dd', $null)).Date
            } catch {
                $batchDate = $null
            }
        }

        if ($fromCutoffDate -and $batchDate -and $batchDate -lt $fromCutoffDate) {
            return
        }

        if ($toCutoffDate -and $batchDate -and $batchDate -gt $toCutoffDate) {
            return
        }

        $specArchiveRoot = Join-Path $_.FullName '.documentation/specs'
        if (Test-Path $specArchiveRoot) {
            Get-ChildItem -Path $specArchiveRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $tasksFile = Join-Path $_.FullName 'tasks.md'
                if (-not (Test-Path $tasksFile)) {
                    return
                }

                $content = Get-Content $tasksFile -Raw -ErrorAction SilentlyContinue
                if (Test-CompletedTasks -Content $content) {
                    $completedSpecs += $_.Name
                }
            }
        }

        $quickfixArchiveRoot = Join-Path $_.FullName '.documentation/quickfixes'
        if (Test-Path $quickfixArchiveRoot) {
            $quickfixes += Get-ChildItem -Path $quickfixArchiveRoot -Filter 'QF-*.md' -ErrorAction SilentlyContinue |
                ForEach-Object { $_.BaseName }
        }
    }

    return @{
        Specs = @($completedSpecs | Where-Object { $_ } | Sort-Object -Unique)
        Quickfixes = @($quickfixes | Where-Object { $_ } | Sort-Object -Unique)
    }
}

function Get-HistoryRecovery {
    param(
        [string]$ScriptPath,
        [string]$BaseRef,
        [string]$FromDate,
        [string]$ToDate
    )

    $empty = @{
        Specs = @()
        Quickfixes = @()
        ArchiveMovesDetected = $false
        ReleaseFrom = $FromDate
        ReleaseTo = $ToDate
        Commits = @()
        Contributors = @()
        MergedPrNumbers = @()
        MergedPrCount = 0
        PrReviews = @()
        PrReviewSummary = @{
            matched_reviews = 0
            files_changed = 0
            tests_added = 0
            breaking_changes = 0
            resolved_high_findings = 0
        }
    }

    if (-not (Test-Path $ScriptPath) -or -not (Test-HasGit)) {
        return $empty
    }

    try {
        $historyJson = if ($BaseRef) {
            & $ScriptPath -BaseRef $BaseRef -FromDate $FromDate -ToDate $ToDate -Json
        } else {
            & $ScriptPath -FromDate $FromDate -ToDate $ToDate -Json
        }

        $history = $historyJson | ConvertFrom-Json
        return @{
            Specs = @($history.RECOVERED_SPECS | Where-Object { $_.completed } | ForEach-Object { $_.name } | Sort-Object -Unique)
            Quickfixes = @($history.RECOVERED_QUICKFIXES | ForEach-Object { $_.id } | Sort-Object -Unique)
            ArchiveMovesDetected = [bool]$history.ARCHIVE_MOVES_DETECTED
            ReleaseFrom = $history.RELEASE_FROM
            ReleaseTo = $history.RELEASE_TO
            Commits = @($history.COMMITS)
            Contributors = @($history.CONTRIBUTORS)
            MergedPrNumbers = @($history.MERGED_PR_NUMBERS)
            MergedPrCount = [int]$history.MERGED_PR_COUNT
            PrReviews = @($history.PR_REVIEWS)
            PrReviewSummary = $history.PR_REVIEW_SUMMARY
        }
    } catch {
        return $empty
    }
}

# Parse arguments
$versionArg = ""
$releaseFromArg = ""
for ($index = 0; $index -lt $Arguments.Count; $index++) {
    $arg = $Arguments[$index]
    if ($arg -match '^v?\d+\.\d+') {
        $versionArg = $arg -replace '^v', ''
        continue
    }

    if ($arg -eq '--from' -and $index + 1 -lt $Arguments.Count) {
        $releaseFromArg = $Arguments[$index + 1]
        $index++
        continue
    }

    if ($arg -match '^--from=(.+)$') {
        $releaseFromArg = $matches[1]
    }
}

# Get repository context
$repoRoot = Get-RepoRoot
$specsDir = Join-Path $repoRoot ".documentation/specs"
$releasesDir = Join-Path $repoRoot ".documentation/releases"
$quickfixDir = Join-Path $repoRoot ".documentation/quickfixes"
$decisionsDir = Join-Path $repoRoot ".documentation/decisions"
$constitutionPath = Join-Path $repoRoot ".documentation/memory/constitution.md"

# Detect current version from package files
$currentVersion = "0.0.0"
$versionSource = "default"

$packageJson = Join-Path $repoRoot "package.json"
$pyprojectToml = Join-Path $repoRoot "pyproject.toml"
$cargoToml = Join-Path $repoRoot "Cargo.toml"

if (Test-Path $packageJson) {
    try {
        $pkg = Get-Content $packageJson -Raw | ConvertFrom-Json
        if ($pkg.version) {
            $currentVersion = $pkg.version
            $versionSource = "package.json"
        }
    } catch { }
}
elseif (Test-Path $pyprojectToml) {
    try {
        $content = Get-Content $pyprojectToml -Raw
        if ($content -match 'version\s*=\s*"([^"]+)"') {
            $currentVersion = $matches[1]
            $versionSource = "pyproject.toml"
        }
    } catch { }
}
elseif (Test-Path $cargoToml) {
    try {
        $content = Get-Content $cargoToml -Raw
        if ($content -match '^version\s*=\s*"([^"]+)"') {
            $currentVersion = $matches[1]
            $versionSource = "Cargo.toml"
        }
    } catch { }
}

# Get last release info from git tags
$lastTag = ""
$lastReleaseDate = ""
$commitsSince = 0

if (Test-HasGit) {
    try {
        $lastTag = git describe --tags --abbrev=0 2>$null
        if ($lastTag) {
            $lastReleaseDate = git log -1 --format=%ci $lastTag 2>$null
            $commitsSince = [int](git rev-list "$lastTag..HEAD" --count 2>$null)
        }
        else {
            $commitsSince = [int](git rev-list HEAD --count 2>$null)
        }
    } catch {
        $lastTag = ""
    }
}

# Get timestamp
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$releaseDate = Get-Date -Format "yyyy-MM-dd"
$releaseFrom = if ($releaseFromArg) { $releaseFromArg } elseif ($lastReleaseDate) { ([datetime]$lastReleaseDate).ToString('yyyy-MM-dd') } else { '' }
$releaseTo = $releaseDate

# Find completed and pending specs
$completedSpecs = @()
$pendingSpecs = @()

if (Test-Path $specsDir) {
    Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
        $specName = $_.Name
        # Skip pr-review directory
        if ($specName -eq "pr-review") { return }

        $tasksFile = Join-Path $_.FullName "tasks.md"
        $specFile = Join-Path $_.FullName "spec.md"

        if (Test-Path $tasksFile) {
            $content = Get-Content $tasksFile -Raw -ErrorAction SilentlyContinue
            $unchecked = ([regex]::Matches($content, '^\s*- \[ \]', 'Multiline')).Count
            $checked = ([regex]::Matches($content, '^\s*- \[[xX]\]', 'Multiline')).Count

            if ($unchecked -eq 0 -and $checked -gt 0) {
                $completedSpecs += $specName
            }
            elseif (Test-Path $specFile) {
                $pendingSpecs += $specName
            }
        }
        elseif (Test-Path $specFile) {
            $pendingSpecs += $specName
        }
    }
}

# Find quickfixes
$quickfixes = @()
if (Test-Path $quickfixDir) {
    $quickfixes = Get-ChildItem -Path $quickfixDir -Filter "QF-*.md" -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName }
}

$activeCompletedSpecs = @($completedSpecs | Sort-Object -Unique)
$activeQuickfixes = @($quickfixes | Sort-Object -Unique)

$archiveRecovery = Get-ArchiveRecovery -RepoRoot $repoRoot -FromDate $releaseFrom -ToDate $releaseTo
$historyRecovery = Get-HistoryRecovery -ScriptPath (Join-Path $PSScriptRoot 'release-history-context.ps1') -BaseRef $lastTag -FromDate $releaseFrom -ToDate $releaseTo

$completedSpecs = @($activeCompletedSpecs + $archiveRecovery.Specs + $historyRecovery.Specs | Where-Object { $_ } | Sort-Object -Unique)
$quickfixes = @($activeQuickfixes + $archiveRecovery.Quickfixes + $historyRecovery.Quickfixes | Where-Object { $_ } | Sort-Object -Unique)

$recoveredCompletedSpecs = @($completedSpecs | Where-Object { $_ -notin $activeCompletedSpecs })
$recoveredQuickfixes = @($quickfixes | Where-Object { $_ -notin $activeQuickfixes })
$archiveRecoveryUsed = [bool](($archiveRecovery.Specs.Count + $archiveRecovery.Quickfixes.Count) -gt 0)
$historyRecoveryUsed = [bool](($historyRecovery.Specs.Count + $historyRecovery.Quickfixes.Count) -gt 0)
$contributors = @($historyRecovery.Contributors | Where-Object { $_ } | Sort-Object -Unique)
$commitsSince = $historyRecovery.Commits.Count
$mergedPrNumbers = @($historyRecovery.MergedPrNumbers | Sort-Object -Unique)
$mergedPrCount = [int]$historyRecovery.MergedPrCount
$prReviews = @($historyRecovery.PrReviews)
$prReviewSummary = $historyRecovery.PrReviewSummary

# Calculate next version if not provided
$nextVersion = $versionArg
$versionBump = "patch"

if (-not $nextVersion) {
    $versionParts = $currentVersion -split '\.'
    $major = [int]($versionParts[0] -replace '[^\d]', '')
    $minor = if ($versionParts.Length -gt 1) { [int]($versionParts[1] -replace '[^\d]', '') } else { 0 }
    $patch = if ($versionParts.Length -gt 2) { [int]($versionParts[2] -replace '[^\d]', '') } else { 0 }

    if ($completedSpecs.Count -gt 0) {
        $versionBump = "minor"
        $nextVersion = "$major.$($minor + 1).0"
    }
    elseif ($quickfixes.Count -gt 0) {
        $versionBump = "patch"
        $nextVersion = "$major.$minor.$($patch + 1)"
    }
    else {
        $versionBump = "patch"
        $nextVersion = "$major.$minor.$($patch + 1)"
    }
}

if ($contributors.Count -eq 0 -and (Test-HasGit)) {
    try {
        if ($lastTag) {
            $contributors = git log "$lastTag..HEAD" --format='%aN' 2>$null | Sort-Object -Unique
        }
        else {
            $contributors = git log --format='%aN' 2>$null | Sort-Object -Unique | Select-Object -First 20
        }
    } catch { }
}

# DevSpark version stamp info
$versionStampPath = Join-Path $repoRoot ".devspark/VERSION"
$legacyVersionStampPath = Join-Path $repoRoot ".documentation/DEVSPARK_VERSION"
$installedVersion = ""
if (Test-Path $versionStampPath) {
    try {
        $installedVersion = ((Get-Content $versionStampPath -ErrorAction SilentlyContinue) | Select-String '^version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
    } catch { }
} elseif (Test-Path $legacyVersionStampPath) {
    try {
        $installedVersion = (Get-Content $legacyVersionStampPath -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
    } catch { }
}

# Output
if ($Json) {
    @{
        REPO_ROOT              = $repoRoot
        SPECS_DIR              = $specsDir
        RELEASES_DIR           = $releasesDir
        QUICKFIX_DIR           = $quickfixDir
        DECISIONS_DIR          = $decisionsDir
        CONSTITUTION_PATH      = $constitutionPath
        CURRENT_VERSION        = $currentVersion
        VERSION_SOURCE         = $versionSource
        NEXT_VERSION           = $nextVersion
        VERSION_BUMP           = $versionBump
        RELEASE_FROM           = $releaseFrom
        RELEASE_TO             = $releaseTo
        ACTIVE_COMPLETED_SPECS = $activeCompletedSpecs
        COMPLETED_SPECS        = $completedSpecs
        RECOVERED_COMPLETED_SPECS = $recoveredCompletedSpecs
        PENDING_SPECS          = $pendingSpecs
        ACTIVE_QUICKFIXES      = $activeQuickfixes
        QUICKFIXES             = $quickfixes
        RECOVERED_QUICKFIXES   = $recoveredQuickfixes
        LAST_TAG               = $lastTag
        LAST_RELEASE_DATE      = $lastReleaseDate
        COMMITS_SINCE_RELEASE  = $commitsSince
        CONTRIBUTORS           = $contributors
        MERGED_PR_NUMBERS      = $mergedPrNumbers
        MERGED_PR_COUNT        = $mergedPrCount
        PR_REVIEWS             = $prReviews
        PR_REVIEW_SUMMARY      = $prReviewSummary
        ARCHIVE_RECOVERY_USED  = $archiveRecoveryUsed
        HISTORY_RECOVERY_USED  = $historyRecoveryUsed
        HISTORY_ARCHIVE_MOVES_DETECTED = [bool]$historyRecovery.ArchiveMovesDetected
        TIMESTAMP              = $timestamp
        RELEASE_DATE           = $releaseDate
        DRY_RUN                = [bool]$DryRun
        DEVSPARK_VERSION_PATH   = $versionStampPath
        LEGACY_DEVSPARK_VERSION_PATH = $legacyVersionStampPath
        INSTALLED_VERSION      = $installedVersion
    } | ConvertTo-Json -Depth 6
}
else {
    Write-Output "Release Context"
    Write-Output "==============="
    Write-Output "Repository: $repoRoot"
    Write-Output "Current Version: $currentVersion (from $versionSource)"
    Write-Output "Next Version: $nextVersion ($versionBump bump)"
    Write-Output "Last Release: $lastTag ($lastReleaseDate)"
    Write-Output "Release Window: $releaseFrom -> $releaseTo"
    Write-Output "Commits Since: $commitsSince"
    Write-Output ""
    Write-Output "Completed Specs: $($completedSpecs.Count)"
    Write-Output "Pending Specs: $($pendingSpecs.Count)"
    Write-Output "Quickfixes: $($quickfixes.Count)"
    Write-Output "Contributors: $($contributors.Count)"
    Write-Output "Merged PRs: $mergedPrCount"
    if ($recoveredCompletedSpecs.Count -gt 0 -or $recoveredQuickfixes.Count -gt 0) {
        Write-Output ''
        Write-Output "Recovered Specs: $($recoveredCompletedSpecs.Count)"
        Write-Output "Recovered Quickfixes: $($recoveredQuickfixes.Count)"
    }
    Write-Output ""
    if ($installedVersion) {
        Write-Output "Installed DevSpark Version: $installedVersion"
    } else {
        Write-Output "Installed DevSpark Version: (VERSION stamp not found)"
    }
    if ($DryRun) {
        Write-Output ""
        Write-Output "** DRY RUN MODE - No changes will be made **"
    }
}
