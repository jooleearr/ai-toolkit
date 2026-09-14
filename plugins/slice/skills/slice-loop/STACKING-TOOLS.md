# Stacking tools

What [`slice-loop`](SKILL.md) Step 0 checks before a run, and the environment quirks that bite mid-run.

## The checks

```bash
gh extension list | grep -q 'github/gh-stack'   # the extension
git config rerere.enabled true                  # idempotent; without it `gh stack init` can prompt and hang
git remote get-url origin                       # must be the GitHub repo — `ss` is the SilverStripe deploy remote
```

The `gh-stack` **skill** must be installed too — it carries the command detail `slice-loop` leans on rather than restating.

**A missing extension or skill stops the run.** Say what to install and stop:

- the extension — `gh extension install github/gh-stack`
- the skill — from `github/gh-stack`, path `skills/gh-stack`, tag `v0.1.0`, into `~/.claude/skills/gh-stack/`

If `gh stack --version` disagrees with the tag the skill is pinned to, note it and carry on. At v0.1.0 the flags still move, and a doc describing a different version fails confidently.

## Quirks that bite

**Two remotes, no `remote.pushDefault`.** Pass `--remote origin` to every `gh stack` command that accepts one.

**Never `checkout`, `trunk` or `modify`.** Those resolve a remote with no flag to override it, so they error out non-interactively — which is every run.

**`init --base` sets the TRUNK, and `link` resolves the trunk on its own.** Two different notions of "base", and conflating them is what re-roots a PR under review. A `slice-loop` run's chain starts at the plan branch, so the plan branch is the stack's **bottom rung** with `develop` as trunk — `gh stack init PROJ-NNN-plan PROJ-NNN-<slice-1>`, never `init --base PROJ-NNN-plan`, which would put the plan PR outside the stack. And `link` ignores local tracking entirely (by design — it serves branches managed by jj, Sapling and friends), so it bases the bottom rung on the repository default branch and rewrites any PR base that disagrees: list the plan PR first, or tell it `--base` explicitly. Read `gh stack link --help` before trusting either.

**Every *slice* branch comes from `gh stack init` or `gh stack add`, never `git switch -c`.** A branch created by hand has no local stack tracking, and both `gh stack top` and `gh stack add` need that tracking to exist — so a hand-made slice branch can't be built on until you retroactively `gh stack init` every existing branch in order. Cheap to fix, but a needless extra step.

The plan branch is the exception, and deliberately: Step 1 makes it with `git switch -c` before any stack exists, because a run with no dependent slices never stacks at all. `gh stack init` then takes it as-is — `--help` says existing branches are adopted and missing ones created — so `gh stack init PROJ-NNN-plan PROJ-NNN-1-<slug>` adopts the plan branch as the bottom rung and creates the first slice branch on top of it in one call.

**`gh stack unstack --local` removes local tracking for the WHOLE stack, not just the current branch.** Read `--help` before running any `unstack` variant — the name suggests something scoped to where you're standing, and it isn't. GitHub's copy of the stack is untouched either way (that's what `--local` means), so recovery is just `gh stack init` again with every branch relisted in order.
