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
- **Versioning is automated — don't bump `version` by hand.** A GitHub Action
  (`.github/workflows/version-bump.yml`) owns each plugin's `version`: on every merge to
  `main` it bumps the changed plugin(s) from the merged commit's conventional-commit type
  (`feat` → minor; `fix`/`docs`/`chore`/`refactor`/`perf` etc. → patch; a `!`/breaking
  change → major), then commits the result back with `[skip ci]`. Leave `plugin.json`
  `version` untouched in PRs — editing it on parallel branches is what caused the version
  conflicts this replaces. New plugins ship with a starting `version` (e.g. `0.1.0`); the
  Action takes it from there. (Without any version the git commit SHA is used, and every
  commit counts as an update.)

## Skill evals

Skills can ship an `evals/` directory (fixtures + `evals/README.md` describing how to
run and grade them — see `plugins/core/skills/pre-push-review/evals/` for the pattern).
Any skill with an `evals/README.md` is picked up automatically by the scheduled
"ai-toolkit daily skill-eval regression check" Routine: it re-runs the eval whenever the
skill or its fixtures change on `main`, logs the result to that skill's
`evals/results/history.jsonl`, and opens a `[eval regression] <skill>: ...` issue if a
run scores worse than the last one. Results land via an auto-merged PR, never a direct
push. No per-skill configuration needed — adding `evals/README.md` + a results log is
enough to be covered.

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
