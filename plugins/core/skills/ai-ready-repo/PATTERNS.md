# AI-ready repo — patterns and rationale

The *why* behind [`SKILL.md`](SKILL.md), and the judgement calls `retrofit` needs. Read a
section when its step reaches it.

## Progressive disclosure is the spine

Every layer loads the minimum up front and points to the rest, so detail loads on demand.
`AGENTS.md` is an index, not a manual; rules are triggers, not content; the substance sits
once in `docs/`. **Point, don't duplicate** is this principle applied to authoring: the same
fact never lives in two files, so a change is a one-place edit and there is exactly one
place for a fact to go stale.

## Why AGENTS.md, not nested CLAUDE.md

- **Tool-agnostic entry point.** `AGENTS.md` is read directly by Cursor, Codex, Claude
  Code, and others; a single canonical file serves every tool.
- **Bridge, not symlink.** `CLAUDE.md` imports it with `@AGENTS.md`. A symlink needs
  Developer Mode on Windows and causes cross-platform git friction; the import is portable
  and lets `CLAUDE.md` still hold Claude-only additions.
- **Rules over nested CLAUDE.md.** Path-scoped rules target by extension (`**/*.tsx`), are
  tool-agnostic in substance, and keep content in one place. Nested per-directory
  `CLAUDE.md` files are location-scoped only, can't target by extension, are Claude-specific,
  and scatter content across the tree.

## Settings tiers

Precedence is **deny > ask > allow**; a git-ignored `settings.local.json` lets each person
tighten or loosen for themselves without touching the shared file.

| Tier | Holds | Examples |
| :--- | :---- | :------- |
| **deny** | Things that must never happen | secret reads (`.env`, `.env.*`, `secrets/**`, terraform state); exfiltration (`curl`, `wget`); destructive git (`push --force`, pushes to the protected branch, `rm -rf /`) |
| **ask** | State-changing but routine | `git commit`, `git push`, `gh pr create`, rebase |
| **allow** | Safe read-only / verify | the detected test runner, linter, formatter, build, and status commands |

Ship the curated default as the baseline, then move stack-specific verify commands into
`allow` from what step 1 detected. Don't interrogate the user command-by-command — confirm
the assembled set instead.

## Docs organised by durability

Topic is the obvious axis; **durability** is the useful one. Separate:

- **The world to preserve** — durable domain knowledge that outlives any implementation:
  the glossary/`CONTEXT.md`, domain ADRs, business rules. This is expensive to reconstruct
  and must survive rewrites.
- **The world being replaced** — implementation-coupled docs tied to the current stack or a
  migration in flight. Group these so an obsolete layer can be retired *wholesale* when its
  implementation is gone, instead of hunting stale paragraphs across the tree.

This generalises any migration or refactor, not one framework swap: the split is what lets
you delete a retired layer with confidence.

### Forward-only ADRs

Write ADRs for decisions **going forward**. Do **not** reconstruct rationale for inherited
decisions whose *why* is unknown — an ADR reads as authoritative, so invented rationale is
worse than none. Record significant inherited choices separately as clearly-labelled
**observations** (an `inherited-baseline.md`), never as fabricated ADRs. When a new decision
changes documented behaviour, cite the prior one in a `Supersedes` / `Previously` field.

### Overview vs ADRs — *what it is now* vs *why it changed*

An ADR log records **why** each decision changed; it never states **what the system is now**.
An agent landing cold would have to replay every ADR to reconstruct the current shape — so
`docs/architecture/README.md` holds that shape directly: the major components, where each
lives, and one representative flow. Keep the two honest about their jobs — the overview is
the map, the ADRs are the changelog.

The overview is **implementation-coupled**, so it is the layer most prone to going stale —
exactly what **point, don't duplicate** guards against. Mitigate the same way everywhere
else does: keep it an *index* (name each part and link to the code/ADR, never restate them),
and make staleness visible with a `⚠️ STALE` marker rather than letting it rot silently. An
overview that copies the code is worse than none; an overview that points at it earns its
place.

### The runbook — operational knowledge scripts can't hold

`scripts/` gives deterministic entry points for *development* workflows (setup, build, verify),
but deploy, operate, and diagnose knowledge — rollback steps, where to look when it breaks,
first-response for a symptom — has no home there. `docs/runbook.md` is that home. It obeys
the same discipline: **defer to `scripts/`** for anything already scripted (point at the
entry point, don't restate the commands), and carry only the on-call knowledge that isn't a
single command.

## Conventions to capture

Record once in `docs/` (a working-agreements file), and point rules and the PR template at
it:

- **Conventional Commits**, with the tracker key where a tracker is in use.
- **Conventional Comments** for review feedback.
- **Rebase over merge commits** in feature branches; a branch-naming format; PR title/body
  hygiene.
- Comment style, editor/indent conventions.
- **Documented, not adjacent** — match the *documented* convention, not the nearest
  existing file. In an inherited codebase the closest file may carry a pattern we don't want
  to perpetuate; if code contradicts the docs, it's legacy debt — flag it or fix the doc,
  don't extend it.
- **Doc-currency discipline** — keeping the agent context current is part of "done",
  surfaced across the working agreements, rules, and PR template, but **advisory, not
  blocking** (blocking doc-diff gates are noisy and get disabled). A "your change → surface
  to update" table makes it concrete; a visible `⚠️ STALE` marker on a doc beats silent rot.

## Scripts as deterministic entry points

One obvious, repeatable way to do each workflow — for humans and agents alike — beats a
remembered command sequence that drifts. When a workflow changes, update the script, not a
pasted copy.

- **Scripts behind skills.** Skills and commands trigger checked-in scripts rather than
  re-derive multi-step logic in prose each run — you get reproducibility, diff-ability, code
  review, and a path for a human to run the exact same tooling.
- **Sanitise at the boundary.** When a workflow pulls external data that may contain
  PII/secrets/contractual content, fetch the raw artefact *without reading it* and pipe it
  through a deterministic sanitisation script before any LLM-facing step. Redaction rules
  belong in the script, not the prompt, so they're testable and can't be prompted away.

## Retrofit judgement calls

`retrofit` is where this skill earns its keep. The posture is **triage, don't trust**:

- **Detect, then adapt.** Populate rules, scripts, and settings from what the project
  *actually* uses — detected test runner, linter, package manager, protected-branch name —
  not boilerplate.
- **Triage inherited docs.** Assess, relocate, or delete existing docs; git history is the
  archive. Don't fabricate rationale for decisions whose *why* is unknown.
- **Don't clobber.** Surface conflicts with existing conventions and confirm before
  overwriting anything. Creating a new top-level parent (e.g. `docs/`) that doesn't yet
  exist is itself a change worth confirming.
- **Incremental and idempotent.** Safe to run repeatedly — add only what's missing, so a
  second run is a no-op.

How **stack-aware** to be is a diminishing-returns call: detect the cheap, high-signal
things (package manager, test runner, linter, protected branch) and populate those; leave
genuinely unknowable domain content as clearly-marked `TODO` prompts for the user rather
than guessing.
