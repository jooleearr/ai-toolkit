---
name: ai-ready-repo
description: Use when making a repository AI-ready — bootstrapping a greenfield project or retrofitting an existing repo so agents and humans collaborate from the same context. Triggers on "make this repo AI-ready", "set up agent docs/rules/settings", "onboard this project for Claude Code / Cursor / Codex", "add AGENTS.md and rules".
---

# AI-ready repo

Set up a repository so agents and humans work from the **same context**: a lean top-level
index, path-scoped rules, guarded settings, a durability-organised knowledge base, and
deterministic scripts. The whole setup obeys one rule — **point, don't duplicate**: each
layer names where the substance lives and links on, so every fact has a **single source of
truth** and staleness has one place to happen.

Two branches share these steps:

- **greenfield** — an empty or new project: scaffold the full structure from the templates.
- **retrofit** — an existing project, often older and never set up for agents: **triage**
  what's there and adapt to what the project *actually* uses, rather than clobbering it.
  This is the harder, higher-value branch.

`retrofit` is **idempotent**: safe to re-run, adding only what's missing and never
overwriting an existing file without confirming first.

The copyable starter content for every file below is in [`TEMPLATES.md`](TEMPLATES.md); the
rationale for each pattern (the *why*, and the retrofit judgement calls) is in
[`PATTERNS.md`](PATTERNS.md). Open each only when the step reaches it.

## 1. Detect the branch and the stack

Inventory the repo before writing anything:

- **greenfield vs retrofit** — is this an empty/new project, or an existing codebase? Any
  existing `AGENTS.md`, `CLAUDE.md`, `.claude/`, `docs/`, or `scripts/` means `retrofit`.
- **stack** — package manager, test runner, linter/formatter, language(s), CI, and the
  **protected branch** name (`main`/`master`/`develop`). Detect from lockfiles, config
  files, and CI workflows — do not assume. Populate later steps from what you find; leave
  genuinely unknowable domain content as a clearly-marked `TODO`, never fabricated.

**Completion criterion:** the branch (greenfield/retrofit) is stated, and a written
inventory lists the detected tooling, protected branch, and every pre-existing agent/docs
file that later steps must not clobber.

## 2. Lean agents file + bridge

Establish the tool-agnostic entry point, kept as a lean **index** that points on to
`docs/`, `.claude/rules/`, and the working agreements — it does not restate their content.

- **AGENTS.md** at the root is canonical, read directly by Cursor, Codex, Claude Code, and
  others. `greenfield`: seed from the [`TEMPLATES.md`](TEMPLATES.md) index. `retrofit`: if
  `AGENTS.md` exists, fold it toward the lean-index shape and move any duplicated detail
  down into `docs/`; if only `CLAUDE.md` exists, lift its tool-agnostic content into a new
  `AGENTS.md`.
- **CLAUDE.md** is a thin bridge that imports the canonical file with `@AGENTS.md` (an
  import, **not** a symlink) and holds only Claude-specific additions.

**Completion criterion:** `AGENTS.md` is a lean index that points on without duplicating,
and `CLAUDE.md` imports it via `@AGENTS.md`.

## 3. Path-scoped rules

Add thin trigger files under `.claude/rules/`, each with `paths:` frontmatter globs (e.g.
`**/*.tsx`). A rule points into `docs/` and carries only a short contract summary — the
substance is tool-agnostic and lives in `docs/`, so only the trigger is Claude-specific.
Prefer these over nested per-directory `CLAUDE.md` files. `retrofit`: create rules only for
the stacks the project actually uses (detected in step 1).

**Completion criterion:** every rule matches real paths in this repo, points into a
`docs/` file, and duplicates none of its content.

## 4. Committed settings with personal override

Set up a `.claude/settings.json` of shared defaults, and let individuals override it
privately. Precedence is **deny > ask > allow**; local overrides shared. The tiers:

- **deny** — secret-read guards (`.env`, `.env.*`, `secrets/**`, terraform state),
  exfiltration guards (`curl`, `wget`), and destructive actions (`git push --force`, pushes
  to the protected branch, `rm -rf /`).
- **allow** — safe read-only/verify commands appropriate to the detected stack.
- **ask** — state-changing-but-routine actions (`git commit`, `git push`, `gh pr create`,
  rebase).

Start from the curated default set in [`TEMPLATES.md`](TEMPLATES.md), then adapt the
allow/ask tiers to the detected tooling.

> **The agent must not write `settings.json` itself.** Claude Code's self-modification
> guardrail blocks an agent from writing `permissions.allow/ask/deny` rules into any
> `settings.json` (it reads as the agent widening its own permissions from untrusted
> content). So **emit the adapted file content and ask the user to save and commit it**
> to `.claude/settings.json` — don't attempt the write yourself, and don't treat the
> denial as a failure. The `.gitignore` addition and other non-settings files in this
> step are yours to write as normal.

