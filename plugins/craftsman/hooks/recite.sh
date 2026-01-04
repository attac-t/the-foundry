#!/bin/bash
# UserPromptSubmit: Prompts working memory update
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")

cat <<EOF
---
**Recite** (ground-recitation protocol)
If you made progress or encountered failures:
→ UPDATE \`$MEMORY_DIR/working.md\`
EOF
