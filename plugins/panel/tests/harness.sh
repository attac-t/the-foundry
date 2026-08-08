#!/usr/bin/env bash
#
# Scoring, shared by the suites. Each suite knows how to invoke its own subject; none of them should
# know how to keep score.
#
# Source it, call `it` rows, end with `summary`.

passed=0
failed=0

succeed() {
  passed=$((passed + 1))
  printf '  ok    %s\n' "$1"
}

refuse() {
  failed=$((failed + 1))
  printf '  FAIL  %s — %s\n' "$1" "$2"
}

# Capture, then test. `$?` after a pipeline belongs to the last command in it, and a check read
# through `| tail -1` reports tail's success forever.
attempt() {
  output=$("$@" 2>&1)
  status=$?
}

# judge <behaviour> <wanted status> <actual status> [output] [expected reason]
#
# A status says something went wrong, never which thing. Where a subject has several refusals, the
# row names a fragment of the one it means, and a right-status-wrong-reason result gets its own
# report rather than a pass.
judge() {
  local behaviour=$1 wanted=$2 actual=$3 output=${4:-} reason=${5:-}

  if [ "$actual" != "$wanted" ]; then
    refuse "$behaviour" "wanted $wanted, got $actual"
    return
  fi

  if [ -n "$reason" ] && ! printf '%s' "$output" | grep -qF "$reason"; then
    refuse "$behaviour" "exit $actual for the wrong reason; wanted \"$reason\""
    return
  fi

  succeed "$behaviour"
}

# summary <what the suite proves>
#
# A suite that collects nothing still exits 0 unless it is asked to account for itself.
summary() {
  local total=$((passed + failed))

  echo

  if [ "$total" -eq 0 ]; then
    echo "FAIL — no assertions ran. An empty suite is not a passing one."
    exit 1
  fi

  if [ "$failed" -gt 0 ]; then
    echo "FAIL — $failed of $total assertions did not hold."
    exit 1
  fi

  echo "PASS — $total assertions; $1"
}
