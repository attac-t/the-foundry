#!/bin/bash
#
# Qualitative Test Evaluation Helper
# Lists scenarios for Claude to evaluate in-session
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"

echo "# Qualitative Test Scenarios"
echo ""
echo "Found $(ls -1 "$SCENARIOS_DIR"/*.yml 2>/dev/null | wc -l | tr -d ' ') scenarios"
echo ""

for scenario in "$SCENARIOS_DIR"/*.yml; do
    [ -f "$scenario" ] || continue
    name=$(basename "$scenario" .yml)
    echo "- $name"
done

echo ""
echo "## Evaluation Protocol"
echo ""
echo "For each scenario:"
echo "1. Read the scenario YAML"
echo "2. Load context files from /tmp/craftsman-test-env/"
echo "3. Respond to the trigger as if from a user"
echo "4. Self-evaluate against the 4-criteria rubric"
echo "5. Report: PASS (4/4) or FAIL (n/4)"
echo ""
echo "## Rubric Criteria"
echo ""
echo "| # | Criterion | Question |"
echo "|---|-----------|----------|"
echo "| 1 | right_abstraction | Did I propose the correct pattern? |"
echo "| 2 | project_conventions | Did I follow existing patterns? |"
echo "| 3 | anti_pattern_pushback | Did I redirect bad practices? |"
echo "| 4 | correct_namespace | Did I place code correctly? |"
