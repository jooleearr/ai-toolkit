# core

Core reusable skills that apply to any project.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `docs-scaffold` | `/core:docs-scaffold` (or model-invoked) | Scaffold a standardised `docs/` structure with architecture, ADRs, and a runbook. |
| `plan` | `/core:plan` (or model-invoked) | Turn a task (Jira ticket, Slack thread, brief) into a shared understanding, then a hand-off/plan doc decomposed into vertical slices. First skill in the plan → implement → review pipeline. Discloses its doc schema to a sibling `HANDOFF-TEMPLATE.md`. |
| `implement` | `/core:implement` (or model-invoked) | Implement a hand-off doc from the `plan` skill one vertical slice at a time, holding quality (testing, clean code, architecture, observability) as a constraint and proving the original problem solved. Dispatches the review agents below per slice. |
| `writing-great-skills` | `/core:writing-great-skills` (user-invoked) | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. Use it when authoring the toolkit's own skills. Discloses its glossary to a sibling `GLOSSARY.md`. |

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
