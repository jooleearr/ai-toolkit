# RESET-142 — Rate-limit the password-reset request endpoint

**Source:** pasted brief · **Status:** in review

## Problem statement

Attackers are hammering `POST /password-reset/request` to spam our users with reset
emails and to probe which addresses have accounts. We need to cap how often a reset can
be requested for a given email, without opening a new account-enumeration hole in the
process.

## Acceptance criteria

- [ ] **AC-1** — A given email may request at most **5** password resets per rolling
  hour; the 6th within the window returns HTTP **429**.
- [ ] **AC-2** — The limit is enforced **per email, case-insensitively**
  (`Alice@x.com` and `alice@x.com` share one counter), not per IP.
- [ ] **AC-3** — A rate-limited response must **not reveal whether the email belongs to
  a real account** — a throttled request and an allowed request that finds no account
  look the same to the caller. Enumeration must stay closed.
- [ ] **AC-4** — Users under the limit keep the existing successful reset flow unchanged.
