#!/bin/bash
# Counters and assertions shared by floor's suites. Sourced, never run.
#
# kernel and signal each carry a file like this one, and none of the three borrows from the others
# on purpose: a plugin is installed on its own, so anything it needs to prove itself has to sit
# inside it. A shared helper one directory up would make this suite unrunnable for anyone who
# installed only floor.

passed=0
failed=0

# Record a passing check.
ok() { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }

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
  printf '  FAIL  %s\n' "$1"

  [ -n "${FOUNDRY_FAIL_FAST:-}" ] || return 0
  printf '%s — stopped at the first failure\n' "${suite:-suite}"
  exit 1
}

# Note a check this platform cannot answer. Counts as neither, and says why out loud — a skip that
# reads as a pass is how a suite ends up certifying a platform it never tested.
skip() { printf '  skip  %s\n' "$1"; }

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

# Report the tally, and answer whether it stands. Zero failures over zero
# checks is not a suite that passed but one that never ran, and the
# gate printed PASS for both. A skip counts as neither.
summary() {
  printf '%s — %d passed, %d failed\n' "$1" "$passed" "$failed"

  [ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — %s ran nothing.\n' "$1"; return 1; }
  [ "$failed" -eq 0 ]
}
