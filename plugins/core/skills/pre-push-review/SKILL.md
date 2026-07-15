---
name: pre-push-review
description: Use when reviewing a change against its ticket and hand-off doc before pushing or opening a PR — checking it satisfies the acceptance criteria and honours the plan's agreed scope, non-goals, and assumptions, not just that the diff reads cleanly. Third skill in the plan → implement → pre-push-review pipeline. Sizes the review to the change — a small, low-risk diff gets a light pass, a large or security-sensitive one the full treatment — and produces categorised, severity-ranked findings in Conventional Comments format with a ready-to-push verdict; owns a proportional diff-level correctness/reuse pass and scans the diff for Fowler code smells.
---

# Pre-push review

Review a change the way a diligent colleague would *before* it goes up — against the **original problem** and the **hand-off doc**, not just the diff. Catch what you'd be embarrassed to have a reviewer catch: a clean diff that solved the *wrong* problem, drifted past the agreed scope, or quietly broke an assumption the plan was built on.

The distinction that defines this skill is **intent over diff**. Generic linters cover mechanical correctness and this skill's own diff-level pass (step 3) covers logic and reuse; layered on top, this skill reviews against **intent** — so don't re-hunt bugs elsewhere, run that pass once (step 3) and spend your legwork on whether the change is the *right* change.

Third skill in the **plan → implement → pre-push-review** pipeline. Its inputs are the same three artefacts the pipeline carries: the **ticket**, the **hand-off doc**, and the **working diff**.

**Where `implement` ends and this skill begins.** [`implement`](../implement/SKILL.md) builds the change one slice at a time and makes the project's **tests, type checks, and linters** pass — and stops there; it runs **no review**. This skill owns the review in full: its own diff-level correctness and reuse pass plus `security-review` where the surface warrants it (step 3), the Fowler code-smell scan (step 4), and the authoritative verdict against the acceptance criteria, scope, non-goals, and assumptions (steps 5–6). The concerns don't overlap and nothing is reviewed twice — because `implement` reviews nothing, every pass here is the first of its kind over the change.

This skill expects to run with a **fresh/cleared context** — ideally a new session, handed off from `implement` — reading its state from the three shared artefacts below rather than the implementation conversation. That keeps the review independent: unprimed by the mental model of whoever wrote the code.

## 1. Gather the three inputs

- **The original problem** — the ticket, brief, or bug report. Its **acceptance criteria** are the contract the change must satisfy.
- **The hand-off doc** — from the [`plan`](../plan/SKILL.md) skill, `docs/plans/<ticket-id-or-slug>.md` by default (wherever the plan skill wrote it; schema in its [`HANDOFF-TEMPLATE.md`](../plan/HANDOFF-TEMPLATE.md)). It gives you the agreed **scope** and **non-goals**, the **decided vs assumed** split, the **slice checklist**, and any **trade-offs** the implement step recorded in the risks section.
- **The working diff** — the full change under review: committed and uncommitted, measured against the base branch the work will merge into.

If no hand-off doc exists, you can still review against the ticket — but say so, and flag that there was no agreed plan to check scope, non-goals, and assumptions against.

**Completion criterion:** you can state the acceptance criteria, the agreed scope and non-goals, and the recorded assumptions, and you have the full diff in view.

## 2. Set the review weight

Size the change and pick how heavily to review it — the **weight** — so the effort stays **proportional** to what is at stake. Two weights:

- **light** — a small, low-risk diff: on the order of a handful of files and a few hundred lines, no security-sensitive surface, and mostly tests, config, or mechanical / moved code.
- **full** — larger than that, or touching a **security-sensitive** surface (auth, secrets, input handling, permissions) or an **architecturally significant** one. When the call is genuinely borderline, go **full** — under-reviewing a risky change is the more expensive miss.

The weight governs the review's overall **shape**: on a light review the code-smell scan folds into the correctness pass (steps 3–4) and the batch-size pass (step 7) is already settled by the sizing you just did, so it is skipped; a full review keeps both as their own passes. The weight never scales the **intent** passes — the acceptance-criteria walk (step 5) and the scope / non-goals / assumptions walk (step 6) run in full at either weight, because "solved the wrong problem" is the class this skill exists to catch and it is no cheaper to miss on a small diff.

The weight and the diff-level pass's **risk tier** (from [`DIFF-REVIEW.md`](DIFF-REVIEW.md), step 3) are one sizing decision, not two: the security/architecture surface check you run here before settling on light is the same signal that lands a change in the **high** risk tier there. A light-weight review sits at the **low** or **elevated** tier; a full-weight review is anything larger *or* a **high**-tier surface. Set the weight here; the correctness pass then reads its depth off the risk tier rather than off line count.

**Completion criterion:** the change is sized and the weight — light or full — is set, with the security and architecture surfaces checked before settling on light.

## 3. Run the correctness pass

Own the diff-level pass — correctness (logic bugs, wrong results, unhandled edges) and reuse/cleanup (a helper that already exists, a simpler construct, dead code the change strands) — with the token-efficient workflow in [`DIFF-REVIEW.md`](DIFF-REVIEW.md). Compute the diff once and validate it, default to a single diff-only pass read inline, skip what tooling already enforces, escalate by **risk tier** rather than line count, and fan out to a bounded 2 dimensions only on a high-risk surface. Fold its findings into your report as the `correctness` and `readability` categories. Reuse it; don't restate it.

