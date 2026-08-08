#!/usr/bin/env bash
#
# Fails when the workflow and the README name different gate commands.
#
# A command specified in two files drifts, and each copy reads correctly alone, so nobody compares
# them. The README is the definition; this checks that the copy still matches.

set -euo pipefail

cd "$(dirname "$0")/.."

readonly WORKFLOW=.github/workflows/gates.yml
readonly README=README.md

# One command per line, trimmed, inner whitespace collapsed, sorted. Sorting means a reordered
# workflow still agrees — order is not what drifts.
tidy() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]][[:space:]]*/ /g' | grep -v '^$' | sort
}

# Anchor on the line that runs the first gate. Selecting by fence order picks the install snippet.
gates_in_readme() {
  grep -m1 'bash bin/frontmatter.sh' "$README" | sed 's/ *&& */\n/g' | tidy
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

# Two empty selections agree with each other. Lose the README anchor and this would print
# "0 gate commands" and call it a pass — the failure `kernel:ground-evidence` is named for.
if [ -z "$(gates_in_readme)" ]; then
  echo "FAIL — found no gate chain in $README."
  echo "  Expected one line running \`bash bin/frontmatter.sh\`. Nothing to compare against."
  exit 1
fi

only_in_readme=$(comm -23 <(gates_in_readme) <(gates_in_workflow))
only_in_workflow=$(comm -13 <(gates_in_readme) <(gates_in_workflow))

if [ -z "$only_in_readme" ] && [ -z "$only_in_workflow" ]; then
  echo "PASS — $(gates_in_readme | wc -l | tr -d ' ') gate commands; the workflow matches the README."
  exit 0
fi

echo "FAIL — $WORKFLOW and $README disagree about the gates."
echo
report "In $README, missing from the workflow:" "$only_in_readme"
report "In the workflow, missing from $README:" "$only_in_workflow"
echo "The README is the definition. A copy that drifts is worse than no copy, because each file"
echo "reads correctly alone and nobody compares them."
exit 1
