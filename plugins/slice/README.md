# slice

Take one ticket from plan to reviewable PRs, one vertical slice at a time.

A ticket goes in; a planning conversation, then a sequence of small, reviewable PRs comes
out. The work is cut into vertical slices — each one end-to-end, demoable, and carrying
its own proof — and each slice is built, checked against the plan, and raised as its own
PR before the next one starts.

The loop orchestrates; each stage runs as a subagent, so the reviewer never sees the
implementer's reasoning and the orchestrator's context stays small.

## Status

**Scaffolding only.** The plugin is registered and its conventions are settled; the
skills themselves are being written by hand, one PR at a time. Nothing here is invokable
yet.

## Skills

| Skill | Invoke | Purpose |
| :---- | :----- | :------ |
| `loop` | `/slice:loop` | _Planned._ Orchestrates a whole ticket: preflight, plan, then build → verify → PR per slice, stopping at each PR and escalating rather than improvising. |
| `plan` | `/slice:plan` | _Planned._ Grills the ticket to shared understanding, then writes a hand-off doc cut into vertical slices, each with named evidence. |
| `implement` | `/slice:implement` | _Planned._ Builds exactly one slice and its tests, gets the project's gates green, commits. No self-review. |
| `verify` | `/slice:verify` | _Planned._ Checks a built slice against the plan — acceptance criteria, scope, assumptions — cold, then raises the PR if it passes. |
| `address` | `/slice:address` | _Planned._ Handles what comes back on a raised PR: review comments, a failed gate, a red check. Fixes in new commits, never a rewrite. |

## Per-project customisation

The skills are generic on purpose — they know the method, not your stack. Each stage
folds in a project-supplied file from `.claude/slice/` in the project being worked on, so
build commands, gates, branch conventions and local hazards live with the project rather
than in the plugin.

See [PROJECT-EXTENSIONS.md](PROJECT-EXTENSIONS.md) for the contract.

## Adding a skill to this plugin

1. Create `skills/<skill-name>/SKILL.md`.
2. Add YAML frontmatter with a `name` and a `description` (the `description` is what the
   model matches on to decide when to auto-invoke — make it specific).
3. Write the instructions as the body, and name the stage's `.claude/slice/` extension
   file in its first step.
4. Run `/reload-plugins` in a session that has this plugin loaded to pick it up.
5. Replace the skill's _Planned_ row in the table above.

See the repo root [README](../../README.md) for how this plugin is distributed.
