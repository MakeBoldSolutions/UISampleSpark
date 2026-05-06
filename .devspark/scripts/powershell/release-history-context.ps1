#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    Build release history context from git between the previous release and HEAD.

.DESCRIPTION
    Emits JSON describing commits, changed files, and recoverable release artifacts
    such as completed specs and quickfixes that may have been moved out of active
    documentation paths before /devspark.release is run.
#>

param(
    [string]$BaseRef = "",
    [string]$HeadRef = "HEAD",
    [string]$FromDate = "",
    [string]$ToDate = "",
    [switch]$Json
)

. (Join-Path $PSScriptRoot 'common.ps1')

function Invoke-GitSafe {
    param([string[]]$GitArgs)

    try {
        $result = & git @GitArgs 2>$null
        if ($LASTEXITCODE -ne 0) {
            return @()
        }
        return @($result)
    } catch {
        return @()
    }
}

function Get-TrackedFileContent {
    param(
        [string]$RepoRoot,
        [string]$GitPath,
        [string]$HeadRef
    )

    $fullPath = Join-Path $RepoRoot ($GitPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path $fullPath) {
        return Get-Content $fullPath -Raw -ErrorAction SilentlyContinue
    }

    $result = Invoke-GitSafe @('show', "$HeadRef`:$GitPath")
    if ($result.Count -eq 0) {
        return ''
    }

    return ($result -join "`n")
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

function Get-FrontmatterValue {
    param(
        [string]$Content,
        [string]$Key
    )

    if ($Content -notmatch '^---\r?\n(.*?)\r?\n---\r?\n') {
        return ''
    }

    $frontmatter = $matches[1]
    $escapedKey = [regex]::Escape($Key)
    $pattern = '(?m)^{0}:\s*"?([^\r\n"]+)"?$' -f $escapedKey
    if ($frontmatter -match $pattern) {
        return $matches[1].Trim()
    }

    return ''
}

function Get-ReviewStat {
    param(
        [string]$Content,
        [string]$Label
    )

    if ($Content -match "(?m)^- $([regex]::Escape($Label)):\s*(\d+)") {
        return [int]$matches[1]
    }

    return 0
}

function Get-PrNumbersFromSubject {
    param([string]$Subject)

    $numbers = New-Object 'System.Collections.Generic.HashSet[int]'
    foreach ($match in ([regex]::Matches($Subject, '\(#(\d+)\)'))) {
        [void]$numbers.Add([int]$match.Groups[1].Value)
    }

    $mergeMatch = [regex]::Match($Subject, 'Merge pull request #(\d+)')
    if ($mergeMatch.Success) {
        [void]$numbers.Add([int]$mergeMatch.Groups[1].Value)
    }

    return @($numbers | Sort-Object)
}

if (-not (Test-HasGit)) {
    throw 'release-history-context requires git.'
}

$repoRoot = Get-RepoRoot
if (-not $BaseRef) {
    $latestTag = @(Invoke-GitSafe @('describe', '--tags', '--abbrev=0'))
    if ($latestTag.Count -gt 0) {
        $BaseRef = "$($latestTag[0])".Trim()
    }
}

if (-not $FromDate -and $BaseRef) {
    $tagDate = @(Invoke-GitSafe @('log', '-1', '--format=%cs', $BaseRef))
    if ($tagDate.Count -gt 0) {
        $FromDate = "$($tagDate[0])".Trim()
    }
}

if (-not $ToDate) {
    $headDate = @(Invoke-GitSafe @('log', '-1', '--format=%cs', $HeadRef))
    if ($headDate.Count -gt 0) {
        $ToDate = "$($headDate[0])".Trim()
    } else {
        $ToDate = (Get-Date -Format 'yyyy-MM-dd')
    }
}

$rangeSpec = if ($BaseRef) { "$BaseRef..$HeadRef" } else { $HeadRef }

$commitArgs = @('log', '--date=iso-strict', '--pretty=format:%H%x09%h%x09%ad%x09%an%x09%s')
if ($FromDate) { $commitArgs += "--since=$FromDate`T00:00:00" }
if ($ToDate) { $commitArgs += "--until=$ToDate`T23:59:59" }
$commitArgs += $HeadRef

$commitLines = Invoke-GitSafe $commitArgs
$commits = @()
$mergedPrNumbers = New-Object 'System.Collections.Generic.HashSet[int]'
foreach ($line in $commitLines) {
    if (-not $line) { continue }
    $parts = $line -split "`t", 5
    if ($parts.Count -lt 5) { continue }
    $prNumbers = @(Get-PrNumbersFromSubject -Subject $parts[4])
    foreach ($prNumber in $prNumbers) {
        [void]$mergedPrNumbers.Add([int]$prNumber)
    }
    $commits += [ordered]@{
        sha       = $parts[0]
        short_sha = $parts[1]
        date      = $parts[2]
        author    = $parts[3]
        subject   = $parts[4]
        pr_numbers = $prNumbers
    }
}

$changedFiles = @()
$changedFileKeys = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($commit in $commits) {
    $diffLines = Invoke-GitSafe @('show', '--name-status', '--find-renames', '--format=', $commit.sha)
    foreach ($line in $diffLines) {
        if (-not $line) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -lt 2) { continue }
        $status = $parts[0]
        $path = $parts[1]
        $previousPath = ''
        if (($status -like 'R*' -or $status -like 'C*') -and $parts.Count -ge 3) {
            $previousPath = $parts[1]
            $path = $parts[2]
        }

        $key = "$status|$path|$previousPath"
        if ($changedFileKeys.Contains($key)) {
            continue
        }
        [void]$changedFileKeys.Add($key)

        $changedFiles += [ordered]@{
            status        = $status
            path          = ($path -replace '\\', '/')
            previous_path = ($previousPath -replace '\\', '/')
        }
    }
}

