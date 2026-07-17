# Eval results log

Append-only history of automated eval runs for `pre-push-review`, written by the
scheduled "ai-toolkit daily skill-eval regression check" Routine (and safe to append to
by hand after a manual run — same format).

## Format

`history.jsonl` — one compact JSON object per line, oldest first:

```json
{"date": "2026-07-20", "commit": "abc1234", "trials": 5, "scores": {"detection": 1.0, "calibration": 0.83, "restraint": 0.67}, "pass": true, "notes": "P1-P5 all caught every trial; P6 missed once."}
```

- `date` — UTC ISO date the run happened.
- `commit` — the `main` SHA that was evaluated (i.e. the skill's state under test).
- `trials` — number of trials run, per `../README.md`'s trial count.
- `scores` — the sub-scores `../README.md`'s "Scoring" section defines (names vary by
  skill; for `pre-push-review` these are `detection`, `calibration`, `restraint`).
- `pass` — the overall verdict from the same scoring section.
- `notes` — one or two sentences on anything that regressed, was borderline, or is
  otherwise worth a human's attention.

## How it's used

Each run compares its scores against the previous line for the same skill. A regression
(verdict flips to fail, a blocker item that used to be caught every trial gets missed, or
a sub-score crosses the README's own pass bar) opens a GitHub issue titled
`[eval regression] pre-push-review: ...`. A clean run just appends a line — no issue, no
noise.
