#!/usr/bin/env bash
#
# The oracle for bin/judges.sh. One row per behaviour, each asserting an exact exit code.
#
# Exact codes, never "non-zero": drafted loosely, three assertions passed against a script that did
# not exist, because 127 is non-zero. A gate satisfied by the absence of the thing it gates is the
# empty green gate this suite exists to prevent.
#
# Usage: bash plugins/panel/tests/judges.test.sh
# Exit   0 every assertion held · 1 one did not, or none ran

set -uo pipefail

cd "$(dirname "$0")/../../.."

readonly JUDGES=plugins/panel/bin/judges.sh
readonly FIXTURES=plugins/panel/tests/fixtures
readonly LOCAL=plugins/panel/tests/agents

pass=0 fail=0

# it <behaviour> <expected exit> <fixture> [agent path]
# The one row whose fixture is meant to be absent. Everything else must exist: a fixture git never
# tracked makes its assertion pass on a fresh clone for the wrong reason, and exempting every
# `want=2` row would unguard two that do exist.
absent() {
  local behaviour="$1" want="$2" fixture="$3" got
  if [ -e "$fixture" ]; then
    fail=$((fail + 1)); printf '  FAIL  %s — %s exists; the row tests nothing\n' "$behaviour" "$fixture"
    return 0
  fi
  bash "$JUDGES" "$fixture" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$behaviour"
    return 0
  fi
  fail=$((fail + 1)); printf '  FAIL  %s — wanted %s, got %s\n' "$behaviour" "$want" "$got"
}

it() {
  local behaviour="$1" want="$2" fixture="$3" agents="${4:-}" got
  if [ ! -e "$fixture" ]; then
    fail=$((fail + 1)); printf '  FAIL  %s — no fixture at %s\n' "$behaviour" "$fixture"
    return 0
  fi
  if [ -n "$agents" ]; then
    PANEL_AGENT_PATH="$agents" bash "$JUDGES" "$fixture" >/dev/null 2>&1
  else
    bash "$JUDGES" "$fixture" >/dev/null 2>&1
  fi
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$behaviour"
  else
    fail=$((fail + 1)); printf '  FAIL  %s — wanted %s, got %s\n' "$behaviour" "$want" "$got"
  fi
}

echo "judges.sh"
echo

it "accepts a judge whose tools are restricted"      0 "$FIXTURES/judge-restricted.md"
it "rejects a judge that can write"                  1 "$FIXTURES/judge-can-write.md"
it "rejects a writer seated on a later gate"         1 "$FIXTURES/writer-on-gate-2.md"
it "rejects a charter that seats only an author"     1 "$FIXTURES/no-judges.md"
it "rejects a judge that does not exist"             1 "$FIXTURES/ghost-judge.md"
it "seats several gates, and one judge repeatedly"   0 "$FIXTURES/two-gates.md"

# Nothing here may assert 0 while naming an agent from another plugin. Panel installs standalone,
# so a suite that needs pest present is a suite that fails for most of the people who run it.
# `pest-critic.md` ships as a fixture and is asserted by the *repo's* gate chain instead: that a
# stack plugin seats an eligible judge is a fact about this monorepo, not about panel.

# The pin, the merge, and the fence — none of which the first seven fixtures could see.
it "will not resolve a pin to another plugin's agent" 1 "$FIXTURES/wrong-plugin.md"
it "keeps every judge when a gate is listed twice"    1 "$FIXTURES/repeated-label.md"
it "parses the section, not the fenced example"       1 "$FIXTURES/fenced-decoy.md" "$LOCAL"

# Eligibility must not depend on another plugin's agent names.
it "rejects an unrestricted local agent"             1 "$FIXTURES/local-writer.md" "$LOCAL"
it "accepts a restricted local agent"                0 "$FIXTURES/local-reader.md" "$LOCAL"

# Usage is a third outcome, not a flavour of failure.
it "refuses a charter with no panel section"         2 "$FIXTURES/no-panel-section.md"
it "refuses a charter with two panel sections"       2 "$FIXTURES/two-panel-sections.md"
absent "refuses a charter that is not there"         2 "$FIXTURES/nothing-of-this-name.md"

echo
total=$((pass + fail))

# A suite that collects nothing still exits 0 unless it is asked to account for itself.
if [ "$total" -eq 0 ]; then
  echo "FAIL — no assertions ran. An empty suite is not a passing one."
  exit 1
fi

if [ "$fail" -gt 0 ]; then
  echo "FAIL — $fail of $total assertions did not hold."
  exit 1
fi

echo "PASS — $total assertions; Law 4 holds for every seat this charter names."
