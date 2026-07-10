# Drift-watch project reference

The register [`architecture-drift-watch`](SKILL.md) reads (step 1). One entry per repo the skill
watches, mapping the repo to everything the review needs and holding the per-repo **watermark**. The
point of this file is that adding the second repo is an *edit*, not a rewrite.

Keep one `## <owner>/<repo>` section per repo, with the fields below. Seeded with the trial repo and
channel only.

## Fields

| Field | Why the skill needs it |
| :---- | :--------------------- |
| **Repo** | `owner/name` and the default branch — the checkout and the window are resolved against it. |
| **Slack channel** | Where a run's findings get posted. One channel per repo. |
| **Cadence** | Weekly, fortnightly, … A repo with two commits a month doesn't want a weekly run. Advisory to the scheduler; never hard-coded in the skill. |
| **Architecture notes** | The stack, the layering the code is meant to obey, and where the ADRs live — the baseline the drift passes grade against. |
| **Accepted trade-offs** | Debt the team has consciously chosen to carry, each with the **condition that would make it a finding again** (e.g. "until the v2 migration lands"). Re-reporting accepted debt is the fastest way to get the skill muted. |
| **Watermark** | The last-reviewed `HEAD` SHA. The skill advances it every run (step 7), even on a silent one. `-` means "never run" — the first run falls back per step 1. |

> Accepted trade-offs are duplicated knowledge: the team that owns the repo can't see this file. Where
> a repo keeps its own ADRs, prefer recording the trade-off there (an ADR, `docs/`) and have this
> entry point at it, so the owning team can edit it. This register is the fallback for repos that have
> nowhere better yet.

---

## jooleearr/ai-toolkit

- **Repo:** `jooleearr/ai-toolkit`, default branch `main`.
- **Slack channel:** `#ai-toolkit` _(placeholder — confirm the real channel before the first
  autonomous post)._
- **Cadence:** weekly.
- **Architecture notes:** a Claude Code plugin marketplace — Markdown + JSON config, no build or
  runtime. Structure and conventions are stated in the repo-root [`AGENTS.md`](../../../../AGENTS.md):
  one plugin per `plugins/<name>/`; only `plugin.json` inside a plugin's `.claude-plugin/`;
  `skills/`, `agents/`, `hooks/` at the plugin root; NZ English; kebab-case; conventional commits.
  No ADR directory yet — the boundary the drift passes watch is the plugin/skill layout rule above.
- **Accepted trade-offs:** none recorded yet.
- **Watermark:** `-`
