# {Endpoint or Capability Name}

> **TL;DR for the Product Owner**
> *What*: {one sentence — what can a caller now do}
> *Why*: {one sentence — what problem this solves}
> *Status*: Planning — no code written yet.
> *Decision needed*: {only if true}

**Tier**: {Patch | Quick | Feature}
**Status**: Draft

## Intent

{What this endpoint/capability does and why it's shaped this way.}

## Contract

- **Method & path**: `{METHOD} /{path}`
- **Auth**: {per `core.api.auth` — none / api_key / oidc; state the required scope/role if any}
- **Request**: {shape, required vs. optional fields}
- **Response**: {success shape; status code}
- **Errors**: {each error case with its status code and when it fires}
- **Versioning**: {if this changes an existing contract, per backbone principle 2 — new version, not in-place mutation}

## Acceptance Criteria

- [ ] {Observable behavior a test could check}

## Affected Files

- {}

## Tasks

- [ ] T1: {}