$contributors = @($commits | ForEach-Object { $_.author } | Where-Object { $_ } | Sort-Object -Unique)
$mergedPrNumberList = @($mergedPrNumbers | Sort-Object)

$specPathMap = @{}
$quickfixPathMap = @{}
$archiveMovesDetected = $false

foreach ($changedFile in $changedFiles) {
    foreach ($candidatePath in @($changedFile.path, $changedFile.previous_path)) {
        if (-not $candidatePath) { continue }

        if ($candidatePath -match '^\.archive/') {
            $archiveMovesDetected = $true
        }

        if ($candidatePath -match '^(?:\.archive/[^/]+/)?\.documentation/specs/([^/]+)/(tasks|spec|plan|research)\.md$') {
            $specName = $matches[1]
            $kind = $matches[2]
            if (-not $specPathMap.ContainsKey($specName)) {
                $specPathMap[$specName] = New-Object System.Collections.ArrayList
            }
            [void]$specPathMap[$specName].Add([ordered]@{
                path = $candidatePath
                kind = $kind
            })
        }

        if ($candidatePath -match '^(?:\.archive/[^/]+/)?\.documentation/quickfixes/(QF-[^/]+)\.md$') {
            $quickfixId = $matches[1]
            if (-not $quickfixPathMap.ContainsKey($quickfixId)) {
                $quickfixPathMap[$quickfixId] = $candidatePath
            }
        }
    }
}

$recoveredSpecs = @()
foreach ($specName in ($specPathMap.Keys | Sort-Object)) {
    $entries = @($specPathMap[$specName])
    $orderedEntries = @(
        $entries | Sort-Object @{ Expression = { if ($_.kind -eq 'tasks') { 0 } else { 1 } } }, @{ Expression = { if ($_.path -like '.archive/*') { 1 } else { 0 } } }
    )

    $selected = $orderedEntries | Select-Object -First 1
    $completed = $false
    $taskEntries = @($orderedEntries | Where-Object { $_.kind -eq 'tasks' })
    foreach ($taskEntry in $taskEntries) {
        $content = Get-TrackedFileContent -RepoRoot $repoRoot -GitPath $taskEntry.path -HeadRef $HeadRef
        if (Test-CompletedTasks -Content $content) {
            $completed = $true
            $selected = $taskEntry
            break
        }
    }

    $recoveredSpecs += [ordered]@{
        name      = $specName
        path      = $selected.path
        completed = [bool]$completed
        source    = if ($selected.path -like '.archive/*') { 'archive-history' } else { 'active-history' }
    }
}

$recoveredQuickfixes = @()
foreach ($quickfixId in ($quickfixPathMap.Keys | Sort-Object)) {
    $path = $quickfixPathMap[$quickfixId]
    $recoveredQuickfixes += [ordered]@{
        id     = $quickfixId
        path   = $path
        source = if ($path -like '.archive/*') { 'archive-history' } else { 'active-history' }
    }
}

