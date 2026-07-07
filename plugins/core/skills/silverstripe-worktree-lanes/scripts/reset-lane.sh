#!/usr/bin/env bash
# Rotate an existing lane onto a fresh base branch for a new task — the cheap,
# repeated operation. Reuses the lane's DDEV project, container, and vendor dir;
# only re-seeds the database and rebuilds the schema. Refuses to clobber
# uncommitted or unpushed work.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: reset-lane.sh <lane> [--base <ref>] [--db <dump.sql.gz>] [--root <dir>] [--force]

  <lane>         Short lane id, e.g. "a" (the existing lane to rotate).
  --base <ref>   Base ref to reset onto              (default: origin/main).
  --db <file>    Canonical DB dump to re-import       (default: $LANE_DB_DUMP,
                 else db.sql.gz at the repo root).
  --root <dir>   Parent dir the worktree lives in     (default: alongside repo).
  --force        Skip the uncommitted/unpushed-work guard.

Environment overrides: LANE_DB_DUMP, LANE_SAKE (default vendor/bin/sake).
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
lane="$1"; shift
base="origin/main"
db="${LANE_DB_DUMP:-}"
root=""
force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --db)   db="$2";   shift 2 ;;
    --root) root="$2"; shift 2 ;;
    --force) force=1;  shift ;;
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

[[ -d "$lane_dir" ]] || { echo "error: no lane at $lane_dir — create it first." >&2; exit 1; }
cd "$lane_dir"

# Rotating discards the working tree. Guard the two ways real work can be lost:
# uncommitted changes, and committed-but-unpushed commits.
if [[ "$force" -ne 1 ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: lane '${lane}' has uncommitted changes. Commit/stash, or pass --force." >&2
    git status --short >&2
    exit 1
  fi
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    unpushed="$(git log --oneline @{u}.. 2>/dev/null || true)"
    if [[ -n "$unpushed" ]]; then
      echo "error: lane '${lane}' has unpushed commits. Push them, or pass --force." >&2
      echo "$unpushed" >&2
      exit 1
    fi
  fi
fi

echo "==> Rotating lane '${lane}' onto ${base}"
git fetch origin --quiet || true
git switch -C "$lane_branch" "$base"
git clean -fd

if [[ -f "$db" ]]; then
  echo "==> Re-importing DB from $db"
  ddev import-db --file="$db"
else
  echo "warning: no DB dump at $db — skipping import." >&2
fi
echo "==> dev/build flush=1"
ddev exec "$sake" dev/build flush=1
echo "==> Lane '${lane}' reset onto ${base} and ready"
