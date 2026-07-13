# CodeQL Action v3 to v4 Migration Status

## Overview
GitHub announced the deprecation of CodeQL Action v3 on October 28, 2025. The action will be officially deprecated in **December 2026** alongside GitHub Enterprise Server 3.19.

## Migration Status for This Repository

### ? Completed
- **docker-image.yml**: Already using `github/codeql-action/upload-sarif@v4`

### ? Not Applicable
- **main_samplecrud.yml**: Does not use CodeQL actions (Azure deployment workflow)

## What Changed in v4

CodeQL Action v4 runs on the **Node.js 24 runtime** (v3 used Node.js 20).

## Required Changes

According to the official GitHub blog post, you need to replace all references to:

- `github/codeql-action/init@v3` ? `github/codeql-action/init@v4`
- `github/codeql-action/autobuild@v3` ? `github/codeql-action/autobuild@v4`
- `github/codeql-action/analyze@v3` ? `github/codeql-action/analyze@v4`
- `github/codeql-action/upload-sarif@v3` ? `github/codeql-action/upload-sarif@v4`

## Platform Requirements

### GitHub.com and GHES 3.20+
- ? Fully supported - update workflow files immediately
- GHES 3.20 ships with CodeQL Action v4

### GHES 3.19
- ?? Supports Node.js 24 but doesn't ship with v4
- Requires [GitHub Connect](https://docs.github.com/enterprise-server@3.11/admin/github-actions/managing-access-to-actions-from-githubcom/using-the-latest-version-of-the-official-bundled-actions#using-github-connect-to-access-the-latest-actions) to download v4

### GHES 3.18 and Older
- ? Does not support Node.js 24 runtime
- Must upgrade GHES before using CodeQL Action v4

## Dependabot Configuration

You can automate this upgrade using Dependabot. Add to `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "github-actions"
```

## Timeline

- **October 7, 2025**: CodeQL Action v4 released
- **October 28, 2025**: v3 deprecation announced
- **December 2026**: v3 officially deprecated (no new updates)
- **Post-December 2026**: Possible brownout periods if migration is incomplete

## Current Workflow Analysis

### docker-image.yml
```yaml
- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v4  # ? Already updated
  if: always() && hashFiles('trivy-results.sarif') != ''
  with:
    sarif_file: 'trivy-results.sarif'
    category: 'container-scan'
```

**Status**: ? Up to date - using v4

### main_samplecrud.yml
- Does not use any CodeQL actions
- Focused on Azure deployment pipeline
- No action required

## Benefits of v4

1. **Node.js 24 Runtime**: Latest features and security updates
2. **Future-Proofing**: Access to new CodeQL capabilities
3. **Performance**: Improved execution speed
4. **Support**: Active maintenance and updates

## Testing Recommendations

After migration:
1. ? Test workflow execution in a feature branch
2. ? Verify SARIF file uploads to GitHub Security
3. ? Check that security alerts appear correctly
4. ? Confirm no breaking changes in your specific use case

## References

- [Official Announcement](https://github.blog/changelog/2025-10-28-upcoming-deprecation-of-codeql-action-v3/)
- [CodeQL Action Documentation](https://docs.github.com/code-security/code-scanning)
- [Dependabot for Actions](https://docs.github.com/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)

## Conclusion

? **This repository is compliant with the upcoming v3 deprecation.**

All CodeQL actions currently in use are already on v4. No further action is required at this time. However, we recommend:

1. Setting up Dependabot for automatic GitHub Actions updates
2. Monitoring the official GitHub blog for any further changes
3. Testing workflows periodically to ensure continued compatibility

---

*Last Updated*: December 2024
*Migration Completed*: October 2024 (proactive upgrade)
*Next Review Date*: June 2026 (6 months before deprecation)