Where the change touches a security-sensitive surface (auth, secrets, input handling, permissions), run `security-review` (a Claude Code built-in) too, and fold its output in as the `security` category — do **not** re-hunt security defects yourself. That delegation stays; this skill owns only the correctness/reuse pass.

**Run this pass inline, in the current context — never hand it to a backgrounded fork.** A subagent that kicks the pass off as its own background workflow reports back with waiting-stubs instead of findings, so you pay tokens and wall-clock for a dead end and end up re-running it inline anyway. Keep it synchronous so the findings land in your hands here. The **weight** decides one thing here: on a **light** review, **fold the code-smell scan (step 4) into this same walk** rather than running it separately, and skip step 4; a **full** review keeps the smell scan as its own pass. The correctness pass's own depth comes from the risk tier in [`DIFF-REVIEW.md`](DIFF-REVIEW.md), not the weight.

This is the pipeline's **single** correctness/reuse pass, run once over the whole change — and, because [`implement`](../implement/SKILL.md) runs no review of its own, the **first** review the change receives at all. Review the full diff here regardless of how it was built.

**Completion criterion:** the diff-level correctness/reuse pass has run inline at a depth scaled to the change's risk tier per [`DIFF-REVIEW.md`](DIFF-REVIEW.md) (and `security-review` where the surface warrants it), its findings captured for your report; on a light review the code-smell scan was folded in here and step 4 is skipped.

## 4. Scan the diff for code smells

**Full reviews reach this step as its own pass; a light review folded it into step 3 and skips here.**

Walk the diff once against the **code-smell** catalogue in [`CODE-SMELLS.md`](CODE-SMELLS.md) — Fowler's smells, each with the signals that betray it in a diff and the refactoring that removes it. This pass owns **maintainability**: structural signs the design is paying for something, which the correctness-focused diff-level pass (step 3) doesn't target.

Two rules keep this pass useful rather than noisy, both spelled out in the catalogue: it is **diff-scoped** (flag only a smell the change *introduces or worsens*, never a pre-existing one the diff merely touches) and it favours **precision over recall** (stay silent on a borderline signal — a wrong flag spends the author's trust). Every finding names a concrete `file:line`, says which signal fired, and ends on the paired refactoring. Findings here are **advisory** — `issue` or `nitpick`, never a blocker on their own.

**Completion criterion:** the diff has been walked against the catalogue; every smell the change introduces or worsens is recorded with its `file:line`, the signal that fired, and a suggested refactoring, and borderline signals were left unflagged.

## 5. Review against the acceptance criteria

Walk **each** acceptance criterion from the ticket and decide whether the change demonstrably satisfies it — with evidence, not assertion. A criterion the diff cannot be shown to meet is a **blocking** finding: this is the "solved the wrong problem" class, the most expensive miss and the whole reason this skill exists.

This acceptance-criteria verdict is **this skill's to own**: [`implement`](../implement/SKILL.md) builds to the criteria and makes the tests, types, and linters pass, but it does not audit them, so this is the first and authoritative walk of them. You can lean on any flow `implement` exercised while verifying a slice (output it observed), but where that doesn't cover a criterion, drive the flow yourself or invoke the `verify` / `run` built-in skills — a green test suite is necessary, not sufficient.

**Completion criterion:** every acceptance criterion is marked met or unmet, each backed by concrete evidence.

## 6. Review against scope, non-goals, and assumptions

The hand-off doc agreed the boundaries; check the diff stayed inside them.

- **Scope drift** — anything in the diff not traceable to a slice or the agreed scope is scope creep. A structural change smuggled in under a feature is **blocking**; a harmless stray extra is non-blocking but still noted.
- **Non-goals** — anything the change does that the plan explicitly ruled out is a finding.
- **Assumptions** — for each item recorded as **assumed** (not decided), confirm it actually held in the code. A broken assumption the change silently coded around is **blocking**.

**Completion criterion:** scope, each non-goal, and each recorded assumption are checked, and every violation is recorded as a finding.

## 7. Check batch size and slice integrity

**Full reviews only — a light review already sized the change as small in step 2, so the batch-size verdict is settled; skip this step.**

A change well past a handful of files or a few hundred lines, or a **horizontal slice** that doesn't stand up end-to-end, is itself a finding — recommend splitting into smaller **vertical slices**. Small batches are easier to review, safer to revert, and faster to validate against the problem.

**Completion criterion:** the change's size and slice shape are assessed; any oversize or horizontal slice is flagged with a concrete split recommendation.

## 8. Categorise, rank, and format the findings

Turn everything from steps 3–7 into findings. Each finding carries a **category**, a **severity**, and a single **Conventional Comments** line — see [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md) for the category set, the severity scale, and the format with a worked example. Order the list **blocker-first**, so the reader triages the highest-impact items before any nit.

**Completion criterion:** every finding has a category, a severity, and a conventional-comment line, and the list is ordered blocker-first.

## 9. Deliver the verdict

Lead with a one-line **verdict** — *ready to push* or *needs work* — and the count of blocking findings. Then the ranked findings beneath it, blockers first; nothing blocking may sit below a nit.

Default output is a **terminal report**: this runs *before* push, so there is often no PR yet. When a PR already exists and the user asks, post the findings as inline PR comments the way the `code-review` skill does with `--comment`.

**Completion criterion:** a verdict line plus the ranked, categorised, conventional-comment findings have been delivered.
