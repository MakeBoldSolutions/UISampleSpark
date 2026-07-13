# Collector for bold.plan init's Migrate path. Inventories a DevSpark
# install so the migration report prompt reasons over structured ground
# truth instead of re-deriving it by hand.
#
# Learned from the TailwindSpark migration (2026-07-09, bold-tool-plan.md
# §15 crucible feedback): a real DevSpark repo accumulates far more than
# the predefined slots below -- guides, ADRs, release history, repo-story,
# legacy per-host adapter files, editor config referencing DevSpark. This
# collector now also emits a generic catch-all inventory of anything under
# .documentation/ it doesn't specifically recognize, detects a pre-existing
# root .archive/ (a real repo may already have one, worth adopting rather
# than treating as a conflict), counts legacy per-host adapter files, and
# scans tracked files for lingering "devspark" text references. It still
# doesn't *classify* any of this -- that's the migration report's job
# (Reason), not the collector's (Collect) -- it just makes sure nothing is
# silently invisible.
param([string]$Root)

$ErrorActionPreference = 'Stop'

if ($Root) {
  $repoRoot = $Root
} else {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
}

function Get-EntrySummary {
  param([string]$Path)
  if (Test-Path $Path -PathType Container) {
    return [ordered]@{ type = 'dir'; file_count = (Get-ChildItem -Path $Path -File -Recurse).Count }
  }
  return [ordered]@{ type = 'file'; file_count = 1 }
}

$devsparkDir = Join-Path $repoRoot '.devspark'
$hasDevsparkDir = Test-Path $devsparkDir
$devsparkFileCount = 0
if ($hasDevsparkDir) {
  $devsparkFileCount = (Get-ChildItem -Path $devsparkDir -File -Recurse).Count
}

$docsDir = Join-Path $repoRoot '.documentation'
$hasDocumentationDir = Test-Path $docsDir

$constitutionPath = Join-Path $docsDir 'memory/constitution.md'
$hasConstitution = Test-Path $constitutionPath
$principleCount = 0
if ($hasConstitution) {
  $lines = Get-Content $constitutionPath
  $inCorePrinciples = $false
  foreach ($line in $lines) {
    if ($line -match '^## Core Principles') { $inCorePrinciples = $true; continue }
    if ($inCorePrinciples -and $line -match '^## ') { break }
    if ($inCorePrinciples -and $line -match '^### ') { $principleCount++ }
  }
}

$teamScriptsDir = Join-Path $docsDir 'scripts'
$hasTeamScriptsOverride = Test-Path $teamScriptsDir
$boldScriptsDir = Join-Path $repoRoot '.bold/scripts'
$boldScriptsPresent = Test-Path $boldScriptsDir
# Per carried script: would three-tier resolution ever serve it? An override
# is live only at an exact relative-path match against .bold/scripts/
# (bold-which's rule), so this is measurable -- the prompt must never
# re-derive it (issue #2: 15 dead scripts sat unflagged in a migrated repo).
$teamScripts = @()
if ($hasTeamScriptsOverride) {
  # Resolve to an absolute base before computing relative paths -- FullName is
  # always absolute, so a relative -Root would silently corrupt the substring.
  $teamScriptsDirFull = (Resolve-Path $teamScriptsDir).Path
  $teamScripts = @(Get-ChildItem -Path $teamScriptsDir -File -Recurse | ForEach-Object {
    $_.FullName.Substring($teamScriptsDirFull.Length + 1) -replace '\\', '/'
  } | Sort-Object { $_ } | ForEach-Object {
    [ordered]@{
      path                  = $_
      resolves_against_bold = (Test-Path (Join-Path $boldScriptsDir $_) -PathType Leaf)
    }
  })
}

$specsDir = Join-Path $docsDir 'specs'
$specDirs = @()
if (Test-Path $specsDir) {
  $specDirs = @(Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
    [ordered]@{
      name       = $_.Name
      file_count = (Get-ChildItem -Path $_.FullName -File -Recurse).Count
    }
  })
}

