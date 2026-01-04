#!/bin/bash
# SessionStart: Topic branch check and grounding
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")

# Detect current branch
BRANCH=""
if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
fi

# Extract branch name from memory path for display
TOPIC=$(echo "$MEMORY_DIR" | sed 's|.*/||')
[ "$TOPIC" = "memory" ] && TOPIC="(no branch)"

echo "---"
echo "📍 **Topic**: \`$TOPIC\`"
echo "💾 **Memory**: \`$MEMORY_DIR/\`"
echo ""

# Check if on protected branch
if [ -n "$BRANCH" ]; then
    case "$BRANCH" in
        main|master|develop)
            echo "⚠️  **WARNING**: You are on the \`$BRANCH\` branch."
            echo ""
            echo "**The Protocol**: One topic, one branch, one memory."
            echo ""
            echo "**Action Required**: Create a topic branch before proceeding:"
            echo "\`\`\`bash"
            echo "git checkout -b feat/your-topic-name"
            echo "\`\`\`"
            echo ""
            echo "Or if continuing existing work:"
            echo "\`\`\`bash"
            echo "git checkout <existing-branch>"
            echo "\`\`\`"
            echo "---"
            ;;
    esac
fi
