#!/bin/sh
# PostToolUse: Prompts ADR consideration after code changes
#
# Uses JSON additionalContext (PostToolUse stdout doesn't reach Claude)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD=$(cat)

#
# Read a value out of the payload.
#
# This used to call `jq`, which ships with neither macOS nor Git Bash. Missing, it did not silence
# the hook — it emptied the path, and an empty path matches no skip rule, so the ADR prompt fired on
# every write the hook exists to ignore. A dependency that fails loud is a bug; one that inverts the
# behaviour is a trap.
#
field() { printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path="$1" 2>/dev/null; }

FILE=$(field tool_input.file_path)
[ -n "$FILE" ] || FILE=$(field tool_input.pathInProject)

# No path means the reader is broken, not that the file is interesting. Stay quiet and let the
# preflight be the one to say so.
[ -n "$FILE" ] || exit 0

# One separator to match against. Windows hands us `src\tests\Foo.php`, and a rule written in
# forward slashes silently declines to fire on half the installs.
FILE=$(printf '%s' "$FILE" | tr '\\' '/')

# Skip non-code files (tests, docs, config)
printf '%s' "$FILE" | grep -qE '(^|/)tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env' && exit 0

# What was edited decides which standard is worth naming. A rule loads once a session; the shape is
# decided at the edit, and by then nobody re-reads a rule.
advice() {
    case "$1" in
        plugins/*/bin/*.sh|plugins/*/lib/*.sh|plugins/*/hooks/*.sh)
            printf 'You modified shipped shell. Its standard is generative → run `craft-sh` before the next edit, not after the review.' ;;
        *)  printf 'You modified code. If this involved a pattern choice, package choice, or schema design → run `craft-adr`.' ;;
    esac
}

printf '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "**Consider**: %s"
  }
}
' "$(advice "$FILE")"
