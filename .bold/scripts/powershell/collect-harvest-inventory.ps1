# Collector for bold.ship harvest. Emits deterministic facts — active feature
# tiers/status, the file inventory inside each feature dir, and the current
# system/ doc set — so classification (durable vs work product) starts from
# a complete inventory instead of the agent re-listing directories.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/Common.ps1')

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
$docsDir = Join-Path $repoRoot 'bold-docs'

$activeFeatures = Get-ActiveFeatures -DocsDir $docsDir
$systemDocs = Get-SystemDocs -RepoRoot $repoRoot -DocsDir $docsDir

$featureFiles = @()
$featuresDir = Join-Path $docsDir 'features'
if (Test-Path $featuresDir) {
  Get-ChildItem -Path $featuresDir -Directory | ForEach-Object {
    $featureDir = $_
    $files = @(Get-ChildItem -Path $featureDir.FullName -File -Recurse |
      ForEach-Object { $_.FullName.Substring($featureDir.FullName.Length + 1) -replace '\\', '/' } |
      Sort-Object)
    $featureFiles += [ordered]@{ id = $featureDir.Name; files = $files }
  }
}

[ordered]@{
  active_features = $activeFeatures
  system_docs     = $systemDocs
  feature_files   = $featureFiles
} | ConvertTo-Json -Depth 10 -Compress
