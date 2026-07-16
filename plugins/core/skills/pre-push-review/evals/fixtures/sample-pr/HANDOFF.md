# RESET-142 — Rate-limit the password-reset request endpoint

**Source:** pasted brief · **Status:** planned

## Problem statement

Cap how often a password reset can be requested for a given email, to stop reset-email
spam and address probing, without opening a new account-enumeration hole.

## Scope

**In scope**
- Rate-limit `POST /password-reset/request` — count requests per email and return 429
  once the limit is exceeded.
- Store the counter in the existing Redis via `redisClient`.

**Non-goals** (explicitly out)
- Rate-limiting any **other** auth endpoint (login, verify, MFA) — separate ticket.
- An admin override / allowlist.
- A global per-IP limit — this ticket is per-email only.

## Acceptance criteria

- [ ] **AC-1** — At most 5 resets per email per rolling hour; the 6th returns 429.
- [ ] **AC-2** — Enforced per email, **case-insensitively**, not per IP.
- [ ] **AC-3** — A throttled response must not reveal whether the account exists.
- [ ] **AC-4** — Users under the limit keep the existing flow unchanged.

## Decided vs assumed

**Decided** (the user chose)
- Limit is **5 per hour**.
- A **fixed 1-hour window** is acceptable — a true sliding window is not required.
- Reuse the existing `redisClient`; no new dependency.

**Assumed** (inferred, unconfirmed — verify before relying)
- **Emails reach this controller already normalised to lowercase** by the upstream
  validation middleware. AC-2 (case-insensitive limiting) leans entirely on this — if it
  does not hold, the counter key must lowercase the email itself.

## Code / context map

- `src/controllers/password-reset.js` — the request handler to gate.
- `src/lib/rate-limit.js` — hourly-counter helper over Redis; extend here.
- `test/password-reset.test.js` — endpoint tests.

## Proposed approach

Add an hourly counter keyed on the email. On each request, increment the counter; if it
is over the limit, return 429 **before** any account lookup or email send, so that a real
and an unknown account are indistinguishable to the caller (AC-3). Keep the change to the
one endpoint.

## Slice checklist

- [ ] **Slice 1 — gate:** counter + 429 on `/password-reset/request`, enumeration-safe.
- [ ] **Slice 2 — tests:** limit boundary, case-insensitivity, and enumeration parity.

## Risks / unknowns

- **Enumeration (AC-3)** is the sharp edge: if the limit is checked only for real
  accounts, the 429 itself leaks existence. Gate before the lookup.
- The **assume-lowercase** item above — confirm the middleware really lowercases, or the
  per-email limit is trivially bypassed by changing case (AC-2).
