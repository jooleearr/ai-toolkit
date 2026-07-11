## What this is

A personal **Claude Code plugin marketplace**: a catalogue of reusable skills, agents,
and shared settings distributed via the plugin system. It is **not** an application —
there is no build, no dependencies, no runtime. Everything is Markdown + JSON config.

## Structure

```
.claude-plugin/marketplace.json   # catalog listing every plugin
plugins/<name>/                    # one plugin per directory
  .claude-plugin/plugin.json       #   manifest (name, description, version)
  skills/<skill>/SKILL.md          #   skills (model-invoked or /<plugin>:<skill>)
  agents/, hooks/, .mcp.json       #   optional components
shared/settings.template.json      # default permissions (installed via install.sh)
install.sh                         # registers marketplace + merges shared settings
```

**Critical rule:** only `plugin.json` goes inside a plugin's `.claude-plugin/` folder.
`skills/`, `agents/`, `hooks/`, `.mcp.json`, `settings.json` all live at the plugin
**root**, never inside `.claude-plugin/`.

## Conventions

- **`AGENTS.md` is canonical** — keep repo guidance for AI agents in `AGENTS.md`, and
  have each tool's own file import it (`CLAUDE.md` contains only `@AGENTS.md`). This keeps
  instructions in one place and portable across AI tooling. Apply this pattern in every
  project.
- **New Zealand English** — "organise", "standardised", "colour".
- **kebab-case** filenames and skill directory names.
- **Skill frontmatter** — every `SKILL.md` needs a `name` and a specific `description`;
  the `description` is what the model matches on to auto-invoke, so make it concrete
  ("Use when ...").
- **Permissions can't ship in a plugin** — a plugin `settings.json` only honours the
  `agent` and `subagentStatusLine` keys. Default permissions belong in
  `shared/settings.template.json` and are applied by `install.sh`.
- **Versioning is automated** — the `Bump plugin versions` workflow
  (`.github/workflows/version-bump.yml`) bumps each changed plugin's `version` on
  merge to `main` (`feat`/breaking → minor, anything else → patch, per changed
  plugin). **Don't edit `version` in a PR** — a manual bump collides across parallel
  branches and CI owns it. Reserve manual edits for deliberate releases (e.g. cutting
  a plugin's `1.0.0`). Without any bump the git commit SHA is used, so every commit
  still counts as an update.

## Common tasks

- **Add a skill** to a plugin: create `plugins/<plugin>/skills/<name>/SKILL.md`, then
  update that plugin's README table.
- **Add a plugin**: scaffold `plugins/<name>/.claude-plugin/plugin.json` + components,
  then add an entry to `.claude-plugin/marketplace.json` and the root README table.
- **Test locally**: `claude --plugin-dir ./plugins/<name>`, then `/reload-plugins`.
- **Validate**: `claude plugin validate .` before committing.

## Git conventions

Conventional commits: `feat`, `fix`, `docs`, `chore`.
Example: `feat(core): add ai-ready-repo skill`.

**Prefer rebase over merge commits.** Keep history linear:

- **Update a branch** by rebasing onto `main`, not merging `main` in — `git pull`
  is configured to rebase (`pull.rebase=true`, `rebase.autoStash=true`).
- **Merge PRs** with squash (default) or rebase — plain merge commits are disabled
  on the GitHub repo, and the source branch is deleted on merge.
- Only reach for a merge commit when deliberately preserving a branch's structure.
