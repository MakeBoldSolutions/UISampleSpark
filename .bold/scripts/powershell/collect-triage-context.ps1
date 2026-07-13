# Collector for bold.plan (default/triage). Emits deterministic JSON facts —
# system doc inventory, active feature tiers/status, backbone principle
# status, and the project genome — so the triage prompt reasons over
# structured ground truth instead of re-deriving it from prose.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Common.ps1')

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
$docsDir = Join-Path $repoRoot 'bold-docs'

$systemDocs = Get-SystemDocs -RepoRoot $repoRoot -DocsDir $docsDir
$activeFeatures = Get-ActiveFeatures -DocsDir $docsDir
$backbonePrinciples = Get-BackbonePrinciples -DocsDir $docsDir
$staleReferences = Get-StaleReferences -RepoRoot $repoRoot -DocsDir $docsDir

$genome = $null
$genomeFile = Join-Path $docsDir 'project.json'
if (Test-Path $genomeFile) {
  $genome = Get-Content $genomeFile -Raw | ConvertFrom-Json
}

[ordered]@{
  system_docs         = $systemDocs
  active_features     = $activeFeatures
  backbone_principles = $backbonePrinciples
  stale_references    = $staleReferences
  genome              = $genome
} | ConvertTo-Json -Depth 10 -Compress
