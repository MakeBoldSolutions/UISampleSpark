# Indexing Troubleshooting and Verification

## Scope
Use this checklist when validating indexing controls for:
- Query-string URLs
- API endpoints
- Create/Edit/Delete utility pages

## Expected Behavior
1. Query-string pages should not be indexable.
2. API endpoints should not be indexable.
3. Create/Edit/Delete pages should not be indexable.
4. Canonical links should not include query strings.
5. Stable public content pages should remain indexable.

## Quick Verification
Run from repository root.

```bash
dotnet build UISampleSpark.UI/UISampleSpark.UI.csproj
dotnet test UISampleSpark.UI.Tests/UISampleSpark.UI.Tests.csproj
```

## Manual Endpoint Checks
Start the UI and verify headers.

```bash
dotnet run --project UISampleSpark.UI/UISampleSpark.UI.csproj
curl -I "http://localhost:5000/Employee?page=2"
curl -I "http://localhost:5000/api/employee"
curl -I "http://localhost:5000/MvcEmployee/Edit/1"
```

Expected header for the three URLs above:

```text
X-Robots-Tag: noindex, nofollow
```

## HTML Checks
For query-string pages, inspect rendered HTML source:
- robots meta should be noindex,nofollow
- canonical should be path-only (no query string)

Example expected canonical for /Employee?page=2:

```html
<link rel="canonical" href="http://localhost/Employee" />
```

## Where to Look in Code
- Robots file: UISampleSpark.UI/wwwroot/robots.txt
- Header middleware: UISampleSpark.UI/Program.cs
- Meta/canonical generation: UISampleSpark.UI/Views/Shared/Sections/_metatags.cshtml
- Regression tests: UISampleSpark.UI.Tests/Test1.cs
- Smoke tests: UISampleSpark.UI.Tests/IndexingSmokeTests.cs

## Common Failure Modes
1. Canonical includes query strings.
Cause: canonical built from full request URL.
Fix: build canonical from scheme + host + path only.

2. Header missing on utility/API routes.
Cause: middleware path match misses route shape or case.
Fix: keep path checks case-insensitive and central in middleware.

3. Robots.txt rules present but pages still indexed.
Cause: robots.txt controls crawling, not guaranteed deindexing.
Fix: keep robots.txt plus X-Robots-Tag and noindex meta together.
