# Collector for bold.ship address. Emits the current PR's number and review
# comments via the gh CLI, so responding to review feedback starts from the
# actual comment thread instead of a human re-pasting it.

$ErrorActionPreference = 'Stop'

$ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)

$prNumber = $null
$reviewComments = @()

if ($ghAvailable) {
  $number = gh pr view --json number -q .number 2>$null
  if ($number) {
    $prNumber = [int]$number
    $raw = gh api "repos/{owner}/{repo}/pulls/$prNumber/comments" `
      --jq '[.[] | {author: .user.login, body: .body}]' 2>$null
    if ($raw) {
      $reviewComments = @(ConvertFrom-Json $raw)
    }
  }
}

[ordered]@{
  gh_available    = $ghAvailable
  pr_number       = $prNumber
  review_comments = $reviewComments
} | ConvertTo-Json -Depth 10 -Compress
