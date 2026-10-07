#!/bin/sh
# PostToolUse: names the standard that governs a code edit
#
# Uses JSON additionalContext (PostToolUse stdout doesn't reach Claude)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD=$(cat)

#
# Read a value out of the payload.
#
# This called `jq`, which ships with neither macOS nor Git Bash.
# Missing, it emptied that path, so the prompt fired on every
# write this hook exists to skip. Inverted, and quiet too.
#
field() { printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path="$1" 2>/dev/null; }

FILE=$(field tool_input.file_path)
[ -n "$FILE" ] || FILE=$(field tool_input.pathInProject)

# No path means the reader is broken, not the file interesting. The preflight says so.
[ -n "$FILE" ] || exit 0

# One separator to match against. Windows hands `src\tests\Foo.php`,
# and a rule written in forward slashes silently declines to fire
# on half the installs it runs on. Nothing says it went wrong.
FILE=$(printf '%s' "$FILE" | tr '\\' '/')

# The directory holding a path, as `dirname` gives it. `git -C ""` would ask the session's own tree.
dir_of() {
    case $1 in
        */*) set -- "${1%/*}"; printf '%s' "${1:-/}" ;;
        *)   printf '.' ;;
    esac
}

# Only a file a commit can hold has a standard: not one outside every work tree, nor one git
# ignores. Inside `.git/` git answers `false`, which is no work tree either.
can_be_committed() {
    [ "$(git -C "$(dir_of "$1")" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || return 1
    ! git -C "$(dir_of "$1")" check-ignore -q "$1" 2>/dev/null
}

# The path from its work tree's root. The harness hands the hook an absolute path, and the patterns
# below read one from its first character.
path_in_its_tree() {
    printf '%s%s' "$(git -C "$(dir_of "$1")" rev-parse --show-prefix 2>/dev/null)" "${1##*/}"
}

can_be_committed "$FILE" || exit 0
IN_TREE=$(path_in_its_tree "$FILE")

# Skip tests, docs and config by the path in the tree, so a folder above it changes nothing.
printf '%s' "$IN_TREE" | grep -qE '(^|/)tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env' && exit 0

# Which standard governs the edit. A copy here would be a second one to keep true.
standard_for() {
    case "$1" in
        plugins/*/bin/*.sh|plugins/*/lib/*.sh|plugins/*/hooks/*.sh) printf 'craft-sh'  ;;
        *)                                                          printf 'craft-adr' ;;
    esac
}

printf '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "**Consider**: `%s` governs what you just edited. Read it before the next one — afterwards is a rewrite."
  }
}
' "$(standard_for "$IN_TREE")"
