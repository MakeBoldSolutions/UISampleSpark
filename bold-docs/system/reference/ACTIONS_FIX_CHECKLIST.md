# GitHub Actions Fix Checklist

Use this checklist to track the resolution of GitHub Actions failures.

## Pre-Commit Checklist

- [ ] Reviewed changes in `UISampleSpark.UI/Dockerfile`
- [ ] Reviewed changes in `.github/workflows/docker-image.yml`
- [ ] Read `GITHUB_ACTIONS_FIX_SUMMARY.md`
- [ ] Read `.github/ACTIONS_FAILURES_ANALYSIS.md`
- [ ] Verified local build is successful (`run_build` ?)

## Commit and Push

- [ ] Stage changes: `git add .`
- [ ] Commit: `git commit -m "fix: resolve Docker build failures and enhance CI/CD"`
- [ ] Push: `git push origin main`
- [ ] Note the commit SHA: __________________

## Post-Push Monitoring (First 10 minutes)

- [ ] Start watching workflow: `gh run watch`
- [ ] Verify workflow triggered successfully
- [ ] Check "Debug - List workspace structure" step passes
- [ ] Verify HttpClientFactory directory is listed in debug output
- [ ] Check Docker build completes without errors

## Post-Build Verification (After successful build)

- [ ] Verify Docker image pushed to DockerHub: `gh run view <run-id>`
- [ ] Check image tags are correct (latest and run number)
- [ ] Verify container test passed in workflow
- [ ] Check Trivy security scan completed
- [ ] Review GitHub Step Summary for image information

## Docker Image Testing (Optional)

- [ ] Pull the new image: `docker pull markhazleton/uisamplespark:latest`
- [ ] Run locally: `docker run -d -p 8080:80 markhazleton/uisamplespark:latest`
- [ ] Test endpoint: `curl http://localhost:8080`
- [ ] Stop container: `docker stop <container-id>`
- [ ] Clean up: `docker rm <container-id>`

## Dependabot Issues

### Docker Updater Issue (External - GitHub Infrastructure)

- [ ] Check GitHub Status: https://www.githubstatus.com/
- [ ] Check if issue is widespread: https://github.com/dependabot/dependabot-core/issues
- [ ] Monitor for automatic resolution (typically 24-48 hours)
- [ ] If persists > 48 hours, create GitHub Support ticket

**Current Status**: ? Waiting for GitHub to resolve  
**Last Checked**: _______________  
**Resolution Date**: _______________

### HttpClientFactory Dependabot Configuration

- [ ] Review configuration in `.github/ACTIONS_FAILURES_ANALYSIS.md`
- [ ] Decide on update approach:
  - [ ] Option A: Manual edit via GitHub web interface
  - [ ] Option B: Create separate PR with dependabot.yml update
  - [ ] Option C: Include in next maintenance PR
- [ ] Add HttpClientFactory section to dependabot.yml
- [ ] Commit and push dependabot.yml changes
- [ ] Verify Dependabot picks up the new configuration
- [ ] Check for initial update PRs from Dependabot

**Current Status**: ?? Documented, awaiting manual update  
**Planned Date**: _______________  
**Completed Date**: _______________

## Follow-up Actions (Week 1)

- [ ] Monitor builds for 5 days to ensure stability
- [ ] Check DockerHub for image updates
- [ ] Verify no new build failures
- [ ] Review Trivy security reports
- [ ] Address any security vulnerabilities found

## Follow-up Actions (Month 1)

- [ ] Review build times and optimize if needed
- [ ] Check Docker image sizes
- [ ] Verify Dependabot is working for all projects
- [ ] Update documentation based on experience

## Long-term Improvements (Backlog)

- [ ] Add integration tests to Docker workflow
- [ ] Implement automated security scanning alerts
- [ ] Create staging environment deployment workflow
- [ ] Add performance testing to CI/CD pipeline
- [ ] Document Docker deployment procedures
- [ ] Set up branch protection requiring successful builds
- [ ] Consider Docker Compose for local development
- [ ] Implement blue-green deployment strategy

## Issues and Notes

### Build Issues
_Use this section to note any issues encountered_

Date: _______________
Issue: _________________________________________________________________
Resolution: ____________________________________________________________

---

Date: _______________
Issue: _________________________________________________________________
Resolution: ____________________________________________________________

---

### Dependabot Issues
_Use this section to note Dependabot-related issues_

Date: _______________
Issue: _________________________________________________________________
Resolution: ____________________________________________________________

---

Date: _______________
Issue: _________________________________________________________________
Resolution: ____________________________________________________________

---

### Other Notes
_General notes about the fixes and improvements_

___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________

## Quick Reference Commands

```bash
# Monitor workflow
gh run watch

# Check recent runs
gh run list --limit 5

# View failed logs
gh run view <run-id> --log-failed

# Re-run failed workflow
gh run rerun <run-id> --failed

# Pull Docker image
docker pull markhazleton/uisamplespark:latest

# Test Docker image
docker run -d -p 8080:80 markhazleton/uisamplespark:latest

# Check Dependabot PRs
gh pr list --author app/dependabot

# Check GitHub Status
curl https://www.githubstatus.com/api/v2/status.json
```

## Success Criteria

This checklist is complete when:

? All Docker builds succeed consistently  
? Images are published to DockerHub successfully  
? Security scans run without critical issues  
? Dependabot Docker updater issue is resolved (or officially documented as persistent)  
? HttpClientFactory is added to dependabot.yml  
? No action item remains in "outstanding" status for > 30 days  

---

**Checklist Created**: 2025-11-16  
**Project**: UISampleSpark  
**Responsible**: Mark Hazleton  
**Review Date**: _______________
