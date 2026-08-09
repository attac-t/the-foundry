#!/bin/sh
# UserPromptSubmit: Prompts working memory update

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")

# Protected branch? Point to topic protocol.
BRANCH=$(git branch --show-current 2>/dev/null)
case "$BRANCH" in
  main|master|develop)
    echo "📝 Protected branch. See: ground-topic"
    exit 0
    ;;
esac

echo "📝 Progress? Update \`$MEMORY_DIR/working.md\`. See: ground-recitation"
