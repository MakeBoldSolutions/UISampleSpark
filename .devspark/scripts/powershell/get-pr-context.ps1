#!/usr/bin/env pwsh
#requires -Version 7.0
# Extract PR context for review
#
# This script fetches Pull Request information from GitHub and provides it
# in JSON format for the pr-review command.
#
# Usage: ./get-pr-context.ps1 [PR_NUMBER] [-Json]
#        ./get-pr-context.ps1 -Json           # Auto-detect PR from current branch
#        ./get-pr-context.ps1 123 -Json       # Specific PR number
#        ./get-pr-context.ps1 "#123" -Json    # Also accepts # prefix
#        ./get-pr-context.ps1 123 -Json -IncludeAllFiles

param(
    [Parameter(Position=0)]
    [string]$PrNumber,
    
    [Parameter()]
    [switch]$Json,

    [Parameter()]
    [switch]$IncludeAllFiles,

    [Parameter()]
    [int]$FileSampleLimit = 200
)

$ErrorActionPreference = "Stop"

# Multi-app support (T042, T067)
if (-not (Get-Command Detect-DevSparkMode -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot/common.ps1"
}

#==============================================================================
# Configuration
#==============================================================================

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load platform adapter
. "$scriptPath/platform.ps1"

$repoRoot = Get-RepoRoot

#==============================================================================
# Utility Functions
#==============================================================================

function Write-JsonError {
    param(
        [string]$Message,
        [string]$Details = ""
    )
    
    if ($Json) {
        $errorObj = @{
            error = $true
            message = $Message
            details = $Details
        } | ConvertTo-Json
        Write-Output $errorObj
    } else {
        Write-Error $Message
        if ($Details) {
            Write-Error $Details
        }
    }
}

if ($FileSampleLimit -lt 1) {
    $FileSampleLimit = 200
}

#==============================================================================
# PR Number Detection
#==============================================================================

function Get-DetectedPrNumber {
    # Method 1: Check platform-specific environment variable
    $platformEnv = [Environment]::GetEnvironmentVariable($DevSparkPlatform.PrEnvVar)
    if ($platformEnv) {
        return $platformEnv
    }

    # Method 2: Check generic env var
    if ($env:PR_NUMBER) {
        return $env:PR_NUMBER
    }
    
    # Method 3: Try platform CLI for current branch
    switch ($DevSparkPlatform.Name) {
        'github' {
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                try {
                    $prData = gh pr view --json number 2>$null | ConvertFrom-Json
                    if ($prData.number) { return $prData.number }
                } catch { }
            }
        }
        'azdo' {
            if (Get-Command az -ErrorAction SilentlyContinue) {
                try {
                    $branch = git rev-parse --abbrev-ref HEAD 2>$null
                    $prList = az repos pr list --source-branch $branch --status active --top 1 2>$null | ConvertFrom-Json
                    if ($prList -and $prList.Count -gt 0) { return $prList[0].pullRequestId }
                } catch { }
            }
        }
        'gitlab' {
            if (Get-Command glab -ErrorAction SilentlyContinue) {
                try {
                    $mrData = glab mr view --output json 2>$null | ConvertFrom-Json
                    if ($mrData.iid) { return $mrData.iid }
                } catch { }
            }
        }
    }
    
    return $null
}

#==============================================================================
# Main Execution
#==============================================================================

# Parse PR number from argument (strip # prefix if present)
if ($PrNumber) {
    $PrNumber = $PrNumber -replace '^#', ''
}

