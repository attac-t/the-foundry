#!/bin/bash
# SessionStart: Loads ground philosophy (foundational principles)
#
# These are non-negotiable. They shape every decision.
#
# Purpose: Establish the philosophy before any work begins.

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "---"
echo "**Ground Philosophy** (non-negotiable)"
echo ""

for skill in "$PLUGIN_DIR"/skills/ground/*/SKILL.md; do
    if [ -f "$skill" ]; then
        name=$(grep '^name:' "$skill" | sed 's/name: //')
        desc=$(grep '^description:' "$skill" | sed 's/description: //')
        echo "- **$name**: $desc"
    fi
done

echo ""
echo "Consult: \`skills/ground/\`"
