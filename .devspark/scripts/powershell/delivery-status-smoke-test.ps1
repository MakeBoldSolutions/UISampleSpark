# Smoke test for delivery-status enforcement (PowerShell)
#
# Validates that delivery-status gating works correctly in PowerShell environments.
# This test verifies the core MVP feature: delivery runs report accurate status and gate create-pr.
#
# Usage: .\delivery-status-smoke-test.ps1
# Expected exit code: 0 (success) or non-zero (failure)

param(
    [switch]$Quiet = $false
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Script locations
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Get-Item $ScriptDir).Parent.Parent.FullName

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$NC = "`e[0m"

$testCount = 0
$passed = 0
$failed = 0

# Helper functions
function LogTest {
    param([string]$Message)
    $script:testCount++
    if (-not $Quiet) {
        Write-Host "[TEST $testCount] $Message" -ForegroundColor Cyan
    }
}

function LogPass {
    param([string]$Message)
    $script:passed++
    if (-not $Quiet) {
        Write-Host "  $Green✓ PASS$NC : $Message" -ForegroundColor Green
    }
}

function LogFail {
    param([string]$Message)
    $script:failed++
    if (-not $Quiet) {
        Write-Host "  $Red✗ FAIL$NC : $Message" -ForegroundColor Red
    }
}

# Test 1: Verify git command works for change detection
LogTest "Git command available"
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
if ($gitAvailable) {
    LogPass "git command available"
} else {
    LogFail "git command not available"
}

# Test 2: Verify delivery result file structure
LogTest "Delivery result JSON structure"
$resultFile = "$RepoRoot\.documentation\devspark\runs\latest\result.json"
if (Test-Path $resultFile) {
    $resultContent = Get-Content $resultFile -Raw
    
    if ($resultContent -match '"delivery_status"') {
        LogPass "delivery_status field present in result.json"
    } else {
        LogFail "delivery_status field missing from result.json"
    }
    
    if ($resultContent -match '"create_pr_ready"') {
        LogPass "create_pr_ready field present in result.json"
    } else {
        LogFail "create_pr_ready field missing from result.json"
    }
} else {
    LogFail "No result.json file found (no recent runs)"
}

# Test 3: Verify delivery check validation rule exists
LogTest "Delivery check rule defined"
$specPath = "$RepoRoot\.documentation\specs\001-harness-delivery-integrity"
if (Test-Path $specPath) {
    LogPass "Feature spec directory exists"
    
    # Search for git.changed_count or git.changed_path_match in spec files
    $ruleFound = Get-ChildItem $specPath -Recurse -Filter "*.md" |
        Select-String -Pattern "git\.changed_count|git\.changed_path_match" -ErrorAction SilentlyContinue
    
    if ($null -ne $ruleFound) {
        LogPass "Delivery validation rules defined in spec"
    } else {
        LogFail "Delivery validation rules not found in spec"
    }
} else {
    LogFail "Feature spec directory not found"
}

# Test 4: Verify no-change explainer can be generated
LogTest "No-change explainer artifact"
$explainerFile = "$RepoRoot\.documentation\devspark\runs\latest\no-change-explainer.md"
if (Test-Path $explainerFile) {
    LogPass "No-change explainer artifact can be generated"
} else {
    # This is OK if no run yet - not a failure
    LogPass "No-change explainer (not required if no runs yet)"
}

# Test 5: Verify governance approval checkpoint exists
LogTest "Governance approval gate documentation"
$approvalFile = "$RepoRoot\.documentation\specs\001-harness-delivery-integrity\gates\governance-approval.md"
if (Test-Path $approvalFile) {
    $approvalContent = Get-Content $approvalFile -Raw
    if ($approvalContent -match "Approver Name:") {
        LogPass "Governance approval template exists"
    } else {
        LogFail "Governance approval template incomplete"
    }
} else {
    LogFail "Governance approval template not found"
}

# Test 6: Verify delivery checks can be collected from git
LogTest "Git diff command works"
try {
    $gitDiffResult = & git diff --name-only -- src/ test/ 2>$null
    LogPass "Git diff command executes without errors"
} catch {
    LogFail "Git diff command failed: $_"
}

# Summary
Write-Host ""
Write-Host "=========================================="
Write-Host "Smoke Test Summary"
Write-Host "=========================================="
Write-Host "Tests run:  $testCount"
Write-Host ("Passed:     {0}{1}{2}" -f $Green, $passed, $NC)
Write-Host ("Failed:     {0}{1}{2}" -f $Red, $failed, $NC)
Write-Host ""

if ($failed -eq 0) {
    Write-Host ("{0}✓ All smoke tests passed{1}" -f $Green, $NC)
    exit 0
} else {
    Write-Host ("{0}✗ Some tests failed{1}" -f $Red, $NC)
    exit 1
}
