#!/usr/bin/env bash
#
# The oracle for bin/judges.sh. One row per behaviour, each naming the status it wants and, where
# the subject has more than one way to refuse, the refusal it means.
#
# Exact statuses, never "non-zero": drafted loosely, three rows passed against a script that did not
# exist, because 127 is not zero. A gate satisfied by the absence of the thing it gates is the empty
# green gate this suite exists to prevent.
#
# Usage: bash plugins/panel/tests/judges.test.sh
# Exit   0 every assertion held · 1 one did not, or none ran

set -uo pipefail

cd "$(dirname "$0")/../../.."
source plugins/panel/tests/harness.sh

readonly JUDGES=plugins/panel/bin/judges.sh
readonly FIXTURES=plugins/panel/tests/fixtures
readonly LOCAL_AGENTS=plugins/panel/tests/agents

# it <behaviour> <wanted status> <fixture> <expected reason> [agent directory]
it() {
  local behaviour=$1 wanted=$2 fixture=$3 reason=$4 agents=${5:-}

  # A fixture git never tracked makes its row pass on a fresh clone for the wrong reason.
  if [ ! -e "$fixture" ]; then
    refuse "$behaviour" "no fixture at $fixture"
    return
  fi

  if [ -n "$agents" ]; then
    PANEL_AGENT_PATH=$agents attempt bash "$JUDGES" "$fixture"
  else
    attempt bash "$JUDGES" "$fixture"
  fi

  judge "$behaviour" "$wanted" "$status" "$output" "$reason"
}

# The one row whose fixture must be missing. Inverted rather than exempted: exempting every `usage`
# row would unguard two fixtures that do exist.
it_missing() {
  local behaviour=$1 wanted=$2 fixture=$3 reason=$4

  if [ -e "$fixture" ]; then
    refuse "$behaviour" "$fixture exists; the row tests nothing"
    return
  fi

  attempt bash "$JUDGES" "$fixture"
  judge "$behaviour" "$wanted" "$status" "$output" "$reason"
}

echo "judges.sh"
echo

it "accepts a judge whose tools are restricted"       0 "$FIXTURES/judge-restricted.md"     "none can write"
it "rejects a judge that can write"                   1 "$FIXTURES/judge-can-write.md"      "declares no \`tools:\`" "$LOCAL_AGENTS"
it "rejects a writer seated on a later gate"          1 "$FIXTURES/writer-on-gate-2.md"     "declares no \`tools:\`"
it "rejects a charter that seats only an author"      1 "$FIXTURES/no-judges.md"            "Only \`author:\` is seated"
it "rejects a judge that does not exist"              1 "$FIXTURES/ghost-judge.md"          "no agent of that name"
it "seats several gates, and one judge repeatedly"    0 "$FIXTURES/two-gates.md"            "2 gates"
# Nothing here may assert 0 while naming an agent from another plugin: panel installs standalone,
# so a suite needing pest present fails for most of the people who run it. That a stack plugin
# seats an eligible judge is a fact about the monorepo, and the repo's own gate chain asserts it.

# The pin, the merge, and the fence — none of which the first seven fixtures could see.
it "will not resolve a pin to another plugin's agent" 1 "$FIXTURES/wrong-plugin.md"         "no agent of that name"
it "keeps every judge when a gate is listed twice"    1 "$FIXTURES/repeated-label.md"       "declares no \`tools:\`"
it "parses the section, not the fenced example"       1 "$FIXTURES/fenced-decoy.md"         "declares no \`tools:\`" "$LOCAL_AGENTS"

# Eligibility must not depend on another plugin's agent names. judge-can-write used to name
# kernel:architect; with kernel absent it still exited 1, through the unresolved branch rather than
# Law 4 — a row passing for a reason it was not written to test. The reason assertion found it.
it "accepts a restricted local agent"                 0 "$FIXTURES/local-reader.md"         "none can write"        "$LOCAL_AGENTS"

# Usage is a third outcome, not a flavour of failure.
it "refuses a charter with no panel section"          2 "$FIXTURES/no-panel-section.md"     "no \`## Panel\` section"
it "refuses a charter with two panel sections"        2 "$FIXTURES/two-panel-sections.md"   "which one governs"
it_missing "refuses a charter that is not there"      2 "$FIXTURES/nothing-of-this-name.md" "no charter at"

summary "Law 4 holds for every seat this charter names."