Add `.claude/settings.local.json` to `.gitignore` while committing the shared `.claude/`
files.

**Completion criterion:** the adapted `.claude/settings.json` content — all three tiers,
protected-branch name filled in — has been handed to the user to save and commit (not
written by the agent); `.gitignore` commits shared `.claude/` files and ignores
`settings.local.json`.

## 5. Durability-organised docs

Build a tool-agnostic `docs/` knowledge base organised by **durability** — separating the
world to *preserve* (durable domain knowledge) from the world being *replaced*
(implementation-coupled docs), so obsolete layers can be retired wholesale. See
[`PATTERNS.md`](PATTERNS.md) for the split. Scaffold:

- `docs/README.md` — index with a "read this when…" table.
- `docs/CONTEXT.md` — the durable domain glossary / shared language.
- `docs/architecture/README.md` — the **current system shape**: a map of the major
  components and where each lives, pointing into the code and `adr/` rather than restating
  them. This is the *what the system is now* an ADR log can't give — an agent landing cold
  reads this instead of replaying every ADR. It is implementation-coupled and the layer most
  prone to drift, so keep it an index (names and links, not copied detail) and top it with a
  visible staleness caution.
- `docs/architecture/adr/` — numbered ADRs with `0000-template.md`, recording *why a
  decision changed* (the README above records *what the system is now*). ADRs are
  **forward-only**: never write retrospective rationale for inherited decisions (a
  reconstructed *why* reads as authoritative but is invented). Record significant inherited
  choices separately as clearly-labelled observations, and use a `Supersedes` field when
  changing documented behaviour.
- `docs/runbook.md` — how to run, deploy, operate, and diagnose: the on-call knowledge
  `scripts/` can't hold. **Defer to `scripts/`** for anything already scripted — point at
  the entry point, never restate the commands — and cover the deploy, operate, and
  first-response steps that aren't a single command.
- `docs/plans/` — per-ticket implementation plans (the hand-off docs the `plan` and
  `implement` skills read).

`retrofit`: **triage** inherited docs — assess, relocate, or delete rather than trust; git
history is the archive. If creating `docs/` requires creating a `docs/` parent that does
not yet exist, confirm with the user first.

**Completion criterion:** `docs/` has the README index, CONTEXT glossary, an architecture
overview, a forward-only ADR directory, a runbook that defers to `scripts/`, and a plans
directory; no inherited doc was trusted without triage, and no rationale was fabricated.

## 6. Capture the conventions

Record the working agreements once, in `docs/`, and point the rules and PR template at
them: Conventional Commits (with tracker key where one is in use), Conventional Comments
for review, rebase-over-merge in feature branches, branch naming, and comment/editor
style. Two carry extra weight — **documented, not adjacent** (match the documented
convention, not the nearest existing file) and **doc-currency discipline** (keeping the
agent context current is part of "done", advisory rather than a blocking gate). See
[`PATTERNS.md`](PATTERNS.md) for the rationale behind each and the full list.

**Completion criterion:** the conventions live in one `docs/` file, including the
documented-not-adjacent precedence and the advisory doc-currency table, and the entry
points point to it rather than restating it.

## 7. Scripts for repeatable tasks

Add a `scripts/` directory of **deterministic entry points** for common workflows (setup,
build, pre-PR verify/lint+test, data import) with a `README.md` table, so there is **one
obvious way** to do each thing for humans and agents alike. Two principles the README
records:

- **scripts behind skills** — skills and commands *trigger* checked-in scripts rather than
  re-derive multi-step logic in prose, giving reproducibility, diff-ability, and a path for
  humans to run the same tooling.
- **sanitise at the boundary** — when a workflow pulls external data that may carry
  PII/secrets, the agent fetches the raw artefact *without reading it* and pipes it through
  a deterministic sanitisation script before any LLM-facing step; redaction rules live in
  the script, not the prompt.

`greenfield`: scaffold stubs for the detected stack. `retrofit`: wrap the commands the
project already uses, and leave documented `TODO` stubs where a workflow has no script yet.

**Completion criterion:** `scripts/` has a README table and at least the setup + pre-PR
verify entry points wired to the detected tooling, with the two principles documented.

## 8. Reconcile and report

Verify the setup holds together and hand back a summary:

- Every rule and PR-template pointer resolves to a real `docs/` file (**point, don't
  duplicate** held).
- `retrofit`: re-running produced no clobbering — only additions.
- Report what was created, what was adapted, what was left as a `TODO` for the user, and
  every conflict surfaced for confirmation.

**Completion criterion:** all pointers resolve, the run was non-destructive, and the
summary lists created/adapted/TODO/conflicts.
