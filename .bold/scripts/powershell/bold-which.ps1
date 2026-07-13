# Three-tier resolution shim (bold-tool-plan.md §9.3). Given a path relative
# to the tool's content root (e.g. commands/plan/critic.md), reports which
# tier would serve it — user (.bold-user/{git-user-name}/) > team
# (bold-docs/overrides/) > source (.bold/) — first hit wins, whole-file
# replacement only (no fragment merging). Doubles as the `bold which`
# diagnostic: it reports the full chain, not just the winner.
param(
  [Parameter(Mandatory = $true)][string]$RelPath,
  [string]$Root
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/lib/Common.ps1"

if ($Root) {
  $repoRoot = $Root
} else {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
}

$userPath = Join-Path $repoRoot ".bold-user/$(Get-BoldUserSlug -Root $repoRoot)/$RelPath"
$teamPath = Join-Path $repoRoot "bold-docs/overrides/$RelPath"
$sourcePath = Join-Path $repoRoot ".bold/$RelPath"

$userExists = Test-Path $userPath -PathType Leaf
$teamExists = Test-Path $teamPath -PathType Leaf
$sourceExists = Test-Path $sourcePath -PathType Leaf

$resolvedTier = 'none'
$resolvedPath = ''
if ($userExists) { $resolvedTier = 'user'; $resolvedPath = $userPath }
elseif ($teamExists) { $resolvedTier = 'team'; $resolvedPath = $teamPath }
elseif ($sourceExists) { $resolvedTier = 'source'; $resolvedPath = $sourcePath }

[ordered]@{
  path          = $RelPath
  resolved_tier = $resolvedTier
  resolved_path = $resolvedPath
  tiers         = @(
    [ordered]@{ tier = 'user'; path = $userPath; exists = $userExists }
    [ordered]@{ tier = 'team'; path = $teamPath; exists = $teamExists }
    [ordered]@{ tier = 'source'; path = $sourcePath; exists = $sourceExists }
  )
} | ConvertTo-Json -Depth 5 -Compress
