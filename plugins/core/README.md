# core

Core reusable skills that apply to any project.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `docs-scaffold` | `/core:docs-scaffold` (or model-invoked) | Scaffold a standardised `docs/` structure with architecture, ADRs, and a runbook. |
| `spec-to-tickets` | `/core:spec-to-tickets` (or model-invoked) | Break a single spec file into individually implementable tracer-bullet tickets — vertical, demoable, one context window each, with explicit blocking edges — each ready to hand straight to `plan`. Zeroth step in the spec → tickets → plan → implement → pre-push-review pipeline. Discloses its ticket schema to a sibling `TICKET-TEMPLATE.md`. |
| `plan` | `/core:plan` (or model-invoked) | Turn a task (Jira ticket, Slack thread, brief) into a shared understanding, then a hand-off/plan doc decomposed into vertical slices. First skill in the plan → implement → review pipeline. Discloses its doc schema to a sibling `HANDOFF-TEMPLATE.md`. |
| `implement` | `/core:implement` (or model-invoked) | Implement a hand-off doc from the `plan` skill one vertical slice at a time, holding quality (testing, clean code, architecture, observability) as a constraint and proving the original problem solved. Dispatches the review agents below per slice. |
| `pre-push-review` | `/core:pre-push-review` (or model-invoked) | Review a change against its ticket and hand-off doc before pushing — checking it meets the acceptance criteria and honours the plan's scope, non-goals, and assumptions, not just that the diff is clean. Third skill in the plan → implement → pre-push review pipeline. Produces categorised, severity-ranked findings in Conventional Comments format with a ready-to-push verdict; delegates bug-hunting to `code-review` and scans the diff for Fowler code smells. Discloses its rubric and smell catalogue to sibling `REVIEW-RUBRIC.md` / `CODE-SMELLS.md`. |
| `pr-review` | `/core:pr-review` (or model-invoked) | Review an open GitHub PR — usually a teammate's — against its Jira ticket and leave feedback that reads like a colleague, not a linter. Outward-facing sibling of `pre-push-review`: reviews someone else's change after it's up, with no hand-off doc. Runs business-context, architecture, security, over-engineering, dependency, semantic-drift, testing, observability, and accessibility passes; delegates bug-hunting to `code-review` and reuses `pre-push-review`'s `CODE-SMELLS.md` / `REVIEW-RUBRIC.md`. Always asks before posting; defaults to a pending draft review. Discloses the pending-review API calls to a sibling `REFERENCE.md`. |
| `concept-explainer` | `/core:concept-explainer` (or model-invoked) | Build a durable mental model in an unfamiliar area — plain terms, an analogy, an end-to-end flow, and a rendered diagram, grounded in your codebase. Companion to the plan → implement → review pipeline. Discloses diagram guidance to a sibling `DIAGRAMS.md`. |
| `ai-ready-repo` | `/core:ai-ready-repo` (or model-invoked) | Make any repo AI-ready — greenfield scaffold or retrofit of the `AGENTS.md` index, `.claude/` rules and settings, a durability-organised `docs/` knowledge base, and a `scripts/` directory. Discloses rationale to a sibling `PATTERNS.md` and copyable starters to `TEMPLATES.md`. |
| `writing-great-skills` | `/core:writing-great-skills` (user-invoked) | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. Use it when authoring the toolkit's own skills. Discloses its glossary to a sibling `GLOSSARY.md`. |
| `silverstripe-worktree-lanes` | `/core:silverstripe-worktree-lanes` (or model-invoked) | Set up and manage long-running git worktree "lanes" for parallel agents on a Silverstripe + DDEV project — create, reset onto a new base, or retire a lane, each with its own isolated DDEV project and per-lane database. Ships `create`/`reset`/`retire` scripts and discloses rationale to `REFERENCE.md`. |

## Agents

Dispatched (not invoked directly) — the `implement` skill spawns these per slice for an independent, fresh-context review pass. Each is read-only and reports findings for the implementing agent to reconcile.

| Agent | Reviews |
| :---- | :------ |
| `architecture-reviewer` | Boundary/layer fit against the plan; structural change smuggled in under a feature. |
| `test-reviewer` | Behaviour coverage of the acceptance criteria; tests that assert behaviour, not implementation. |
| `observability-reviewer` | Whether the slice is diagnosable in production (logging, metrics, tracing) without leaking secrets. |

### Attribution

`writing-great-skills` (and its `GLOSSARY.md`) is copied from Matt Pocock's skills
collection: <https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills>.
Kept verbatim; credit and thanks to the author.

## Adding a skill to this plugin

1. Create `skills/<skill-name>/SKILL.md`.
2. Add YAML frontmatter with a `name` and a `description` (the `description` is what the
   model matches on to decide when to auto-invoke — make it specific).
3. Write the instructions as the body.
4. Run `/reload-plugins` in a session that has this plugin loaded to pick it up.
5. Add a row to the table above.

See the repo root [README](../../README.md) for how this plugin is distributed.
