# Collector for bold.plan discover. Emits deterministic facts about codified
# decisions already present in the repo — config files, CI workflows,
# dependency manifests, contribution docs, and recent commit history — so
# discover reasons over inventory instead of re-scanning the tree itself.

param([string]$Root)

$ErrorActionPreference = 'Stop'

if ($Root) {
  $repoRoot = $Root
} else {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
}
Set-Location $repoRoot

$knownConfigs = @('.editorconfig', '.eslintrc', '.eslintrc.json', '.eslintrc.js', '.eslintrc.cjs',
  '.eslintrc.yml', '.prettierrc', '.prettierrc.json', '.prettierrc.js', 'tsconfig.json',
  'pyproject.toml', '.flake8', 'setup.cfg', 'Dockerfile', 'docker-compose.yml', '.pre-commit-config.yaml')
$configFilesPresent = @($knownConfigs | Where-Object { Test-Path $_ })

$knownManifests = @('package.json', 'requirements.txt', 'Gemfile', 'go.mod', 'pom.xml')
$dependencyManifestsPresent = @($knownManifests | Where-Object { Test-Path $_ })
$dependencyManifestsPresent += @(Get-ChildItem -Path . -Filter '*.csproj' -Depth 1 -File -ErrorAction SilentlyContinue |
  ForEach-Object { $_.Name })

$ciWorkflows = @()
if (Test-Path '.github/workflows') {
  $ciWorkflows = @(Get-ChildItem -Path '.github/workflows' -File -Recurse |
    ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/' })
}

$hasContributing = Test-Path 'CONTRIBUTING.md'
$hasPrTemplate = Test-Path '.github/PULL_REQUEST_TEMPLATE.md'

$recentCommitMessages = @()
if (Test-Path (Join-Path $repoRoot '.git')) {
  try {
    $recentCommitMessages = @(git -C $repoRoot log -20 --pretty=format:'%s' 2>$null)
  } catch {}
}

[ordered]@{
  config_files_present         = $configFilesPresent
  dependency_manifests_present = $dependencyManifestsPresent
  ci_workflows                 = $ciWorkflows
  has_contributing              = $hasContributing
  has_pr_template                = $hasPrTemplate
  recent_commit_messages       = $recentCommitMessages
} | ConvertTo-Json -Compress
