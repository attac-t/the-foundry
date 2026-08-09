#!/bin/sh
# Resolves the branch-aware memory directory path.
# Outputs: .claude/memory/<branch>/ or .claude/memory/ (fallback)
#
# The redirects here read `>/dev/null 2>&1`, never `&>/dev/null`. `&>` is bash's, and dash reads it
# as "run in the background, then redirect": the guard always succeeds, and git's own output lands
# on stdout, where the caller reads it as the memory path.

MEMORY_BASE="${CLAUDE_MEMORY_DIR:-.claude/memory}"

# No git? Use base.
command -v git >/dev/null 2>&1 || { echo "$MEMORY_BASE"; exit 0; }

# Not a repo? Use base.
git rev-parse --git-dir >/dev/null 2>&1 || { echo "$MEMORY_BASE"; exit 0; }

# No branch (detached HEAD)? Use base.
BRANCH=$(git branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] || { echo "$MEMORY_BASE"; exit 0; }

# Sanitize and output
SANITIZED=$(printf '%s' "$BRANCH" | sed 's/[^a-zA-Z0-9\/-]/-/g')
echo "$MEMORY_BASE/$SANITIZED"
