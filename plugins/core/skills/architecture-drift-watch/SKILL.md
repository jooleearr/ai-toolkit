---
name: architecture-drift-watch
description: Use when taking a scheduled, sceptical, architecture-level look at what has drifted in a repo since the last review — the holistic decay across a window of merged history that no single PR review could catch (boundary erosion, convergent duplication, abstraction decay, churn hotspots, co-change coupling, dependency creep, test rot, config/flag accumulation, widening security surface, documentation drift). Reviews a window of commits against the repo's stated architecture using git history as a first-class input, not a diff. Files a labelled GitHub issue and posts one Slack message per run only when a finding clears the triage bar — silence is the common, successful outcome. Reuses pre-push-review's CODE-SMELLS.md read at system altitude.
---

# Architecture drift watch

Every PR can be individually defensible and the codebase still gets worse. Three changes each add a
slightly different HTTP client; a boundary erodes one import at a time; an abstraction picks up its
fourth special case, each added by someone who never saw the other three; a test gets skipped
"temporarily" and never comes back. None of that shows up in a diff. It is only visible **across
time**, over a window of merged changes, by someone holding the whole system in their head and asking
what shape it is **drifting** into.

This skill is that someone. It runs on a **schedule**, takes a sceptical look at everything that
landed since the last run, and surfaces the holistic problems no per-PR review could have caught.
When something clears a **triage bar** a senior engineer would agree on, it files a GitHub issue and
posts a link in the project's Slack channel. Most runs find nothing — and say so.

## What this is *not*

Three skills review code; the boundaries between them are the whole point.

- [`pre-push-review`](../pre-push-review/SKILL.md) — *my* change, before it goes up, against a ticket
  and hand-off doc. Scope: one diff. Intent: did I solve the right problem?
- [`pr-review`](../pr-review/SKILL.md) — *someone else's* change, after it's up, against a Jira
  ticket. Scope: one diff. Intent: should this merge?
- **This skill** — *everyone's* changes, long after they merged, against **the architecture and the
  codebase's own conventions**. Scope: a **window** of history. Intent: what shape is this system
  drifting into?

The failure mode is re-running `code-review` over a bigger diff — re-litigating line-level bugs that
PR review already had its chance at, and drowning the signal this skill exists to find. **If a
finding would have been catchable by reading a single PR in isolation, it is out of scope here.** The
distinguishing input is **git history itself** — churn, co-change coupling, the third appearance of a
pattern, a skip introduced four PRs ago. If a pass doesn't need history to run, question whether it
belongs.

## The two constants

- **The window is a watermark, not a date range.** The unit of review is every commit merged since a
  recorded **watermark** (the last-reviewed SHA), never "the last 7 days". A run that finds nothing
  still advances the watermark, so those commits aren't hidden from the next run; a run that is late
  doesn't skip anything.
- **Silence is a successful run.** This skill files issues and posts to Slack on its own, with nobody
  in the loop. A noisy scheduled bot gets muted within three weeks and never unmuted, and everything
  it would have caught after that is lost. So most weeks file nothing and post nothing, and say so
  plainly. The bar is "a senior engineer would agree this needs triaging", never "this is imperfect".

## 1. Load the project reference and resolve the window

Read [`PROJECTS.md`](PROJECTS.md) — it maps each repo the team manages to what this skill needs:
`owner/name` and default branch, the Slack channel, the architecture notes, the **accepted
trade-offs**, the **watermark**, and the cadence. Pick the entry for the repo under review (a run
targets one repo).

Resolve the **window** as `watermark..HEAD` on the default branch. If the entry has no watermark yet
(first run), fall back — in this order — to the SHA of the last `drift-watch` issue this skill filed,
then to a bounded default (e.g. the last 30 days) — and say in the summary which fallback you used and
that the first window is therefore approximate.

History analysis wants a real clone, not the API: get the repo checked out at the default branch's
`HEAD` with full history (`git fetch --unshallow` if the checkout is shallow). If the window is empty
(`watermark == HEAD`), stop here: report "no new commits since last run", post nothing, and skip to
step 7 to leave the watermark where it is.

