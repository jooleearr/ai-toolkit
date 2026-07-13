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

### DDEV project name — local-only (default) vs drop-name

Each lane needs its **own** DDEV project name (and therefore its own `*.ddev.site` host), or
worktrees collide on one project. There are two ways to get there; `create-lane.sh` defaults to
the first and offers the second via `--mode drop-name`.

**Local-only (default, `--mode local`) — recommended.** Leave the committed `.ddev/config.yaml`
untouched, keeping its `name:`. `create-lane.sh` writes an **untracked**
`.ddev/config.local.yaml` into each lane (DDEV already gitignores `config.local.y*ml`, and its
override wins over `config.yaml`). This is the whole file — it pins the lane's project name, and
the `SS_BASE_URL` explained under "CMS/admin host-jump" below:

```yaml
# <lane>/.ddev/config.local.yaml  — written by create-lane.sh, never committed
name: myapp-wt-a          # local mode only; drop-name derives the name from the dir
web_environment:
  - SS_BASE_URL=https://myapp-wt-a.ddev.site
```

Why this is the default: a project's `name:` is usually **load-bearing** — the derived host
(`myapp.ddev.site`) is baked into Auth0 callback URLs, the CSP / `SecurityHeaders` middleware,
`security.yml`, `playwright.config.ts`, and more. Dropping `name:` renames the *main* checkout's
URL and quietly breaks local auth and the E2E suite; worse, it's a change to a **committed,
shared** file, so every teammate then needs their own local override or their URL breaks on the
next pull. Local-only keeps the main checkout's host exactly as-is and puts **zero footprint on
the shared branch**. Note the DDEV project name is decoupled from the worktree **directory** name
— the dir can be `myapp-wt-a/` while the project/URL is `<canonical>-wt-a`.

**drop-name (`--mode drop-name`) — the alternative.** DDEV derives the project name from the
directory *only if* `.ddev/config.yaml` does not pin one. Remove the `name:` line:

```yaml
# .ddev/config.yaml
# name: myapp        <-- delete this line; DDEV now uses the directory name
type: silverstripe
php_version: "8.3"
# ...rest unchanged
```

Now `myapp-wt-a/` starts as project `myapp-wt-a`. Use this only when the project name is *not*
load-bearing and you're happy to change the committed config. `create-lane.sh --mode drop-name`
refuses to run until `name:` is removed.

### Host allow-listing — the "Invalid Host" 400

Silverstripe's `AllowedHostsMiddleware` (via `SS_ALLOWED_HOSTS` or a YAML list) whitelists
specific hosts. A freshly-created lane looks healthy (`ddev describe` is green) but **every
request returns HTTP 400 "Invalid Host"**, because the lane's own `…-wt-a.ddev.site` host isn't
on the list. `create-lane.sh` handles this automatically when it detects host restriction:

- **YAML projects** — it writes an untracked `app/_config/lane-local.yml` adding the lane host.
  Silverstripe's Config **merges** arrays across fragments, so only the lane host is listed and
  the committed entries are preserved:

  ```yaml
  ---
  Name: lane-local-allowedhosts
  ---
  SilverStripe\Core\Injector\Injector:
    SilverStripe\Control\Middleware\AllowedHostsMiddleware:
      properties:
        AllowedHosts:
          - 'myapp-wt-a.ddev.site'
  ```

- **`.env` projects** — where the allow-list lives in `SS_ALLOWED_HOSTS` in `.env`, it appends
  the lane host to the lane's copied `.env` value instead.

The fragment is written **before first boot**, so the initial config-manifest build already
includes the host and the lane serves 200 on the first request — no flush dance. The config dir
is assumed to be `app/_config`; override with `LANE_SS_CONFIG_DIR` if the app module differs.

**Only when hosts are actually restricted.** If a project doesn't whitelist hosts (an empty
`AllowedHosts` means "allow all"), writing a fragment that sets `AllowedHosts: ['<lane-host>']`
would *restrict* it to just the lane host and break everything else. `create-lane.sh` detects
`AllowedHostsMiddleware` / `SS_ALLOWED_HOSTS` first and writes nothing when neither is present.

