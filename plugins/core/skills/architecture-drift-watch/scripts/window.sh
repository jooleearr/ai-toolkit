#!/usr/bin/env bash
# The review window: every commit merged since the watermark, plus per-file
# change stats within it. This is what's UNDER review — the drift passes read it
# against the longer baseline that churn.sh / co-change.sh measure.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: window.sh <watermark> [<head>]

  <watermark>   Last-reviewed commit SHA (exclusive). The window is
                <watermark>..<head>. Pass the value from PROJECTS.md.
  <head>        End of the window (default: HEAD).

Emits three sections: the commit list, files ranked by touches in the window,
and the net line churn per file (added/removed).
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
watermark="$1"
head_ref="${2:-HEAD}"
range="${watermark}..${head_ref}"

git rev-parse --quiet --verify "$watermark^{commit}" >/dev/null \
  || { echo "window.sh: unknown watermark '$watermark'" >&2; exit 2; }

echo "== Window ${range} =="
count=$(git rev-list --count "$range")
echo "${count} commit(s)"
echo

echo "== Commits =="
git log --no-merges --pretty=format:'%h %ad %an  %s' --date=short "$range"
echo; echo

echo "== Files by touches in window =="
git log --no-merges --name-only --pretty=format: "$range" \
  | sed '/^$/d' | sort | uniq -c | sort -rn
echo

echo "== Net line churn per file (added / removed) =="
git log --no-merges --numstat --pretty=format: "$range" \
  | awk 'NF==3 { add[$3]+=$1; del[$3]+=$2 }
         END { for (f in add) printf "%6d +%s\t-%s\n", add[f]+del[f], add[f], del[f]" "f }' \
  | sort -rn
