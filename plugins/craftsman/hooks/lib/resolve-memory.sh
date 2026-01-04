#!/bin/bash
# Resolves the branch-aware memory directory path.
# Outputs: .claude/memory/<branch>/ or .claude/memory/ (fallback)

MEMORY_BASE="${CLAUDE_MEMORY_DIR:-.claude/memory}"

# No git? Use base.
command -v git &>/dev/null || { echo "$MEMORY_BASE"; exit 0; }

# Not a repo? Use base.
git rev-parse --git-dir &>/dev/null 2>&1 || { echo "$MEMORY_BASE"; exit 0; }

# No branch (detached HEAD)? Use base.
BRANCH=$(git branch --show-current 2>/dev/null)
[ -z "$BRANCH" ] && { echo "$MEMORY_BASE"; exit 0; }

# Sanitize and output
SANITIZED=$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9\/-]/-/g')
echo "$MEMORY_BASE/$SANITIZED"
