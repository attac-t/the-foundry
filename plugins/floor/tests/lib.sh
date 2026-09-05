#!/bin/bash
# Counters and assertions shared by floor's suites. Sourced, never run.
#
# kernel and signal each carry a file like this one, and none of the three borrows from the others
# on purpose: a plugin is installed on its own, so anything it needs to prove itself has to sit
# inside it. A shared helper one directory up would make this suite unrunnable for anyone who
# installed only floor.

passed=0
failed=0
skipped=0
unanswerable=0

# Record a passing check.
ok() { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }

#
# The name of the check that failed, for the audit that groups breaks by it.
#
# **A name is not a message.** The helpers below append what they wanted and what they got, and that
# tail holds a tmp path with a pid in it. An audit reading the printed line would have to cut the
# name back out at the em dash — and names here carry em dashes of their own, so the cut dropped the
# script each one exists to name and read two scripts as a single check.
#
# So the name is handed over rather than parsed back. A `bad` called with no name records its whole
# message, which is that check's identity when there is no other.
#
# Off unless a caller names a file, so every suite prints exactly what it printed before.
#
name_the_check() {
  [ -n "${FOUNDRY_CHECK:-}" ] || return 0
  printf '%s\n' "$1" >> "$FOUNDRY_CHECK"
}

#
# Record a failing check.
#
# `FOUNDRY_FAIL_FAST` leaves at the first one. The audit runs this suite once per break and reads
# only whether it went red — an answer settled by the first failure, after which every remaining
# assertion is paid for and discarded. A person reading a suite wants the tally; the audit never
# does, so only the audit sets it.
#
bad() {
  failed=$((failed + 1))
  name_the_check "${2:-$1}"
  printf '  FAIL  %s\n' "$1"

  [ -n "${FOUNDRY_FAIL_FAST:-}" ] || return 0
  printf '%s — stopped at the first failure\n' "${suite:-suite}"
  exit 1
}

#
# A setup that would not build. **Red, like any other, and not a check.**
#
# The suite has to go red — a check that could not run proved nothing. But the audit asks which
# check killed a break, and a fixture that would not build is not one. Recorded under `bad` it would
# read as a rule the break broke, and the break would pass on a red it never earned.
#
# The reader sees the same line either way. Only the name changes.
#
broke() { bad "$1" 'a setup that would not build'; }

#
# Note a check that did not run because its setup failed. **Red.**
#
# It used to be amber. Two tests reused a fixture name another test already owned, inherited that
# test's repository, and skipped on the state they found. Both printed their reason into a 700-line
# log, the tally said green, and the gate said PASS. Nobody read the middle.
#
# So a skip fails the suite now. A check that did not run has proved nothing, and 160 of these say
# "git could not make a repo here" — on a machine where that were true, a green suite would be a lie
# about every one of them.
skip() { skipped=$((skipped + 1)); printf '  skip  %s\n' "$1"; }

#
# Note a check this platform cannot answer. **Amber, and it needs a predicate.**
#
# `records_exec` is one: NTFS keeps no executable bit, so the check that reads one is unanswerable
# here and answerable in the container. That is not a defect, and failing on it would make the suite
# unrunnable on the machine it is written on.
#
# The separation is the whole point. A setup that broke and a platform that cannot answer read the
# same in a log and mean opposite things.
cannot() { unanswerable=$((unanswerable + 1)); printf '  n/a   %s\n' "$1"; }

# Assert two values match.
is() {
  [ "$2" = "$3" ] && { ok "$1"; return; }
  bad "$1 — want [$3], got [$2]" "$1"
}

# Assert a string contains the given text.
has() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1 — [$3] missing from [$2]" "$1" ;;
  esac
}

# Assert two values differ.
differs() {
  [ "$2" != "$3" ] && { ok "$1"; return; }
  bad "$1 — both are [$2]" "$1"
}

# Assert a string matches an extended regular expression.
matches() {
  printf '%s' "$2" | grep -Eq -- "$3" && { ok "$1"; return; }
  bad "$1 — [$2] does not match /$3/" "$1"
}

# Assert a string does not contain the given text.
lacks() {
  case "$2" in
    *"$3"*) bad "$1 — [$3] should not be in [$2]" "$1" ;;
    *)      ok "$1" ;;
  esac
}

# Assert a path exists.
exists() {
  [ -e "$2" ] && { ok "$1"; return; }
  bad "$1 — $2 is not there" "$1"
}

# Assert a path does not exist.
absent() {
  [ -e "$2" ] && { bad "$1 — $2 should not be there" "$1"; return; }
  ok "$1"
}

#
# Report the tally, and answer whether it stands.
#
# Zero failures over zero checks is not a suite that passed but one that never ran, and the gate
# printed PASS for both.
#
# Four numbers, because three of them are how a suite lies. A skip is red. A count this platform
# could not answer is printed so nobody reads the passes as the whole set.
#
summary() {
  printf '%s — %d passed, %d failed, %d skipped, %d n/a\n' \
         "$1" "$passed" "$failed" "$skipped" "$unanswerable"

  [ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — %s ran nothing.\n' "$1"; return 1; }

  [ "$skipped" -eq 0 ] || {
    printf 'FAIL — %s skipped %d. A check that did not run proved nothing.\n' "$1" "$skipped"
    return 1
  }

  [ "$failed" -eq 0 ]
}
