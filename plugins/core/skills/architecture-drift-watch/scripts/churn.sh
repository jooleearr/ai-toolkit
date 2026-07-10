#!/usr/bin/env bash
# Churn hotspots: files ranked by how often they change over a BASELINE longer
# than the review window. Sustained high churn is design pressure — a hotspot is
# a trend, not one busy week — so this is measured against history, not the diff.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: churn.sh [--since <when>] [--top <n>] [-- <pathspec>...]

  --since <when>   Baseline start, any git date (default: "6 months ago").
  --top <n>        Show only the top n files (default: 40).
  -- <pathspec>    Restrict to paths, e.g. -- src/ lib/.

A file near the top that is also complex is where to look first.
EOF
}

since="6 months ago"
top=40
paths=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) since="$2"; shift 2 ;;
    --top)   top="$2"; shift 2 ;;
    --) shift; paths=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    *) echo "churn.sh: unexpected arg '$1'" >&2; usage; exit 1 ;;
  esac
done

echo "== Churn since ${since} (top ${top}) =="
git log --no-merges --since="$since" --name-only --pretty=format: -- "${paths[@]}" \
  | sed '/^$/d' | sort | uniq -c | sort -rn | head -n "$top"
