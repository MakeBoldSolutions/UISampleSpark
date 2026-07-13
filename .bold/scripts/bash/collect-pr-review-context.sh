#!/usr/bin/env bash
# Collector for bold.ship address. Emits the current PR's number and review
# comments via the gh CLI, so responding to review feedback starts from the
# actual comment thread instead of a human re-pasting it.
set -euo pipefail

gh_available=false
command -v gh >/dev/null 2>&1 && gh_available=true

pr_number="null"
review_comments="[]"

if [ "$gh_available" = true ]; then
  if number="$(gh pr view --json number -q .number 2>/dev/null)" && [ -n "$number" ]; then
    pr_number="$number"
    review_comments="$(gh api "repos/{owner}/{repo}/pulls/$number/comments" \
      --jq '[.[] | {author: .user.login, body: .body}]' 2>/dev/null || echo '[]')"
    [ -z "$review_comments" ] && review_comments="[]"
  fi
fi

printf '{"gh_available":%s,"pr_number":%s,"review_comments":%s}\n' \
  "$gh_available" "$pr_number" "$review_comments"
