#!/usr/bin/env bash
#
# Fails when the workflow and the README name different gate commands.
#
# Promoted after the same drift twice: a gate reached the README's copy-paste line and not the
# workflow, then a widened scope reached the workflow and not the README. Both times the two files
# each looked correct alone, which is what makes a re-specified command worse than a shared one.
#
# The README is the definition. This checks the copy still matches it.

set -euo pipefail

cd "$(dirname "$0")/.."

readonly WORKFLOW=.github/workflows/gates.yml
readonly README=README.md

# Commands, one per line, whitespace collapsed. The README's line is a single `&&` chain inside the
# first bash fence; the workflow spreads the same commands over `run:` keys.
commands() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]][[:space:]]*/ /g' \
    | grep -v '^$' | sort
}

# The gate chain is the one line that runs the first gate. Selecting by fence order picks the
# install snippet instead, which is how this script failed its own first run.
readme_gates() {
  grep -m1 'bash bin/frontmatter.sh' "$README" | sed 's/ *&& */\n/g' | commands
}

workflow_gates() {
  grep -o '^ *run: bash .*' "$WORKFLOW" | sed 's/^ *run: //' | commands
}

# Two empty selections agree with each other. Lose the README anchor and the workflow's `run:` keys
# and this would print `PASS — 0 gate commands`, which is the failure the skill beside it is named
# for. Refuse instead.
if [ "$(readme_gates | wc -l)" -eq 0 ]; then
  echo "FAIL — found no gate chain in $README."
  echo "  Expected one line running \`bash bin/frontmatter.sh\`. Nothing to compare against."
  exit 1
fi

missing=$(comm -23 <(readme_gates) <(workflow_gates))
extra=$(comm -13 <(readme_gates) <(workflow_gates))

if [ -z "$missing" ] && [ -z "$extra" ]; then
  echo "PASS — $(readme_gates | wc -l | tr -d ' ') gate commands; the workflow matches the README."
  exit 0
fi

echo "FAIL — $WORKFLOW and $README disagree about the gates."
echo

[ -n "$missing" ] && { echo "  In $README, not in the workflow:"; printf '      %s\n' "$missing"; echo; }
[ -n "$extra" ]   && { echo "  In the workflow, not in $README:"; printf '      %s\n' "$extra"; echo; }

echo "The README is the definition. A copy that drifts is worse than no copy — each file reads"
echo "correctly alone, and nobody compares them."
exit 1