$reviewPaths = @()
$activeReviewRoot = Join-Path $repoRoot '.documentation/specs/pr-review'
if (Test-Path $activeReviewRoot) {
    $reviewPaths += Get-ChildItem -Path $activeReviewRoot -Filter 'pr-*.md' -ErrorAction SilentlyContinue
}

$archiveRoot = Join-Path $repoRoot '.archive'
if (Test-Path $archiveRoot) {
    Get-ChildItem -Path $archiveRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notmatch '^\d{4}-\d{2}-\d{2}$') { return }
        if ($FromDate -and $_.Name -lt $FromDate) { return }
        if ($ToDate -and $_.Name -gt $ToDate) { return }
        $reviewRoot = Join-Path $_.FullName '.documentation/specs/pr-review'
        if (Test-Path $reviewRoot) {
            $reviewPaths += Get-ChildItem -Path $reviewRoot -Filter 'pr-*.md' -ErrorAction SilentlyContinue
        }
    }
}

$matchedReviews = @()
foreach ($reviewPath in $reviewPaths) {
    $content = Get-Content $reviewPath.FullName -Raw -ErrorAction SilentlyContinue
    $prNumberText = Get-FrontmatterValue -Content $content -Key 'pr_number'
    if (-not $prNumberText -and $reviewPath.Name -match '^pr-(\d+)\.md$') {
        $prNumberText = $matches[1]
    }
    if (-not $prNumberText) { continue }
    $prNumber = [int]$prNumberText
    if ($prNumber -notin $mergedPrNumberList) { continue }

    $resolvedHighFindings = ([regex]::Matches($content, '(?m)^###\s+[HC]-\d+.*Resolved')).Count
    $matchedReviews += [ordered]@{
        pr_number = $prNumber
        path = $reviewPath.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        files_changed = Get-ReviewStat -Content $content -Label 'Files changed'
        tests_added = Get-ReviewStat -Content $content -Label 'Tests added'
        breaking_changes = Get-ReviewStat -Content $content -Label 'Breaking changes'
        resolved_high_findings = $resolvedHighFindings
    }
}

$filesChangedTotal = 0
$testsAddedTotal = 0
$breakingChangesTotal = 0
$resolvedHighFindingsTotal = 0
foreach ($review in $matchedReviews) {
    $filesChangedTotal += [int]$review['files_changed']
    $testsAddedTotal += [int]$review['tests_added']
    $breakingChangesTotal += [int]$review['breaking_changes']
    $resolvedHighFindingsTotal += [int]$review['resolved_high_findings']
}

$prReviewSummary = [ordered]@{
    matched_reviews = $matchedReviews.Count
    files_changed = $filesChangedTotal
    tests_added = $testsAddedTotal
    breaking_changes = $breakingChangesTotal
    resolved_high_findings = $resolvedHighFindingsTotal
}

$result = [ordered]@{
    REPO_ROOT              = $repoRoot
    BASE_REF               = $BaseRef
    HEAD_REF               = $HeadRef
    RANGE_SPEC             = $rangeSpec
    RELEASE_FROM           = $FromDate
    RELEASE_TO             = $ToDate
    COMMITS                = $commits
    COMMIT_SUBJECTS        = @($commits | ForEach-Object { $_.subject })
    CONTRIBUTORS           = $contributors
    CHANGED_FILES          = $changedFiles
    MERGED_PR_NUMBERS      = $mergedPrNumberList
    MERGED_PR_COUNT        = $mergedPrNumberList.Count
    RECOVERED_SPECS        = $recoveredSpecs
    RECOVERED_QUICKFIXES   = $recoveredQuickfixes
    PR_REVIEWS             = $matchedReviews
    PR_REVIEW_SUMMARY      = $prReviewSummary
    ARCHIVE_MOVES_DETECTED = [bool]$archiveMovesDetected
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    Write-Output 'Release History Context'
    Write-Output '======================='
    Write-Output "Repository: $repoRoot"
    Write-Output "Range: $rangeSpec"
    Write-Output "Release Window: $FromDate -> $ToDate"
    Write-Output "Commits: $($commits.Count)"
    Write-Output "Merged PRs: $(@($mergedPrNumbers).Count)"
    Write-Output "Recovered Specs: $($recoveredSpecs.Count)"
    Write-Output "Recovered Quickfixes: $($recoveredQuickfixes.Count)"
}