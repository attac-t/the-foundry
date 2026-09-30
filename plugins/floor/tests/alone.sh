#!/bin/bash
#
# A case run alone: `model.sh` with every other case call skipped, and nothing else changed.
#
# Definitions only. `tests/model.sh` sources this for `--only`. A line that ran at the top of it would
# run inside every suite that sources it. #1112.
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
