#!/usr/bin/env bash
#
# Bump the version of every plugin that changed in a commit range, based on the
# conventional-commit type of the commits in that range.
#
#   feat / breaking change  -> minor  (we stay in 0.x until a deliberate 1.0)
#   everything else         -> patch
#
# Intended to run on push to main (see .github/workflows/version-bump.yml), but
# safe to run locally to preview:
#
#   .github/scripts/bump-plugin-versions.sh <before-ref> [<after-ref>]
#
# Writes the bumped plugin.json files in place. Sets "changed=1|0" on
# $GITHUB_OUTPUT so the workflow knows whether there is anything to commit.
set -euo pipefail

before="${1:-}"
after="${2:-HEAD}"

# No usable "before" (first push sends an all-zero SHA): fall back to the
# parent of the after commit so we still have a one-commit range.
if [[ -z "$before" || "$before" =~ ^0+$ ]]; then
  before="$(git rev-parse "${after}^" 2>/dev/null || true)"
fi

if [[ -n "$before" ]]; then
  range="${before}..${after}"
  changed_files="$(git diff --name-only "$before" "$after" -- plugins/)"
else
  range="$after"
  changed_files="$(git show --name-only --format= "$after" -- plugins/)"
fi

messages="$(git log --format='%B' "$range")"

# Determine the bump level from the strongest signal in the range.
if grep -qE 'BREAKING CHANGE' <<<"$messages" \
   || grep -qE '^[a-z]+(\([^)]*\))?!:' <<<"$messages" \
   || grep -qE '^feat(\([^)]*\))?:' <<<"$messages"; then
  level="minor"
else
  level="patch"
fi

# Plugins touched in this range (top-level dir under plugins/).
plugins="$(awk -F/ 'NF>2 && $1=="plugins" {print $2}' <<<"$changed_files" | sort -u)"

changed_any=0
while IFS= read -r plugin; do
  [[ -n "$plugin" ]] || continue
  manifest="plugins/${plugin}/.claude-plugin/plugin.json"
  [[ -f "$manifest" ]] || continue

  current="$(jq -r '.version' "$manifest")"
  IFS='.' read -r major minor patch <<<"$current"
  case "$level" in
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
  esac
  new="${major}.${minor}.${patch}"

  tmp="$(mktemp)"
  jq --indent 2 --arg v "$new" '.version = $v' "$manifest" >"$tmp"
  mv "$tmp" "$manifest"
  echo "Bumped ${plugin}: ${current} -> ${new} (${level})"
  changed_any=1
done <<<"$plugins"

if [[ "$changed_any" == "0" ]]; then
  echo "No plugin changes in range ${range}; nothing to bump."
fi

echo "changed=${changed_any}" >>"${GITHUB_OUTPUT:-/dev/null}"
