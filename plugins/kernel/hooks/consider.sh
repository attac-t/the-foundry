#!/bin/sh
# PostToolUse: Prompts ADR consideration after code changes
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

# Skip non-code files (tests, docs, config)
printf '%s' "$FILE" | grep -qE '(^|/)tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env' && exit 0

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
' "$(standard_for "$FILE")"
