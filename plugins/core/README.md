# core

Core reusable skills that apply to any project.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `docs-scaffold` | `/core:docs-scaffold` (or model-invoked) | Scaffold a standardised `docs/` structure with architecture, ADRs, and a runbook. |
| `writing-great-skills` | `/core:writing-great-skills` (user-invoked) | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. Use it when authoring the toolkit's own skills. Discloses its glossary to a sibling `GLOSSARY.md`. |
| `silverstripe-worktree-lanes` | `/core:silverstripe-worktree-lanes` (or model-invoked) | Set up and manage long-running git worktree "lanes" for parallel agents on a Silverstripe + DDEV project — create, reset onto a new base, or retire a lane, each with its own isolated DDEV project and per-lane database. Ships `create`/`reset`/`retire` scripts and discloses rationale to `REFERENCE.md`. |

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
