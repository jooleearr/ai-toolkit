#!/usr/bin/env bash
# Create a long-running worktree "lane": a persistent parallel checkout with its
# own isolated DDEV project (web + db container), a seeded database, and a built
# Silverstripe schema. Expensive setup is paid once here, then amortised across
# many tasks by reset-lane.sh.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: create-lane.sh <lane> [--base <ref>] [--db <dump.sql.gz>] [--root <dir>]

  <lane>         Short lane id, e.g. "a". Becomes worktree dir "<repo>-wt-<lane>"
                 and — because .ddev/config.yaml has no name: — the DDEV project
                 of the same name.
  --base <ref>   Base ref to start the lane from        (default: origin/main).
  --db <file>    Canonical DB dump to import            (default: $LANE_DB_DUMP,
                 else db.sql.gz at the repo root).
  --root <dir>   Parent dir to create the worktree in   (default: alongside repo).

Environment overrides:
  LANE_DB_DUMP        default canonical dump path
  LANE_SAKE           sake invocation (default: vendor/bin/sake)
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
lane="$1"; shift
base="origin/main"
db="${LANE_DB_DUMP:-}"
root=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --db)   db="$2";   shift 2 ;;
    --root) root="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_root")"
root="${root:-$(dirname "$repo_root")}"
lane_dir="$root/${repo_name}-wt-${lane}"
lane_branch="wt/${lane}"
db="${db:-$repo_root/db.sql.gz}"
sake="${LANE_SAKE:-vendor/bin/sake}"

# A committed name: in .ddev/config.yaml pins every worktree to the same DDEV
# project — lanes then collide. Deriving the name from the directory is what
# makes lanes isolated, so refuse to proceed until it is removed.
if grep -qE '^\s*name:' "$repo_root/.ddev/config.yaml" 2>/dev/null; then
  echo "error: .ddev/config.yaml still sets 'name:' — remove it so DDEV derives" >&2
  echo "       the project name per worktree. See REFERENCE.md > DDEV config." >&2
  exit 1
fi

echo "==> Creating lane '${lane}' at ${lane_dir} (base ${base}, project ${repo_name}-wt-${lane})"
git fetch origin --quiet || true
git worktree add -b "$lane_branch" "$lane_dir" "$base"

# Copy the untracked files each lane needs (.env, secrets). git worktree does not
# copy untracked files; .worktreeinclude lists them so the same file drives both
# these scripts and Claude Code's native worktree support.
include_file="$repo_root/.worktreeinclude"
if [[ -f "$include_file" ]]; then
  while IFS= read -r rel; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    if [[ -e "$repo_root/$rel" ]]; then
      mkdir -p "$lane_dir/$(dirname "$rel")"
      cp -a "$repo_root/$rel" "$lane_dir/$rel"
      echo "    copied $rel"
    fi
  done < "$include_file"
elif [[ -f "$repo_root/.env" ]]; then
  cp -a "$repo_root/.env" "$lane_dir/.env"
  echo "    copied .env (no .worktreeinclude found)"
fi

cd "$lane_dir"
echo "==> ddev start"
ddev start
echo "==> ddev composer install (shared global cache — network-free after first lane)"
ddev composer install
if [[ -f "$db" ]]; then
  echo "==> ddev import-db --file=$db"
  ddev import-db --file="$db"
else
  echo "warning: no DB dump at $db — skipping import. Pass --db or set LANE_DB_DUMP." >&2
fi
echo "==> dev/build (once per lane)"
ddev exec "$sake" dev/build flush=1

url="$(ddev describe -j 2>/dev/null | grep -oE 'https://[a-z0-9.-]+\.ddev\.site' | head -1 || true)"
echo "==> Lane '${lane}' ready${url:+ at ${url}}"
