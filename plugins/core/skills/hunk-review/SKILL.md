---
name: hunk-review
description: Use when the user wants to see a diff or changeset in a terminal viewer, or to work through review comments they left on their changes — phrasings like "open the diff", "show me the changes", "diff this branch against main", "open that in a new pane/tab", "review my comments", "action the comments I left", plus the bare words hunk and herdr. The discoverable front door that loads hunk's own review skill and drives it inside a herdr pane or tab.
---

# Hunk review

Be the **front door** for [hunk](https://github.com/modem-dev/hunk) (terminal diff viewer)
and [herdr](https://herdr.dev) (pane/tab workspace manager). Both ship real capability the
user shouldn't have to summon by hand: this skill fires on the way they'd naturally ask,
loads hunk's own knowledge, and supplies the herdr glue hunk doesn't cover — so neither CLI
has to be recalled.

The whole point is **recall**: if the user still has to remember a command to make this
work, the skill has failed. Auto-fire on the phrasings in the description; never make them
name the tools.

## Preflight — run every time, before either workflow

1. **hunk on `PATH`?** If not, say so plainly and stop — don't guess at CLI syntax.
2. **Load hunk's own skill.** Run `hunk skill path` and read the file it prints; follow it
   for every hunk CLI detail. Resolve it fresh each run — the path is version-pinned
   (`.../hunk/<version>/...`), so anything copied or hard-coded goes stale on the next
   `brew upgrade hunk`. Loading it live also inherits hunk's updates for free. Defer to that
   skill rather than restating it here.
3. **herdr is not symmetric with hunk.** It ships no on-disk skill and has no
   `herdr skill path`, so the commands this skill needs are written inline below. If `herdr`
   isn't on `PATH`, or no herdr server is running, say so plainly rather than inventing
   syntax.

### herdr commands used here

Keep to this handful so there's less to drift:

- `herdr workspace list` — see live workspaces/panes.
- `herdr pane split --direction right|down --cwd <repo>` — open a pane (the default surface).
- `herdr tab create --label "review" --cwd <repo>` — open a tab instead.
- `herdr pane run <target> "<command>"` — run a command in the new pane or tab.

`herdr integration install claude` reports Claude Code's session identity to herdr for pane
attribution — a nice-to-have, not skill discovery, and **not** required by either workflow.
It writes to `settings.json`, so **suggest** the user run it; never run it yourself.

## Workflow — "show me the diff"

> "Open the current diffs in a new pane" · "Show me this branch vs main in a new tab"

1. **Pick the review target.** Working tree (`hunk diff`), staged (`hunk diff --staged`), or
   branch-vs-base (`hunk diff <base>`) — resolve the repo's actual default branch rather than
   assuming `main`.
2. **Reuse a live session before opening a new one.** Check `hunk session list` /
   `hunk session get --repo .`; if one is already live for this repo,
   `hunk session reload --repo . -- diff <target>` so the existing window updates instead of
   spawning a duplicate viewer.
3. **Otherwise create the surface in herdr** in the repo's directory — a `pane split` by
   default, or a `tab create` when the user asked for a tab — then `herdr pane run <target>
   "hunk diff <target>"`.

**Completion criterion:** the requested diff is showing in the surface the user asked for
(pane by default, tab on request), with no duplicate viewer left open.

## Workflow — "action my comments"

> "Review and action the comments I've left on the changes"

1. **Find the live window** with `hunk session get --repo .`; if there isn't one, tell the
   user plainly instead of guessing.
2. **Read their notes.** `hunk session comment list --repo . --type user` for the comments,
   and `hunk session review --repo . --json` for surrounding context — add `--include-patch`
   only when the patch text is actually needed, to keep context small.
3. **Work each comment in turn.** Make the code change it asks for, or push back when you
   disagree or the comment is ambiguous — ask rather than guess. You may leave your own note
   on the diff with `hunk session comment add` where a reply belongs there (e.g. flagging a
   comment you deliberately didn't action); you cannot create or edit the user's comments.
4. **Reflect the new state.** `hunk session reload --repo . -- diff`, then report back per
   comment: what you changed, or why you didn't.
5. **Remove only what the user confirms.** Ask them to confirm comment by comment; clear each
   agreed one with `hunk session comment rm --repo . <id>`, and leave the rest. So "all good
   except the third" removes the first two and keeps the third.

**Completion criterion:** every user comment is either actioned-and-removed *after explicit
confirmation*, or left in place with a reported reason. A comment is **never** removed on
your belief alone that you handled it, and bulk `comment clear` is used only when the user
explicitly asks for it.
