# Dashboard: Today's Order Count Widget

> **TL;DR for the Product Owner**
> *What*: Adds a widget to the dashboard showing how many orders have come in today.
> *Why*: Staff currently open a separate reporting tool every morning just to check this one number.
> *Status*: Complete.
> *Decision needed*: none.

**Tier**: Feature
**Status**: Complete

## Intent

Add a dashboard widget that shows today's order count, refreshed on page load (not real-time — that's a larger feature this doesn't need to become). Feature tier because it introduces a new API contract the frontend depends on (backbone principle 2, same as the `api` starter) and a new piece of cross-module flow (UI → API → data).

## Contract

- **UI**: a card on the dashboard showing a number and the label "Orders today"; a loading state while the count is fetched; an inline error state (not a blocking one) if the fetch fails
- **API**: `GET /reports/orders/today` — returns `{ "count": 42, "as_of": "2026-07-09T14:00:00Z" }`. Auth per `core.api.auth` (`oidc`), same session as the rest of the dashboard, no new scope needed (read-only, already-visible data)
- **Data**: counts orders where `created_at` falls within the caller's local "today" — the API takes a `tz` query param (IANA timezone name) so "today" means the same thing to the user as it does on their clock, not the server's
- **Errors**: if the count query fails, the API returns 500; the widget shows "Couldn't load" with a retry button rather than crashing the dashboard

## Acceptance Criteria

- [x] Widget shows the correct count for orders created today in the caller's timezone
- [x] Missing/invalid `tz` falls back to UTC rather than erroring
- [x] Widget shows a loading state while the request is in flight
- [x] A failed request shows an inline retry, not a broken dashboard
- [x] Widget re-fetches on page load, not on a timer (explicitly out of scope: live updates)

## Affected Files

- `src/api/routes/reports/orders-today.{ext}` (new)
- `src/web/components/dashboard/OrdersTodayWidget.{ext}` (new)
- `src/web/components/dashboard/Dashboard.{ext}` (add the widget)

## Tasks

- [x] T001 Define the `/reports/orders/today` response contract as a fixture, `src/api/routes/reports/orders-today.contract.test.{ext}`
- [x] T002 [P] Implement the API route and the timezone-aware "today" query, `src/api/routes/reports/orders-today.{ext}`
- [x] T003 [P] Build `OrdersTodayWidget` with loading/error/success states, `src/web/components/dashboard/OrdersTodayWidget.{ext}`
- [x] T004 Wire the widget into `Dashboard`, `src/web/components/dashboard/Dashboard.{ext}` (depends on T003)
- [x] T005 Test the invalid/missing `tz` fallback against the contract fixture from T001
