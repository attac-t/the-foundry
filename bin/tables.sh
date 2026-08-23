#!/usr/bin/env bash
#
# Fails when a table cell is a paragraph.
#
# Alignment was the first answer and it cannot be given: `length` counts bytes in one locale and
# characters in another, so a table padded by one awk is ragged to the next. Measured, and it is why
# no gate here pads anything.
#
# What is actually unreadable is a cell holding four hundred characters. Nine cells in ten are under
# fifty and read fine unpadded.
#
# Usage: bin/tables.sh [files...]
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -euo pipefail

# Bytes, under `LC_ALL=C`, so every machine counts the same thing. The p99 of this tree is 196, so
# the cap sits just above what normal prose reaches
# and well below a paragraph.
readonly CAP=200

# A panel verdict is a transcript and a pull request template is a form. `.claude/rules` is graded:
# it is the prose a session reads first, and skipping
# it would exempt the file stating this rule.
readonly SKIP='^\.claude/panel/|PULL_REQUEST_TEMPLATE'

# The RFC is an accepted design and its revision log. That log is read in
# sequence rather than scanned as a grid, and its `Was | Is |
# What forced it` rows are three columns of sentences.
#
# Named here rather than in a caller's arguments, for the reason `repeats.sh` gives: a bare run and
# CI disagreeing is worse than a gap written down.
readonly DEBT='^docs/rfc/'

files=("$@")
if [ "$#" -eq 0 ]; then
  while IFS= read -r line; do
    files+=("$line")
  done < <(git ls-files '*.md' | grep -Ev "$SKIP|$DEBT")
fi

# An empty list is not a tree whose tables are all fine. `git ls-files` answers empty from outside a
# repository and from one holding no markdown.
[ "${#files[@]}" -gt 0 ] || { echo "FAIL — no markdown found. This gate read nothing."; exit 3; }

# A row, never the `|---|---|` under the header. Leading and trailing pipes make the first and last
# fields empty, so the cells are the ones between.
oversized() {
  LC_ALL=C awk -F'|' -v cap="$CAP" '
    /^\|/ && !/^\|[- :|]*\|$/ {
      for (i = 2; i < NF; i++) {
        cell = $i
        gsub(/^ +| +$/, "", cell)
        if (length(cell) > cap) printf "%s:%d  %d bytes  %.60s…\n", FILENAME, FNR, length(cell), cell
      }
    }
  ' "$@"
}

found=$(oversized "${files[@]}")

if [ -z "$found" ]; then
  echo "PASS — no table cell over $CAP bytes across ${#files[@]} files."
  exit 0
fi

echo "FAIL — a table cell is a paragraph. A grid puts like things above like things."
echo
printf '%s\n' "$found"
echo
printf '%s cells over %s bytes.\n' "$(printf '%s\n' "$found" | grep -c .)" "$CAP"

exit 1
