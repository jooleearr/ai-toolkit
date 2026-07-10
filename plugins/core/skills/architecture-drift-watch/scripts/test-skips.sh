#!/usr/bin/env bash
# Test rot: skips introduced in the window and still present, plus test files
# deleted in the window. A skip is a decision someone made once and nobody
# revisited — the net diff since the watermark shows the ones that stuck.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: test-skips.sh <watermark> [<head>]

  <watermark>   Last-reviewed commit SHA (exclusive).
  <head>        End of the window (default: HEAD).

Reports skip idioms added net across the window (JS/TS, Python, Go, Java, Ruby,
PHP, Rust) and any deleted *test* files. Edit the SKIP_RE below per repo.
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
watermark="$1"
head_ref="${2:-HEAD}"
range="${watermark}..${head_ref}"

git rev-parse --quiet --verify "$watermark^{commit}" >/dev/null \
  || { echo "test-skips.sh: unknown watermark '$watermark'" >&2; exit 2; }

# Cross-language skip / focus / disable idioms. Extend for the repo's stack.
SKIP_RE='(\.(skip|only)\(|\bxit\(|\bxdescribe\(|\bfdescribe\(|@[Dd]isabled|@[Ii]gnore|pytest\.mark\.(skip|xfail)|@unittest\.skip|t\.Skip\(|#\[ignore\]|->markTestSkipped|@Test\(enabled *= *false)'

echo "== Skip idioms added net in ${range} =="
git diff "$range" -- '*test*' '*spec*' '*_test.*' '*Test.*' \
  | grep -E '^\+' | grep -Ev '^\+\+\+' \
  | grep -E "$SKIP_RE" || echo "(none)"
echo

echo "== Test files deleted in ${range} =="
git log --no-merges --diff-filter=D --name-only --pretty=format: "$range" \
  | sed '/^$/d' | grep -Ei '(test|spec)' | sort -u || echo "(none)"
