# Mobile App Risk Checklist

## Platform Compliance

- [ ] **Store policies reviewed** — Apple App Review, Google Play Data Safety, permissions declarations
- [ ] **OS version support window declared and tested** (min/target/latest)
- [ ] **Privacy manifest / SDK declarations current** — e.g., iOS PrivacyInfo, Android data-safety form

## Lifecycle & Background

- [ ] **Background execution within platform limits** — iOS background modes, Android WorkManager/foreground service rules
- [ ] **Push / background-fetch failure paths handled** (no silent broken state)
- [ ] **Deep-link / intent handling validated** for malformed and hostile inputs

## Performance & Size

- [ ] **App size budget tracked per release** (download + install)
- [ ] **Cold-start budget measured on low-end target device**
- [ ] **Battery / network impact measured** on representative workloads

## Offline & Sync

- [ ] **Offline queue durable across app kill / OS reboot**
- [ ] **Conflict resolution strategy declared** (LWW, CRDT, server-wins, manual merge)
- [ ] **Clock skew tolerated** (use server time for ordering where needed)

## Distribution

- [ ] **Crash reporting + symbol upload automated** — e.g., Crashlytics, Sentry, App Center
- [ ] **OTA / forced-update path** for security fixes
- [ ] **Secrets not bundled in client** (no API keys with server-side privilege)
