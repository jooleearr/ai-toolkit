---
name: spec-to-tickets
description: Use when turning a single spec file (SPEC.md or similar, at any level of detail) into individually implementable tickets, each ready to hand straight to the plan skill. The zeroth step in the spec → tickets → plan → implement → pre-push-review pipeline. Slices the whole spec into vertical, demoable tracer-bullet tickets with explicit blocking edges, calibrating how hard it grills the spec to how much detail the spec already carries.
---

# Spec to tickets

Turn one **spec file** into a set of **tracer-bullet tickets**, each a coherent unit of user-visible work that a fresh **plan** context can pick up unchanged. This is the missing zeroth step of the pipeline:

```txt
spec → [this skill] → tickets → plan → implement → pre-push-review
```

Stay at the right **altitude**. This skill decides *what* gets built and in *what order* — a ticket is a demoable unit of behaviour. It does **not** decide *how* any one ticket is built: no code map, no chosen approach, no file paths. That is `plan`'s job, per ticket, later. A ticket that carries an approach is this skill doing `plan`'s work a level too low.

## 1. Locate and restate the spec

Take the spec path as an argument. With none, discover `SPEC.md` at the repo root; if several candidates exist or none is obvious, ask rather than guess.

Read the spec **in full**, then restate its goal in two or three sentences and get a "yes, that's it" before slicing anything — the same restate-first gate `plan` opens with. If you cannot restate it, you do not understand it yet.

**Completion criterion:** the user has confirmed your restatement of the spec's goal.

## 2. Targeted gap pass

A spec written earlier — by someone else, or by you months ago — arrives cold, with no prior conversation to synthesise from. Close only the gaps that matter, and calibrate the interrogation to what is actually missing:

> Ask only the questions whose answers **change ticket boundaries or their order**. Everything else is `plan`'s job, per ticket, later.

- **Thin spec** ("build a todo app with tags") — most of the work is drawing boundaries; expect many questions.
- **Thick spec** (explicit parts, non-goals, a priority rubric) — the boundaries are largely implied; mostly slice, and **do not re-litigate decisions the spec already settled**.

Ask **one question at a time** — a single sharp question, take the answer, then the next — per `plan`'s one-decision-at-a-time rule. Skip this step entirely where the spec already answers the boundary questions. Grilling a spec that already answers is the failure mode on this end.

If, after this pass, the spec is still too thin to draw sound boundaries, say so and recommend fleshing the spec out first rather than inventing scope — there is no `to-spec` skill in this toolkit yet.

**Completion criterion:** every open question that would move a ticket boundary or reorder the tickets is resolved, or the spec is declared too thin to slice and the user is routed to expand it.

## 3. Detect greenfield vs brownfield

The first ticket differs by ground:

- **Brownfield** — an existing codebase. Explore it, look for **prefactoring** ("make the change easy, then make the easy change"), and sequence that work first.
- **Greenfield** — an empty or near-empty repo, the common case for the personal projects and prototypes this skill serves. There is nothing to prefactor. The first ticket is a **walking skeleton**: the thinnest end-to-end path proving the stack is wired together (e.g. one record fetched from the real API and rendered). Everything else blocks on it.

Get this wrong on a greenfield repo and you emit a "set up the project" ticket followed by horizontal layers — precisely the failure tracer bullets exist to prevent.

**Completion criterion:** the repo is classified greenfield or brownfield, and the opening ticket is a walking skeleton or a prefactoring ticket accordingly.

## 4. Slice into tracer-bullet tickets

Slice by **demoable user-visible behaviour**, never by the spec's own headings — a spec's structure is usually a poor ticket boundary (a "Part" with five requirements is too big for one ticket; a "loading and error states" line is a property of every ticket, not a ticket of its own). Hold each ticket to the tracer-bullet shape:

- A **tracer bullet** — a thin *vertical* slice cutting through every layer it touches (schema, API, UI, tests), never a *horizontal* slice of one layer.
- **Demoable or verifiable on its own** once complete.
- Sized to fit in **a single fresh context window**.
- Declares its **blocking edges** — the tickets that must finish before it can start. A ticket with no blockers is on the **frontier** and can be picked up immediately.

Then bind the slices to the whole spec:

- **Coverage check** — every requirement in the spec lands in exactly one ticket, *or* is named as a **cross-cutting constraint** carried into several. Nothing silently dropped, nothing duplicated. A constraint (e.g. "writes must feel instant and the UI must never lie about the server") is not a follow-up ticket — it rides along inside the tickets it constrains.
- **Non-goals survive.** Carry the spec's non-goals into the tickets so they are never quietly re-scoped back in.
- **Order by dependency, then by value.** Sequence primarily by the blocking graph, but respect the spec's own priority signal — an evaluation rubric, a "rough priority order" list, a timebox. When a spec is timeboxed, order so that **stopping early still leaves something coherent and demoable**, and front-load whatever the spec says it values.
- **Wide-refactor exception** (brownfield) — a change whose blast radius is too wide for any vertical slice to land green (rename a shared column, retype a shared symbol) is the one case a ticket may span a layer; handle it as an expand–contract migration rather than forcing it vertical.

**Completion criterion:** an ordered set of tickets exists; every spec requirement maps to exactly one ticket or a named cross-cutting constraint; every ticket has its blocking edges; non-goals are carried through; and a timeboxed spec stops cleanly at any point in the sequence.

## 5. Quiz the user, then iterate

Before publishing anything, walk the user through the proposed breakdown and quiz them: is the granularity too coarse or too fine, are the blocking edges right, is anything worth merging or splitting? Iterate until they approve. Publishing an unreviewed breakdown is the failure mode here.

**Completion criterion:** the user has approved the ticket set — granularity, boundaries, and blocking edges.

## 6. Emit the tickets

One artifact, two readings — the tickets are identical, only the blocking edges change form. Ask the user which shape they want. Populate every ticket from [`TICKET-TEMPLATE.md`](TICKET-TEMPLATE.md); do not open the template before this step.

- **Local file** — a `docs/tickets/tickets.md` in dependency order (blockers first), each ticket's "Blocked by" written as text. Worked top to bottom, by hand, staying in the loop. Create `docs/tickets/` if absent; if a `docs/` directory does not already exist, check with the user before creating that parent, per the `plan` convention.
- **GitHub issues** — one issue per ticket, **published blockers first** so each "Blocked by" can reference a real issue number via native sub-issue/blocking relationships. A ticket is then picked up exactly like a Jira ticket and fed straight into `plan` — which is the point: it makes a personal project feel like the day-job board.

Whatever the shape, each ticket must be consumable by a **fresh `plan` context without reading the whole spec**, while still linking back to it. The frontier is parallelisable — several unblocked tickets can be handed to several agents at once (see `silverstripe-worktree-lanes` for isolated lanes) — but that is the operator's call, not this skill's to orchestrate.

**Completion criterion:** the tickets exist in the chosen shape, blockers first, each filled from the template with no placeholders, each linking back to the spec and readable without it.
