# PowerShell wrapper that forwards arguments to `python -m devspark_cli run`.
#
# Usage:
#   scripts\powershell\run-workflow.ps1 create-spec
#   scripts\powershell\run-workflow.ps1 execute-plan --autonomy assisted

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'
& python -m devspark_cli run @Args
exit $LASTEXITCODE
