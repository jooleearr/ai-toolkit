---
name: pre-push-review
description: Use when reviewing a change against its ticket and hand-off doc before pushing or opening a PR — checking it satisfies the acceptance criteria and honours the plan's agreed scope, non-goals, and assumptions, not just that the diff reads cleanly. Third skill in the plan → implement → pre-push review pipeline. Produces categorised, severity-ranked findings in Conventional Comments format with a ready-to-push verdict; delegates pure-diff bug-hunting to the code-review skill and scans the diff for Fowler code smells.
---

# Pre-push review

Review a change the way a diligent colleague would *before* it goes up — against the **original problem** and the **hand-off doc**, not just the diff. Catch what you'd be embarrassed to have a reviewer catch: a clean diff that solved the *wrong* problem, drifted past the agreed scope, or quietly broke an assumption the plan was built on.

The distinction that defines this skill is **intent over diff**. Generic linters and the `code-review` skill already cover diff-level correctness and cleanup; this skill reviews against **intent** and layers on top — so don't re-hunt bugs here, delegate that (step 2) and spend your legwork on whether the change is the *right* change.

Third skill in the **plan → implement → pre-push review** pipeline. Its inputs are the same three artefacts the pipeline carries: the **ticket**, the **hand-off doc**, and the **working diff**.

## 1. Gather the three inputs

- **The original problem** — the ticket, brief, or bug report. Its **acceptance criteria** are the contract the change must satisfy.
- **The hand-off doc** — from the [`plan`](../plan/SKILL.md) skill, `.plans/<ticket-id-or-slug>.md` by default (wherever the plan skill wrote it; schema in its [`HANDOFF-TEMPLATE.md`](../plan/HANDOFF-TEMPLATE.md)). It gives you the agreed **scope** and **non-goals**, the **decided vs assumed** split, the **slice checklist**, and any **trade-offs** the implement step recorded in the risks section.
- **The working diff** — the full change under review: committed and uncommitted, measured against the base branch the work will merge into.

If no hand-off doc exists, you can still review against the ticket — but say so, and flag that there was no agreed plan to check scope, non-goals, and assumptions against.

**Completion criterion:** you can state the acceptance criteria, the agreed scope and non-goals, and the recorded assumptions, and you have the full diff in view.

## 2. Delegate the diff-level pass

Run the `code-review` skill (a Claude Code built-in) for correctness and reuse/cleanup on the raw diff. Where the change touches a security-sensitive surface (auth, secrets, input handling, permissions), run `security-review` too. Fold their output into your report as the correctness and security categories — do **not** re-hunt those defects yourself; that is what those skills are for.

**Completion criterion:** `code-review` has run (and `security-review` where the surface warrants it), and their findings are captured for your report.

## 3. Scan the diff for code smells

Walk the diff once against the **code-smell** catalogue in [`CODE-SMELLS.md`](CODE-SMELLS.md) — Fowler's smells, each with the signals that betray it in a diff and the refactoring that removes it. This pass owns **maintainability**: structural signs the design is paying for something, which the correctness-focused `code-review` pass doesn't target.

Two rules keep this pass useful rather than noisy, both spelled out in the catalogue: it is **diff-scoped** (flag only a smell the change *introduces or worsens*, never a pre-existing one the diff merely touches) and it favours **precision over recall** (stay silent on a borderline signal — a wrong flag spends the author's trust). Every finding names a concrete `file:line`, says which signal fired, and ends on the paired refactoring. Findings here are **advisory** — `issue` or `nitpick`, never a blocker on their own.

**Completion criterion:** the diff has been walked against the catalogue; every smell the change introduces or worsens is recorded with its `file:line`, the signal that fired, and a suggested refactoring, and borderline signals were left unflagged.

## 4. Review against the acceptance criteria

Walk **each** acceptance criterion from the ticket and decide whether the change demonstrably satisfies it — with evidence, not assertion. A criterion the diff cannot be shown to meet is a **blocking** finding: this is the "solved the wrong problem" class, the most expensive miss and the whole reason this skill exists.

Prefer evidence the implement step already produced (a flow it exercised, output it observed). Where none exists, drive the flow yourself or invoke the `verify` / `run` built-in skills — a green test suite is necessary, not sufficient.

**Completion criterion:** every acceptance criterion is marked met or unmet, each backed by concrete evidence.

## 5. Review against scope, non-goals, and assumptions

The hand-off doc agreed the boundaries; check the diff stayed inside them.

- **Scope drift** — anything in the diff not traceable to a slice or the agreed scope is scope creep. A structural change smuggled in under a feature is **blocking**; a harmless stray extra is non-blocking but still noted.
- **Non-goals** — anything the change does that the plan explicitly ruled out is a finding.
- **Assumptions** — for each item recorded as **assumed** (not decided), confirm it actually held in the code. A broken assumption the change silently coded around is **blocking**.

**Completion criterion:** scope, each non-goal, and each recorded assumption are checked, and every violation is recorded as a finding.

## 6. Check batch size and slice integrity

A change well past a handful of files or a few hundred lines, or a **horizontal slice** that doesn't stand up end-to-end, is itself a finding — recommend splitting into smaller **vertical slices**. Small batches are easier to review, safer to revert, and faster to validate against the problem.

**Completion criterion:** the change's size and slice shape are assessed; any oversize or horizontal slice is flagged with a concrete split recommendation.

## 7. Categorise, rank, and format the findings

Turn everything from steps 2–6 into findings. Each finding carries a **category**, a **severity**, and a single **Conventional Comments** line — see [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md) for the category set, the severity scale, and the format with a worked example. Order the list **blocker-first**, so the reader triages the highest-impact items before any nit.

**Completion criterion:** every finding has a category, a severity, and a conventional-comment line, and the list is ordered blocker-first.

## 8. Deliver the verdict

Lead with a one-line **verdict** — *ready to push* or *needs work* — and the count of blocking findings. Then the ranked findings beneath it, blockers first; nothing blocking may sit below a nit.

Default output is a **terminal report**: this runs *before* push, so there is often no PR yet. When a PR already exists and the user asks, post the findings as inline PR comments the way the `code-review` skill does with `--comment`.

**Completion criterion:** a verdict line plus the ranked, categorised, conventional-comment findings have been delivered.
