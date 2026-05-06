#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [ValidateSet('Preflight','Create','Update')]
    [string]$Mode = 'Preflight',
    [switch]$Json,
    [string]$Title,
    [string]$Body,
    [string]$BodyFile,
    [string]$Base,
    [int]$PrNumber,
    [switch]$Draft,
    [string[]]$Reviewer = @(),
    [string[]]$Label = @(),
    [string[]]$Assignee = @(),
    [string[]]$Issue = @()
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"
. "$PSScriptRoot/platform.ps1"

function Get-JsonError {
    param([string]$Message, [string]$Details = '')
    [PSCustomObject]@{
        error = $true
        message = $Message
        details = $Details
    } | ConvertTo-Json -Depth 10
}

function Get-DefaultBaseBranch {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            if (& $DevSparkPlatform.AuthCheck) {
                $branch = gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>$null
                if ($branch) { return $branch }
            }
        } catch { }
    }
    try {
        $symbolic = git symbolic-ref refs/remotes/origin/HEAD 2>$null
        if ($symbolic) { return ($symbolic -replace '^refs/remotes/origin/', '') }
    } catch { }
    return 'main'
}

function Resolve-PrBody {
    $bodyValue = $Body
    if ($BodyFile -and (Test-Path $BodyFile)) {
        $bodyValue = Get-Content -LiteralPath $BodyFile -Raw -Encoding utf8
    }
    if ($Issue.Count -gt 0) {
        $issueLine = 'Refs: ' + ($Issue -join ', ')
        if ($bodyValue) { $bodyValue += [Environment]::NewLine + [Environment]::NewLine }
        $bodyValue += $issueLine
    }
    return $bodyValue
}

function Get-MarkdownSectionText {
    param(
        [string]$Path,
        [string]$SectionName
    )

    if (-not (Test-Path $Path)) {
        return ''
    }

    $content = Get-Content -LiteralPath $Path -Encoding utf8
    $capture = $false
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $content) {
        $sectionMatch = [regex]::Match($line, '^##\s+(.+)$')
        if ($sectionMatch.Success) {
            $heading = $sectionMatch.Groups[1].Value.Trim()
            if ($capture -and $heading -ne $SectionName) {
                break
            }
            $capture = $heading -eq $SectionName
            continue
        }
        if ($capture) {
            $lines.Add($line)
        }
    }

    return (($lines -join [Environment]::NewLine).Trim())
}

function Get-GateAcknowledgements {
    param([string]$TasksPath)

    if (-not (Test-Path $TasksPath)) {
        return @()
    }

    $section = Get-MarkdownSectionText -Path $TasksPath -SectionName 'Gate Acknowledgements'
    if (-not $section) {
        return @()
    }

    $entries = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($section -split "`r?`n")) {
        $trimmed = $line.Trim()
        if (-not $trimmed) {
            if ($current.Count -gt 0) {
                $entries.Add(($current -join [Environment]::NewLine).Trim())
                $current.Clear()
            }
            continue
        }
        if ($trimmed.StartsWith('- Gate:') -and $current.Count -gt 0) {
            $entries.Add(($current -join [Environment]::NewLine).Trim())
            $current.Clear()
        }
        $current.Add($trimmed)
    }
    if ($current.Count -gt 0) {
        $entries.Add(($current -join [Environment]::NewLine).Trim())
    }
    return @($entries)
}

function Find-QuickfixRecordForBranch {
    param(
        [string]$RepoRoot,
        [string]$BranchName
    )

    $quickfixDir = Join-Path $RepoRoot '.documentation/quickfixes'
    if (-not (Test-Path $quickfixDir)) {
        return $null
    }

    $quickfixFiles = Get-ChildItem -Path $quickfixDir -Filter *.md -File -ErrorAction SilentlyContinue |
        Where-Object {
            $content = Get-Content -LiteralPath $_.FullName -Encoding utf8
            $branchLine = $content | Where-Object { $_ -match '^- \*\*Branch\*\*:\s*(.+)$' } | Select-Object -First 1
            $branchLine -and (($branchLine -replace '^- \*\*Branch\*\*:\s*', '').Trim() -eq $BranchName)
        } |
        Sort-Object Name

    if ($quickfixFiles) {
        return ($quickfixFiles | Select-Object -Last 1).FullName
    }
    return $null
}

