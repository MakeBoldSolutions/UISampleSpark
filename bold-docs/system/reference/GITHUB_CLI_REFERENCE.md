# GitHub Actions Quick Reference

Quick commands for debugging and monitoring GitHub Actions using GitHub CLI (`gh`).

## Installation
```bash
# Windows (via winget)
winget install GitHub.cli

# Windows (via Chocolatey)
choco install gh

# macOS
brew install gh

# Linux
sudo apt install gh
```

## Authentication
```bash
# Login to GitHub
gh auth login

# Check authentication status
gh auth status
```

## Workflow Management

### List Workflows
```bash
# List all workflows
gh workflow list

# View specific workflow
gh workflow view docker-markhazletonsample
```

### Runs

```bash
# List recent runs (default: 10)
gh run list

# List runs with limit
gh run list --limit 20

# List runs for specific workflow
gh run list --workflow=docker-image.yml

# List failed runs only
gh run list --status=failure

# List runs for specific branch
gh run list --branch=main
```

### View Run Details

```bash
# View run details
gh run view <run-id>

# View run with logs
gh run view <run-id> --log

# View only failed logs
gh run view <run-id> --log-failed

# Watch a running workflow
gh run watch

# Watch specific run
gh run watch <run-id>
```

### Trigger Workflows

```bash
# Manually trigger workflow (workflow_dispatch)
gh workflow run docker-image.yml

# Trigger with inputs
gh workflow run docker-image.yml --field environment=staging
```

### Re-run Workflows

```bash
# Re-run a failed workflow
gh run rerun <run-id>

# Re-run only failed jobs
gh run rerun <run-id> --failed

# Re-run a specific job
gh run rerun <run-id> --job <job-id>
```

### Download Artifacts

```bash
# List artifacts for a run
gh run view <run-id> --log

# Download all artifacts
gh run download <run-id>

# Download specific artifact
gh run download <run-id> --name artifact-name
```

## Repository Analysis

### Check Repository Status
```bash
# View repository info
gh repo view

# View repository with web browser
gh repo view --web
```

### Dependabot

```bash
# List Dependabot alerts
gh api repos/:owner/:repo/dependabot/alerts

# View dependabot.yml file
gh api repos/:owner/:repo/contents/.github/dependabot.yml

# List open Dependabot PRs
gh pr list --author app/dependabot
```

### Security

```bash
# List security advisories
gh api repos/:owner/:repo/security-advisories

# List code scanning alerts
gh api repos/:owner/:repo/code-scanning/alerts
```

## Docker-Specific Commands

### Docker Images on GitHub Container Registry

```bash
# List packages
gh api user/packages

# Get package details
gh api users/:username/packages/container/:package-name
```

### Local Docker Testing

```bash
# Build Docker image
docker build -f UISampleSpark.UI/Dockerfile -t uisamplespark:test .

# Build with build args
docker build -f UISampleSpark.UI/Dockerfile \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t uisamplespark:test .

# Run container
docker run -d -p 8080:80 uisamplespark:test

# View container logs
docker logs <container-id>

# Execute command in container
docker exec -it <container-id> /bin/bash

# Stop and remove container
docker stop <container-id>
docker rm <container-id>
```

## Common Troubleshooting Workflows

### Check Recent Failures
```bash
gh run list --limit 10 --status=failure
```

### View Latest Failed Run
```bash
gh run list --limit 1 --status=failure --json databaseId --jq '.[0].databaseId' | xargs gh run view --log-failed
```

### Monitor Current Run
```bash
# Get latest run ID
$runId = gh run list --limit 1 --json databaseId --jq '.[0].databaseId'

# Watch the run
gh run watch $runId
```

### Re-run All Failed Workflows
```bash
# PowerShell
gh run list --limit 10 --status=failure --json databaseId --jq '.[].databaseId' | ForEach-Object { gh run rerun $_ --failed }

# Bash
gh run list --limit 10 --status=failure --json databaseId --jq '.[].databaseId' | xargs -I {} gh run rerun {} --failed
```

### Check Workflow Syntax
```bash
# View workflow file
gh workflow view docker-markhazletonsample

# Download workflow file
gh api repos/:owner/:repo/contents/.github/workflows/docker-image.yml | jq -r .content | base64 -d
```

### View Job Logs
```bash
# List jobs for a run
gh api repos/:owner/:repo/actions/runs/<run-id>/jobs

# Get specific job log
gh api repos/:owner/:repo/actions/jobs/<job-id>/logs
```

## Advanced API Usage

### Get Workflow Run Details (JSON)
```bash
gh api repos/:owner/:repo/actions/runs/<run-id>
```

### List All Workflow Runs (with filters)
```bash
# PowerShell
gh api "repos/:owner/:repo/actions/runs?status=failure&per_page=10" | ConvertFrom-Json | Select-Object -ExpandProperty workflow_runs

# Bash
gh api "repos/:owner/:repo/actions/runs?status=failure&per_page=10" | jq '.workflow_runs[]'
```

### Cancel Running Workflow
```bash
gh run cancel <run-id>
```

### Delete Workflow Run
```bash
gh api -X DELETE repos/:owner/:repo/actions/runs/<run-id>
```

## Environment Variables

### Set for Current Session
```bash
# PowerShell
$env:GH_TOKEN = "your_token_here"

# Bash
export GH_TOKEN="your_token_here"
```

### Common Environment Variables
- `GH_TOKEN` - GitHub Personal Access Token
- `GH_REPO` - Default repository (owner/repo)
- `GH_HOST` - GitHub Enterprise hostname

## Useful Aliases

### PowerShell Profile
```powershell
# Add to $PROFILE
function gh-watch-latest { gh run watch (gh run list --limit 1 --json databaseId --jq '.[0].databaseId') }
function gh-failed { gh run list --limit 10 --status=failure }
function gh-rerun-latest { gh run rerun (gh run list --limit 1 --json databaseId --jq '.[0].databaseId') }
```

### Bash/Zsh Profile
```bash
# Add to ~/.bashrc or ~/.zshrc
alias gh-watch-latest='gh run watch $(gh run list --limit 1 --json databaseId --jq ".[0].databaseId")'
alias gh-failed='gh run list --limit 10 --status=failure'
alias gh-rerun-latest='gh run rerun $(gh run list --limit 1 --json databaseId --jq ".[0].databaseId")'
```

## Tips and Best Practices

1. **Use JSON output for scripting**: Add `--json` flag for programmatic access
2. **Check API rate limits**: `gh api rate_limit`
3. **Use `--web` flag**: Opens results in browser for detailed view
4. **Save frequently used commands**: Create aliases or functions
5. **Monitor workflow runs**: Use `gh run watch` for real-time updates
6. **Leverage JQ**: Use `jq` for JSON parsing and filtering
7. **Check GitHub Status**: Visit https://www.githubstatus.com/ for service issues

## Related Documentation

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitHub REST API](https://docs.github.com/rest)
- [JQ Manual](https://stedolan.github.io/jq/manual/)

## Emergency Contacts

- **GitHub Status**: https://www.githubstatus.com/
- **GitHub Support**: https://support.github.com/
- **Community Forum**: https://github.community/

---

**Last Updated**: 2025-11-16  
**Maintained By**: DevOps Team
