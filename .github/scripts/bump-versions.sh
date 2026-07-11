#!/usr/bin/env bash
#
# Auto-bump the `version` in each changed plugin's plugin.json, deriving the
# bump size from the conventional-commit type(s) of the pushed commit(s).
#
#   feat                                   -> minor
#   fix | docs | chore | refactor | perf   -> patch
#   style | test | build | ci              -> patch
#   any type with a `!` (breaking change)  -> major
#
# Invoked by .github/workflows/version-bump.yml on push to main. Reads the push
# range from BEFORE/AFTER (github.event.before / .after); falls back to the last
# commit when they are unset or the branch was just created.
#
# The version is a single monotonic counter per plugin, owned here at merge time,
# so PRs never touch it and parallel branches never conflict on it.

set -euo pipefail

before="${BEFORE:-}"
after="${AFTER:-HEAD}"

# On a brand-new branch, github.event.before is all zeros — review just the tip.
if [[ -z "$before" || "$before" =~ ^0+$ ]]; then
  before="$(git rev-parse "${after}^" 2>/dev/null || echo "$after")"
fi

range="${before}..${after}"

# Rank the strongest bump requested across every commit in the range.
# none < patch < minor < major
bump="none"
rank() { case "$1" in major) echo 3 ;; minor) echo 2 ;; patch) echo 1 ;; *) echo 0 ;; esac; }
raise() { [[ "$(rank "$1")" -gt "$(rank "$bump")" ]] && bump="$1"; return 0; }

while IFS= read -r subject; do
  [[ -z "$subject" ]] && continue
  header="${subject%%:*}"          # "feat(core)!" from "feat(core)!: add thing"
  type="${header%%(*}"             # strip an optional (scope)
  type="${type%!}"                 # strip a trailing ! (kept for breaking test below)
  type="$(printf '%s' "$type" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

  # A `!` before the colon, or a BREAKING CHANGE footer, means a major bump.
  if [[ "$header" == *"!" ]]; then
    raise major
    continue
  fi

  case "$type" in
    feat) raise minor ;;
    fix|docs|chore|refactor|perf|style|test|build|ci|revert) raise patch ;;
    *) : ;;  # non-conventional subject contributes no bump
  esac
done < <(git log --format='%s' "$range")

if [[ "$bump" == "none" ]]; then
  echo "No conventional-commit types found in $range; nothing to bump."
  exit 0
fi

# Which plugin directories were touched in the range?
changed_plugins="$(git diff --name-only "$range" -- 'plugins/' \
  | sed -n 's#^plugins/\([^/]*\)/.*#\1#p' | sort -u)"

if [[ -z "$changed_plugins" ]]; then
  echo "No plugin directories changed in $range; nothing to bump."
  exit 0
fi

for plugin in $changed_plugins; do
  manifest="plugins/${plugin}/.claude-plugin/plugin.json"
  if [[ ! -f "$manifest" ]]; then
    echo "No manifest at $manifest; skipping $plugin."
    continue
  fi

  current="$(jq -r '.version // "0.0.0"' "$manifest")"
  IFS='.' read -r major minor patch <<< "$current"
  major="${major:-0}"; minor="${minor:-0}"; patch="${patch:-0}"

  case "$bump" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
  esac
  new="${major}.${minor}.${patch}"

  tmp="$(mktemp)"
  jq --arg v "$new" '.version = $v' "$manifest" > "$tmp" && mv "$tmp" "$manifest"
  echo "Bumped ${plugin}: ${current} -> ${new} (${bump})"
done