**Completion criterion:** you have the repo checked out with full history, the window resolved to a
concrete commit range, and the accepted-trade-offs list in hand.

## 2. Read the stated architecture

Drift is only drift relative to something. Read the repo's statement of intent — `AGENTS.md`, `docs/`
and ADRs (per [`ai-ready-repo`](../ai-ready-repo/SKILL.md)'s conventions), and the README — to learn
what the boundaries, layering, and conventions are *meant* to be.

A repo that documents its architecture gets a much sharper review than one that doesn't. If the repo
has **no** stated architecture, do not invent conventions by inferring them from the code and then
grading the code against them — that is circular. Instead, run only the passes that need no stated
intent (churn, co-change, dependency existence, test rot), state plainly that the sharper passes were
skipped for lack of a baseline, and make the run's first recommendation "adopt `ai-ready-repo` so the
next run has something to review against."

**Completion criterion:** you can state the architecture the code is *meant* to obey, or you have
recorded that there is none and narrowed the run accordingly.

## 3. Compute the history signals

Churn, co-change coupling, and skip-tracking are `git log` pipelines a model shouldn't re-derive each
run. Run the scripts in [`scripts/`](scripts/) against the checkout — they emit the raw signal the
passes read:

- `scripts/window.sh <watermark>` — the commit list and per-file change stats for the window.
- `scripts/churn.sh [--since <baseline>]` — files ranked by change frequency over a **baseline**
  longer than the window (default 6 months), so a hotspot is a sustained trend, not one busy week.
- `scripts/co-change.sh [--since <baseline>] [--min <n>]` — pairs of files that change together more
  often than chance, across module boundaries.
- `scripts/test-skips.sh <watermark>` — skips/`xit`/`it.only`/`@Disabled`/`t.Skip` and deleted test
  files introduced in the window and not since removed.

Hotspots and coupling only mean something against the longer baseline; the window is what's *under
review*, but the pressure is measured against history. Read the scripts before trusting them — they
carry the exact `git log` invocations and the languages' skip idioms, and are meant to be edited per
repo.

**Completion criterion:** the window commit list, the churn and co-change rankings, the dependency-
manifest changes across the window, and the skip inventory are all in hand.

## 4. Run the drift passes

Walk the table below. Each pass is **conditional**: skip an inapplicable one and *say* it was
skipped, rather than manufacturing a finding to fill a heading. Read
[`pre-push-review`'s CODE-SMELLS.md](../pre-push-review/CODE-SMELLS.md) at the **system** altitude —
Shotgun Surgery across modules, Divergent Change, Feature Envy between packages — not the method
altitude the pre-push pass reads it at.

| Pass | What it asks | History signal it needs |
| :--- | :----------- | :---------------------- |
| **Boundary erosion** | Are the layering and module boundaries in `AGENTS.md`/ADRs still the ones the code obeys? Which imports crossed a line they didn't used to cross? | Which commits introduced each cross-boundary import |
| **Convergent duplication** | Did several changes independently solve one problem different ways — three HTTP clients, two error shapes, two date formatters? | The *third* occurrence is the finding; one is a choice, two a coincidence |
| **Abstraction decay** | Which abstractions gained special cases, flags, or `if (type === …)` branches this window, against the shape they were meant to have? | Case accumulation over commits |
| **Churn hotspots** | Which files does every change touch? Sustained high churn is design pressure — something in there wants splitting. | `churn.sh` frequency over the baseline |
| **Co-change coupling** | Which files always change together despite living in different modules? A hidden dependency the directory structure is lying about. | `co-change.sh` co-occurrence |
| **Dependency creep** | New libraries: does one already in the repo do this? Is it maintained, does it carry known CVEs, **does the package even exist**? Anything abandoned since adoption? | Manifest additions across the window |
| **Test rot** | Tests skipped, deleted, weakened; assertions loosened; coverage falling on paths that used to have it. A skip is a decision made once and never revisited. | `test-skips.sh` — skips introduced and never removed |
| **Config & flag accumulation** | Feature flags whose branches are both dead, config knobs with one caller, env vars nothing reads. | Flags added and never retired |
| **Security surface** | Did the attack surface widen a little at a time — an endpoint here, a loosened check there — invisibly to any single PR? | Sensitive-surface touches across the window |
| **Documentation drift** | Do `AGENTS.md`, the docs, and the ADRs still describe the system that exists? A doc that has quietly gone wrong is worse than no doc. | Code changed, doc didn't |

**Completion criterion:** every pass has either produced evidence-based candidate findings or been
recorded as skipped with the reason.

## 5. Apply the triage bar

The bar is the part that matters most, because a wrong flag on a shared channel spends trust the skill
can't easily earn back. Take each candidate finding from step 4 through every gate; a finding that
fails any gate is dropped, not softened.

- **Senior-engineer bar.** Would a senior engineer agree this needs triaging? Nits, style, and
  single-diff bugs never clear it.
- **Evidence, not opinion.** Every surviving finding names the commits or PRs, names the `file:line`,
  and says what actually goes wrong if this continues. A finding without a commit reference is an
  opinion — cut it. Borrow the severity discipline of
  [`REVIEW-RUBRIC.md`](../pre-push-review/REVIEW-RUBRIC.md).
- **Trend, not instance.** "This abstraction has taken on four special cases in six weeks; here they
  are" clears the bar; "this class is complex" does not.
- **Never twice.** Before a finding survives, search the repo's open **and recently closed**
  `drift-watch` issues for the same drift. An open one means it's already filed; a closed one means
  someone already said no — respect that and don't reopen the argument.
- **Accepted trade-offs are not findings.** Read the accepted-trade-offs list; honour it. The one
  exception is the finding: a trade-off whose justification has **expired** (the migration it was
  waiting on has landed) is worth surfacing.

**Completion criterion:** every candidate is either a confirmed finding with commits + `file:line` +
consequence, or has been dropped against a named gate; none duplicates an existing `drift-watch`
issue or a live accepted trade-off.

## 6. Deliver

Delivery order matters: summarise always, file conservatively, post once.

1. **Always print a run summary** — the window reviewed, passes run, passes skipped and why, findings
   and their severity — whether or not anything cleared the bar. This is the record that the run
   happened and did its job even on a silent week.
2. **If findings cleared the bar, file GitHub issues** — one issue per distinct drift, labelled
   `drift-watch` so the next run can dedupe against it. The body carries the evidence: commits, files,
   what breaks if it continues, and a suggested *first step*. Suggest, don't prescribe — this is
   triage input, not a plan.
3. **Then post one Slack message per run** — not per finding — to the channel in `PROJECTS.md`,
   linking the issue(s) with a one-line plain-language summary of each. It must read like a colleague
   flagging something, not a bot dumping a scan. Post via whichever mechanism the run has: a connected
   Slack MCP server, an incoming-webhook URL from the environment, or the Claude Slack app; if none is
   available, print the message and note it could not be posted. **If nothing cleared the bar, post
   nothing** — do not manufacture a weekly finding to justify the run.
4. **When run interactively, ask before posting anything.** Filing an issue and posting to Slack are
   outward-facing, notifying actions on shared spaces. The autonomous path — filing and posting
   without asking — is for the scheduled run only.

**Completion criterion:** the summary is printed; issues are filed only for findings that cleared the
bar; at most one Slack message was posted (or none on a silent run, or none until confirmed when
interactive).

## 7. Advance the watermark

Record the reviewed `HEAD` SHA as the new watermark for this repo in `PROJECTS.md`, so the next run's
window starts exactly where this one ended — even on a silent run. On the scheduled path this means
committing the updated `PROJECTS.md` back to this repo with a `chore(drift-watch):` message; note that
this is the one piece of persistent state the skill keeps, and it lives here rather than in the repo
under review so the skill never writes to a codebase it is only meant to observe.

**Completion criterion:** `PROJECTS.md` records the reviewed `HEAD` as the repo's watermark, committed
on the scheduled path.

## Scheduling

Meant to run as a **cloud routine** (`/schedule`), the same way a nightly skill routine does. Weekly
is the plausible default — long enough for a trend to be a trend, short enough that the evidence is
still fresh in the authors' heads — but the cadence lives in `PROJECTS.md` per repo, never hard-coded
here, so the same skill is equally usable when a human runs it by hand after a big merge.
