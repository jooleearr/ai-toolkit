# Diff-level review

The correctness and reuse/cleanup pass, **owned by `pre-push-review` itself** — not delegated to the built-in `code-review` skill. Consulted from step 3 of [`SKILL.md`](SKILL.md).

The pass hunts the defects a diff can hide — logic bugs, wrong results, unhandled edge cases, a dropped case in a duplicated branch, a leaked resource — and the reuse/cleanup wins beside them: a helper that already exists, a simpler construct, dead code the change strands. It feeds the `correctness` and `readability` categories of [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md). The Fowler code-smell scan (step 4) owns maintainability, and `security-review` still owns `security` — this pass does neither.

Owning it ourselves is a cost decision. The built-in `code-review` fans out a fleet of finder and verifier subagents whose spend we don't control — one measured run burned ~406k subagent tokens, 71% of the whole review, running `high` against a 489-line diff a cheaper pass would have read just as well. The rule that replaces that swarm is **proportional**: spend tokens in proportion to the change's blast radius, never its line count. Every rule below serves it.

## How this reconciles with the review weight

`pre-push-review` already sizes each review to a **weight** — light or full (step 2). The weight governs the skill's overall **shape**: a light review folds the code-smell scan into this pass and skips the batch-size step; a full review keeps them separate. That structural choice is unchanged.

The **risk tier** below governs one thing only — how wide and deep *this* diff-level pass goes. It replaces the old size-driven effort knob (run `code-review` at `low`/`medium` for light, `high` for full) with the change's blast radius. The two are not a second sizing model bolted on: the security/architecture surface check that step 2 already runs before settling on a weight is the same signal that lands a change in the **high** tier here. In practice a light-weight review sits at the **low** or **elevated** tier; a full-weight review is anything larger *or* a **high**-tier surface. The intent passes (steps 5–6) always run in full regardless of weight or tier — only this diff-level work scales.

## The payload — compute the diff once

Compute the diff **once** in the parent and treat it as the payload every later step reads from. Never have a subagent re-derive it or read whole files to reconstruct what the diff already states.

- Take the full change under review — committed and uncommitted — against the base branch the work will merge into, plus `git log --oneline` for the commit context. This is the same diff step 1 already gathered.
- **Validate before you spend.** Confirm the ref resolves and the diff is **non-empty** before any fan-out. An empty or unresolvable diff is a fast, cheap stop: say so and skip the pass rather than fanning out over nothing.

## Default to a single diff-only pass

Default to **one pass over the diff alone**, read inline in the current context. Reach into surrounding code only where a specific finding needs local context — the caller of a changed function, the helper you suspect already exists, the type a value flows into. A small-to-medium diff reads in a single pass; a fan-out over it buys nothing but tokens.

**Skip what tooling already enforces** — lint, formatting, type-checking. `implement` already made the project's linters, formatters, and type checks pass before handing the change over; a finding one of them would catch on the next commit spends the author's trust for nothing.

## Escalate by risk tier, not line count

Widen the pass by the change's **risk tier** — its blast radius — not its size. A config tweak earns a linter and a glance; a payments or auth path earns the full pass at ten lines. Size is a weak proxy: a 400-line generated-fixture diff is low-risk, a 15-line change to token validation is not.

| Risk tier | Surface | Pass |
| :-------- | :------ | :--- |
| **low** | config, docs, tests, mechanical or moved code, generated output | single diff-only pass; skip what tooling enforces |
| **elevated** | ordinary product logic, a new dependency, a data-model change | single diff-only pass; read local context where a finding turns on it |
| **high** | auth, secrets, input handling, permissions, deserialisation, money, migrations, concurrency | fan out (below), and **scrutinise test changes hardest** — a test edited to match new behaviour can be the bug, not the fix |

Honour an explicit effort the user asks for over the tier.

## When you fan out, keep it bounded

Fan out only at the **high** tier, and cap it at **2 orthogonal dimensions** — one read-only reviewer per axis so they don't pollute each other's context, never a per-concern swarm:

- **correctness / bugs** — logic errors, wrong results, unhandled edges, dropped cases, leaks.
- **reuse / cleanup** — a helper that already exists, a simpler construct, dead code the change strands.

Two rules keep the fan-out cheap and precise:

- **Self-contained prompts.** Paste the diff payload — and any local context the axis needs — straight into each reviewer's prompt, so it makes no extra file-reading round-trips, and hold it to a hard budget (**under ~400 words** each).
- **Documented standards win.** A repo standard the codebase already states overrides the generic baseline; say so in the prompt, so a reviewer doesn't flag house style as a defect.

## Output

No separate output shape. Findings fold into the same report as every other pass — the `correctness` and `readability` categories — severity-ranked, in Conventional Comments format, per [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md).

## The pass in one line

Compute the diff once and validate it; default to a single diff-only pass at the change's risk tier; skip what tooling enforces; fan out to at most 2 self-contained reviewers only on a high-risk surface; fold the findings in as `correctness` and `readability`.