function Get-QuickfixRecordSummary {
    param([string]$QuickfixPath)

    if (-not $QuickfixPath -or -not (Test-Path $QuickfixPath)) {
        return $null
    }

    $heading = Get-Content -LiteralPath $QuickfixPath -Encoding utf8 | Where-Object { $_ -match '^# ' } | Select-Object -First 1
    $idLine = Get-Content -LiteralPath $QuickfixPath -Encoding utf8 | Where-Object { $_ -match '^- \*\*ID\*\*:\s*(.+)$' } | Select-Object -First 1
    return [PSCustomObject]@{
        path = $QuickfixPath
        id = if ($idLine) { ($idLine -replace '^- \*\*ID\*\*:\s*', '').Trim() } else { [IO.Path]::GetFileNameWithoutExtension($QuickfixPath) }
        title = if ($heading) { $heading -replace '^#\s*', '' } else { '' }
        classification = Get-MarkdownFrontmatterValue -Path $QuickfixPath -Key 'classification'
        risk_level = Get-MarkdownFrontmatterValue -Path $QuickfixPath -Key 'risk_level'
        required_gates = Get-MarkdownFrontmatterValue -Path $QuickfixPath -Key 'required_gates'
        recommended_next_step = Get-MarkdownFrontmatterValue -Path $QuickfixPath -Key 'recommended_next_step'
        problem_statement = Get-MarkdownSectionText -Path $QuickfixPath -SectionName 'Problem Statement'
        gate_acknowledgements = Get-MarkdownSectionText -Path $QuickfixPath -SectionName 'Gate Acknowledgements'
    }
}

function Get-TaskCounts {
    param([string]$TasksPath)
    if (-not (Test-Path $TasksPath)) {
        return [PSCustomObject]@{ total = 0; completed = 0; incomplete = 0 }
    }
    $content = Get-Content -LiteralPath $TasksPath -Encoding utf8
    $taskLines = @($content | Where-Object { $_ -match '^\s*- \[([ xX])\]' })
    $completedLines = @($content | Where-Object { $_ -match '^\s*- \[[xX]\]' })
    return [PSCustomObject]@{
        total = $taskLines.Count
        completed = $completedLines.Count
        incomplete = $taskLines.Count - $completedLines.Count
    }
}

function Get-ChecklistSummary {
    param([string]$ChecklistDir)
    if (-not (Test-Path $ChecklistDir)) {
        return @()
    }
    $results = @()
    Get-ChildItem -Path $ChecklistDir -Filter *.md -File -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Encoding utf8
        $taskLines = @($content | Where-Object { $_ -match '^\s*- \[([ xX])\]' })
        $completed = @($content | Where-Object { $_ -match '^\s*- \[[xX]\]' })
        $results += [PSCustomObject]@{
            name = $_.Name
            total = $taskLines.Count
            completed = $completed.Count
            incomplete = $taskLines.Count - $completed.Count
            status = if (($taskLines.Count - $completed.Count) -eq 0) { 'pass' } else { 'fail' }
        }
    }
    return $results
}

