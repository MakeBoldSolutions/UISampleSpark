#!/usr/bin/env pwsh
# gather-context.ps1 — Gather repository context for the write-spec skill.
# Always exits 0. Always emits valid JSON to stdout.
# Records anything that could not be gathered in the skipped_context array.

$result = @{
    constitution_summary = $null
    prior_specs          = @()
    skipped_context      = @()
}

# Detect git repository
$isGitRepo = $false
try {
    $gitCheck = git rev-parse --git-dir 2>$null
    $isGitRepo = $LASTEXITCODE -eq 0
} catch {
    $isGitRepo = $false
}

if (-not $isGitRepo) {
    $result.skipped_context += "no-git-repo"
}

# Locate repository root
$repoRoot = $null
if ($isGitRepo) {
    try {
        $repoRoot = (git rev-parse --show-toplevel 2>$null).Trim()
    } catch {
        $repoRoot = $null
    }
}

if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

# Load constitution summary
$constitutionPaths = @(
    Join-Path $repoRoot ".documentation/memory/constitution.md"
    Join-Path $repoRoot "constitution.md"
)

$constitutionFound = $false
foreach ($path in $constitutionPaths) {
    if (Test-Path $path) {
        try {
            $content = Get-Content $path -Raw -ErrorAction Stop
            # Extract first meaningful paragraph as summary (first 500 chars)
            $lines = $content -split "`n" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
            $summary = ($lines | Select-Object -First 10) -join " "
            if ($summary.Length -gt 500) {
                $summary = $summary.Substring(0, 497) + "..."
            }
            if ($summary.Length -gt 0) {
                $result.constitution_summary = $summary
                $constitutionFound = $true
                break
            }
        } catch {
            # continue to next path
        }
    }
}

if (-not $constitutionFound) {
    $result.skipped_context += "constitution-not-found"
}

# Gather prior specs
$specsDir = Join-Path $repoRoot ".documentation/specs"
if (Test-Path $specsDir) {
    try {
        $specFolders = Get-ChildItem $specsDir -Directory -ErrorAction Stop |
            Where-Object { Test-Path (Join-Path $_.FullName "spec.md") } |
            Sort-Object Name
        foreach ($folder in $specFolders) {
            $specFile = Join-Path $folder.FullName "spec.md"
            try {
                $specContent = Get-Content $specFile -TotalCount 20 -ErrorAction Stop
                $titleLine = $specContent | Where-Object { $_ -match "^# " } | Select-Object -First 1
                $title = if ($titleLine) { $titleLine -replace "^# ", "" } else { $folder.Name }
                $result.prior_specs += @{
                    name  = $folder.Name
                    title = $title
                }
            } catch {
                $result.prior_specs += @{
                    name  = $folder.Name
                    title = $folder.Name
                }
            }
        }
    } catch {
        $result.skipped_context += "specs-dir-unreadable"
    }
} else {
    $result.skipped_context += "no-specs-dir"
}

# Emit JSON — always exit 0
$result | ConvertTo-Json -Depth 5 -Compress
exit 0
