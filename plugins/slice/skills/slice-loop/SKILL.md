---
name: slice-loop
description: Use when taking a ticket from plan through to reviewable PRs. Grills the ticket with you and gets the plan signed off, then implements, verifies and raises a PR for each vertical slice. Triggers on "work PROJ-NNN", "pick up PROJ-NNN", "run the loop on <ticket>".
---

# Slice loop

Take the input of a ticket or feature description and orchestrate a multi-phase loop:

1. Plan
2. Implement
3. Verify
4. Address issues / feedback

You are the loop orchestrator. Your job is to run the skill for each phase via a subagent, guarding the context window on the main thread from unecessary, phase-specific details. You are also responsible for relaying communication between the user and the sub-agents as required (e.g. for the grill session).

This skill is made to be generic and allows for project-specific overrides throughout. Where the generic and project-specific instructions (or local agent guidance/conventions docs) differ, the project-specific guidance should be obeyed (unless they are likely to derail the core structure of the slice-loop workflow - in which case flag the issue with the user).

## Step 0 - Preflight

The following checks are required before moving to the plan phase. Additional, project-specific, preflight instructions should be included from ${CLAUDE_PROJECT_DIR}/.claude/skills/slice-loop/preflight.md (if file present).

If any of the following checks fail, flag the issue with the user and ask them to address before running the slice-loop skill again from scratch (after clearing the current session).

### Preflight checks:

1. Resolve the ticket key from the user's message or the current branch (`PROJ-\d+`)
2. Confirm the working tree is clean and `develop` is up to date
3. Run ./STACKING-TOOLS.md checks to ensure required Github stack extension is installed.
4. Run any additional per-project checks in the local preflight.md document mentioned above (if present).

Once all checks have passed:

1. Explain your current understanding of the purpose of the ticket in one or two sentences, in the language a user of the system would use, not the language of the code. Use plain language, the way you'd explain it out loud to a colleague. Use the technical term when it's the clearest word, then say what it means. No jargon soup, no padding.
2. Tell the user that you're about to begin the planning phase, which will include a grilling session with the planner sub-agent relaying questions to resolve any branching paths not captured, any gaps and any amiguities until you reach a shared understanding. The planning subagent will then use what it knows about the ticket and the codebase to generate the planning hand-off doc.

**Completion criterion:** the ticket key is resolved, the tree is clean, the stacking tools check out and any additional, project-specific pre-flight checks have passed. The user has been told what's about to happen - a grill session to ask questions of the user and creation of the planning doc.

## Step 1 - Plan

Dispatch one subagent running [`slice-plan`](../slice-plan/SKILL.md) for the ticket, **named** so you can talk to it. It reads the ticket and the code, then grills the user on everything the ticket left open, then writes a hand-off doc to `docs/plans/PROJ-NNN-<slug>.md`, uncommitted, and returns the path.

### Relay the grill session

The planner has the ticket and the codebase in its context and you deliberately don't, so it drives and **you relay**. It sends you one question at a time with its recommended answer; you put that question to the user verbatim, and send the answer straight back with `SendMessage` to the same agent, which keeps its context intact:

```
SendMessage({to: "<the planner's name>", message: "<the user's answer, verbatim>"})
```

Three things to hold while relaying:

- **One question at a time, unedited.** Don't batch the planner's questions to save turns and don't summarise its reasoning away — the recommendation is what lets the user answer in one word.
- **Don't answer on the user's behalf.** You have less context than either party. "I think they'd want B" is the loop guessing under cover of a grill, which is worse than the honest assumption it replaced.
- **The planner decides when it's done.** It stops when the next question would be manufactured — not when you judge the user has had enough.

**Wait for the answers.** The run does not move past the grill without them. Only the user saying so explicitly — "skip the questions" — ends it early, and then you tell the planner to take its recommendations as accepted and file them as assumptions.

Once the planner says it's done, it will create the hand-off doc.

The doc gets **its own branch and its own PR**. Branches are yours, so you make it — but commit only, and **don't push yet**:

```bash
git switch -c PROJ-NNN-plan origin/develop     # the uncommitted doc follows onto the branch
git add docs/plans/PROJ-NNN-<slug>.md && git commit -m 'docs: PROJ-NNN hand-off doc'
```

Read the doc's **Slices** checklist — your work queue — and its **Assumed** list.

### Get plan signed off

**Stop here and put the plan in front of the user before anything gets built.** Summarise it and **link the doc** for anyone who wants it:

- **The slices**, in order, one line each, with any dependency between them and which are stacked as a result.
- **What was assumed rather than decided** — the Assumed list, short. Decided items settled at the grill don't need re-reading.
- **Anything under Open questions**, which is the planner saying out loud that it doesn't know.

Ask for one of three things: go, change something, or stop. A change goes back to the planner — same agent, context intact — and the revision is amended into the plan commit while the branch is still local and unpushed:

```
SendMessage({to: "<the planner's name>", message: "<what the user wants changed, verbatim>"})
```

then `git add docs/plans/PROJ-NNN-<slug>.md && git commit --amend --no-edit`. Amending is only safe *because* nothing has been pushed; once the PR exists the plan branch is being read like any other, and it gets a new commit instead.

**Wait for the answer here too.** Same rule as the grill: no reply yet isn't a go. Only the user explicitly waving it through moves the run past this without a sign-off.

### Push it

Once the plan is signed off (or consciously not):

```bash
git push -u origin PROJ-NNN-plan
gh pr create --draft --assignee @me --base develop --title 'docs: PROJ-NNN (slice 0/N) hand-off doc' --body '<the ticket>'
```

`N` is the count of entries in the doc's **Slices** checklist. Every slice PR raised later titles itself `(slice x/N)` the same way — the plan PR is slice 0. Raise every PR in this run as a draft, assigned to yourself (`@me`); the reviewer un-drafts and reassigns when it's actually ready to look at.

Every slice branch then roots on **the plan branch** rather than `develop`: GitHub diffs each PR against its own base, which is what keeps the doc out of the slice diffs.

**Completion criterion:** the grill has run and the plan has been signed off — or the user has explicitly waived either — the doc is committed on `PROJ-NNN-plan` with nothing else in the commit, its PR is raised, and you can list the slices in order with their dependencies.

## Step 2 - Loop, one slice at a time

TODO.
