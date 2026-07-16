# Eval — `pre-push-review`

The first eval in this marketplace, and a deliberate experiment: build one good eval for
**`pre-push-review`**, learn from it, then decide whether evalling skills is worth rolling
out more widely. Tracks [#64](https://github.com/jooleearr/ai-toolkit/issues/64).

## What it measures

Whether the skill reviews a raised PR *well* — graded through **"done is better than
perfect"**. A good review does two things, and this eval scores both symmetrically:

1. **Raises the issues that will sting** — a failed acceptance criterion, silent scope
   drift, a broken plan assumption, a real correctness or security bug. Missing one of
   these is a **false negative**, the expensive failure mode.
2. **Shows restraint on low-ROI churn** — a cosmetic nit, a style preference, a
   micro-optimisation, a pre-existing smell it merely touched. Dressing these up as
   blockers is a **false positive / over-firing**, and costs the author's trust.

It grades **detection *and* calibration** — not just *did it find X*, but *did it judge X
correctly and say the right thing about it*. This extends the precision-over-recall check
already in the sibling [`../fixtures/EXPECTED-FINDINGS.md`](../fixtures/EXPECTED-FINDINGS.md)
(the code-smell pass) from one pass to a whole review.

## The fixture: a sample PR

Unlike the code-smell fixture — a bare file — this one is a **full PR**, so the intent
passes (steps 5–6 of the skill) have something to check against, not just a diff:

| File | Role |
| :--- | :--- |
| [`fixtures/sample-pr/TICKET.md`](fixtures/sample-pr/TICKET.md) | The original problem + acceptance criteria (AC-1…AC-4). |
| [`fixtures/sample-pr/HANDOFF.md`](fixtures/sample-pr/HANDOFF.md) | The `plan`-style hand-off doc: scope, non-goals, decided-vs-assumed, slices, risks. |
| [`fixtures/sample-pr/change.diff`](fixtures/sample-pr/change.diff) | The working diff under review. |
| [`fixtures/EXPECTED-FINDINGS.md`](fixtures/EXPECTED-FINDINGS.md) | The answer key: planted issues + decoys, each with expected `file:line`, category, and **severity**. |

The scenario — rate-limiting a password-reset endpoint — is chosen so the review must run
**full weight** (a security-sensitive auth surface) and so intent lives across all three
artefacts. The planted issues span **obvious → subtle**:

- **Obvious:** a flat failed acceptance criterion (limit set to 10, not 5); an obvious
  correctness bug (a 429 gate with no `return`, so it never gates).
- **Medium:** scope creep not traceable to a slice (login throttling — an explicit
  non-goal); a broken *assumed* item (raw-email key when case-insensitivity was only
  assumed to hold upstream).
- **Subtle:** a change that reads clean but solved a slightly-wrong problem (limiting only
  known accounts, which reopens enumeration); a test gap on the two riskiest criteria.
- **Decoys (must not be blocked):** a terse variable name, a pre-existing `==` the diff
  merely touches, a not-worth-it micro-optimisation.

## How to run it

The skill is model-invoked, so the eval is an **agent run against fixed inputs**. One
trial:

1. Start a **fresh** Claude Code session (the skill expects cleared context — the same
   independence a real hand-off gives it).
2. Prompt it with the three artefacts as the change under review, e.g.:

   > Run `pre-push-review` on this change. Ticket: `TICKET.md`. Hand-off doc:
   > `HANDOFF.md`. Working diff: `change.diff`. Treat the diff as the full change against
   > the base branch. Give the verdict and the ranked findings.

   (Point it at the files in `evals/fixtures/sample-pr/`, or paste their contents.)
3. Capture the verbatim output — the verdict line plus the ranked findings.
4. **Grade** it against [`fixtures/EXPECTED-FINDINGS.md`](fixtures/EXPECTED-FINDINGS.md)
   using the scoring in that file: verdict, detection, calibration, restraint → pass/fail
   plus the three sub-scores.

Because review output is free-form prose, grading is an **LLM-judge** step, not a string
match: hand the *expected-findings table* and the *run's output* to a judge (a second,
separate agent, or a human) and ask it to fill in, per planted issue, **detected? at what
severity?** and, per decoy, **over-fired?** Then apply the scoring formula. The expected
table is written to be a machine-checkable answer key — every row has a `file:line`, a
category, and a severity — so the judge grades against fixed targets, not vibes.

**Variance.** The skill is stochastic; a single trial is noise. Run **5 trials** and report
the **median** sub-scores plus the **worst-case on the blockers** — if any P1–P5 blocker is
missed in *any* trial, say so loudly, because an intermittently-missed security blocker is
still a shipped security blocker. Five is enough to see whether a miss is a fluke or a
pattern without burning a full session per number.

## Decisions settled while building (issue's open questions)

- **Harness** — hand-rolled and documented here for the first cut, because it needs zero
  new infrastructure in a Markdown-only repo and is runnable today. The `skill-creator`
  skill advertises an eval runner with variance analysis; wiring this fixture into it (so
  the 5-trial loop and scoring are automated rather than manual) is the natural **next
  step**, captured as a follow-up, not a blocker.
- **Grading** — **LLM-judge against the expected-findings table**, not deterministic
  assertions. Free-form review prose defeats string matching; the fixed `file:line` +
  category + severity per row keeps the judge honest. A thin deterministic pre-check is
  cheap and worth adding later (verdict must be *needs work*; the string `429` and the
  limit `5` must appear) to catch total misfires before spending a judge call.
- **Repeats** — **5 trials**, median for the sub-scores, worst-case for the blockers.

## What we learned

Findings from building this first eval, to inform whether to extend the approach:

- **A skill with graded fixtures evals cheaply.** `pre-push-review` already shipped a
  fixture with an explicit precision check, so extending it to a full PR was a small step —
  the pattern (planted issues + a `file:line`/category/**severity** answer key) is
  reusable, and the severity column is what lets an eval grade *calibration*, not just
  detection. Skills without that scaffolding would pay more to eval.
- **Calibration is the harder, more valuable half.** Detection ("did it find the bug") is
  the easy score; **restraint on decoys** and **right-severity** are where a review earns
  or loses trust, and where "done is better than perfect" lives. An eval that only counts
  hits would miss the failure mode — an over-firing review — that most annoys a real author.
- **The judge is the moving part.** Because grading is LLM-judged, the eval is only as
  stable as the judge; a fixed answer table narrows the judge's discretion, but the eval's
  own variance (judge + skill) is why we report medians and worst-case, not a single number.
- **Recommendation.** The precision/severity-fixture pattern is worth extending to the
  other review-shaped skills (`pr-review`, `hunk-review`) first, where the same answer-key
  shape applies directly. Roll out more broadly only once the `skill-creator` runner
  automates the trial loop — a manual 5-trial run per skill does not scale by hand.
