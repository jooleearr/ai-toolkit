# Expected findings — the RESET-142 sample PR

The answer key for the eval. It grades a `pre-push-review` run over
[`sample-pr/`](sample-pr/) — the [ticket](sample-pr/TICKET.md), the
[hand-off doc](sample-pr/HANDOFF.md), and the [diff](sample-pr/change.diff) — through the
**"done is better than perfect"** lens: a good review catches the issues that will *sting*
and stays quiet on churn a sensible reviewer would wave through.

Line numbers key into the **post-change** files (the `+` side of the diff), matching the
in-diff numbering.

The change is **security-sensitive** (auth surface), so the correct review **weight is
full** — a run that sizes it *light* has already mis-sized before it starts and should lose
calibration points.

## Part A — genuine issues (must be caught)

Ordered obvious → subtle. **Expected severity** is what a calibrated review should land on;
grade both *detection* (found at all) and *calibration* (right severity — a genuine blocker
under-rated to a nit is a calibration miss, not a pass).

| # | Tier | Where | Category | Expected severity | The issue |
| :- | :--- | :---- | :------- | :---------------- | :-------- |
| **P1** | obvious | `password-reset.js:6` | `scope-fit` | **blocker** | `RESET_LIMIT_PER_HOUR = 10` fails **AC-1**, which sets the limit at **5**. A flat, checkable acceptance-criterion miss. |
| **P2** | obvious | `password-reset.js:15–18` | `correctness` | **blocker** | The 429 branch has **no `return`**: after `res.status(429).json(...)` runs, control falls through to `sendResetEmail(user)` and then the line-21 `res.status(200)` — the reset email is sent to a throttled user *and* the handler double-sends the response (throws in Express). The gate does not gate. (The `n > LIMIT` boundary is also off by one — the limit fires on the 12th, not the 6th — same fix locus.) |
| **P3** | medium | `password-reset.js:13` | `scope-fit` | **blocker** | The counter key `pwreset:${email}` uses the **raw** email. The hand-off recorded "emails arrive lowercased upstream" as **assumed, unconfirmed** — and **AC-2** demands case-insensitive limiting. Nothing in the diff verifies the assumption or lowercases the key, so `Alice@x.com` and `alice@x.com` get separate counters and the per-email cap is bypassed by changing case. A silently-relied-on broken assumption → blocking. |
| **P4** | medium | `password-reset.js:24–32` | `scope-fit` | **blocker** | `throttledLogin` rate-limits the **login** endpoint. The hand-off lists "rate-limiting any other auth endpoint (login…)" as an explicit **non-goal**. A second, untested auth-surface change smuggled in under this ticket — scope creep on a security surface. |
| **P5** | subtle | `password-reset.js:12–19` | `scope-fit` | **blocker** | The entire rate-limit sits **inside `if (user)`**, so only real accounts are ever counted or throttled. A known email starts returning 429 after the limit; an unknown email never does — the 429 now **leaks account existence**, reopening the enumeration hole **AC-3** exists to close (and the hand-off's named risk). Reads clean ("only limit real accounts") but solves a slightly-wrong problem. The fix — gate *before* the lookup — is the approach the hand-off spelled out. |
| **P6** | subtle | `password-reset.test.js` | `tests` | **issue** | The tests cover only the happy path and a limit count. The two riskiest criteria — **AC-2** (case-insensitivity) and **AC-3** (enumeration parity: throttled vs unknown-account responses are indistinguishable) — have **no test**. Coverage gap on exactly the behaviour most likely to regress. Should be fixed; not a blocker on its own. |

## Part B — decoys (must NOT be blocked)

These exercise **restraint** — the "done is better than perfect" back half. A calibrated
review leaves them unsaid or, at most, files a single `nitpick`. Flagging any of them as a
blocker or `issue`, or stacking multiple nitpicks, is **over-firing** and loses points.

| # | Kind | Where | Expected handling | Why |
| :- | :--- | :---- | :---------------- | :-- |
| **D1** | style preference | `password-reset.js:14,27` (`const n = …`) | leave, or one `nitpick` at most | Terse local name. Harmless; renaming is churn a sensible reviewer waves through. |
| **D2** | pre-existing smell the diff merely touches | `rate-limit.js:6` (`return a == b`) | **do not flag** | Loose `==` in `sloppyEqual` is real, but it is **pre-existing and unchanged** — the diff only adds a function below it. The pass is diff-scoped: flagging it violates the rule. |
| **D3** | low-ROI micro-optimisation | `rate-limit.js:11–15` (`incr` then `expire` = two round-trips) | leave, or one `nitpick` at most | Could be pipelined into one Redis round-trip, but the volume is tiny and the code is clearer as-is. Not worth the churn; never a blocker. |

## Scoring

Run the review, then score it against the two tables. Verdict first: the review **must
land on _needs work_** — there are 5 genuine blockers, so a *ready to push* verdict is an
automatic fail regardless of the finding list.

Three sub-scores, each 0–1:

- **Detection** — genuine issues found ÷ 6 (P1–P6). A miss on **any** of the four
  *blocking* `scope-fit`/`correctness` items (P1–P5) is the expensive failure mode this
  skill exists to prevent; weight those misses hardest.
- **Calibration** — of the issues found, the fraction landed at the expected severity, and
  the weight set to *full*. Right finding, wrong severity (e.g. P5 filed as a nitpick) is a
  half-credit calibration miss.
- **Restraint** — 1 minus (over-fired decoys ÷ 3). Any decoy raised as `issue`/`blocker`
  counts as a full over-fire; a lone `nitpick` on D1 or D3 is tolerated (no penalty); D2
  flagged at all is an over-fire.

A run **passes** when: verdict is *needs work*, **all five blockers (P1–P5) are detected
and none under-rated below `issue`**, and **restraint ≥ 0.67** (at most one decoy
over-fired). Detection/calibration on P6 and tidy handling of decoys separate a strong run
from a bare pass. See [`../README.md`](../README.md) for how to run and grade.
