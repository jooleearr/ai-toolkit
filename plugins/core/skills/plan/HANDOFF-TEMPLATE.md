# Hand-off doc template

The shared schema for a plan. The **plan** skill writes it; the **implement** and
**pre-push review** skills consume it, so keep the headings stable. Copy the block
below into `.plans/<ticket-id-or-slug>.md` and fill every section — legible to a human
reviewer first, downstream skills second.

---

# <Ticket ID> — <one-line title>

**Source:** <Jira URL / Slack link / "pasted brief"> · **Status:** planned

## Problem statement

<Two or three sentences, in plain terms: what we're solving and why. The restatement
the user confirmed in step 1.>

## Scope

**In scope**
- <…>

**Non-goals** (explicitly out)
- <…>

## Acceptance criteria

- [ ] <Concrete, checkable condition we agreed marks this done.>

## Decided vs assumed

Everything resolved during grilling, split so review can check the assumptions held.

**Decided** (the user chose)
- <decision>

**Assumed** (inferred, unconfirmed — verify before relying on)
- <assumption>

## Code / context map

Where in the codebase this lives — components, files, and boundaries the change touches.

- `<path>` — <why it's relevant>

## Proposed approach

<How we intend to solve it, respecting the existing architecture. Note any structural
change the ticket implies rather than smuggling it in.>

## Slice checklist

The vertical-slice sequence. Each slice is a small PR (a handful of files, a few hundred
LOC) that leaves the mainline mergeable; flag any that needs a feature branch/flag.

- [ ] **Slice 1 — <name>:** <the working end-to-end path this delivers>
- [ ] **Slice 2 — <name>:** <…>

## Risks / unknowns

- <Risk or open unknown, and how we'll handle it if it bites.>
