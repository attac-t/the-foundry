#!/bin/bash
#
# A case run alone, `model.sh` with every other case call skipped, and a runner break decided at its
# killer's case that way before the whole suite runs for it.
#
# Definitions only. `tests/model.sh` sources this for `--only`, and `tests/run.sh` to decide each
# runner break. The model suite drives every rule here from the copy beside the runner under test,
# so a break of any one of them goes red there. A line that ran at the top of this file would run
# inside every suite that sources it. #1112.
#

#
# The cases of a suite: each function it defines at column 0 and calls once, bare, at column 0.
#
# **Once, because a helper is called that way too.** `restore_selection` is called bare four times,
# and a tool that skipped it as a case left two checks reading a selection nobody had put back.
#
# A heredoc body is text, never a call. Its opener is read the way `bin/taper.awk` reads one, and a
# `<<` inside a quoted string still opens one falsely, as it does there.
#
# `list` prints each case in call order. `only` prints the suite with every call of a case not named
# made `:`, and refuses a name that is no case before it prints a line.
#
cases_of() {
  local mode=$1 suite=$2
  shift 2

  awk -v mode="$mode" -v named=" $* " '
    FNR == 1 { pass++; heredoc = "" }
    FNR == 1 && pass == 2 && mode == "only" && !every_name_is_a_case() { exit 2 }

    heredoc != "" { if (pass == 2 && mode == "only") print; if (closes($0, heredoc)) heredoc = ""; next }

    pass == 1 && /^[a-z_][a-z0-9_]*\(\) *\{/ { name = $0; sub(/\(\).*/, "", name); defined[name] = 1 }
    pass == 1 && /^[a-z_][a-z0-9_]*$/        { calls[$0]++ }

    pass == 2 && mode == "list" && is_case($0)                   { print; next }
    pass == 2 && mode == "only" && is_case($0) && !is_named($0) { print ":"; next }
    pass == 2 && mode == "only"                                   { print }

    { heredoc = opener($0) }

    function is_case(line)  { return (line in defined) && calls[line] == 1 }
    function is_named(line) { return index(named, " " line " ") > 0 }

    function every_name_is_a_case(   n, all, i, fine) {
      fine = 1
      n = split(named, all, " ")
      for (i = 1; i <= n; i++) {
        if (is_case(all[i])) continue
        printf "--only: %s is no case of %s\n", all[i], FILENAME > "/dev/stderr"
        fine = 0
      }
      return fine
    }

    function opener(line,   word) {
      if (line ~ /^[ \t]*#/ || line ~ /<<</) return ""
      if (line !~ /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*/) return ""
      word = line
      sub(/^.*<<-?[ \t]*/, "", word)
      sub(/^["\047]/, "", word)
      sub(/[^A-Za-z0-9_].*$/, "", word)
      return word
    }

    function closes(line, word) { sub(/^[ \t]*/, "", line); return line == word }
  ' "$suite" "$suite"
}

cases_in() { cases_of list "$1"; }

# The suite with every case not named made `:`. Naming nothing is refused too: that suite would run
# every top-level check and no case, and read as clean.
only_these() {
  local suite=$1
  shift
  [ "$#" -gt 0 ] || { printf -- '--only: name at least one case\n' >&2; return 2; }

  cases_of only "$suite" "$@"
}

#
# One runner break, decided. It answers as `model_caught` does, 0 caught, 1 missed and 2 the clock,
# and leaves `how` saying what decided it:
#
#   alone    its case went red alone
#   whole    the whole suite: it had no row, its case failed clean alone, or its case missed it
#   sampled  red alone, and the whole suite, run for the sample, went red too
#   split    red alone, and the sample's whole suite missed it: an earlier case's state hid it
#
# The caller names two paths and supplies two runs:
#
#   killer_cases           the table: a break's tag, a tab, its killer's case
#   alone_records          the directory each case's clean alone run is kept in
#   run_alone <case> <s>   that case alone against the mutant under s seconds, as `bounded` answers
#   caught_whole           the whole suite against the mutant, as `model_caught` answers
#
# `sampled` as the second argument is the sample choosing this break.
#
decide_a_break() {
  local killer_case
  how=whole
  killer_case=$(row_for "$1")

  [ -n "$killer_case" ]       || { caught_whole; return; }
  clean_alone "$killer_case"  || { caught_whole; return; }
  caught_alone "$killer_case" || { caught_whole; return; }

  how=alone
  [ "${2:-}" = sampled ] || return 0

  how=sampled
  caught_whole
  read_the_sample "$?"
}

# A break's killer's case, from its tag's row, or nothing when the table holds none.
row_for() { awk -F'\t' -v tag="$1" '$1 == tag { print $2; exit }' "$killer_cases" 2>/dev/null; }

#
# The case alone against the mutant. Its passing is a miss, and so is the clock: both hand the break
# to the whole suite, and neither is a `MOOT`.
#
caught_alone() {
  local said
  run_alone "$1" "$(alone_deadline "$(took_alone "$1")")"
  said=$?

  [ "$said" -eq 0 ] && return 1
  [ "$said" -eq 2 ] && return 1
  return 0
}

# Five clean alone runs, and never under two minutes: the whole suite's rule, at one case's size.
alone_deadline() {
  local seconds=$(( ${1:-0} * 5 ))
  [ "$seconds" -lt 120 ] && seconds=120
  printf '%s' "$seconds"
}

# The sample's whole run, read. A miss there is the split the sample exists to find, and it answers 1
# so the break is red however `how` is worded.
read_the_sample() {
  [ "$1" -eq 1 ] || return "$1"
  how=split
  return 1
}

#
# Each case's clean alone run: its exit and its seconds, one file a case. Kept once an audit, and read
# by every break its row names, so a case that failed clean alone hands them all to the whole suite.
#
keep_the_clean_run() { printf '%s %s\n' "$2" "$3" > "$alone_records/$1"; }
clean_alone()        { [ "$(clean_run_field "$1" 1)" = 0 ]; }
took_alone()         { clean_run_field "$1" 2; }
clean_run_field()    { awk -v field="$2" '{ print $field; exit }' "$alone_records/$1" 2>/dev/null; }

#
# Run what it is handed, and keep its status and seconds as that case's clean alone run. The status
# is read straight off the run, so nothing between the two can answer in its place. Kept wrong, a
# case red on its own would read clean, and every break it decides would read `ok`.
#
keep_what_it_answered() {
  local named=$1 began said
  shift
  began=$(date +%s)
  "$@"
  said=$?
  keep_the_clean_run "$named" "$said" "$(( $(date +%s) - began ))"
}

#
# The sample. One slot in ten runs the whole suite as well, and the tree's commit says which tenth, so
# over many trees every slot takes a turn. A break caught alone that no sample ever reaches is a mask
# nobody looked for.
#
sample_tenth_of()       { printf '%s' "$1" | cksum | awk '{ print $1 % 10 }'; }
chosen_for_the_sample() { [ $(( ($1 + $2) % 10 )) -eq 0 ]; }

# A sample of none is red. It looked for no mask, and it reads exactly like one that found none.
say_the_sample() {
  printf 'audit — %s of the %s breaks caught alone ran the whole suite too, as the sample\n' "$1" "$2"
  [ "$1" -gt 0 ]
}
