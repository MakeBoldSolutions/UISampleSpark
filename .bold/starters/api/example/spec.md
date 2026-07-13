# List Active Subscriptions

> **TL;DR for the Product Owner**
> *What*: Adds an endpoint that returns a customer's currently active subscriptions.
> *Why*: Support staff currently have to query the database directly to answer "what is this customer paying for right now" — this makes it a normal API call.
> *Status*: Complete.
> *Decision needed*: none.

**Tier**: Feature
**Status**: Complete

## Intent

Add `GET /customers/{id}/subscriptions?status=active` so any authenticated caller can retrieve a customer's active subscriptions without direct database access. Feature tier because this is a new contract a future caller will depend on (backbone principle 2: a shipped contract is versioned before it changes incompatibly — this is the *first* version, so nothing to version against yet, but the shape chosen here is what future versioning has to work around).

## Contract

- **Method & path**: `GET /customers/{id}/subscriptions`
- **Auth**: per `core.api.auth` (`oidc`) — caller must hold the `customers:read` scope
- **Request**: path param `id` (customer ID); optional query param `status` (`active` | `canceled` | `all`, default `active`)
- **Response** (200): `{ "customer_id": "...", "subscriptions": [{ "id": "...", "plan": "...", "started_at": "...", "status": "active" }] }`
- **Errors**: 404 if `id` doesn't exist; 403 if the caller lacks `customers:read`; 400 if `status` isn't one of the enumerated values
- **Versioning**: this is v1 of this contract — no prior version to be compatible with

## Acceptance Criteria

- [x] `GET /customers/{id}/subscriptions` with no `status` param returns only active subscriptions
- [x] `status=all` returns every subscription regardless of state
- [x] An unknown customer `id` returns 404, not an empty list
- [x] A caller without `customers:read` gets 403, not a 200 with empty results
- [x] An invalid `status` value returns 400 naming the allowed values

## Affected Files

- `src/routes/customers/subscriptions.{ext}` (new)
- `src/auth/scopes.{ext}` (add `customers:read` if not already defined)

## Tasks

- [x] T001 Define the response shape and error cases as a contract test fixture, `src/routes/customers/subscriptions.contract.test.{ext}`
- [x] T002 [P] Implement the route handler, `src/routes/customers/subscriptions.{ext}`
- [x] T003 [P] Wire the `customers:read` scope check into the route, `src/auth/scopes.{ext}`
- [x] T004 Implement the `status` query param validation and the 400 case, `src/routes/customers/subscriptions.{ext}`
- [x] T005 Write the 404/403/400 test cases against the contract fixture from T001
