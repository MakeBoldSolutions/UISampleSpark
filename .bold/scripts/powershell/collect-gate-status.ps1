# Collector for bold.build (default and status). Emits deterministic facts —
# per-feature ratified tier, backbone principle enforcement status, detected
# test-runner config, and working-tree cleanliness — so gates are decided
# from ground truth instead of re-derived by reading the tree by hand.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Common.ps1')

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
$docsDir = Join-Path $repoRoot 'bold-docs'
Set-Location $repoRoot

$activeFeatures = Get-ActiveFeatures -DocsDir $docsDir
$backbonePrinciples = Get-BackbonePrinciples -DocsDir $docsDir
$staleReferences = Get-StaleReferences -RepoRoot $repoRoot -DocsDir $docsDir

$knownTestConfigs = @('jest.config.js', 'jest.config.ts', 'pytest.ini', 'tox.ini', '.mocharc.json',
  '.mocharc.yml', 'karma.conf.js', 'phpunit.xml')
$testConfigPresent = @($knownTestConfigs | Where-Object { Test-Path $_ })
$testConfigPresent += @(Get-ChildItem -Path . -Filter '*.Tests.csproj' -Depth 1 -File -ErrorAction SilentlyContinue |
  ForEach-Object { $_.Name })

$hasUncommittedChanges = [bool](git status --porcelain 2>$null)

[ordered]@{
  active_features         = $activeFeatures
  backbone_principles     = $backbonePrinciples
  stale_references        = $staleReferences
  test_config_present     = $testConfigPresent
  has_uncommitted_changes = $hasUncommittedChanges
} | ConvertTo-Json -Depth 10 -Compress