function Get-GateArtifacts {
    param([string]$FeatureDir)
    $results = @()
    foreach ($gate in @('analyze','critic','checklist')) {
        $candidatePaths = @(
            (Join-Path $FeatureDir "gates/$gate.md"),
            (Join-Path $FeatureDir "$gate.md")
        )
        $path = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($path) {
            $content = Get-Content -LiteralPath $path -Encoding utf8
            $status = (($content | Where-Object { $_ -match '^status:\s*' } | Select-Object -First 1) -replace '^status:\s*', '')
            $blockingRaw = (($content | Where-Object { $_ -match '^blocking:\s*' } | Select-Object -First 1) -replace '^blocking:\s*', '')
            $severity = (($content | Where-Object { $_ -match '^severity:\s*' } | Select-Object -First 1) -replace '^severity:\s*', '')
            $summary = (($content | Where-Object { $_ -match '^summary:\s*' } | Select-Object -First 1) -replace '^summary:\s*', '')
            $results += [PSCustomObject]@{
                gate = $gate
                path = $path
                status = if ($status) { $status } else { 'unknown' }
                severity = if ($severity) { $severity } else { 'info' }
                summary = $summary
                blocking = ($blockingRaw -eq 'true')
            }
        }
    }
    return $results
}

function Get-CreatePrPreflight {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $targetBranch = if ($Base) { $Base } else { Get-DefaultBaseBranch }
    $dirty = [bool](git status --porcelain 2>$null)
    $localHead = ''
    $remoteHead = ''
    $originExists = $false
    $remoteBranchExists = $false
    $branchPushedToRemote = $false
    $branchPushDetails = ''

    try {
        $localHead = (git rev-parse HEAD 2>$null | Select-Object -First 1).Trim()
    } catch { }

    try {
        git remote get-url origin 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $originExists = $true
        }
    } catch { }

    if ($originExists) {
        try {
            $remoteLine = (git ls-remote --heads origin "refs/heads/$currentBranch" 2>$null | Select-Object -First 1)
            if ($remoteLine) {
                $remoteHead = (($remoteLine -split "`t")[0]).Trim()
                $remoteBranchExists = [bool]$remoteHead
            }
        } catch { }
    }

    if (-not $originExists) {
        $branchPushDetails = 'Remote ''origin'' is not configured'
    } elseif (-not $remoteBranchExists) {
        $branchPushDetails = "Branch '$currentBranch' has not been pushed to origin"
    } elseif ($localHead -and $remoteHead -and $localHead -eq $remoteHead) {
        $branchPushedToRemote = $true
        $branchPushDetails = "Branch '$currentBranch' is pushed to origin"
    } else {
        $branchPushDetails = "Push the latest commits from '$currentBranch' to origin before creating a PR"
    }

    $cliAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)
    $authOk = $false
    if ($cliAvailable) {
        try { $authOk = & $DevSparkPlatform.AuthCheck } catch { $authOk = $false }
    }
    $creationSupported = $cliAvailable -and $DevSparkPlatform.Name -eq 'github'

    $featureDir = Find-FeatureDirByPrefix -RepoRoot $repoRoot -BranchName $currentBranch
    $specPath = Join-Path $featureDir 'spec.md'
    $planPath = Join-Path $featureDir 'plan.md'
    $tasksPath = Join-Path $featureDir 'tasks.md'
    $checklistDir = Join-Path $featureDir 'checklists'

    $specExists = Test-Path $specPath
    $planExists = Test-Path $planPath
    $tasksExists = Test-Path $tasksPath

    $specTitle = ''
    $classification = ''
    $riskLevel = ''
    $requiredGates = ''
    $recommendedNextStep = ''
    if ($specExists) {
        $heading = Get-Content -LiteralPath $specPath -Encoding utf8 | Where-Object { $_ -match '^# ' } | Select-Object -First 1
        $specTitle = $heading -replace '^#\s*', ''
        $classification = Get-MarkdownFrontmatterValue -Path $specPath -Key 'classification'
        $riskLevel = Get-MarkdownFrontmatterValue -Path $specPath -Key 'risk_level'
        $requiredGates = Get-MarkdownFrontmatterValue -Path $specPath -Key 'required_gates'
        $recommendedNextStep = Get-MarkdownFrontmatterValue -Path $specPath -Key 'recommended_next_step'
    }

    $taskCounts = Get-TaskCounts -TasksPath $tasksPath
    $checklists = Get-ChecklistSummary -ChecklistDir $checklistDir
    $gateArtifacts = Get-GateArtifacts -FeatureDir $featureDir
    $gateAcknowledgements = Get-GateAcknowledgements -TasksPath $tasksPath
    $quickfixRecordPath = Find-QuickfixRecordForBranch -RepoRoot $repoRoot -BranchName $currentBranch
    $quickfixRecord = Get-QuickfixRecordSummary -QuickfixPath $quickfixRecordPath

    if (-not $specExists -and $quickfixRecord) {
        $specTitle = $quickfixRecord.title
        $classification = $quickfixRecord.classification
        $riskLevel = $quickfixRecord.risk_level
        $requiredGates = $quickfixRecord.required_gates
        $recommendedNextStep = $quickfixRecord.recommended_next_step
        if ($quickfixRecord.gate_acknowledgements) {
            $gateAcknowledgements = @($quickfixRecord.gate_acknowledgements.Trim())
        }
    }

    $diffRef = 'HEAD~1...HEAD'
    try {
        git rev-parse --verify "origin/$targetBranch" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            git fetch origin $targetBranch 2>$null | Out-Null
            $diffRef = "origin/$targetBranch...HEAD"
        }
    } catch { }
    $linesSummary = (git diff --shortstat $diffRef 2>$null) -join ''
    $changedFiles = @(git diff --name-only $diffRef 2>$null)
    $recentCommits = @(git log --format='%s' -n 10 $diffRef 2>$null)

    $existingPr = [PSCustomObject]@{ exists = $false; number = $null; url = ''; title = ''; state = ''; draft = $false }
    if ($cliAvailable -and $authOk) {
        try {
            $existingRaw = gh pr list --head $currentBranch --json number,url,title,state,isDraft --limit 1 2>$null | ConvertFrom-Json
            $pr = @($existingRaw)[0]
            if ($pr) {
                $existingPr = [PSCustomObject]@{
                    exists = $true
                    number = $pr.number
                    url = $pr.url
                    title = $pr.title
                    state = $pr.state
                    draft = [bool]$pr.isDraft
                }
            }
        } catch { }
    }

    return [PSCustomObject]@{
        repo_root = $repoRoot
        current_branch = $currentBranch
        target_branch = $targetBranch
        dirty_worktree = $dirty
        prerequisites = [PSCustomObject]@{
            clean_worktree = (-not $dirty)
            branch_pushed_to_remote = $branchPushedToRemote
        }
        remote = [PSCustomObject]@{
            name = 'origin'
            exists = $originExists
            branch_exists = $remoteBranchExists
            branch_pushed_to_remote = $branchPushedToRemote
            local_head = $localHead
            remote_head = $remoteHead
            details = $branchPushDetails
        }
        cli_available = $cliAvailable
        auth_ok = $authOk
        creation_supported = $creationSupported
        feature = [PSCustomObject]@{
            dir = $featureDir
            spec_path = $specPath
            plan_path = $planPath
            tasks_path = $tasksPath
            checklist_dir = $checklistDir
            spec_exists = $specExists
            plan_exists = $planExists
            tasks_exists = $tasksExists
            spec_title = $specTitle
            classification = $classification
            risk_level = $riskLevel
            required_gates = $requiredGates
            recommended_next_step = $recommendedNextStep
            tasks_total = $taskCounts.total
            tasks_completed = $taskCounts.completed
            tasks_incomplete = $taskCounts.incomplete
            checklists = $checklists
            gate_artifacts = $gateArtifacts
            gate_acknowledgements = @($gateAcknowledgements)
        }
        diff = [PSCustomObject]@{
            changed_files_count = $changedFiles.Count
            lines_summary = $linesSummary
            recent_commit_subjects = $recentCommits
        }
        quickfix_record = $quickfixRecord
        existing_pr = $existingPr
    }
}