# Catch-all: anything under .documentation/ that isn't memory/scripts/specs.
# TailwindSpark had guides/, decisions/, releases/, repo-story/, templates/,
# copilot/, plus loose files (Guide.md, DEVSPARK_VERSION) -- none of that
# would have shown up anywhere above.
$documentationOtherEntries = @()
if ($hasDocumentationDir) {
  $known = @('memory', 'scripts', 'specs')
  $documentationOtherEntries = @(Get-ChildItem -Path $docsDir | Where-Object { $known -notcontains $_.Name } | ForEach-Object {
    $summary = Get-EntrySummary -Path $_.FullName
    [ordered]@{ name = $_.Name; type = $summary.type; file_count = $summary.file_count }
  })
}

# A real DevSpark repo may already have its own root .archive/ convention --
# worth detecting and proposing adoption, not treating as a conflict.
$archiveDir = Join-Path $repoRoot '.archive'
$hasExistingArchive = Test-Path $archiveDir
$existingArchiveEntries = @()
if ($hasExistingArchive) {
  $existingArchiveEntries = @(Get-ChildItem -Path $archiveDir | ForEach-Object {
    $summary = Get-EntrySummary -Path $_.FullName
    [ordered]@{ name = $_.Name; type = $summary.type; file_count = $summary.file_count }
  })
}

# Legacy per-host adapter files -- a class the original mapping table never
# anticipated, since Bold's own adapter system postdates most DevSpark
# installs. Anything found here pre-migration is presumptively legacy (Bold
# hasn't installed its own adapters yet at collection time).
function Get-FileNames {
  param([string]$Path, [string]$Filter)
  if (-not (Test-Path $Path)) { return ,@() }
  return ,@(Get-ChildItem -Path $Path -File -Filter $Filter | ForEach-Object { $_.Name })
}
$legacyClaudeCommands = Get-FileNames -Path (Join-Path $repoRoot '.claude/commands') -Filter '*.md'
$legacyGithubAgents = Get-FileNames -Path (Join-Path $repoRoot '.github/agents') -Filter '*.md'
$legacyGithubPrompts = Get-FileNames -Path (Join-Path $repoRoot '.github/prompts') -Filter '*.md'
$hasAgentsRegistry = Test-Path (Join-Path $repoRoot 'agents-registry.json')

# Multi-app config: named devspark.json per bold-tool-plan.md's own mapping
# table; not every repo has one (single-app is the common case).
$multiAppConfigPath = Join-Path $repoRoot 'devspark.json'
$hasMultiAppConfig = Test-Path $multiAppConfigPath

# Verification sweep: tracked files (git ls-files respects .gitignore and is
# far faster than a filesystem walk) mentioning "devspark", excluding
# .archive/ (legitimate historical references belong there).
$devsparkReferenceFiles = @()
if (Test-Path (Join-Path $repoRoot '.git')) {
  $trackedFiles = git -C $repoRoot ls-files 2>$null
  if ($trackedFiles) {
    foreach ($f in $trackedFiles) {
      if ($f -like '.archive/*') { continue }
      $full = Join-Path $repoRoot $f
      if (-not (Test-Path $full -PathType Leaf)) { continue }
      if ($f -notmatch '\.(md|json|ya?ml|txt)$') { continue }
      if (Select-String -Path $full -Pattern 'devspark' -SimpleMatch -Quiet -CaseSensitive:$false -ErrorAction SilentlyContinue) {
        $devsparkReferenceFiles += $f
      }
    }
  }
}

[ordered]@{
  has_devspark_dir             = $hasDevsparkDir
  devspark_dir_file_count      = $devsparkFileCount
  has_documentation_dir        = $hasDocumentationDir
  has_constitution              = $hasConstitution
  constitution_principle_count = $principleCount
  has_team_scripts_override    = $hasTeamScriptsOverride
  bold_scripts_present         = $boldScriptsPresent
  team_scripts                 = $teamScripts
  spec_dirs                    = $specDirs
  documentation_other_entries  = $documentationOtherEntries
  has_existing_archive         = $hasExistingArchive
  existing_archive_entries     = $existingArchiveEntries
  legacy_claude_commands       = $legacyClaudeCommands
  legacy_github_agents         = $legacyGithubAgents
  legacy_github_prompts        = $legacyGithubPrompts
  has_agents_registry          = $hasAgentsRegistry
  has_multi_app_config         = $hasMultiAppConfig
  devspark_reference_files     = $devsparkReferenceFiles
} | ConvertTo-Json -Depth 10 -Compress
