#!/bin/bash
# UserPromptSubmit: Prompts working memory update

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")

# Protected branch? Point to topic protocol.
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    echo "📝 Protected branch. See: ground-topic"
    exit 0
fi

echo "📝 Progress? Update \`$MEMORY_DIR/working.md\`. See: ground-recitation"
