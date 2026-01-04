#!/bin/bash
# UserPromptSubmit: Prompts working memory update or topic protocol
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Protected branch? Point to topic protocol.
BRANCH=$(git branch --show-current 2>/dev/null)
[[ "$BRANCH" =~ ^(main|master|develop)$ ]] && cat <<EOF && exit 0
---
**Recite** (ground-recitation protocol)
→ ground-topic protocol
EOF

# Feature branch: remind about memory.
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")
cat <<EOF
---
**Recite** (ground-recitation protocol)
If you made progress or encountered failures:
→ UPDATE \`$MEMORY_DIR/working.md\`
EOF
