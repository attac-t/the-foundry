#!/bin/bash
#
# Every floor break whose `sed` no longer changes its file, named in seconds. #1169.
#
# **A break that changes nothing proves nothing**, and the audit said so only on that break's turn,
# hours in. This replays each declaration in `tests/run.sh` with drivers that only apply and
# compare, so it reads what the audit reads and keeps no list of its own.
#
# Definitions, and a main that runs only when this file is run. `tests/run.sh` sources it for
# `break_tags`, and asks it before any break runs.
#
#   bash tests/applies.sh [<plugin root>]
#
# Exit: 0 every break changes its file. 1 one does not, or one could not be replayed.
#       2 no plugin at the root named.

main() {
  local root work named
  root=$(cd "${1:-$(dirname "$0")/..}" 2>/dev/null && pwd) \
    || { printf 'applies — no plugin at [%s]\n' "${1:-}" >&2; exit 2; }
  work=$(mktemp -d "${TMPDIR:-/tmp}/applies-XXXXXX") || exit 2
  trap 'rm -rf "$work"' EXIT

  named=$(breaks_that_change_nothing "$root" "$work")
  [ -n "$named" ] || { printf 'applies — each of %s breaks changes its file\n' "$(sed_breaks_in "$work")"; exit 0; }

  printf '%s\n' "$named"
  printf 'applies — %s would prove nothing\n' "$(printf '%s\n' "$named" | grep -c .)"
  exit 1
}

#
# Each break that cannot prove anything, one line each: a `sed` that fails, prints nothing or changes
# nothing, and a tag `break_tags` reads that no replay printed. The replay stays in `$2/replayed`.
breaks_that_change_nothing() {
  local root="$1" work="$2" kind tag mutation file
  mkdir -p "$work" || return 1
  replayed "$root/tests/run.sh" > "$work/replayed"

  while IFS=$'\037' read -r kind tag mutation file; do
    [ "$kind" = sed ] || continue
    why_it_proves_nothing "$root" "$tag" "$mutation" "$file" "$work/out"
  done < "$work/replayed"

  tags_never_replayed "$root/tests/run.sh" "$work"
}

sed_breaks_in() { grep -c '^sed' "$1/replayed"; }

# Nothing when a break's `sed` changes its file, else the way it does not.
why_it_proves_nothing() {
  sed "$3" "$1/$4" > "$5" 2>/dev/null || { printf '%s — its sed fails on %s\n' "$2" "$4"; return; }
  [ -s "$5" ] || { printf '%s — its sed prints nothing from %s\n' "$2" "$4"; return; }
  cmp -s "$5" "$1/$4" || return 0

  printf '%s — its sed changes nothing in %s\n' "$2" "$4"
}

#
# A tag the audit would drive that no replay printed. The shell could not read that declaration, so
# what it breaks is unknown, and it is named rather than passed.
tags_never_replayed() {
  cut -d$'\037' -f2 "$2/replayed" | LC_ALL=C sort -u > "$2/replayed-tags"
  break_tags "$1" | LC_ALL=C sort -u | LC_ALL=C comm -23 - "$2/replayed-tags" > "$2/never"

  while IFS= read -r tag; do printf '%s — its declaration could not be replayed\n' "$tag"; done < "$2/never"
}

# A tool finds a break by its tag and drives the first it meets, so a shared tag hides a break.
# Five were shared until #1106, and on 29 September a break reported as lived had never run.
#
# A tag is the first word after a break's description, on that line or the next. A break declared
# behind a guard is read too, and its guard's own quotes are never taken for the description.
break_tags() {
  awk '
    held { print $1; held = 0; next }

    /(^|&&|\|\||;)[ \t]*wreck[a-z_]*[ \t]+"/ {
      sub(/^.*wreck[a-z_]*[ \t]+"[^"]*"[ \t]*/, "")
      if ($0 == "\\") { held = 1; next }
      print $1
    }' "$1"
}

#
# Each declaration, from its driver word to the end of its continuation lines, then a line holding
# only a record separator. A declaration is found where `break_tags` finds one.
declarations_in() {
  awk '
    held { statement = statement "\n" $0; if ($0 !~ /\\$/) { print statement; print "\036"; held = 0 }; next }

    match($0, /(^|&&|\|\||;)[ \t]*wreck[a-z_]*[ \t]+"/) {
      statement = substr($0, RSTART)
      sub(/^(&&|\|\||;)?[ \t]*/, "", statement)
      if (statement ~ /\\$/) { held = 1; next }
      print statement; print "\036"
    }' "$1"
}

#
# The kind, tag, `sed` and file each declaration hands its driver. **Read by a bash started with no
# variable of its caller's, under `-u`**, so a declaration leaning on the audit's state fails loudly.
replayed() {
  declarations_in "$1" | env -i "$BASH" --noprofile --norc -u "${BASH_SOURCE[0]}" replay
}

# Each declaration alone, in a subshell with no positional parameter. A driver here prints what it
# was handed, and breaks nothing.
replay_each() {
  wreck_runner() { printf 'sed\037%s\037%s\037%s\n' "$2" "$3" "${4:-bin/run.sh}"; }
  wreck_join()   { printf 'sed\037%s\037%s\037%s\n' "$2" "$3" "${4:-bin/join.sh}"; }
  wreck_adopt()  { printf 'sed\037%s\037%s\037%s\n' "$2" "$3" bin/adopt.sh; }
  wreck()        { printf 'function\037%s\037\037\n' "$2"; }

  local applies_statement='' line
  while IFS= read -r line; do
    [ "$line" = $'\036' ] || { applies_statement+="$line"$'\n'; continue; }
    ( unset line; set --; eval "$applies_statement" ) 2>/dev/null
    applies_statement=''
  done
}

# Sourced, this file is definitions alone. Run, it checks the plugin, or replays for `replayed`.
[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

# The replay's `-u` is the flag `replayed` starts its bash with, and nothing else, so it is one guard.
[ "${1:-}" = replay ] && { replay_each; exit 0; }

set -u
main "$@"
