1. **Every mutating endpoint requires authentication** unless `api.auth` is explicitly `none`.
   <!-- source: starter(api) -->
   **Status**: enforced

2. **A shipped API contract is versioned before it changes incompatibly** — a breaking change gets a new version, never an in-place mutation of a contract a caller already depends on.
   <!-- source: starter(api) -->
   **Status**: enforced
