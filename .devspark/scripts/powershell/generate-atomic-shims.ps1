#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate atomic-prompt shim files for every templates/commands/*.md.

.DESCRIPTION
    For each command in templates/commands/, writes a thin atomic-prompt
    shim under templates/prompts/atomic/<command>.md whose body is a
    one-line pointer back to the canonical command file.

    Exit codes:
        0 - success (no drift, or shims (re)generated)
        1 - drift detected with -Check (CI gate)
        2 - I/O failure
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [string]$RepoRoot
)

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$commandsDir = Join-Path $RepoRoot "templates/commands"
$atomicDir = Join-Path $RepoRoot "templates/prompts/atomic"

if (-not (Test-Path $commandsDir)) {
    Write-Error "commands dir not found: $commandsDir"; exit 2
}
New-Item -ItemType Directory -Force -Path $atomicDir | Out-Null

$drift = @()
$generated = 0

Get-ChildItem -Path $commandsDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
    $cmd = $_.BaseName
    $shim = Join-Path $atomicDir "$cmd.md"

    $description = "Atomic shim for /devspark.$cmd. Resolves to templates/commands/$cmd.md."
    if ($description.Length -gt 200) {
        $description = $description.Substring(0, 197) + "..."
    }

    $body = @"
---
id: $cmd
name: $cmd
audience: expert
exposed: false
category: legacy-command
description: $description
inputs: []
outputs: []
legacy_command: $cmd
---

## Outline

This atomic prompt is a backward-compatibility shim. Its execution is
delegated to the canonical command file at ``templates/commands/$cmd.md``.

The workflow runner resolves this id through the standard 3-tier override
chain (personal -> team -> stock) and forwards execution to the legacy
command body.
"@

    if (Test-Path $shim) {
        $existing = Get-Content -Raw -LiteralPath $shim
        if ($existing -ne ($body + "`n")) {
            $drift += $cmd
            if (-not $Check) {
                Set-Content -LiteralPath $shim -Value ($body + "`n") -NoNewline
                $generated += 1
            }
        }
    } else {
        $drift += $cmd
        if (-not $Check) {
            Set-Content -LiteralPath $shim -Value ($body + "`n") -NoNewline
            $generated += 1
        }
    }
}

if ($Check) {
    if ($drift.Count -gt 0) {
        Write-Host "Atomic-shim drift detected for $($drift.Count) command(s):"
        $drift | ForEach-Object { Write-Host "  - $_" }
        Write-Host ""
        Write-Host "Run scripts/powershell/generate-atomic-shims.ps1 to regenerate."
        exit 1
    }
    Write-Host "No atomic-shim drift detected."
    exit 0
}

Write-Host "Generated/updated $generated atomic-prompt shim(s) under templates/prompts/atomic/."
exit 0
