# Diff-level review

The correctness and reuse/cleanup pass, **owned by `pr-review` itself** — not delegated to the built-in `code-review` skill. Consulted from step 2 of [`SKILL.md`](SKILL.md).

The pass hunts the defects a diff can hide — logic bugs, wrong results, unhandled edge cases, a dropped case in a duplicated branch, a leaked resource — and the reuse/cleanup wins beside them: a helper that already exists, a simpler construct, dead code the change strands. It feeds the `correctness` and `readability` categories of [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md). The Fowler code-smell scan (step 3) owns maintainability, and `security-review` still owns `security` — this pass does neither.

Owning it ourselves is a cost decision. The built-in `code-review` fans out a fleet of finder and verifier subagents whose spend we don't control — one measured run burned ~406k subagent tokens, 71% of the whole review, running `high` against a 489-line diff a cheaper pass would have read just as well. The rule that replaces that swarm is **proportional**: spend tokens in proportion to the change's blast radius, never its line count. Every rule below serves it.

## The payload — compute the diff once

Compute the diff **once** in the parent and treat it as the payload every later step reads from. Never have a subagent re-derive it or read whole files to reconstruct what the diff already states.

- Take the diff against the branch's merge base plus `git log --oneline` (or the equivalent GitHub MCP calls) for the commit context — the same diff step 1 already pulled.
- **Validate before you spend.** Confirm the ref resolves and the diff is **non-empty** before any fan-out. An empty or unresolvable diff is a fast, cheap stop: say so and skip the pass rather than fanning out over nothing.

## Default to a single diff-only pass

Default to **one pass over the diff alone**, read inline in the current context. Reach into surrounding code only where a specific finding needs local context — the caller of a changed function, the helper you suspect already exists, the type a value flows into. A small-to-medium diff reads in a single pass; a fan-out over it buys nothing but tokens.

**Skip what tooling already enforces** — lint, formatting, type-checking. A finding a linter would catch on the author's next commit spends the author's trust for nothing.

**Don't run the project's build, tests, type-checker, or linter.** CI gates these on every push — reviewing their output is CI's job, not the review's. Running a suite whose findings you've already been told to skip is doubly wasteful: it burns time and tokens (often an extra branch checkout) for no signal the PR's CI isn't already reporting. Read the diff and reason about correctness statically; if a check *has already failed on the PR*, cite that failure rather than reproducing it locally. The one deliberate exception is behaviour that genuinely can't be reasoned about from the diff — a specific repro you must execute to confirm — which is a narrow, named call, not routine pre-flight verification.

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

Compute the diff once and validate it; default to a single diff-only pass at the change's risk tier; skip what tooling enforces and don't run it yourself; fan out to at most 2 self-contained reviewers only on a high-risk surface; fold the findings in as `correctness` and `readability`.
