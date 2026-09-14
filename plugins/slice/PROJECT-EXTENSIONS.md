# Project extensions

The `slice` skills are deliberately generic. They know how to cut a ticket into slices,
build one, check it against the plan and raise a PR — but they know nothing about your
ticket tracker, your test commands, your CI, or the three things that always go wrong on
your stack. That knowledge is per-project, changes independently of the skills, and has
no business being baked into a plugin installed from a marketplace.

So each stage looks for a project-supplied file and folds it into its own instructions at
run time. If the file isn't there, the stage runs generically.

## Where the files live

In the project being worked on, **not** in this repo:

```
<project>/.claude/slice/
├── preflight.md    # tooling and environment checks before a run starts
├── plan.md         # how this project wants tickets read and slices cut
├── implement.md    # build commands, gates, conventions the code must meet
├── verify.md       # what proof this project accepts, and how PRs are raised
├── address.md      # where review feedback hides, and how it's replied to
└── retro.md        # where improvement work gets filed
```

Every file is optional and independent. A project that only ever needs to tell the
implement stage how to rebuild its containers ships one file.

## How a stage uses its file

Each stage reads its file as a **first step, before doing anything else**, and treats the
contents as project-specific instruction that sits alongside the skill's own. The rule is:

- **The skill owns the method** — the shape of a slice, the order of the stages, the
  round cap, what counts as evidence, when to stop and escalate.
- **The project file owns the particulars** — the commands, the paths, the names, the
  local hazards.

Where the two genuinely conflict, the project file wins on particulars and the skill wins
on method. A project file saying "run `ddev sake dev/build` after a schema change" is a
particular, and it is obeyed. A project file saying "skip verification when the change is
small" is an attempt to rewrite the method, and the stage says so rather than complying.

A stage that finds no file for it says so once in its opening report and carries on — a
missing extension is a normal state, not a warning.

## What belongs in one

Things that are true of this project and would otherwise have to be re-derived, guessed,
or learned the hard way on every run:

- **Commands** — how tests, type checks, linters and builds are actually invoked here,
  including the ones that need a container, a Node version, or a rebuild first.
- **Gates** — what has to be green before a PR goes up, and how to read each one's output.
- **Conventions** — branch naming, commit format, PR title shape, base branch, whether
  work stacks and with what tool.
- **Tracker coupling** — what a ticket key looks like, where tickets are fetched from,
  and anything the tracker's own automation does when it sees a key.
- **Hazards** — the failure everyone on the team has hit at least once. This is the
  highest-value content in the file and the hardest to get any other way.

## What does not belong in one

- **Anything already in `AGENTS.md`.** That file is the project's canonical agent
  guidance and every stage reads it anyway. Point at it rather than restating it —
  duplicated guidance drifts, and the copy in `.claude/slice/` is the one nobody updates.
- **Secrets, tokens, or anything you'd mind being committed.** These files are versioned
  with the project and read into agent context.
- **The method.** Reordering the stages or relaxing the checks belongs in a change to the
  skill, or in a fork of it — not in a project file the stage is obliged to honour.

## Writing one

Prose, not configuration. The stage reads it the way it reads its own instructions, so
write it the way you'd brief a new developer: say what to do, and say why when the why is
what makes the instruction stick.

Keep each file short. A page is generous; anything much longer is usually `AGENTS.md`
content that has ended up in the wrong place.

### Example — `.claude/slice/implement.md`

```markdown
# Implement — project notes

## Commands

- Tests: `ddev exec vendor/bin/phpunit` — never host-side, the DB isn't reachable.
- Front end: `npm run test` after `nvm use` (Node 22; the default is 18 and will fail
  confusingly on the ESM imports rather than on the version).
- Lint: `npm run lint` host-side. It diverges from the container, and CI runs the
  host-side one.

## Before testing

Changed a model's `$db` / `$has_one` / `$has_many`? Run `ddev sake dev/build flush=all`
first. Skipping it produces test failures that look like logic bugs and aren't.

## Commits

`<type>: <TICKET-KEY> <description>`. No `Co-Authored-By` trailers.
```
