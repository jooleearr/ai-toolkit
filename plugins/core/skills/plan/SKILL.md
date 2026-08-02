---
name: plan
description: Use when turning a task — a Jira ticket, Slack thread, bug report, or verbal brief — into an agreed problem statement and a hand-off doc for a later implementation pass. First skill in the plan → implement → pre-push-review pipeline. Grills the task to shared understanding before writing any plan, then decomposes the work into small vertical slices.
---

# Plan

Turn a task into a **hand-off doc** the **implement** and **pre-push-review** skills can execute against. A plan is only as good as the **shared understanding** behind it, so **grill** the task until ambiguity is gone *before* proposing any approach.

The order is a guardrail: agreement on *what* and *why* is a hard gate that comes before *how*. Do not draft the approach, the slices, or the doc until the shared understanding is confirmed.

## 1. Ingest the task

Normalise the source into one restated problem, in your own words:

- **Jira** — if a Jira MCP server or `jira` CLI is available, pull the ticket by ID/URL; otherwise ask the user to paste it. Follow linked tickets and docs that bear on scope.
- **Ticket from `spec-to-tickets`** — a tracer-bullet ticket (a `docs/tickets/tickets.md` entry or a GitHub issue) is already scoped, demoable, and readable without the spec; ingest it directly and follow its "Spec reference" back only if you need the wider context.
- **Other sources** — Slack thread, bug report, verbal brief: capture the raw text and any links the user gives.

Restate the problem back to the user in two or three sentences and get a "yes, that's it" before grilling. If you can't restate it, you don't understand it yet.

**Completion criterion:** the user has confirmed your restatement of the problem.

## 2. Grill to shared understanding

Interrogate the task and the user like a senior engineer who refuses to start on a thin ticket. **One decision at a time** — ask a single sharp question, take the answer, then ask the next. Never dump a list of twenty questions.

Cover, until each is settled:

- **Scope boundaries** — what is in, what is explicitly out.
- **Acceptance criteria** — how *we* will both know it's done, concretely.
- **Non-goals** — what this deliberately does not do.
- **Edge cases and failure modes** — the inputs and states the ticket didn't mention.
- **Assumptions and unknowns** — what has to be true, and what neither of you knows yet.

As you go, surface every place the ticket is under-specified or **contradicts the codebase**, and resolve it with the user rather than guessing. Track each resolution as **decided** (the user chose) or **assumed** (you inferred, unconfirmed) — the split matters, because the review skill checks that assumptions held.

**Completion criterion:** scope, acceptance criteria, non-goals, and open assumptions are each written down and confirmed by the user; no known ambiguity remains unresolved. Do not proceed to step 3 until this holds.

## 3. Ground the approach in the code

Now, and not before, work out *how*. Map the change onto the actual codebase — spawn an Explore or Plan agent for the legwork when the surface is large. Identify the components, files, and boundaries the change touches, and confirm the approach respects existing architecture rather than smuggling in a structural change.

**Completion criterion:** a proposed approach exists and names the concrete code it touches.

## 4. Size the work into vertical slices

Start by sizing the task against a single small PR — **a handful of files and no more than a few hundred lines** — before assuming it needs breaking up. The right shape depends on how the task arrives: a **tracer-bullet** ticket from `spec-to-tickets`, or a Jira ticket someone already scoped down, may already *be* one slice. Branch on the size:

- **Already one slice** — the task is a single tracer bullet that fits one small PR. Emit a one-item checklist and move on. A one-slice plan is a correct outcome, not a step you skipped.
- **Bigger than one PR** — decompose. Agents default to large batches — a whole horizontal layer (all the models, then all the services, then all the UI) before anything works end to end. Sequence the opposite way, as thin **vertical slices**, each a tracer bullet delivering a working path through the system, each sized to a small PR and ordered so every slice leaves the mainline **working and mergeable**.
- **Just over the line, not cleanly splittable** — a bit more than one PR, but the pieces can't each land alone (a component that must branch on loading / error / data from the outset). Mark it as **internal slices of one atomic change** — the vocabulary `implement` step 2 reads — and keep it one unit; forcing a split here buys artificial commits and a broken intermediate mainline, not smaller PRs.
- **Too wide to be one ticket** — if it needs well more than one small PR and the boundary was drawn too wide, say so and recommend re-drawing the ticket boundary upstream, rather than absorbing it into a sprawling multi-slice plan.

Where a slice genuinely can't merge partially working, note that it belongs behind a **feature branch**. Each slice on the doc's checklist is a working end-to-end path sized to a small PR.

Some calls sit with the user, not the plan — **raise them as suggestions and let the user's constraints decide**. Where a slice would land more safely behind a **feature flag**, or the ticket boundary looks too wide (above), surface it upstream the same way rather than baking it into the plan; the current WIP, the state of releases, and the size of the request are the user's to weigh, and a suggestion shouldn't override constraints they already work under.

**Completion criterion:** the work is sized — a one-slice checklist, an ordered multi-slice sequence, a single atomic change marked as internal slices, or a recommendation to re-draw a too-wide boundary — with each slice sized to a small PR and leaving the mainline mergeable (or flagged as needing a feature branch).

## 5. Write the hand-off doc

Write the doc to `docs/plans/<ticket-id-or-slug>.md` (create `docs/plans/` if absent; commit it — it is a shared artefact for the human reviewer and the downstream skills). If you need to create the `docs/plans/` directory and a `docs/` directory does not already exist, check with the user that it's OK to create that parent directory before doing so. Populate every section of [`HANDOFF-TEMPLATE.md`](HANDOFF-TEMPLATE.md) from what the grilling and slicing produced — do not open the template before this step.

**Completion criterion:** the file exists at `docs/plans/…`, every template section is filled (no placeholders), and the decided/assumed split from step 2 is recorded verbatim.
