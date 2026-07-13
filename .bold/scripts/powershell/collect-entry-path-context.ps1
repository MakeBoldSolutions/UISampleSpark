# Collector for bold.plan init. Emits deterministic facts about which entry
# path applies — legacy methodology install present, existing bold install,
# and repo file counts — so init doesn't have to re-derive them by hand.

param([string]$Root)

$ErrorActionPreference = 'Stop'

if ($Root) {
  $repoRoot = $Root
} else {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
}

$hasDevspark = Test-Path (Join-Path $repoRoot '.devspark')
$hasDocumentationDir = Test-Path (Join-Path $repoRoot '.documentation')
$hasBoldDocs = Test-Path (Join-Path $repoRoot 'bold-docs/backbone.md')

$allFiles = Get-ChildItem -Path $repoRoot -File -Recurse -Force |
  Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$totalFiles = $allFiles.Count
$nonHiddenFiles = ($allFiles | Where-Object { $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' -and $_.Name -notmatch '^\.' }).Count

[ordered]@{
  has_devspark          = $hasDevspark
  has_documentation_dir = $hasDocumentationDir
  has_bold_docs         = $hasBoldDocs
  total_files           = $totalFiles
  non_hidden_files      = $nonHiddenFiles
} | ConvertTo-Json -Compress
