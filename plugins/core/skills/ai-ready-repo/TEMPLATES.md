# AI-ready repo — starter templates

Copyable starter content for each generated file. Write each block to the path in its
heading, then fill the `TODO`/`<…>` placeholders from the detected stack (step 1). Adapt
freely — these are a baseline, not a cage. Use New Zealand English in generated prose.

## `AGENTS.md` (root — the lean index)

```md
# AGENTS.md

Canonical guidance for AI agents and humans on this repo. Read directly by Cursor, Codex,
Claude Code, and others. This file is a lean **index** — it points on, it does not
duplicate. Load the minimum here; follow the links for detail.

## What this is

<one or two sentences: what the project is, and its stack>

## Where things live

- `docs/README.md` — the knowledge base and a "read this when…" table.
- `docs/CONTEXT.md` — domain glossary / shared language. Read before non-trivial changes.
- `docs/architecture/adr/` — architecture decisions (forward-only).
- `docs/plans/` — per-ticket implementation plans.
- `docs/working-agreements.md` — conventions (commits, comments, branching, doc-currency).
- `scripts/README.md` — deterministic entry points for common workflows.
- `.claude/rules/` — path-scoped triggers that point into `docs/`.

## Working agreements

See `docs/working-agreements.md`. In short: Conventional Commits; rebase over merge in
feature branches; match the **documented** convention, not the nearest file; keeping docs
current is part of "done".
```

## `CLAUDE.md` (root — the bridge)

```md
Instructions for this repo live in the tool-agnostic `AGENTS.md`. Imported below so
Claude Code picks them up:

@AGENTS.md
```

## `.claude/rules/<stack>.md` (path-scoped rule — one per detected stack)

```md
---
paths:
  - "<glob, e.g. **/*.tsx>"
---

Before editing these files, read `docs/<area>/conventions.md`.

Contract summary: <the one or two rules most often got wrong — the rest lives in the doc>.
```

## `.claude/settings.json` (committed shared defaults)

