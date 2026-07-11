# Ticket template

The shared schema for a tracer-bullet ticket. The **spec-to-tickets** skill writes it; the
**plan** skill ingests one ticket at a time, so keep the headings stable and keep each ticket
readable **without** the spec beside it. A ticket carries *what* and *why* and stops there —
no code map, no chosen approach, no file paths. That is `plan`'s job, per ticket, later.

Emit tickets in dependency order, blockers first. Open a `tickets.md` with the header block
below, then one ticket block per unit of work.

---

## Header block (once, top of `tickets.md`)

```markdown
# Tickets — <project / spec name>

**Spec:** <path or URL to the source spec> · **Ground:** greenfield | brownfield

## Goal

<Two or three sentences: the spec's goal, in the words the user confirmed.>

## Sequencing

<How to read the order: dependency-first, then the spec's value/priority signal. If the spec
is timeboxed, state where a clean early stop lands — which prefix leaves something demoable.>

## Non-goals (carried from the spec, never re-scoped in)

- <…>

## Cross-cutting constraints (ride inside the tickets they constrain, not a ticket of their own)

- <constraint> — carried into: <ticket ids>

## Coverage check

Every spec requirement maps to exactly one ticket, or to a named constraint above.

| Spec requirement | Lands in |
| :--- | :--- |
| <requirement> | <ticket id / "constraint: …"> |
```

---

## Ticket block (repeat per ticket)

```markdown
### <ticket-id> — <one-line title>

**Blocked by:** <ticket ids, or "none — frontier">

**Goal (what & why):** <The user-visible behaviour this delivers and why it matters. One
demoable unit. No approach, no file paths. For a **foundational ticket**, the "what" is the
convention it establishes and documents — a project-structure layout, a testing framework,
tooling — that later tickets extend; its verification is that the convention is documented
and, where relevant, enforced.>

**In scope**
- <…>

**Out of scope for this ticket**
- <what a reader might assume is here but isn't — deferred to which ticket, or a non-goal>

**Constraints carried in**
- <cross-cutting constraints from the header that bind this ticket>

**Demo / verification** (checkable, not vibes)
- [ ] <how you know this ticket is done — the demoable or verifiable behaviour>

**Spec reference:** <section/anchor in the source spec this came from>
```
