#!/usr/bin/env bash
#
# Fails when the workflow and the contributing guide name different gate commands.
#
# A command specified in two files drifts, and each copy reads correctly alone, so nobody compares
# them. CONTRIBUTING.md is the definition; this checks that the copy still matches.

set -euo pipefail

cd "$(dirname "$0")/.."

readonly WORKFLOW=.github/workflows/gates.yml
readonly DEFINITION=CONTRIBUTING.md

# One command per line, trimmed, inner whitespace collapsed, sorted. Sorting means a reordered
# workflow still agrees — order is not what drifts.
tidy() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]][[:space:]]*/ /g' | grep -v '^$' | sort
}

# Anchor on the line that runs the first gate, not on fence order.
gates_declared() {
  grep -m1 'bash bin/frontmatter.sh' "$DEFINITION" | sed 's/ *&& */\n/g' | tidy
}

gates_in_workflow() {
  grep -o '^ *run: bash .*' "$WORKFLOW" | sed 's/^ *run: //' | tidy
}

report() {
  local heading=$1 commands=$2
  [ -n "$commands" ] || return 0
  echo "  $heading"
  printf '      %s\n' "$commands"
  echo
}

# Two empty selections agree with each other. Lose the anchor and this would print "0 gate commands"
# and call it a pass — the failure `kernel:ground-evidence` is named for.
if [ -z "$(gates_declared)" ]; then
  echo "FAIL — found no gate chain in $DEFINITION."
  echo "  Expected one line running \`bash bin/frontmatter.sh\`. Nothing to compare against."
  exit 1
fi

only_declared=$(comm -23 <(gates_declared) <(gates_in_workflow))
only_in_workflow=$(comm -13 <(gates_declared) <(gates_in_workflow))

if [ -z "$only_declared" ] && [ -z "$only_in_workflow" ]; then
  echo "PASS — $(gates_declared | wc -l | tr -d ' ') gate commands; the workflow matches $DEFINITION."
  exit 0
fi

echo "FAIL — $WORKFLOW and $DEFINITION disagree about the gates."
echo
report "In $DEFINITION, missing from the workflow:" "$only_declared"
report "In the workflow, missing from $DEFINITION:" "$only_in_workflow"
echo "$DEFINITION is the definition. A copy that drifts is worse than no copy, because each file"
echo "reads correctly alone and nobody compares them."
exit 1