Fill `<protected-branch>` and swap the `allow` verify commands for the detected stack.

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/*.tfstate)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(git push --force:*)",
      "Bash(git push origin <protected-branch>:*)",
      "Bash(rm -rf /:*)"
    ],
    "ask": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git rebase:*)",
      "Bash(gh pr create:*)"
    ],
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(<test runner, e.g. npm test>:*)",
      "Bash(<linter>:*)",
      "Bash(<formatter --check>:*)"
    ]
  }
}
```

## `.gitignore` additions

```gitignore
# Personal Claude Code overrides — commit the shared config, ignore the personal one
.claude/settings.local.json
```

## `docs/README.md` (knowledge-base index)

```md
# Docs

How this context system works: durable domain knowledge is separated from
implementation-coupled docs, so obsolete layers can be retired wholesale. Agents and humans
read the same files.

## Read this when…

| When you're… | Read |
| :----------- | :--- |
| making any non-trivial change | `CONTEXT.md` (domain glossary) |
| getting the shape of the system | `architecture/README.md` (current components) |
| changing architecture | `architecture/adr/` (past decisions), then add a new ADR |
| running, deploying, or operating it | `runbook.md` |
| picking up a ticket | `plans/<ticket>.md` |
| unsure of a convention | `working-agreements.md` |
```

## `docs/CONTEXT.md` (domain glossary)

```md
# Context

The durable domain language for this project — the shared vocabulary to preserve across any
rewrite. Read before non-trivial changes.

## Glossary

- **<Term>** — <definition>. <!-- TODO: seed with the project's real domain terms -->
```

## `docs/architecture/README.md` (current system shape)

```md
# Architecture

> ⚠️ Implementation-coupled — the layer most prone to drift. Keep it a **map**, not a copy:
> name each part and link to where it lives; don't restate what the code or an ADR already
> says. Mark it `⚠️ STALE` at the top the moment you know it has drifted.

What the system **is now** — the shape an agent needs before touching it. For *why* a
decision was made, see [`adr/`](adr/); for the durable domain language, see
[`../CONTEXT.md`](../CONTEXT.md).

## Components

| Part | Lives in | Responsibility |
| :--- | :------- | :------------- |
| <component> | `<path/>` | <one line — what it owns> | <!-- TODO: seed from the real tree -->

## How a request flows

<two or three sentences, or a small diagram, tracing one representative path end to end>

## Key decisions in force

- <decision> — see [`adr/NNNN-*.md`](adr/). <!-- link, don't restate the rationale -->
```

## `docs/architecture/adr/0000-template.md` (ADR template — forward-only)

```md
# ADR 0000: <title>

- **Status:** proposed | accepted | superseded
- **Date:** <YYYY-MM-DD>
- **Supersedes / Previously:** <link to the ADR this changes, if any>

## Context

<the forces at play — what makes this decision necessary now>

## Decision

<the choice made, in the active voice>

## Consequences

### Positive

<what becomes easier or better as a result of this decision>

### Negative

<what becomes harder — the cost, risk, or capability given up>

### Neutral

<trade-offs accepted that are neither a clear win nor loss>
```

Also seed `docs/architecture/adr/inherited-baseline.md` for a retrofit, as clearly-labelled
**observations** of significant inherited choices — never as invented rationale.

## `docs/runbook.md` (operate and diagnose)

```md
# Runbook

How to run, deploy, operate, and diagnose this project — the on-call knowledge that isn't a
single command. Anything already scripted lives in [`../scripts/`](../scripts/); this file
**points at the script, it does not restate the commands**.

## Run locally

`scripts/setup.sh`, then `<how to start it>`. <!-- point at the script, not a command list -->

## Deploy

<who deploys, from where, how to trigger it, how to roll back>

## Operate

- **Health / where to look:** <dashboards, logs, key metrics>
- **Config & secrets:** <where they live; never paste real values>

## When it breaks

| Symptom | First look | Likely cause / fix |
| :------ | :--------- | :----------------- |
| <symptom> | <log / dashboard> | <first response> | <!-- TODO: seed from real incidents -->
```

## `docs/working-agreements.md` (conventions)

```md
# Working agreements

- **Commits:** Conventional Commits (`feat`, `fix`, `docs`, `chore`), with the tracker key
  where a tracker is in use.
- **Review:** Conventional Comments (conventionalcomments.org).
- **Branches:** rebase over merge commits in feature branches; branch names `<type>/<slug>`.
- **Documented, not adjacent:** match the documented convention, not the nearest file. If
  code contradicts the docs, treat it as legacy debt — flag it or fix the doc, don't extend
  it.
- **Doc-currency (advisory, not blocking):** keeping this context current is part of "done".

## Your change → surface to update

| When you change… | Update… |
| :--------------- | :------ |
| a domain term or rule | `docs/CONTEXT.md` |
| an architectural decision | add an ADR under `docs/architecture/adr/` |
| a workflow's steps | the matching `scripts/` entry (not a pasted copy) |

A doc you know is stale but can't fix now gets a visible `⚠️ STALE` marker at the top.
```

## `scripts/README.md` (deterministic entry points)

```md
# Scripts

One obvious, repeatable way to do each workflow — for humans and agents alike. If a workflow
changes, update the script, not a remembered command sequence.

- **Scripts behind skills:** agent skills/commands trigger these scripts rather than
  re-derive the steps in prose each run.
- **Sanitise at the boundary:** when pulling external data that may carry PII/secrets, fetch
  the raw artefact without reading it and pipe it through a sanitisation script before any
  LLM-facing step.

| Script | Does |
| :----- | :--- |
| `setup.sh` | Install deps and prepare the project to run. |
| `verify.sh` | Pre-PR gate: lint + test. Run before opening a PR. |
```

## `.github/pull_request_template.md` (surfaces doc-currency)

```md
## What & why

<the change and the problem it solves>

## Checklist

- [ ] Tests / `scripts/verify.sh` pass.
- [ ] Docs updated where this change touches a domain term, decision, or workflow
      (advisory — see `docs/working-agreements.md`).
```
