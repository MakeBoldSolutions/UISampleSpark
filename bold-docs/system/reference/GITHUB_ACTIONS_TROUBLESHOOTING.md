# GitHub Actions Troubleshooting Guide

## Current Issues Detected

### 1. Docker Build Failure - Missing HttpClientFactory Project

**Error:**
```
ERROR: failed to build: failed to solve: failed to compute cache key: 
failed to calculate checksum of ref: "/UISampleSpark.HttpClientFactory/UISampleSpark.HttpClientFactory.csproj": not found
```

**Root Cause:**
The Docker build context is not properly including the `UISampleSpark.HttpClientFactory` directory when building from GitHub Actions.

**Solutions:**

#### Option A: Verify .dockerignore (Recommended)
The `.dockerignore` file should NOT exclude project directories. Current configuration is correct, but verify:
- `**/bin` and `**/obj` are excluded (good)
- Project directories are NOT excluded (verify this)

#### Option B: Update Dockerfile to Use Wildcard COPY
Instead of copying individual project files, copy all .csproj files at once:

```dockerfile
# Copy all project files at once
COPY ["*.sln", "./"]
COPY ["*/*.csproj", "./"]
RUN for file in $(ls *.csproj); do mkdir -p ${file%.*}/ && mv $file ${file%.*}/; done
```

#### Option C: Simplify Dockerfile (Current Recommended Fix)
Update the Dockerfile to copy the entire solution context first, then restore:

```dockerfile
# Copy solution file first
COPY ["*.sln", "./"]
COPY ["nuget.config", "./"]

# Copy all csproj files with proper directory structure
COPY ["UISampleSpark.UI/*.csproj", "UISampleSpark.UI/"]
COPY ["UISampleSpark.Data/*.csproj", "UISampleSpark.Data/"]
COPY ["UISampleSpark.Core/*.csproj", "UISampleSpark.Core/"]
COPY ["UISampleSpark.HttpClientFactory/*.csproj", "UISampleSpark.HttpClientFactory/"]
COPY ["UISampleSpark.CLI/*.csproj", "UISampleSpark.CLI/"]
```

### 2. Dependabot Docker Updater Failures

**Error:**
```
Error: (HTTP code 404) no such container - No such image: 
ghcr.io/dependabot/dependabot-updater-docker:e2126b1ab7d8ada068d357915e4a90b2499101d0
```

**Root Cause:**
This is a GitHub infrastructure issue where Dependabot cannot find the Docker updater container image. This is typically a temporary issue on GitHub's side.

**Solutions:**

1. **Wait and Retry** (Most Common)
   - This is usually a temporary GitHub infrastructure issue
   - Dependabot will automatically retry failed updates
   - Check GitHub Status: https://www.githubstatus.com/

2. **Disable Docker Ecosystem Temporarily**
   - Comment out the Docker ecosystem in `.github/dependabot.yml`
   - Wait for GitHub to resolve the infrastructure issue
   - Re-enable after confirmation

3. **Manual Dependency Check**
   ```bash
   # Check for updated base images manually
   docker pull mcr.microsoft.com/dotnet/aspnet:9.0
   docker pull mcr.microsoft.com/dotnet/sdk:9.0
   ```

### 3. Missing Dependabot Configuration for HttpClientFactory

**Issue:**
The `UISampleSpark.HttpClientFactory` project is not included in the Dependabot configuration.

**Fix:**
Add the following to `.github/dependabot.yml`:

```yaml
  # NuGet dependencies for HttpClientFactory project
  - package-ecosystem: "nuget"
    directory: "/UISampleSpark.HttpClientFactory"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "nuget"
    commit-message:
      prefix: "deps"
      include: "scope"
```

## Verification Steps

### Check GitHub Actions Status
```bash
# List recent workflow runs
gh run list --limit 10

# View specific run details
gh run view <run-id>

# View failed logs
gh run view <run-id> --log-failed
```

### Verify Dependabot Configuration
```bash
# Validate dependabot.yml syntax
gh api repos/:owner/:repo/contents/.github/dependabot.yml

# List Dependabot alerts
gh api repos/:owner/:repo/dependabot/alerts
```

### Test Docker Build Locally
```bash
# Test the Docker build with the same context as GitHub Actions
docker build -f UISampleSpark.UI/Dockerfile -t uisamplespark:test .

# Check for context issues
docker build -f UISampleSpark.UI/Dockerfile --progress=plain -t uisamplespark:test . 2>&1 | grep "not found"
```

## Recommended Actions

1. **Immediate:** Update Dockerfile to fix the HttpClientFactory path issue
2. **Short-term:** Monitor Dependabot failures - likely to resolve automatically
3. **Long-term:** Add comprehensive CI/CD testing before merge

## Additional Resources

- [Docker Build Context Documentation](https://docs.docker.com/build/building/context/)
- [Dependabot Configuration Options](https://docs.github.com/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [GitHub Actions Troubleshooting](https://docs.github.com/actions/monitoring-and-troubleshooting-workflows)
- [.dockerignore Documentation](https://docs.docker.com/build/building/context/#dockerignore-files)
