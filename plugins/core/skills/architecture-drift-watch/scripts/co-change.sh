#!/usr/bin/env bash
# Co-change coupling: pairs of files that change together far more often than
# chance. A pair in two different top-level modules is a hidden dependency the
# directory structure is lying about — the highest-signal rows to read first.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: co-change.sh [--since <when>] [--min <n>] [--max-files <n>] [--cross-only]

  --since <when>    Baseline start, any git date (default: "6 months ago").
  --min <n>         Only pairs that co-changed at least n times (default: 3).
  --max-files <n>   Ignore commits touching more than n files — a sweeping
                    commit couples everything spuriously (default: 30).
  --cross-only      Only pairs whose top-level directories differ.

Output: "<count>  <fileA>  <fileB>  [CROSS]", most-coupled first.
EOF
}

since="6 months ago"
min=3
max_files=30
cross_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) since="$2"; shift 2 ;;
    --min) min="$2"; shift 2 ;;
    --max-files) max_files="$2"; shift 2 ;;
    --cross-only) cross_only=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "co-change.sh: unexpected arg '$1'" >&2; usage; exit 1 ;;
  esac
done

echo "== Co-change coupling since ${since} (min ${min}, max-files ${max_files}) =="
git log --no-merges --since="$since" --name-only --pretty=format:'::commit' \
  | awk -v maxf="$max_files" '
      function flush(   i, j, a, b) {
        if (n > 1 && n <= maxf) {
          # emit each unordered pair once, lexicographically ordered
          for (i = 1; i <= n; i++)
            for (j = i + 1; j <= n; j++) {
              a = files[i]; b = files[j]
              if (a < b) print a "\t" b; else print b "\t" a
            }
        }
      }
      /^::commit$/ { flush(); n = 0; next }
      NF == 0 { next }
      { files[++n] = $0 }
      END { flush() }
    ' \
  | sort | uniq -c | sort -rn \
  | awk -v min="$min" -v cross="$cross_only" '
      $1 >= min {
        a = $2; b = $3
        da = a; sub(/\/.*/, "", da)
        db = b; sub(/\/.*/, "", db)
        tag = (da != db) ? "CROSS" : ""
        if (cross && tag == "") next
        printf "%6d  %s  %s  %s\n", $1, a, b, tag
      }'
