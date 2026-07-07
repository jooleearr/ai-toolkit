# core

Core reusable skills that apply to any project.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `docs-scaffold` | `/core:docs-scaffold` (or model-invoked) | Scaffold a standardised `docs/` structure with architecture, ADRs, and a runbook. |

## Adding a skill to this plugin

1. Create `skills/<skill-name>/SKILL.md`.
2. Add YAML frontmatter with a `name` and a `description` (the `description` is what the
   model matches on to decide when to auto-invoke — make it specific).
3. Write the instructions as the body.
4. Run `/reload-plugins` in a session that has this plugin loaded to pick it up.
5. Add a row to the table above.

See the repo root [README](../../README.md) for how this plugin is distributed.
