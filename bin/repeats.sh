#!/usr/bin/env bash
#
# Fails when a sentence appears verbatim in more than one place.
#
# Promoted from a judgement that recurred six times in a single review. A judgement costs a review
# round. An oracle costs an exit code and never gets tired.
#
# Usage: bin/repeats.sh [files...]   (defaults to what CI grades — see DEBT)
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -euo pipefail

# Below MIN, sentences repeat legitimately. Above MAX, a match swallows whole tables.
readonly MIN=35 MAX=400

# Code and link fragments. A URL truncated at its first dot is noise, not a repeat.
readonly NOISE='://|::|\[|\]|[{}$]|->|=>'

# `.claude/` is Claude-local, and a pull request template is a form rather than prose.
readonly SKIP='^\.claude/|PULL_REQUEST_TEMPLATE'

# The trees this does not reach yet. Named here and not in a caller's
# arguments, because that is what let a bare run and CI
# disagree by 22 repeats nobody could act on.
#
# An exclusion, never an inclusion. A plugin added tomorrow is
# graded without anyone editing this line, where an
# inclusion list would have skipped it.
readonly DEBT='^docs/|^plugins/floor/|^plugins/kernel/|^plugins/laravel-ddd/|^plugins/laravel-playbook/'

files=("$@")
if [ "$#" -eq 0 ]; then
  while IFS= read -r line; do
    files+=("$line")
  done < <(git ls-files '*.md' | grep -Ev "$SKIP|$DEBT")
fi
# An empty list is not a list nobody repeats a sentence in. `git ls-files` answers empty from
# outside a repository and from one holding no markdown, and both used to read as clean.
[ "${#files[@]}" -gt 0 ] || { echo "FAIL — no markdown found. This gate read nothing."; exit 3; }

# Collapse newlines so a wrapped sentence still matches — but only within a paragraph. Fences,
# headings and blank lines emit "." to end a sentence rather than fuse the text either side of them.
# Code inside fences is dropped: a skill and its examples are meant to share it.
paragraphs() {
  awk '
    /^[[:space:]]*```/ { fenced = !fenced; print "."; next }
    fenced             { next }
    /^[[:space:]]*#/   { print "."; next }
    /^[[:space:]]*$/   { print "."; next }
                       { print }
  ' "$1" | tr '\n' ' '
}

# Cut the stream into sentences: from a capital to the next full stop, sized between MIN and MAX.
#
# awk, not `grep -o "[A-Z][^.!?]\{$MIN,$MAX\}[.!?]"` — BSD grep refuses any interval above 255 and
# dies with "maximum repetition exceeds 255", so that gate was red on every Mac and green in CI. A
# gate whose answer depends on which grep you have is not a gate.
cut_up() {
  awk -v min="$MIN" -v max="$MAX" '
    {
      rest = $0
      while (match(rest, /[.!?]/)) {
        chunk = substr(rest, 1, RSTART)
        rest  = substr(rest, RSTART + 1)
        sub(/^[^A-Z]*/, "", chunk)
        if (chunk != "" && length(chunk) - 2 >= min && length(chunk) - 2 <= max) print chunk
      }
    }
  '
}

# One line per sentence, tab, the file it came from. Tagging via awk, not sed — BSD sed emits a
# literal "t" for \t and would corrupt the delimiter without failing.
# `grep` answers 1 when it filters everything out, which is what a file holding no sentence
# between MIN and MAX looks like. Under `pipefail` that ended the script at whichever
# file sorted last, silently. 2 is a real failure and still is.
without_noise() {
  grep -Ev "$NOISE" || [ "$?" -eq 1 ]
}

sentences=$(
  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    paragraphs "$file" \
      | cut_up \
      | sed 's/  */ /g; s/^ //' \
      | without_noise \n      | awk -v file="$file" '{ print $0 "\t" file }'
  done
)

repeated=$(printf '%s\n' "$sentences" | cut -f1 | sort | uniq -d)

if [ -z "$repeated" ]; then
  echo "PASS — no sentence appears twice across ${#files[@]} files."
  exit 0
fi

echo "FAIL — prose repeated. A copy carries no information; it only drifts."
echo

# One pass. Scanning the corpus once per repeat is quadratic and dies on a large repo.
#
# The repeats arrive as a file, not as `-v repeated=...`. A `-v` value holding newlines is a syntax
# error to the awk macOS ships — "newline in string" — so this report died on the only machines
# where it had something to report.
printf '%s\n' "$sentences" | awk -F'\t' '
  NR == FNR { if ($0 != "") wanted[$0] = 1; next }
  $1 in wanted && !seen[$0]++ {
    if (!($1 in found)) order[++count] = $1
    found[$1] = found[$1] "\n      " $2
  }
  END {
    for (i = 1; i <= count; i++) printf "  \"%s\"%s\n\n", order[i], found[order[i]]
    printf "%d repeated sentences.\n", count
  }
' <(printf '%s\n' "$repeated") -

exit 1
