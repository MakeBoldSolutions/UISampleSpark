#!/usr/bin/env pwsh
#requires -Version 7.0
# Helper script for /devspark.address-pr-review
# -PrId: parse review file and emit open findings JSON
# -Gate: enforce staged-path isolation for code-only or review-only commits

param(
    [Parameter()]
    [string]$PrId,

    [Parameter()]
    [ValidateSet('code-only', 'review-only')]
    [string]$Gate,

    [Parameter()]
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'common.ps1')
}

function Get-StagedPaths {
    try {
        $paths = @(git diff --cached --name-only 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        return $paths
    }
    catch {
        return @()
    }
}

function Test-IsReviewPath {
    param([string]$Path)
    return $Path -match '^\.documentation/specs/pr-review/pr-.*\.md$'
}

function Write-GateFailure {
    param(
        [string]$Message,
        [string[]]$OffendingPaths
    )

    Write-Error "DevSpark: $Message"
    if ($OffendingPaths.Count -gt 0) {
        Write-Error "Offending staged paths:"
        foreach ($item in $OffendingPaths) {
            Write-Error "  - $item"
        }
    }
    exit 1
}

if ($Gate) {
    $staged = Get-StagedPaths

    if ($Gate -eq 'code-only') {
        $reviewStaged = @($staged | Where-Object { Test-IsReviewPath $_ })
        if ($reviewStaged.Count -gt 0) {
            Write-GateFailure -Message 'Code commit gate failed. Review files must not be staged for code-only commits.' -OffendingPaths $reviewStaged
        }
    }

    if ($Gate -eq 'review-only') {
        $nonReviewStaged = @($staged | Where-Object { -not (Test-IsReviewPath $_) })
        if ($nonReviewStaged.Count -gt 0) {
            Write-GateFailure -Message 'Review commit gate failed. Only PR review markdown files may be staged.' -OffendingPaths $nonReviewStaged
        }
    }

    if (-not $Json) {
        Write-Output "Gate '$Gate' passed."
    }
    exit 0
}

if (-not $PrId) {
    Write-Error 'DevSpark: Provide -PrId <N> or -Gate <code-only|review-only>.'
    exit 1
}

$normalizedPrId = ($PrId -replace '^#', '').Trim()
if ($normalizedPrId -notmatch '^\d+$') {
    Write-Error "DevSpark: Invalid PR id '$PrId'. Expected a positive integer."
    exit 1
}

$repoRoot = Get-RepoRoot
$reviewFile = Join-Path $repoRoot ".documentation/specs/pr-review/pr-$normalizedPrId.md"

if (-not (Test-Path -LiteralPath $reviewFile)) {
    Write-Error "DevSpark: Review file not found: $reviewFile"
    exit 1
}

$lines = Get-Content -LiteralPath $reviewFile -Encoding utf8
$openFindings = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # Severity prefixes mirror /devspark.pr-review finding IDs: C, H, M, L, CON.
    if ($line -match '^\s*-\s*\[\s\]\s+\*\*((C|H|M|L|CON)-\d{2})\*\*') {
        $findingId = $matches[1]
        $severity = $matches[2]
        $openFindings.Add([PSCustomObject]@{
            id = $findingId
            severity = $severity
            line_number = $i + 1
            line = $line.Trim()
        })
    }
}

$result = [PSCustomObject]@{
    pr_id = [int]$normalizedPrId
    review_file = $reviewFile
    open_findings = $openFindings
    open_count = $openFindings.Count
}

if ($Json) {
    $result | ConvertTo-Json -Depth 4
}
else {
    Write-Output "Review file: $reviewFile"
    Write-Output "Open findings: $($openFindings.Count)"
    foreach ($finding in $openFindings) {
        Write-Output "- $($finding.id) (line $($finding.line_number))"
    }
}
