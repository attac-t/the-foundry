#!/usr/bin/env bash
#
# Fails when a sentence appears verbatim in more than one place.
#
# Promoted from a judgement that recurred six times in a single review. A judgement costs a review
# round. An oracle costs an exit code and never gets tired.
#
# Usage: bin/repeats.sh [files...]   (defaults to every tracked markdown file)

set -euo pipefail

# Below MIN, sentences repeat legitimately. Above MAX, a match swallows whole tables.
readonly MIN=35 MAX=400

# Code and link fragments. A URL truncated at its first dot is noise, not a repeat.
readonly NOISE='://|::|\[|\]|[{}$]|->|=>'

files=("$@")
if [ "$#" -eq 0 ]; then
  while IFS= read -r line; do
    files+=("$line")
  # -co: tracked AND untracked. Tracked-only reads none of the work under review, which is exactly
  # when this gate is run — it reported PASS over 36 files having opened none of them.
  done < <(git ls-files -co --exclude-standard '*.md' \
             | grep -v -e '^\.claude/' -e 'PULL_REQUEST_TEMPLATE')
fi
[ "${#files[@]}" -gt 0 ] || { echo "No files to check."; exit 0; }

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

# One line per sentence, tab, the file it came from. Tagging via awk, not sed — BSD sed emits a
# literal "t" for \t and would corrupt the delimiter without failing.
missing=()
for file in "${files[@]}"; do
  [ -f "$file" ] || missing+=("$file")
done

# Skipping quietly and then reporting the argument count is a gate claiming work it did not do.
# Under fork exhaustion on Windows this reported PASS across 80 files while subprocesses died.
if [ "${#missing[@]}" -gt 0 ]; then
  echo "FAIL — ${#missing[@]} of ${#files[@]} arguments cannot be read:"
  printf '  %s\n' "${missing[@]}"
  exit 1
fi

sentences=$(
  for file in "${files[@]}"; do
    paragraphs "$file" \
      | grep -o "[A-Z][^.!?]\{$MIN,$MAX\}[.!?]" \
      | sed 's/  */ /g; s/^ //' \
      | grep -Ev "$NOISE" \
      | awk -v file="$file" '{ print $0 "\t" file }'
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
printf '%s\n' "$sentences" | awk -F'\t' -v repeated="$repeated" '
  BEGIN {
    total = split(repeated, list, "\n")
    for (i = 1; i <= total; i++) if (list[i] != "") wanted[list[i]] = 1
  }
  $1 in wanted && !seen[$0]++ {
    if (!($1 in found)) order[++count] = $1
    found[$1] = found[$1] "\n      " $2
  }
  END {
    for (i = 1; i <= count; i++) printf "  \"%s\"%s\n\n", order[i], found[order[i]]
    printf "%d repeated sentences.\n", count
  }
'

exit 1