# Detect PR number if not provided
if ([string]::IsNullOrWhiteSpace($PrNumber)) {
    $PrNumber = Get-DetectedPrNumber
    if (-not $PrNumber) {
        Write-JsonError -Message "Unable to detect PR number" `
            -Details "Please provide PR number explicitly: /devspark.pr-review #123"
        exit 1
    }
}

# Validate PR number is numeric
if ($PrNumber -notmatch '^\d+$') {
    Write-JsonError -Message "Invalid PR number: $PrNumber" `
        -Details "PR number must be a positive integer"
    exit 1
}

# Check if platform CLI is available
$cliCommand = $DevSparkPlatform.PrCli
if (-not (Get-Command $cliCommand -ErrorAction SilentlyContinue)) {
    Write-JsonError -Message "$($DevSparkPlatform.DisplayName) CLI ($cliCommand) is required but not installed" `
        -Details "Install from: $($DevSparkPlatform.PrCliInstallUrl)"
    exit 1
}

# Check platform CLI authentication
$authOk = & $DevSparkPlatform.AuthCheck
if (-not $authOk) {
    $authCmd = switch ($DevSparkPlatform.Name) {
        'github' { 'gh auth login' }
        'azdo'   { 'az login' }
        'gitlab' { 'glab auth login' }
        default  { 'See platform documentation' }
    }
    Write-JsonError -Message "$($DevSparkPlatform.DisplayName) CLI not authenticated" `
        -Details "Run: $authCmd"
    exit 1
}

# Fetch PR data (platform-specific, normalized to common fields)
$prNumber_int = [int]$PrNumber
$prTitle = ""; $prBody = ""; $prState = ""; $prAuthor = ""
$sourceBranch = ""; $targetBranch = ""
$commitSha = "unknown"; $commitCount = 0
$allFilesChanged = @(); $linesAdded = 0; $linesDeleted = 0
$createdAt = ""; $updatedAt = ""
$mergeStateStatus = "UNKNOWN"

switch ($DevSparkPlatform.Name) {
    'github' {
        try {
            $prDataJson = gh pr view $PrNumber --json number,title,body,state,author,headRefName,baseRefName,commits,files,additions,deletions,createdAt,updatedAt,mergeStateStatus 2>$null
            $prData = $prDataJson | ConvertFrom-Json
        } catch {
            Write-JsonError -Message "Failed to fetch PR #$PrNumber" `
                -Details "Verify PR exists and you have access. Error: $_"
            exit 1
        }
        $prNumber_int  = $prData.number
        $prTitle       = $prData.title
        $prBody        = $prData.body ?? ""
        $prState       = $prData.state
        $prAuthor      = $prData.author.login
        $sourceBranch  = $prData.headRefName
        $targetBranch  = $prData.baseRefName
        if ($prData.commits -and $prData.commits.Count -gt 0) { $commitSha = $prData.commits[-1].oid }
        $commitCount   = $prData.commits.Count
        $allFilesChanged = @($prData.files | ForEach-Object { $_.path })
        $linesAdded    = $prData.additions ?? 0
        $linesDeleted  = $prData.deletions ?? 0
        $createdAt     = $prData.createdAt
        $updatedAt     = $prData.updatedAt
        $mergeStateStatus = $prData.mergeStateStatus ?? "UNKNOWN"
    }
    'azdo' {
        try {
            $prRaw = az repos pr show --id $PrNumber --output json 2>$null
            $prData = $prRaw | ConvertFrom-Json
        } catch {
            Write-JsonError -Message "Failed to fetch PR #$PrNumber" `
                -Details "Verify PR exists and you have access. Error: $_"
            exit 1
        }
        $prNumber_int  = $prData.pullRequestId
        $prTitle       = $prData.title
        $prBody        = $prData.description ?? ""
        $prState       = $prData.status
        $prAuthor      = $prData.createdBy.uniqueName
        $sourceBranch  = $prData.sourceRefName -replace '^refs/heads/', ''
        $targetBranch  = $prData.targetRefName -replace '^refs/heads/', ''
        if ($prData.commits -and $prData.commits.Count -gt 0) { $commitSha = $prData.commits[-1].commitId }
        $commitCount   = if ($prData.commits) { $prData.commits.Count } else { 0 }
        # AzDO mergeStatus: notSet | conflicts | succeeded | rejectedByPolicy | failure
        $mergeStateStatus = ($prData.mergeStatus ?? "UNKNOWN").ToUpper()
        $createdAt     = $prData.creationDate
        $updatedAt     = $prData.completionQueueTime ?? $prData.creationDate
        # Files not available directly from pr show; resolved via git below
    }
    'gitlab' {
        try {
            $mrRaw = glab mr view $PrNumber --output json 2>$null
            $mrData = $mrRaw | ConvertFrom-Json
        } catch {
            Write-JsonError -Message "Failed to fetch MR !$PrNumber" `
                -Details "Verify MR exists and you have access. Error: $_"
            exit 1
        }
        $prNumber_int  = $mrData.iid
        $prTitle       = $mrData.title
        $prBody        = $mrData.description ?? ""
        $prState       = $mrData.state
        $prAuthor      = $mrData.author.username
        $sourceBranch  = $mrData.source_branch
        $targetBranch  = $mrData.target_branch
        $mergeStateStatus = if ($mrData.merge_status -eq "can_be_merged") { "CLEAN" } else { ($mrData.merge_status ?? "UNKNOWN").ToUpper() }
        $createdAt     = $mrData.created_at
        $updatedAt     = $mrData.updated_at
    }
}

# For non-GitHub platforms, resolve file list via git diff
if ($DevSparkPlatform.Name -ne 'github' -and $sourceBranch -and $targetBranch) {
    try {
        git fetch origin $sourceBranch $targetBranch 2>$null | Out-Null
        $allFilesChanged = @(git diff --name-only "origin/$targetBranch...origin/$sourceBranch" 2>$null)
    } catch { $allFilesChanged = @() }
}

# If commit SHA still unknown, try git (works for all platforms after fetch)
if ($commitSha -eq "unknown" -and $sourceBranch) {
    try { $commitSha = git rev-parse "origin/$sourceBranch" 2>$null } catch {}
}

#==============================================================================
# HARD RULE: Source branch MUST be in sync with target branch
# GitHub's mergeStateStatus=="BEHIND" is treated as authoritative.
# A universal git-based check covers AzDO, GitLab, and verifies GitHub.
#==============================================================================
$isBehindTarget = $false

# Fast path: GitHub API already says BEHIND
if ($mergeStateStatus -eq "BEHIND") {
    $isBehindTarget = $true
}

# Universal git check — fetch both refs, count target commits absent from source
if (-not $isBehindTarget -and $sourceBranch -and $targetBranch) {
    try {
        git fetch origin $sourceBranch $targetBranch 2>$null | Out-Null
        $behindCount = git rev-list "origin/$targetBranch" "^origin/$sourceBranch" --count 2>$null
        if ([int]($behindCount ?? "0") -gt 0) {
            $isBehindTarget = $true
        }
    } catch {
        # Git check failed; rely on API status only
    }
}

if ($isBehindTarget) {
    $fixHint = switch ($DevSparkPlatform.Name) {
        'github' { "gh pr update-branch $PrNumber  OR  git fetch origin && git rebase origin/$targetBranch" }
        default  { "git fetch origin && git rebase origin/$targetBranch" }
    }
    Write-JsonError -Message "BLOCKED: Source branch '$sourceBranch' is behind target branch '$targetBranch'" `
        -Details "HARD RULE: PR review and approval are blocked until the source branch is in sync with the target branch. Fix with: $fixHint"
    exit 1
}

# Check if diff is available (platform-specific)
$diffAvailable = $false
try {
    switch ($DevSparkPlatform.Name) {
        'github' { gh pr diff $PrNumber 2>$null | Out-Null; $diffAvailable = $true }
        default  { git diff "origin/$targetBranch...origin/$sourceBranch" 2>$null | Out-Null; $diffAvailable = $true }
    }
} catch { $diffAvailable = $false }

# Apply file sampling
$filesChangedTotal = $allFilesChanged.Count
$filesChangedTruncated = $false
$filesChanged = $allFilesChanged
if (-not $IncludeAllFiles -and $filesChangedTotal -gt $FileSampleLimit) {
    $filesChanged = @($allFilesChanged | Select-Object -First $FileSampleLimit)
    $filesChangedTruncated = $true
}

# Check for constitution
$constitutionPath = Join-Path $repoRoot ".documentation\memory\constitution.md"
$constitutionExists = Test-Path $constitutionPath

#==============================================================================
# Spec Lifecycle Detection
# Extract feature identifier from branch name and check spec/task status
#==============================================================================
$specFeatureId = ""
$specStatus = "N/A"
$specPath = ""
$tasksTotal = 0
$tasksCompleted = 0
$tasksIncomplete = 0
$isFeatureBranch = $false

# Detect feature branch pattern: digits-name (e.g., 001-feature-name)
if ($sourceBranch -match '^(\d+-[a-zA-Z].*)$') {
    $isFeatureBranch = $true
    $specFeatureId = $sourceBranch

    # Check for spec directory
    $featureDir = Join-Path $repoRoot ".documentation\specs\$specFeatureId"
    $specPath = Join-Path $featureDir "spec.md"

    if (Test-Path $specPath) {
        # Extract Status field from spec.md
        $specContent = Get-Content $specPath -Raw
        # Multiline mode so $ matches end-of-line; tolerate trailing
        # "<!-- Valid: ... -->" helper comment from the spec template.
        if ($specContent -match '(?m)^\*\*Status\*\*:\s*([A-Za-z ]+?)(?:\s*<!--.*?-->)?\s*$') {
            $specStatus = $Matches[1].Trim()
        } else {
            $specStatus = "Unknown"
        }
    } else {
        $specStatus = "Missing"
    }

    # Check tasks.md completion
    $tasksPath = Join-Path $featureDir "tasks.md"
    if (Test-Path $tasksPath) {
        $tasksContent = Get-Content $tasksPath
        $taskLines = $tasksContent | Where-Object { $_ -match '^\s*- \[([ xX])\]' }
        $tasksTotal = ($taskLines | Measure-Object).Count
        $completedLines = $tasksContent | Where-Object { $_ -match '^\s*- \[[xX]\]' }
        $tasksCompleted = ($completedLines | Measure-Object).Count
        $tasksIncomplete = $tasksTotal - $tasksCompleted
    }
}

# Prepare review directory
$reviewDir = Join-Path $repoRoot ".documentation\specs\pr-review"

# Build output
if ($Json) {
    $output = @{
        REPO_ROOT = $repoRoot
        PR_CONTEXT = @{
            enabled = $true
            pr_number = $prNumber_int
            pr_title = $prTitle
            pr_body = $prBody
            pr_state = $prState
            pr_author = $prAuthor
            source_branch = $sourceBranch
            target_branch = $targetBranch
            commit_sha = $commitSha
            commit_count = $commitCount
            files_changed = $filesChanged
            files_changed_total = $filesChangedTotal
            files_changed_truncated = $filesChangedTruncated
            lines_added = $linesAdded
            lines_deleted = $linesDeleted
            created_at = $createdAt
            updated_at = $updatedAt
            diff_available = $diffAvailable
            file_sample_limit = $FileSampleLimit
            include_all_files = [bool]$IncludeAllFiles
            merge_state_status = $mergeStateStatus
            is_behind_target = $isBehindTarget
        }
        CONSTITUTION_PATH = $constitutionPath
        CONSTITUTION_EXISTS = $constitutionExists
        REVIEW_DIR = $reviewDir
        SPEC_LIFECYCLE = @{
            is_feature_branch = $isFeatureBranch
            feature_id = $specFeatureId
            spec_status = $specStatus
            spec_path = $specPath
            tasks_total = $tasksTotal
            tasks_completed = $tasksCompleted
            tasks_incomplete = $tasksIncomplete
        }
    } | ConvertTo-Json -Depth 10

    Write-Output $output
} else {
    # Human-readable output
    Write-Output "PR Context for #$prNumber_int"
    Write-Output "========================="
    Write-Output "Title:  $prTitle"
    Write-Output "Author: $prAuthor"
    Write-Output "State:  $prState"
    Write-Output "Branch: $sourceBranch → $targetBranch"
    Write-Output "Sync:   $(if ($isBehindTarget) { 'BEHIND (blocked)' } else { "In sync ($mergeStateStatus)" })"
    Write-Output "Commit: $commitSha"
    Write-Output "Files:  $($filesChanged.Count)"
    Write-Output "Lines:  +$linesAdded -$linesDeleted"
    Write-Output ""
    Write-Output "Constitution: $(if ($constitutionExists) { '✓ Found' } else { '✗ Missing' })"
    if ($isFeatureBranch) {
        Write-Output ""
        Write-Output "Spec Lifecycle:"
        Write-Output "  Feature:  $specFeatureId"
        Write-Output "  Status:   $specStatus"
        Write-Output "  Tasks:    $tasksCompleted/$tasksTotal complete ($tasksIncomplete remaining)"
    }
    Write-Output "Review will be saved to: $reviewDir\pr-$prNumber_int.md"
}
