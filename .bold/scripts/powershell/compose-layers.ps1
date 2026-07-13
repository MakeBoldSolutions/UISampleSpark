# Collector for bold.plan init's greenfield questionnaire. Given a starter
# (+ optional stacks/flavors) or a kit, resolves the full layer set, merges
# each layer's questions.json in composition order (starter -> stacks ->
# flavors), and flags any question `id` that appears in more than one layer
# as a conflict. A kit's answer_defaults pass through unmodified as their own
# field -- applying the override is part of *asking*, which belongs to
# bold.plan init, not to this collector, which only measures and reports.
# See source/starters/FORMAT.md.
param(
  [string]$LayersRoot,
  [string]$Kit,
  [string]$Starter,
  [string[]]$Stacks = @(),
  [string[]]$Flavors = @()
)

$ErrorActionPreference = 'Stop'

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
if (-not $LayersRoot) { $LayersRoot = Join-Path $repoRoot 'source' }

$kitName = $null
$kitAnswerDefaults = [ordered]@{}

if ($Kit) {
  $kitName = $Kit
  $kitPath = Join-Path $LayersRoot "kits/$Kit.json"
  if (-not (Test-Path $kitPath)) { throw "Kit not found: $kitPath" }
  $kitDef = Get-Content $kitPath -Raw | ConvertFrom-Json
  $Starter = $kitDef.composition.starter
  $Stacks = @($kitDef.composition.stacks)
  $Flavors = @($kitDef.composition.flavors)
  if ($kitDef.answer_defaults) {
    $kitDef.answer_defaults.PSObject.Properties | ForEach-Object { $kitAnswerDefaults[$_.Name] = $_.Value }
  }
}

if (-not $Starter) { throw "Either -Kit or -Starter is required" }

$layerRefs = [System.Collections.Generic.List[object]]::new()
$layerRefs.Add([pscustomobject]@{ type = 'starter'; name = $Starter })
foreach ($s in $Stacks) { $layerRefs.Add([pscustomobject]@{ type = 'stack'; name = $s }) }
foreach ($f in $Flavors) { $layerRefs.Add([pscustomobject]@{ type = 'flavor'; name = $f }) }

$composedQuestions = [System.Collections.Generic.List[object]]::new()
$backboneFragments = [System.Collections.Generic.List[object]]::new()

foreach ($ref in $layerRefs) {
  $dir = Join-Path $LayersRoot "$($ref.type)s/$($ref.name)"
  $source = "$($ref.type):$($ref.name)"

  $questionsPath = Join-Path $dir 'questions.json'
  if (Test-Path $questionsPath) {
    $questions = Get-Content $questionsPath -Raw | ConvertFrom-Json
    foreach ($q in @($questions)) {
      $entry = [ordered]@{}
      $q.PSObject.Properties | ForEach-Object { $entry[$_.Name] = $_.Value }
      $entry['source'] = $source
      $composedQuestions.Add([pscustomobject]$entry)
    }
  }

  $backbonePath = Join-Path $dir 'backbone.md'
  if (Test-Path $backbonePath) {
    # Trim exactly one trailing newline to match bash's $(...) command
    # substitution, which always strips trailing newlines -- keeps both
    # collectors byte-identical on this field.
    $backboneFragments.Add([ordered]@{
      source  = $source
      content = ((Get-Content $backbonePath -Raw) -replace '[\r\n]+$', '')
    })
  }
}

# Mechanical conflict detection: any id appearing in more than one layer.
$conflicts = [System.Collections.Generic.List[object]]::new()
$composedQuestions | Group-Object -Property id | Where-Object { $_.Count -gt 1 } | ForEach-Object {
  $conflicts.Add([ordered]@{
    id      = $_.Name
    sources = @($_.Group | ForEach-Object { $_.source })
  })
}

[ordered]@{
  composition = [ordered]@{
    kit     = $kitName
    starter = $Starter
    stacks  = @($Stacks)
    flavors = @($Flavors)
  }
  composed_questions = @($composedQuestions)
  conflicts           = @($conflicts)
  backbone_fragments  = @($backboneFragments)
  kit_answer_defaults = $kitAnswerDefaults
} | ConvertTo-Json -Depth 10 -Compress