function Invoke-CreateOrUpdatePr {
    param([ValidateSet('Create','Update')][string]$Action)

    $preflight = Get-CreatePrPreflight
    if (-not $preflight.prerequisites.clean_worktree) {
        return (Get-JsonError -Message 'Working tree has unmanaged changes' -Details 'Commit, stash, or discard all changes before creating or updating a PR')
    }
    if (-not $preflight.prerequisites.branch_pushed_to_remote) {
        return (Get-JsonError -Message 'Current branch is not pushed to remote' -Details $preflight.remote.details)
    }
    if (-not $preflight.creation_supported) {
        return (Get-JsonError -Message 'Automated PR creation is only supported for GitHub in this release' -Details "Platform: $($DevSparkPlatform.Name)")
    }
    if (-not $preflight.auth_ok) {
        return (Get-JsonError -Message 'GitHub CLI is not authenticated' -Details 'Run: gh auth login')
    }

    $bodyValue = Resolve-PrBody
    if (-not $Title -or -not $bodyValue) {
        return (Get-JsonError -Message 'Title and body are required for create/update mode' -Details 'Pass -Title and -Body or -BodyFile')
    }

    if ($Action -eq 'Create' -and $preflight.existing_pr.exists) {
        return (Get-JsonError -Message 'A PR already exists for this branch' -Details 'Use update mode or pass -PrNumber')
    }

    if ($Action -eq 'Update') {
        $targetPr = if ($PrNumber) { $PrNumber } else { $preflight.existing_pr.number }
        if (-not $targetPr) {
            return (Get-JsonError -Message 'No PR found to update' -Details 'Create a PR first or pass -PrNumber')
        }
        gh pr edit $targetPr --title $Title --body $bodyValue --base $(if ($Base) { $Base } else { $preflight.target_branch }) 2>$null | Out-Null
        foreach ($item in $Reviewer) { gh pr edit $targetPr --add-reviewer $item 2>$null | Out-Null }
        foreach ($item in $Label) { gh pr edit $targetPr --add-label $item 2>$null | Out-Null }
        foreach ($item in $Assignee) { gh pr edit $targetPr --add-assignee $item 2>$null | Out-Null }
        $view = gh pr view $targetPr --json number,url,title,state,isDraft 2>$null | ConvertFrom-Json
    } else {
        $ghCreateCommand = @('pr','create','--title',$Title,'--body',$bodyValue,'--base',$(if ($Base) { $Base } else { $preflight.target_branch }))
        if ($Draft) { $ghCreateCommand += '--draft' }
        foreach ($item in $Reviewer) { $ghCreateCommand += @('--reviewer',$item) }
        foreach ($item in $Label) { $ghCreateCommand += @('--label',$item) }
        foreach ($item in $Assignee) { $ghCreateCommand += @('--assignee',$item) }
        $created = & gh @ghCreateCommand 2>$null
        $url = ($created | Select-Object -Last 1)
        if (-not $url) {
            return (Get-JsonError -Message 'Failed to create pull request' -Details 'gh pr create did not return a URL')
        }
        $view = gh pr view $url --json number,url,title,state,isDraft 2>$null | ConvertFrom-Json
    }

    return ([PSCustomObject]@{
        status = 'ok'
        action = $Action.ToLower()
        pr_number = $view.number
        url = $view.url
        title = $view.title
        state = $view.state
        draft = [bool]$view.isDraft
    } | ConvertTo-Json -Depth 10)
}

switch ($Mode) {
    'Preflight' {
        $output = Get-CreatePrPreflight | ConvertTo-Json -Depth 10
        Write-Output $output
    }
    'Create' {
        Write-Output (Invoke-CreateOrUpdatePr -Action Create)
    }
    'Update' {
        Write-Output (Invoke-CreateOrUpdatePr -Action Update)
    }
}