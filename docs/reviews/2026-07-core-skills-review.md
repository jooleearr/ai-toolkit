# Core-plugin skills review — July 2026

A review of every skill in `plugins/core/skills/` against the repo's own
[`writing-great-skills`](../../plugins/core/skills/writing-great-skills/SKILL.md)
rubric and its [`GLOSSARY.md`](../../plugins/core/skills/writing-great-skills/GLOSSARY.md).
Addresses issue #56.

Each skill is assessed on the five acceptance-criteria dimensions — trigger-focused
**description**, **progressive disclosure**, **structure/naming consistency**, **bundled
resources referenced correctly**, and **accuracy** (no stale paths/commands) — plus the
rubric's own levers: **leading words**, **duplication**, **no-ops**, **negation**, and
**sprawl**.

Findings are ranked **high → low** impact per skill. Verdict shorthand: **Strong** (ship
as-is), **Solid** (small wins available), **Needs a pass** (one or more high-impact fixes).

## Snapshot

| Skill | Lines | Verdict | Highest-impact finding |
| :---- | ----: | :------ | :--------------------- |
| `ai-ready-repo` | 183 | Solid | Description restates the whole structure already in the body |
| `concept-explainer` | 47 | Needs a pass | Describes itself as both "Fourth skill in the pipeline" *and* "a companion" |
| `hunk-review` | 84 | Strong | — (minor description trim only) |
| `implement` | 94 | Solid | "runs no review — pre-push-review owns it" restated at ~4 sites |
| `plan` | 60 | Strong | Pipeline label reads `plan → implement → review` (odd one out) |
| `pr-review` | 107 | Solid | Longest description; restates the 10-pass table verbatim |
| `pre-push-review` | 80 | Solid | `fixtures/` is bundled but never referenced from `SKILL.md` |
| `silverstripe-worktree-lanes` | 75 | Strong | — |
| `spec-to-tickets` | 98 | Strong | — |
| `writing-great-skills` | 83 | Strong (verbatim) | External copy — review, but do not edit in place (see note) |

Overall the plugin is in good shape: every skill carries checkable **completion criteria**,
NZ English and kebab-case are consistent throughout, and all sibling-file pointers at the
top level resolve. The findings below are refinements, not rebuilds. The single most
valuable cross-cutting fix is **trimming descriptions that restate the body** (below).

---

## Cross-cutting themes

These recur across skills and are worth standardising in one pass.

### 1. Descriptions restate identity the body already carries (highest impact)

`writing-great-skills` is explicit: a description's job is *triggers plus a reach clause* —
"**Cut identity that's already in the body.**" Several descriptions instead re-enumerate the
skill's structure or pass-list, spending permanent **context load** (the description sits in
the window every turn) to repeat what the body states once:

- **`pr-review`** — the description names all ten review passes; step 4's table names them
  again. The description is ~140 words, the longest in the plugin.
- **`ai-ready-repo`** — the description spells out the full artefact list (`AGENTS.md` index,
  `.claude/` rules and settings, `docs/` knowledge base, `scripts/`), which the opening
  paragraph and steps already establish.
- **`implement`** — the parenthetical `(testing, clean code, architecture, observability)`
  duplicates step 3's bullet headings.

**Recommendation:** prune each to its distinct trigger branches plus any "when another skill
needs…" reach clause. Keep the leading word up front; drop the enumerations the body owns.
This is the clearest, lowest-risk win in the review.

### 2. Pipeline naming is inconsistent (single-source-of-truth drift)

The `plan → implement → pre-push-review` pipeline is named four different ways across the
skills that reference it:

| Where | Phrasing |
| :---- | :------- |
| `plan` | `plan → implement → **review**` |
| `implement`, `pre-push-review`, `concept-explainer` | `plan → implement → **pre-push review**` (space) |
| `spec-to-tickets` | `spec → tickets → plan → implement → **pre-push-review**` (hyphen) |

The actual skill directory is `pre-push-review` (hyphen). The label should be spelled the
same way everywhere it appears. **Recommendation:** standardise on `plan → implement →
pre-push-review` (matching the directory name) and fix `plan`'s odd-one-out `→ review`.

The ordinals compound this: `plan` = "First", `implement` = "Second", `pre-push-review` =
"Third", `spec-to-tickets` = "Zeroth", and `concept-explainer` = "Fourth" — see the
`concept-explainer` finding below for why "Fourth" is wrong.

### 3. Bundled resources should each be reachable from their `SKILL.md`

The rubric's acceptance dimension is "bundled resources that are actually used and referenced
correctly." One gap: `pre-push-review/fixtures/` (`smelly-order-service.js`,
`EXPECTED-FINDINGS.md`) is never mentioned in `SKILL.md`. Either wire in a **context pointer**
(if the skill should exercise the fixture) or confirm it is author-time test data that
deliberately stays unreferenced — and if so, a one-line note in the plugin README keeps a
future reviewer from re-flagging it.

---

## Per-skill findings

### `ai-ready-repo` — Solid

1. **Description restates the whole structure (medium).** See cross-cutting theme 1. Trim
   the artefact enumeration; keep the greenfield/retrofit branches and the trigger list.
2. **Length is justified, not sprawl (note).** At 183 lines it is the longest skill, but it
   discloses heavily to `TEMPLATES.md` and `PATTERNS.md` and every step earns its place with
   a distinct completion criterion. No action — recording it so a future pass doesn't cut
   muscle mistaking it for fat.
