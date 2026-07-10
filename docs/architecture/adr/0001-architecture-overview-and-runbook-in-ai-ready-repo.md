# ADR 0001: ai-ready-repo scaffolds an architecture overview and a runbook

- **Status:** accepted
- **Date:** 2026-07-10
- **Supersedes / Previously:** removes the `docs-scaffold` skill (issue #19); its two
  unique stubs (`architecture.md`, `runbook.md`) are ported into `ai-ready-repo`.

## Context

`docs-scaffold` was a strict subset of `ai-ready-repo` apart from two doc stubs — a
system-architecture overview and a runbook. Removing `docs-scaffold` (issue #19) leaves two
gaps in `ai-ready-repo`'s `docs/` scaffold:

- **Architecture overview** — `ai-ready-repo` scaffolds `docs/architecture/adr/` but nothing
  at `docs/architecture/` itself. ADRs record *why a decision changed*; they never state
  *what the system is now*. An agent landing cold has to replay every ADR to reconstruct the
  current shape.
- **Runbook** — `scripts/` covers *development* workflows (setup, build, verify) but has no
  home for deploy, operate, and diagnose knowledge — the on-call steps that aren't a single
  command.

The overview is implementation-coupled, so it is the layer most prone to going stale —
exactly what the skill's **point, don't duplicate** rule guards against. That tension made
the overview a deliberate decision rather than a straight port.

## Decision

Add both to `ai-ready-repo`'s step-5 scaffold, in `SKILL.md`, `TEMPLATES.md`, and
`PATTERNS.md`, and link them from the `docs/README.md` index table:

- **`docs/architecture/README.md`** — a current-system-shape overview. Chosen over the two
  alternatives:
  - *Fold a "system shape" section into `docs/CONTEXT.md`* — rejected. `CONTEXT.md` is the
    durable layer (the world to *preserve*); an implementation-coupled overview there
    contaminates the durability split the skill is built on.
  - *ADR log plus code is sufficient (wontfix)* — rejected. It leaves the cold-start gap
    above unaddressed.
  The overview sits beside `adr/` in the implementation-coupled `architecture/` area, and is
  held to the skill's own discipline: keep it a map (names and links, not copied detail) with
  a visible staleness caution.
- **`docs/runbook.md`** — operate-and-diagnose knowledge that **defers to `scripts/`** for
  anything already scripted rather than restating commands.

`docs-scaffold`'s step-6 rule ("match the surrounding project's conventions") is **not**
ported — `ai-ready-repo`'s **documented, not adjacent** rule deliberately reverses it.

## Consequences

- One obvious way to scaffold a repo's docs; `docs-scaffold` and its five references are
  removed.
- The `docs/` scaffold now covers *what the system is now* (overview) and *how to operate it*
  (runbook), not only *why decisions changed* (ADRs) and *the durable domain language*
  (CONTEXT).
- The architecture overview is the layer most prone to drift; the skill mitigates with the
  point-don't-duplicate + `⚠️ STALE` discipline, but it still needs upkeep as part of "done".
