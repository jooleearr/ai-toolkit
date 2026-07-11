---
name: implement
description: Use when implementing a hand-off doc or plan from the plan skill — turning an agreed plan into working code, one vertical slice at a time, with quality held as a constraint (testing, clean code, architecture, observability) and the original problem proven solved. Second skill in the plan → implement → pre-push review pipeline. Works in small batches and dispatches fresh-context review agents per slice.
---

# Implement

Turn a **hand-off doc** (from the [`plan`](../plan/SKILL.md) skill) into working code without accruing the tech debt that jeopardises future work. The default failure mode of agentic coding is *make the ticket pass* — shipping a whole solution in one large batch, quality bolted on afterwards if at all. This skill refuses that shape: **quality is a constraint held while coding, not a review at the end**, and work lands as **small vertical slices**, each proven end-to-end before the next begins.

The hand-off doc is your contract. Its **acceptance criteria are the definition of done**; its **slice checklist is the work queue**. You implement against them and, at the end, prove the *original problem* is solved — not merely that the code compiles and tests are green.

## 1. Load the plan

Read the hand-off doc — `docs/plans/<ticket-id-or-slug>.md` by default (see the [`plan`](../plan/SKILL.md) skill's `HANDOFF-TEMPLATE.md` for the schema). If none exists, stop and send the user to the `plan` skill first; do not invent a plan and start coding. If you need to create the `docs/plans/` directory and a `docs/` directory does not already exist, check with the user that it's OK to create that parent directory before doing so.

Take the **acceptance criteria** as the definition of done and the **slice checklist** as the ordered work queue. Note the **decided vs assumed** split — you will verify the assumptions as you go, and flag any that turn out false rather than quietly coding around them.

**Completion criterion:** you can state the acceptance criteria and the ordered list of slices, and confirm each assumption you are about to rely on.

## 2. Take one slice

Pull the **next unchecked slice** from the checklist and read its shape before you branch — the checklist holds two kinds, and the right unit of work is one or the other:

- **Independently mergeable slice** — the default. A **small batch** (a handful of files, a few hundred lines at most) whose end-to-end path leaves the mainline in a **working, mergeable state** on its own. Take exactly one, branch it, and if it grows past that size once you are into it, stop and re-slice — a bloated slice is the signal the plan's decomposition was too coarse.
- **Internal slices of one atomic change** — pieces the hand-off doc marks as a single **tracer-bullet** unit (e.g. "T1 is itself one ticket, split into two *internal* slices"), or that you discover can't each land alone: a component that must branch on loading / error / data from the outset already carries the structure a later "add the error state" slice would only be restating. Take them **together** as one unit on one branch, and say so — forcing a split here buys artificial commits and a broken intermediate mainline, not smaller PRs.

The test is mergeability, not count: split while the pieces each leave the mainline working; land them together the moment a split would produce **non-independently-mergeable** pieces. Where even an atomic unit genuinely can't merge partially working, put it behind a **feature branch** (and ideally a feature flag), as the plan noted.

**Completion criterion:** the next unit of work is on its own branch — either one independently mergeable slice, or a set of internal slices taken together as one atomic change — sized to a small PR (or explicitly flagged as needing a feature branch/flag).

## 3. Build the slice, holding quality in view

Implement the slice's **end-to-end path** — a thin but complete route through the system, not a horizontal layer. Hold every quality concern *while* you write, not after:

- **Testing** — cover the slice's behaviour; test-first where it fits. Tests assert **behaviour, not implementation**, so they survive a refactor.
- **Clean code** — small units, names that match the surrounding idiom, no dead code, no commented-out spikes left behind.
- **Architecture** — respect the existing boundaries and layers. If the slice *implies* a structural change, surface it to the user as a decision — never smuggle a refactor in under a feature.
- **Observability** — add the logging, metrics, or tracing the change warrants, so the slice is diagnosable in production, not just on your machine.
- **No stealth debt** — when you take a shortcut, it is a *conscious, recorded* trade-off (step 6), never a silent one.

**Completion criterion:** the slice's working path is coded, and each concern above is either satisfied or captured as a recorded trade-off — checked one by one, not waved through.

## 4. Verify the slice works

Prove the slice actually works end-to-end before reviewing it. Drive the real flow — invoke the `verify` or `run` skill — and observe the behaviour; a green test suite is necessary, not sufficient. A slice that compiles but was never exercised is not done.

**When the slice's acceptance criteria are browser-UI behaviour** and no automated test covers them, driving the flow means *rendering* it — a fetch that throws and a query that reports `isError` are logic, not the plain-language error and working **Try again** button a criterion actually asks for. Check whether a Playwright MCP server is connected; if it is, offer to use it to drive the UI and observe the real rendered states (load → success, forced-failure → error state → retry click). If no browser driver is available, verify at the logic level instead and **say so explicitly** — name the criterion as verified logic-level only — so the gap between reasoned-about and observed behaviour is visible rather than silent.

> **Note:** `verify`, `run`, `code-review`, and `simplify` are Claude Code built-in skills available in the environment — they are not part of this marketplace and don't need to be written here.

**Completion criterion:** the slice's end-to-end path has been observed working, not merely built — and any browser-UI criterion has either been driven through a browser (via Playwright MCP) or explicitly flagged as verified at the logic level only.

## 5. Review the slice from fresh context

The context that wrote the slice is blind to its own gaps. Get an **independent, structural pass** before the slice is done:

- **Dispatch the review agents in parallel**, in one turn — [`architecture-reviewer`](../../agents/architecture-reviewer.md), [`test-reviewer`](../../agents/test-reviewer.md), and [`observability-reviewer`](../../agents/observability-reviewer.md). Each reviews only its concern, against the hand-off doc's definition of done, from clean context. Give each the diff, the hand-off doc path, and the slice's intent.

This pass is deliberately **slice-scoped and structural** — the three concerns that are cheapest to fix while the slice's context is still fresh. It does **not** run `code-review`/`simplify` or `security-review`: line-level correctness, reuse/cleanup, and security are a **whole-change** concern owned by [`pre-push-review`](../pre-push-review/SKILL.md) (its step 2), run once over the full diff rather than repeated per slice. Leaving them out here is what keeps this pass fast and stops the same lines being reviewed twice across the pipeline.

Reconcile the agents' findings into a single list, dropping near-duplicates. Fix the blocking ones on this slice; fold anything genuinely out of scope into a recorded trade-off (step 6) rather than expanding the slice.

**Completion criterion:** the three structural agents have reported, their findings are reconciled, and every blocking finding is either fixed or consciously deferred with a reason.

## 6. Record trade-offs taken

Whatever shortcut, deferral, or debt you took consciously, write it down where the **pre-push review** skill will see it — a short note in the hand-off doc's risks section (or the PR description). The point is that debt is **visible and owned**, so a reviewer weighs a choice you made on purpose, not one they have to discover.

**Completion criterion:** every trade-off from steps 3–5 is recorded (or you have confirmed there were none).

## 7. Checkpoint: surface the diff, commit on the user's say-so

The commit is a **checkpoint the user owns**, not a step you take on their behalf. Once the slice is built, verified, and reviewed, show the user the change — the diff, or the changed files with a short summary — and **ask before committing**. Default to *not* committing: the slice is left staged for the user to inspect locally, and a commit happens only once they confirm.

The user can **opt into auto-commit for the rest of the session** — a faster loop for those who don't want the prompt. Once they do, commit each subsequent slice as it reaches this checkpoint without re-asking, until they say to stop.

**Completion criterion:** the diff has been surfaced, and the slice is committed only after the user confirmed (or opted into session auto-commit) — never committed by default.

## 8. Tick the slice, then close the loop

Tick the slice on the checklist. **Slices remaining → return to step 2** for the next one; keep the mainline mergeable between them.

When the last slice is done, **prove the original problem is solved**: walk each **acceptance criterion** from the hand-off doc and show the evidence that it holds — the flow exercised, the output observed. This is the loop closing back to the ticket, and it is the real definition of done. "Tests pass" is not evidence a criterion is met; a demonstrated criterion is. **Record this evidence** (in the hand-off doc or the PR description): it is exactly what [`pre-push-review`](../pre-push-review/SKILL.md) step 4 audits, so a criterion you demonstrate here is one it need not re-drive from scratch.

**Completion criterion:** every slice is ticked and every acceptance criterion is demonstrably met with concrete, recorded evidence — not just a green suite. Any criterion you can't demonstrate is an open item, surfaced to the user, not a silent gap.

## 8. Hand off to pre-push review — or stop

This skill's review pass (step 5) was **structural and per-slice**. The **whole-change** passes — `code-review`/`simplify` for correctness and reuse, `security-review` where the surface warrants it, the Fowler code-smell scan, and the authoritative verdict against acceptance criteria, scope, and non-goals — belong to [`pre-push-review`](../pre-push-review/SKILL.md) and have **not** run yet. Implement doesn't silently roll into them.

So, explicitly **offer the hand-off** rather than assuming it:

- **Proceed into `pre-push-review` now**, carrying the same three artefacts (ticket, hand-off doc, working diff) plus the acceptance-criteria evidence from step 7, so the review runs as part of the flow.
- **Or stop here** so the user can review separately, later, or by hand.

Default to **asking**, not auto-proceeding. If the user stops, say plainly that the whole-change correctness/reuse/security pass and the acceptance-criteria verdict are still outstanding — so "implement is done" isn't mistaken for "reviewed and ready to push".

**Completion criterion:** the user has been told review is not yet complete and asked whether to hand off to `pre-push-review` or stop; you act on their choice rather than defaulting into or silently skipping the review.
