# Reference — Silverstripe + DDEV worktree lanes

Disclosed reference for [`silverstripe-worktree-lanes`](SKILL.md): the one-off repo setup, the
design rationale behind the chosen approach, per-lane cost mitigations, and the gotchas. Reach
for the section you need; the day-to-day loop lives in `SKILL.md`.

## Why one DDEV project per worktree

DDEV is built to run many projects concurrently — a maintainer-documented pattern (rfay's
worktree writeup, linked below). Each project gets its own web + db container, its own
`*.ddev.site` host, and auto-assigned ports. That buys full isolation with no manual port
juggling, and — crucially for Silverstripe — a **separate database per lane for free**.

The tempting shortcuts are both wrong here:

- **Shared DB across lanes** — unsafe. Silverstripe's schema is code-driven, so `dev/build` on
  a different branch reshapes a shared schema under the other lanes (corruption, silent).
- **One db container, many databases (multi-DB trick)** — not worth it. Each branch is
  different PHP, so a separate *web* container is needed per lane regardless; the db container
  is the cheap part, so there is nothing to save by sharing it.

## One-off repo setup

### DDEV config — drop `name:`

DDEV derives the project name from the directory *only if* `.ddev/config.yaml` does not pin one.
Remove the `name:` line from the committed config:

```yaml
# .ddev/config.yaml
# name: myapp        <-- delete this line; DDEV now uses the directory name
type: silverstripe
php_version: "8.3"
# ...rest unchanged
```

Now `myapp-wt-a/` starts as project `myapp-wt-a`, `myapp-wt-b/` as `myapp-wt-b`, no collisions.
(Alternative: keep `name:` and add a gitignored `.ddev/config.local.yaml` per lane overriding
it — more per-lane fiddling, so prefer dropping `name:`.)

### `.worktreeinclude`

`git worktree add` copies only tracked files, so each lane starts without `.env` and secrets.
List them once at the repo root; `create-lane.sh` copies each into a new lane, and Claude
Code's native `--worktree` support reads the same file.

```
# .worktreeinclude — untracked files every lane needs
.env
.env.local
```

Because every lane's DB lives in its own container, the DB name can stay `db` everywhere — so
the *same* `.env` works in every lane, unmodified.

### `.gitignore`

```
.claude/worktrees/
.ddev/config.local.yaml
```

### Canonical database dump

Keep one portable dump the scripts import per lane. A plain `ddev export-db` /
`mysqldump`-style `db.sql.gz` is preferred over a DDEV snapshot: snapshots are faster but locked
to one DB engine + version and tied to a single project directory, whereas a dump imports into
any lane. Default location is the repo-root `db.sql.gz`; override per invocation with `--db` or
globally with `LANE_DB_DUMP`. Refresh it by re-exporting from a known-good environment whenever
the canonical content drifts.

## Per-lane cost & mitigations

| Cost | Mitigation |
|------|-----------|
| `composer install` (large vendor) | `ddev composer install` shares a global Composer cache across all DDEV projects → network-free after the first lane. Don't symlink `vendor/` across branches — different branches need different dependencies. |
| Content database | One canonical `db.sql.gz`; `ddev import-db --file=…` per lane. |
| `dev/build` | Run once per lane after import (create-lane), and again only on reset. The main reason lanes are long-running: you pay it per *lane*, not per *task*. |

## Gotchas

- **Stale `.git/…/index.lock`** — a crashed git process in one worktree can leave a lock that
  blocks operations in *any* worktree sharing the repo. If git reports a lock and no git
  process is running, remove the named `index.lock` file.
- **Native cleanup ignores DDEV** — `git worktree remove` (and Claude Code's automatic worktree
  teardown) delete the checkout but leave the DDEV project's containers and volumes orphaned.
  Always retire via `retire-lane.sh`, which runs `ddev delete -Oy` first. To GC orphans by
  hand: `ddev delete -Oy <project>` then `git worktree prune`.
- **DB engine/version must match the dump** — `import-db` needs the lane's DB engine (MariaDB
  vs MySQL) and version to match what produced the dump. Keep the engine/version consistent
  across the canonical dump and every lane's `.ddev/config.yaml`.
- **One task per lane** — sharing a lane across concurrent tasks reintroduces the schema/DB
  clash the lane model exists to prevent. Reset between tasks; don't interleave them.

## References

- Claude Code — worktrees & `.worktreeinclude`: <https://code.claude.com/docs/en/worktrees>
- rfay — git worktree with multiple DDEV projects: <https://rfay.github.io/git-worktree-ddev/>
- DDEV blog — git worktree contributor training: <https://ddev.com/blog/git-worktree-contributor-training/>
- DDEV docs — database management (snapshot vs import-db): <https://docs.ddev.com/en/stable/users/usage/database-management/>
- DDEV docs — config options (project name from directory): <https://docs.ddev.com/en/stable/users/configuration/config/>
