#!/bin/sh
# Resolves the branch-aware memory directory path.
# Outputs: .claude/memory/<branch> or .claude/memory (fallback)
#
# Redirects here read `>/dev/null 2>&1`, never `&>/dev/null`. To
# dash that second form means background, then redirect: this
# guard always passes, and git's output becomes that path.

# The folder the session works in, when a hook read one from its payload. Named, it is where git
# is asked, and the path comes back full. Not named, everything here answers as before. #1137.
SESSION="${1:-}"
MEMORY_BASE="${CLAUDE_MEMORY_DIR:-.claude/memory}"

# Print one answer whole. Dash's `echo` reads `\\` as one backslash, so a UNC base could not leave
# through it. #1162.
answer() { printf '%s\n' "$1"; }

# An active run outranks the branch, and outranks the base above.
#
# One variable is the whole handshake with floor. No shared file,
# no call, so each plugin works when the other is missing. But
# a hook cannot export, so floor's own pointer goes unseen.
if [ -n "${FOUNDRY_RUN:-}" ] && [ -d "$FOUNDRY_RUN" ]; then
    answer "$FOUNDRY_RUN/memory"
    exit 0
fi

# Whether a path starts at a root, as `/x`, `C:\x`, `C:/x`, `\\srv\share` and `\x` do.
is_absolute() { case $1 in /*|[A-Za-z]:*|\\*) return 0 ;; esac; return 1; }

# Read a relative base from the session's folder. An absolute one stays as given.
base_in_the_session() { is_absolute "$MEMORY_BASE" || MEMORY_BASE="$SESSION/$MEMORY_BASE"; }

# Move into the session's folder, where git is asked.
enter_the_session() { cd "$SESSION" 2>/dev/null; }

# The base is set first, so a folder that is gone answers it joined, as one outside a repo does.
[ -z "$SESSION" ] || base_in_the_session
[ -z "$SESSION" ] || enter_the_session || { answer "$MEMORY_BASE"; exit 0; }

# No git? Use base.
command -v git >/dev/null 2>&1 || { answer "$MEMORY_BASE"; exit 0; }

# Not a repo? Use base.
git rev-parse --git-dir >/dev/null 2>&1 || { answer "$MEMORY_BASE"; exit 0; }

# No branch (detached HEAD)? Use base.
BRANCH=$(git branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] || { answer "$MEMORY_BASE"; exit 0; }

SAFE_BRANCH=$(printf '%s' "$BRANCH" | sed 's/[^a-zA-Z0-9\/-]/-/g')
answer "$MEMORY_BASE/$SAFE_BRANCH"
