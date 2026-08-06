#!/usr/bin/env bash
#
# Fails when a sentence appears verbatim in more than one place.
#
# Promoted from a judgement (panel verdict, 2026-08-06) that recurred six times in one review.
# A judgement costs a review round. An oracle costs an exit code and never gets tired.
#
# Newlines are collapsed per file before matching, so a sentence that wraps across lines is still
# caught — the reason a plain `grep` misses these. Line numbers are lost to that normalisation;
# the offending files are named, which is enough to act on.
#
# Usage: bin/no-duplicate-prose.sh [files...]   (defaults to every shipped markdown file)

set -euo pipefail

files=("$@")
if [ ${#files[@]} -eq 0 ]; then
  mapfile -t files < <(git ls-files '*.md' | grep -v -e '^\.claude/' -e 'PULL_REQUEST_TEMPLATE')
fi

# Minimum sentence length. Short sentences repeat legitimately ("Most of the time.").
# Maximum, because an unbounded match swallows whole tables and lists as one "sentence".
readonly MIN=35
readonly MAX=400

sentences=$(
  for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    # Newlines collapse so a wrapped sentence still matches — but only *within* a paragraph.
    # Fences, headings and blank lines emit "." so they terminate a sentence instead of fusing
    # the text on either side of them into one. Code inside fences is dropped: a skill and its
    # examples are supposed to share code.
    awk '
      /^[[:space:]]*```/ { fenced = !fenced; print "."; next }
      fenced             { next }
      /^[[:space:]]*#/   { print "."; next }
      /^[[:space:]]*$/   { print "."; next }
                         { print }
    ' "$f" \
      | tr '\n' ' ' \
      | grep -o "[A-Z][^.!?]\{$MIN,$MAX\}[.!?]" \
      | sed 's/  */ /g; s/^ //' \
      | grep -v '://\|::\|\[\|\]\|[{}$]\|->\|=>' \
      | sed "s|\$|\t$f|"
  done
)

duplicates=$(printf '%s\n' "$sentences" | cut -f1 | sort | uniq -d)

if [ -z "$duplicates" ]; then
  echo "PASS — no sentence appears twice across ${#files[@]} files."
  exit 0
fi

echo "FAIL — prose duplicated. A copy carries no information; it only drifts."
echo

# Single pass. Looping the corpus once per duplicate is quadratic and dies on a large repo.
printf '%s\n' "$sentences" | awk -F'\t' -v dups="$duplicates" '
  BEGIN {
    n = split(dups, arr, "\n")
    for (i = 1; i <= n; i++) if (arr[i] != "") wanted[arr[i]] = 1
  }
  $1 in wanted && !seen[$1 FS $2]++ {
    if (!(($1) in out)) order[++count] = $1
    out[$1] = out[$1] "\n      " $2
  }
  END {
    for (i = 1; i <= count; i++) printf "  \"%s\"%s\n\n", order[i], out[order[i]]
    printf "%d duplicated sentences.\n", count
  }
'

exit 1
