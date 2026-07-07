#!/usr/bin/env bash
#
# install.sh — set up the ai-toolkit for use with Claude Code.
#
# Does two independent things:
#   1. Registers this repo as a Claude Code plugin marketplace (so you can
#      /plugin install core@ai-toolkit in any project).
#   2. Merges the shared default permissions (shared/settings.template.json)
#      into a settings.json — globally (~/.claude) by default, or into a
#      specific project with --project.
#
# Usage:
#   ./install.sh                     # register marketplace + merge into ~/.claude/settings.json
#   ./install.sh --project /path     # merge into /path/.claude/settings.json instead
#   ./install.sh --no-settings       # only register the marketplace
#   ./install.sh --no-marketplace    # only merge settings
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$REPO_DIR/shared/settings.template.json"
MARKETPLACE="jooleear/ai-toolkit"

DO_MARKETPLACE=true
DO_SETTINGS=true
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)       PROJECT_DIR="${2:?--project needs a path}"; shift 2 ;;
    --no-settings)   DO_SETTINGS=false; shift ;;
    --no-marketplace) DO_MARKETPLACE=false; shift ;;
    -h|--help)       sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# 1. Register the marketplace ------------------------------------------------
if $DO_MARKETPLACE; then
  if command -v claude >/dev/null 2>&1; then
    echo "==> Registering marketplace '$MARKETPLACE'"
    claude plugin marketplace add "$MARKETPLACE" || \
      echo "    (already registered or add failed — continuing)"
    echo "    Install plugins with:  claude plugin install core@ai-toolkit"
  else
    echo "==> 'claude' CLI not found. To register the marketplace, run this inside Claude Code:"
    echo "    /plugin marketplace add $MARKETPLACE"
  fi
fi

# 2. Merge shared permissions ------------------------------------------------
if $DO_SETTINGS; then
  if [[ -n "$PROJECT_DIR" ]]; then
    TARGET="$PROJECT_DIR/.claude/settings.json"
  else
    TARGET="$HOME/.claude/settings.json"
  fi
  mkdir -p "$(dirname "$TARGET")"

  if ! command -v jq >/dev/null 2>&1; then
    echo "==> jq is required to merge settings (brew install jq). Skipping settings." >&2
    exit 1
  fi

  echo "==> Merging default permissions into $TARGET"
  if [[ -f "$TARGET" ]]; then
    cp "$TARGET" "$TARGET.bak"
    echo "    Backed up existing settings to $TARGET.bak"
  else
    echo '{}' > "$TARGET"
  fi

  # Deep-merge: template wins on scalars; permission arrays are unioned.
  jq -s '
    (.[0] // {}) as $cur | (.[1] // {}) as $tpl |
    ($cur * $tpl) |
    del(.["$comment"], .["_comment"]) |
    .permissions.allow = (($cur.permissions.allow // []) + ($tpl.permissions.allow // []) | unique) |
    .permissions.ask   = (($cur.permissions.ask   // []) + ($tpl.permissions.ask   // []) | unique) |
    .permissions.deny  = (($cur.permissions.deny  // []) + ($tpl.permissions.deny  // []) | unique)
  ' "$TARGET" "$TEMPLATE" > "$TARGET.tmp" && mv "$TARGET.tmp" "$TARGET"

  echo "    Done. Review with:  cat \"$TARGET\""
fi

echo "==> Finished."