3. **Step 4's settings.json guardrail is negation-shaped but correctly paired (low).** "The
   agent must not write `settings.json` itself" is a hard guardrail the rubric permits, and
   it *is* paired with the positive action ("emit the adapted file content and ask the user
   to save and commit it"). Leave as-is; noted only so it isn't mistaken for a stray
   prohibition.

### `concept-explainer` — Needs a pass

1. **Self-contradictory pipeline placement (high).** The description says "**Fourth skill in
   the plan → implement → pre-push review pipeline**, a companion used throughout." It cannot
   be both an ordinal pipeline *stage* and a *companion used throughout* — those are different
   claims. The core plugin README already resolves it correctly: "**Companion** to the plan →
   implement → review pipeline." **Recommendation:** drop "Fourth skill in the … pipeline" and
   keep the companion framing, matching the README.
2. **Otherwise a model skill (note).** Tight at 47 lines, clean **scaffold / follow-the-flow /
   plain-voice** leading words, good progressive disclosure to `DIAGRAMS.md`. Only finding #1
   needs action.

### `hunk-review` — Strong

1. **Description could shed one clause (low).** Long but mostly trigger phrasing, which is its
   job for a discoverability front door; the "bare words hunk and herdr" triggers are exactly
   right. The trailing "so both tools work in plain language without recalling their CLIs"
   restates the body's **recall** thesis — a candidate trim.
2. **Runtime-loaded hunk skill is exemplary (note).** Resolving `hunk skill path` fresh each
   run instead of restating hunk's CLI is a clean **single source of truth** — worth citing as
   a pattern other wrapper skills should copy.

### `implement` — Solid

1. **"Runs no review" is restated ~four times (medium).** The boundary "implement runs no
   review; `pre-push-review` owns it" appears in the intro, step 5, step 8, and step 9 as full
   sentences. That is closer to **duplication** (same *meaning* repeated) than a **leading
   word** (same *token* repeated). **Recommendation:** state it authoritatively once (step 9,
   the hand-off), and let the earlier mentions point to it in a clause rather than re-arguing
   it. Keeps the boundary without paying for it four times.
2. **Description parenthetical duplicates step 3 (low).** See cross-cutting theme 1.

### `plan` — Strong

1. **Pipeline label is the odd one out (low).** Its description reads `plan → implement →
   **review**` where every sibling says `pre-push review`. Fold into cross-cutting theme 2.
2. Clean, tight, well-gated otherwise. The "grill … one decision at a time" **leading word**
   carries the whole skill economically.

### `pr-review` — Solid

1. **Longest description, restates the pass table (medium).** See cross-cutting theme 1 — the
   biggest single instance. The step-4 table is the **single source of truth** for the passes;
   the description should trigger, not re-list.
2. **Effort-scaling table is excellent (note).** The changed-lines → effort table with the
   measured-cost rationale is a standout; no change.

### `pre-push-review` — Solid

1. **Unreferenced `fixtures/` (medium).** See cross-cutting theme 3.
2. Strong intent-over-diff framing and clean division of labour with `implement`; no other
   findings.

### `silverstripe-worktree-lanes` — Strong

1. **Correctly project-specific (note).** The one deliberately non-general skill; the **lane**
   leading word and the "one invariant: a database per lane" framing are tight. Scripts are
   referenced and the `REFERENCE.md` disclosure is well-gated ("read it when a lane
   misbehaves, not before"). No action.

### `spec-to-tickets` — Strong

1. **Well-structured (note).** Strong **tracer-bullet / altitude / walking-skeleton** leading
   words, calibrates grilling to spec thickness, coverage check is exhaustive. Only shares the
   pipeline-spelling nit (theme 2). No standalone action.

### `writing-great-skills` — Strong, but treat as external

1. **Verbatim external copy (important constraint).** The plugin README records that this skill
   and its `GLOSSARY.md` are "copied from Matt Pocock's skills collection … **Kept verbatim**;
   credit and thanks to the author." Reviewing it against itself: it is exemplary — it is the
   rubric. But **suggestions should not be applied in place**, because that breaks the
   "kept verbatim" attribution promise. If the team wants a local divergence, fork it under a
   new name and update the attribution rather than editing the verbatim copy. No in-place
   action.

---

## Recommended next steps

Grouped by how safely they can be applied. Nothing here was applied in this PR — per issue
#56's acceptance criterion 4, applying suggestions is gated on the team agreeing which to
take. This report is the input to that decision.

**Apply directly (low-risk, high-value):**

1. Standardise the pipeline label on `plan → implement → pre-push-review` everywhere, and fix
   `plan`'s `→ review` (theme 2).
2. Fix `concept-explainer`'s description: drop "Fourth skill in the … pipeline", keep the
   companion framing (matches the README).
3. Reference `pre-push-review/fixtures/` from its `SKILL.md`, or add a one-line README note
   marking it as author-time test data (theme 3).

**Apply with author judgement (a focused editing pass):**

4. Trim the descriptions that restate the body — `pr-review`, `ai-ready-repo`, `implement`
   (theme 1). Best done by the skill author, since pruning a description is a judgement call
   about which triggers are load-bearing.
5. Collapse `implement`'s four-times-stated "runs no review" boundary to one authoritative
   statement plus pointers.

**Do not apply in place:**

6. `writing-great-skills` — external verbatim copy; fork rather than edit if a local change is
   wanted.

Suggested split: items 1–3 are a single small `fix(core)` PR; items 4–5 are a `docs(core)` /
`refactor(core)` PR (or one issue per skill if the team prefers). If the team would rather
track these as issues than fold them into PRs, each numbered item maps cleanly to one.
