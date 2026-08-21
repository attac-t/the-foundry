#!/bin/bash
# Counters and assertions shared by the suites. Sourced, never run.

passed=0
failed=0

# Record a passing check.
ok() { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }

# Record a failing check.
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

# Note a check this platform cannot answer. Counts as neither, and says why out loud — a skip that
# reads as a pass is how a suite ends up certifying a platform it never tested.
skip() { printf '  skip  %s\n' "$1"; }

# Assert two values match.
is() {
  [ "$2" = "$3" ] && { ok "$1"; return; }
  bad "$1 — want [$3], got [$2]"
}

# Assert a value is anything but the given one.
not() {
  [ "$2" != "$3" ] && { ok "$1"; return; }
  bad "$1 — got [$3], the one answer it must not be"
}

# Assert a string contains the given text.
has() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1 — [$3] missing from [$2]" ;;
  esac
}

# Assert a string does not contain the given text.
lacks() {
  case "$2" in
    *"$3"*) bad "$1 — [$3] should not be in [$2]" ;;
    *)      ok "$1" ;;
  esac
}

# Report the tally, and answer whether it stands. Zero failures over zero
# checks is not a suite that passed but one that never ran, and the
# gate printed PASS for both. A skip counts as neither.
summary() {
  printf '%s — %d passed, %d failed\n' "$1" "$passed" "$failed"

  [ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — %s ran nothing.\n' "$1"; return 1; }
  [ "$failed" -eq 0 ]
}
