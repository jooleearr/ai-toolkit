---
name: pr-review
description: Use when reviewing an open GitHub PR — usually a teammate's — against its Jira ticket, when asked to "review this PR" or "review PR #123", or when you want teammate-style feedback drafted as an editable pending review. Outward-facing sibling of pre-push-review: reviews someone else's change after it's up, against the ticket, PR description, and diff, with no hand-off doc to lean on. Walks business-context, architecture, security, over-engineering, dependency, semantic-drift, documentation, testing, observability, and accessibility passes; delegates diff-level bug-hunting to code-review and reuses pre-push-review's Fowler smell catalogue and rubric. Comments read as a colleague, not a linter. Always asks before posting, and defaults to a pending draft review you can edit in GitHub.
---

# PR review

Review an open GitHub PR — usually **someone else's** — the way a good colleague would: against the **ticket** it claims to satisfy, not just the diff that reads cleanly. Catch the change that compiles, reads plausibly, and quietly solves a *slightly different problem* than the one asked for — the failure mode that only gets worse as more of the diff is AI-written.

The distinction that defines this skill is **teammate, not linter**. Two things follow from it. The findings are **evidence-based** — each names a `file:line` and says what actually goes wrong, never an opinion dressed as a rule. And the delivery is **outward-facing**: this posts to another person's PR, so it **always asks before posting** and defaults to a **pending** draft only you can see.

Outward-facing sibling of [`pre-push-review`](../pre-push-review/SKILL.md). That skill reviews *your own* change before it goes up, against a ticket and a hand-off doc you wrote. This one reviews *someone else's* change after it's up, where there is no hand-off doc — only the ticket, the PR description, and the diff.

## 1. Gather the inputs

- **The PR** — a number or URL. Pull its diff, description, commits, and changed-file list (GitHub MCP tools, or `gh pr view` / `gh pr diff`). A PR well past a few hundred lines is itself a finding (step 6) — note the size now.
- **The Jira ticket** — resolve the key from the branch name (`feature/ABC-123-thing`) or the PR title (`[ABC-123] Thing`). Fetch it via the **Atlassian MCP** if one is connected — summary, description, **acceptance criteria**. If there is no MCP or no ticket reference, say so plainly and review against the PR description instead: don't guess at intent, and don't abort.
- **The surrounding codebase** — check out the branch (or read the repo at the PR's head). The architecture, over-engineering, and semantic-drift passes need it: a diff alone can't tell you whether an abstraction was warranted or a helper already existed.

**Completion criterion:** you have the diff, the ticket's acceptance criteria (or an explicit note that there was no ticket to fetch), and access to the surrounding code.

## 2. Delegate the diff-level pass

Run the `code-review` skill (a Claude Code built-in) for correctness and reuse/cleanup on the raw diff. Where the change touches a security-sensitive surface (auth, secrets, input handling, permissions, deserialisation), run `security-review` too. Fold their output into your report as the correctness and security categories — do **not** re-hunt those defects yourself; that is what those skills are for.

**Completion criterion:** `code-review` has run (and `security-review` where the surface warrants it), and their findings are captured for your report.

## 3. Scan the diff for code smells

Walk the diff once against the shared **code-smell** catalogue in [`../pre-push-review/CODE-SMELLS.md`](../pre-push-review/CODE-SMELLS.md) — Fowler's smells, each with the diff signals that betray it and the refactoring that removes it. Reuse it; don't restate it.

The catalogue's two rules keep this pass useful rather than noisy: it is **diff-scoped** (flag only a smell the change *introduces or worsens*, never a pre-existing one the diff merely sits next to) and it favours **precision over recall** (stay silent on a borderline signal — a wrong flag on someone else's PR spends more trust than it does on your own). Findings here are **advisory** — `issue` or `nitpick`, never a blocker on their own.

**Completion criterion:** the diff has been walked against the catalogue; every smell the change introduces or worsens is recorded with its `file:line`, the signal that fired, and a suggested refactoring.

## 4. Run the review passes

Each pass below is **conditional**: run it where it applies, and where it doesn't, say it was **skipped** rather than manufacturing a finding to fill the heading. A pure-backend PR gets no accessibility section.

