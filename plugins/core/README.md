# core

Core reusable skills that apply to any project.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `docs-scaffold` | `/core:docs-scaffold` (or model-invoked) | Scaffold a standardised `docs/` structure with architecture, ADRs, and a runbook. |
| `plan` | `/core:plan` (or model-invoked) | Turn a task (Jira ticket, Slack thread, brief) into a shared understanding, then a hand-off/plan doc decomposed into vertical slices. First skill in the plan → implement → review pipeline. Discloses its doc schema to a sibling `HANDOFF-TEMPLATE.md`. |
| `writing-great-skills` | `/core:writing-great-skills` (user-invoked) | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. Use it when authoring the toolkit's own skills. Discloses its glossary to a sibling `GLOSSARY.md`. |

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
