# Posting the review

The exact calls for step 7 of [`SKILL.md`](SKILL.md). The default is a **pending** review — a draft only the author of the review can see, editable in GitHub's UI before it's submitted.

## Why not `gh pr review`

`gh pr review` always submits: it requires an event (`--approve`, `--request-changes`, `--comment`), so there is no way to leave a review **pending** with it. A pending review is created by the REST API when you `POST` a review **without** an `event` field. That means a raw `gh api` call (or the equivalent GitHub MCP tools).

## 1. Draft it — a pending review with inline comments (default)

One call creates the pending review and attaches every inline comment. Omitting `event` is what keeps it pending:

```bash
gh api --method POST \
  repos/{owner}/{repo}/pulls/{number}/reviews \
  -f body='Overall summary comment for the review.' \
  -f 'comments[][path]=src/auth/session.ts' \
  -F 'comments[][line]=42' \
  -f 'comments[][side]=RIGHT' \
  -f 'comments[][body]=This breaks if the token is already expired — worth an early return?'
```

Repeat the four `comments[][...]` fields once per inline comment. Fields per comment:

| Field | Meaning |
| :---- | :------ |
| `path` | Repo-relative file path, exactly as it appears in the diff. |
| `line` | Line number in the **new** file (the `RIGHT` side). For a multi-line comment, this is the last line; add `start_line` for the first. |
| `side` | `RIGHT` for the new state (default), `LEFT` for the old. |
| `body` | The comment text. |

The response includes the review `id`. The review is now **pending**: the user opens the PR's *Files changed* tab in GitHub, sees the draft comments, edits/deletes/adds as they like, then clicks **Finish your review** to submit.

Equivalent via the GitHub MCP: `pull_request_review_write` with `method: create` (no event) to open the pending review, `add_comment_to_pending_review` per inline comment, and leave it unsubmitted.

## 2. Submit it — post immediately (explicit confirmation only)

To post the review straight away, include an `event`. Build the same call with the inline `comments[]`, plus:

```bash
  -f event='COMMENT'   # or 'REQUEST_CHANGES' when there are blocking findings, or 'APPROVE'
```

Or submit a review that is already pending:

```bash
gh api --method POST \
  repos/{owner}/{repo}/pulls/{number}/reviews/{review_id}/events \
  -f event='REQUEST_CHANGES' \
  -f body='Summary of the blocking findings.'
```

Equivalent via the GitHub MCP: `pull_request_review_write` with `method: submit_pending` and the chosen `event`.

## Notes

- **Never submit without being asked.** A submitted review notifies the author and everyone watching; a pending review notifies no one. Default to pending.
- An inline comment must point at a line **within the diff hunk** — the API rejects comments on unchanged lines outside the visible context. For a point that isn't on a changed line, fold it into the top-level `body` and name the `file:line` in the text.