### CMS/admin host-jump — `SS_BASE_URL` pinned per lane

Same class of bug as "Invalid Host", but silent and destructive rather than a visible 400. The
copied `.env` sets `SS_BASE_URL` to the **main** host, and a very common pattern maps that onto
the absolute base URL — e.g. in `app/_config.php`:

```php
if (Environment::getEnv('SS_ENVIRONMENT_TYPE') === 'dev') {
    Director::config()->set('alternate_base_url', Environment::getEnv('SS_BASE_URL'));
}
```

So the CMS builds absolute URLs and redirects against the main host: on a lane, `/admin` 302s to
`https://<main-host>/admin/pages` and you edit **main-repo** content without noticing. (The
front-end home renders fine — it is served for the request host; only absolute-URL/redirect paths
jump. `SS_BASE_URL` also feeds the CSP and the React asset base, so those mis-point too.)

`create-lane.sh` fixes this by pinning `SS_BASE_URL` to the lane host, **without editing the
copied `.env`**. Silverstripe's `.env` loader is non-overloading by default
(`EnvironmentLoader::loadFile($path, $overload = false)` skips any var already set in the real
environment), so a DDEV-injected value wins. It rides in the `web_environment:` block of the
per-lane, untracked `.ddev/config.local.yaml` shown above — written *before first boot*, so no
restart is needed.

Unlike the AllowedHosts fragment, this is safe as an **unconditional** default: if the project
uses `SS_BASE_URL` it fixes the host-jump; if it doesn't, the var is simply unread. And
`https://<lane-host>` is exactly what Silverstripe would derive from the request host anyway, so
it can't be wrong. Both modes write it (the host-jump happens regardless of how the project name
is pinned); in `drop-name` mode the file carries only the `web_environment:` block, no `name:`.
`reset-lane.sh` needs no change — `config.local.yaml` persists across a reset, so the pin stays
applied.

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

### Keeping the lane machinery invisible

The untracked lane files should never show up as changes on the shared branch. DDEV already
gitignores `.ddev/config.local.y*ml`; add the rest to `.git/info/exclude` (a local, uncommitted
ignore file — no shared-branch footprint), or to `.gitignore` if you're happy committing it:

```
# .git/info/exclude — local, not shared
.claude/worktrees/
app/_config/lane-local.yml
.worktreeinclude
db.sql.gz
```

### Base branch

`create-lane.sh` / `reset-lane.sh` default `--base` to origin's own default branch
(`origin/HEAD`), so a project that integrates on `develop` works without passing `--base`.
Override per-invocation with `--base origin/<ref>` when you want to branch off something else.

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
- **Web-vs-CLI config flush** — after adding a host to an *already-running* lane (i.e. on
  `reset-lane.sh`, which rebuilds over a warm cache), a CLI `sake … dev/build flush=1` only
  rebuilds the **CLI** process's config manifest; **php-fpm keeps serving its stale one**, so
  the browser still 400s while the CLI insists the host is allowed. The reliable fix is to flush
  *through the web process* via a host that's already whitelisted — which is exactly what the
  scripts do:

  ```bash
  ddev exec "curl -s -o /dev/null -H 'Host: <canonical>.ddev.site' 'http://localhost/?flush=1'"
  ```

  `create-lane.sh` avoids the trap entirely by writing the host fragment *before first boot*, so
  the web flush there is belt-and-braces; on `reset-lane.sh` (warm cache) it is load-bearing.

## References

- Claude Code — worktrees & `.worktreeinclude`: <https://code.claude.com/docs/en/worktrees>
- rfay — git worktree with multiple DDEV projects: <https://rfay.github.io/git-worktree-ddev/>
- DDEV blog — git worktree contributor training: <https://ddev.com/blog/git-worktree-contributor-training/>
- DDEV docs — database management (snapshot vs import-db): <https://docs.ddev.com/en/stable/users/usage/database-management/>
- DDEV docs — config options (project name from directory): <https://docs.ddev.com/en/stable/users/configuration/config/>