| Pass | What it asks |
| :--- | :----------- |
| **Business context & logic** | Does the code do what the ticket asked? Walk **each** acceptance criterion and decide met or unmet, with evidence. Flag anything in the diff not traceable back to the ticket — out-of-scope extras are a finding even when they're improvements. |
| **Architectural impact** | How does this sit in the existing system — scalability, maintainability, reliability, and whether it respects the established layering and module boundaries? |
| **Security vetting** | Weighted heavily on sensitive surfaces: user input, authn/authz, PII, database queries, secrets, file paths, deserialisation. Builds on step 2's `security-review`. |
| **Over-engineering & anti-patterns** | Abstractions, patterns, and config knobs with no current caller — speculative generality, a strategy pattern for one strategy, an interface with one implementation. Ask what breaks if it's deleted. |
| **Dependencies** | Any new external library: does it **exist**, is it maintained, when was it last released, does it carry known CVEs, and is there already something in the repo that does this? Hallucinated packages are a real supply-chain risk — verify every new import resolves to a real, correctly-named package. |
| **Semantic drift & stale assumptions** | Names that no longer describe what the thing does; comments, docs, and tests that describe the old behaviour; assumptions baked in silently (error handling, defaults, edge cases) that no longer hold. |
| **Documentation upkeep** | Did the change carry its docs with it? Where the diff alters behaviour a reader relies on — public API, config, CLI flags, env vars, setup steps — check the docs that describe it were updated (README, `docs/`, ADRs, changelog, inline usage) or a new one added where the surface is now worth documenting. Flag the gap when code changed but the doc that should mirror it didn't. Distinct from *semantic drift*, which flags docs that now describe the old behaviour; this flags docs that **should** exist or be updated and aren't. |
| **Testing coverage** | Is each acceptance criterion actually exercised? Do the tests assert *behaviour* rather than implementation? What would still pass if the change were reverted? |
| **Observability** | Can this be diagnosed in production — logs, metrics, traces at the right seams — and does any of it leak secrets or PII? |
| **Accessibility** | UI changes only: semantics, keyboard reachability, focus handling, labels and alt text, contrast, motion. |

**Completion criterion:** every applicable pass has produced findings or a clean note; every inapplicable pass is explicitly marked skipped with the reason.

## 5. Write the comments as a teammate

This is the pass that matters most. A comment must read like a message between colleagues — plain language, no jargon used as a verdict. Don't write:

> This violates the Single Responsibility Principle and is the wrong approach.

Write:

> We might run into trouble here — this class is now doing the fetch *and* the formatting, so a change to either one means touching it. Have you considered pulling the formatting into its own function?

The rules behind that:

- **Say what could go wrong, in concrete terms**, instead of naming the principle it breaks.
- **Always pair a problem with a suggestion.** "This is fragile" is a complaint; "this breaks if the list is empty — worth an early return?" is a review.
- **Ask rather than instruct** where there's genuine room for another answer — the author usually knows something you don't.
- **Comment on the code, not the person.** "Why did you do X" → "X could cause Y."
- **Lead with real praise** where it's earned, and be specific about why. A review that only lists faults reads as adversarial.
- **Nits are nits.** Don't let them gate a merge, and don't bury a blocker under six of them.

**Completion criterion:** every finding is phrased as concrete, code-focused teammate feedback that pairs the problem with a suggestion.

## 6. Categorise, rank, and check the batch

Turn everything from steps 2–5 into findings, each carrying a **category**, a **severity**, and a single **Conventional Comments** line — the category set, severity scale, and `(blocking)` / `(non-blocking)` decorations all live in the shared [`../pre-push-review/REVIEW-RUBRIC.md`](../pre-push-review/REVIEW-RUBRIC.md). Reuse it; don't restate it. Order the list **blocker-first**, so the reader triages the highest-impact items before any nit.

Two scoping rules keep the review fair to the author:

- **Diff-scoped** — flag what this change introduces or worsens, not a pre-existing problem it happens to sit next to.
- **Batch size is a finding.** A PR well past a few hundred lines is hard to review well; recommend splitting into smaller vertical slices and note that review quality falls off a cliff past that point.

**Completion criterion:** every finding has a category, a severity, and a conventional-comment line; the list is ordered blocker-first; and oversize is flagged if present.

## 7. Deliver — always ask before posting

Print the ranked summary in the terminal (blockers first, then a one-line verdict: *request changes* if there are blockers, otherwise *comment*). Then **ask the user which they want** — never post to a teammate's PR unprompted:

1. **Draft it** *(default)* — create a **pending** review with the inline comments attached, visible only to the user, who can edit, delete, or add to it in GitHub's UI before submitting. `gh pr review` **cannot** do this; a pending review is a raw API call with no `event` field — see [`REFERENCE.md`](REFERENCE.md) for the exact call.
2. **Submit it** — post the review as `COMMENT` (or `REQUEST_CHANGES` when there are blockers), on explicit confirmation only.
3. **Terminal only** — post nothing.

Degrade gracefully throughout: no Atlassian MCP, no ticket ID, no test suite, no CI each downgrades a pass to "couldn't check, here's why" — never abort the review.

**Completion criterion:** the ranked findings and verdict were shown in the terminal, the user was asked how to deliver, and nothing was posted to the PR without their choice.
