# Collector for bold.ship (default and review). Emits deterministic facts —
# branch position relative to the base branch, changed-file inventory,
# active feature tiers, and backbone status — so drafting or reviewing a PR
# starts from current, structured ground truth.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Common.ps1')

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
$docsDir = Join-Path $repoRoot 'bold-docs'
Set-Location $repoRoot

$baseBranch = 'main'
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $currentBranch) { $currentBranch = 'unknown' }

$commitsAhead = 0
$commitsBehind = 0
$changedFiles = @()
$baseBranchExists = (git rev-parse --verify $baseBranch 2>$null)
if ($baseBranchExists -and $currentBranch -ne $baseBranch) {
  $commitsAhead = [int](git rev-list --count "$baseBranch..HEAD" 2>$null)
  $commitsBehind = [int](git rev-list --count "HEAD..$baseBranch" 2>$null)
  $changedFiles = @(git diff --name-only "$baseBranch...HEAD" 2>$null | Where-Object { $_ })
}

$hasUncommittedChanges = [bool](git status --porcelain 2>$null)

$activeFeatures = Get-ActiveFeatures -DocsDir $docsDir
$backbonePrinciples = Get-BackbonePrinciples -DocsDir $docsDir

[ordered]@{
  base_branch             = $baseBranch
  current_branch          = $currentBranch
  commits_ahead           = $commitsAhead
  commits_behind          = $commitsBehind
  changed_files           = $changedFiles
  has_uncommitted_changes = $hasUncommittedChanges
  active_features         = $activeFeatures
  backbone_principles     = $backbonePrinciples
} | ConvertTo-Json -Depth 10 -Compress
