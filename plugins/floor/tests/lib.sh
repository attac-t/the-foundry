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

#
# The same check, in a shape the audit can read.
#
# One line per assertion — its result and its name — and only when a caller asks for the file. The
# `--case-smoke` audit binds one mutant to one of these names, and credits a kill only when that name
# flips. Reading whether the suite went red cannot tell that from a break tripping something else.
#
# All four results, never the two that decide. A case that skipped its own assertion proved nothing
# about its mutant, and a reader of passes alone would never see that.
#
# Off by default, so every suite that does not ask for it writes nothing and behaves as it did.
#
record() {
  [ -n "${FOUNDRY_ASSERTIONS:-}" ] || return 0

  printf '%s\t%s\n' "$1" "$2" >> "$FOUNDRY_ASSERTIONS"
}

# Record a passing check.
ok() { passed=$((passed + 1)); record ok "$1"; printf '  ok    %s\n' "$1"; }

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
  record FAIL "$1"
  printf '  FAIL  %s\n' "$1"

  [ -n "${FOUNDRY_FAIL_FAST:-}" ] || return 0
  printf '%s — stopped at the first failure\n' "${suite:-suite}"
  exit 1
}

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
skip() { skipped=$((skipped + 1)); record skip "$1"; printf '  skip  %s\n' "$1"; }

#
# Note a check this platform cannot answer. **Amber, and it needs a predicate.**
#
# `records_exec` is one: NTFS keeps no executable bit, so the check that reads one is unanswerable
# here and answerable in the container. That is not a defect, and failing on it would make the suite
# unrunnable on the machine it is written on.
#
# The separation is the whole point. A setup that broke and a platform that cannot answer read the
# same in a log and mean opposite things.
cannot() { unanswerable=$((unanswerable + 1)); record n/a "$1"; printf '  n/a   %s\n' "$1"; }

# Assert two values match.
is() {
  [ "$2" = "$3" ] && { ok "$1"; return; }
  bad "$1 — want [$3], got [$2]"
}

# Assert a string contains the given text.
has() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1 — [$3] missing from [$2]" ;;
  esac
}

# Assert two values differ.
differs() {
  [ "$2" != "$3" ] && { ok "$1"; return; }
  bad "$1 — both are [$2]"
}

# Assert a string matches an extended regular expression.
matches() {
  printf '%s' "$2" | grep -Eq -- "$3" && { ok "$1"; return; }
  bad "$1 — [$2] does not match /$3/"
}

# Assert a string does not contain the given text.
lacks() {
  case "$2" in
    *"$3"*) bad "$1 — [$3] should not be in [$2]" ;;
    *)      ok "$1" ;;
  esac
}

# Assert a path exists.
exists() {
  [ -e "$2" ] && { ok "$1"; return; }
  bad "$1 — $2 is not there"
}

# Assert a path does not exist.
absent() {
  [ -e "$2" ] && { bad "$1 — $2 should not be there"; return; }
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
