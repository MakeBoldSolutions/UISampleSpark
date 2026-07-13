1. **The frontend never holds a third-party secret.** Any call that needs one goes through the backend, which holds the secret server-side.
   <!-- source: starter(fullstack) -->
   **Status**: enforced

2. **A shipped API contract is versioned before it changes incompatibly** — same rule as the `api` starter: a breaking change gets a new version, never an in-place mutation of a contract the frontend already depends on.
   <!-- source: starter(fullstack) -->
   **Status**: enforced
