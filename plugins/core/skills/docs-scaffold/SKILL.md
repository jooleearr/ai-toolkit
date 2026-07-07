---
name: docs-scaffold
description: Scaffold a standardised project documentation structure (docs/ with architecture, decisions, and runbook stubs). Use when starting a new project or when a repo lacks organised docs.
---

# Docs scaffold

Create a consistent `docs/` structure so every project documents the same things in
the same places. Adapt the exact set to the project, but default to this layout:

```
docs/
├── README.md              # Index — what lives where
├── architecture.md        # System overview, key components, data flow
├── decisions/             # Architecture Decision Records (ADRs)
│   └── 0001-record-architecture-decisions.md
├── runbook.md             # How to run, deploy, and operate the project
└── glossary.md            # Domain terms and acronyms
```

## Steps

1. Check whether a `docs/` directory already exists. If it does, report what's there
   and only fill gaps — never overwrite existing content without confirming.
2. Create the directories and stub files above. Each stub should contain a short
   heading and a one-line prompt describing what belongs in it, not placeholder lorem.
3. Seed `decisions/0001-record-architecture-decisions.md` as a real first ADR that
   records the decision to keep ADRs, using the standard ADR format (Status, Context,
   Decision, Consequences).
4. Write `docs/README.md` as an index linking to each file with a one-line summary.
5. Set up the **agent-instructions convention** at the project root: keep guidance for AI
   agents in a tool-agnostic `AGENTS.md`, and make each tool's file import it rather than
   duplicate it. Concretely:
   - If `AGENTS.md` doesn't exist, create it (seed from any existing `CLAUDE.md` content).
   - Ensure `CLAUDE.md` contains only an import line: `@AGENTS.md` (plus a one-line note).
   - Leave existing content intact if `AGENTS.md` is already canonical.
6. Match the surrounding project's conventions (spelling, tone, existing headings).

Keep it lightweight: the goal is a skeleton the user can fill in, not exhaustive
boilerplate.
