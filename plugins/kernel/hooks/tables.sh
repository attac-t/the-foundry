#!/bin/sh
# PostToolUse: Names a markdown table whose pipes do not line up
#
# Speaks only when the file just written is markdown and holds a ragged table. Every other write is
# silent — a hook that talks on every save gets read as noise and then not read at all.
#
# It names the table and leaves the repair to the model, which is already mid-write and holds the
# file in context. Deciding *whether* a table lines up is arithmetic, so it lives in awk. Rewriting
# the cells is an edit the model was making anyway.
#
# Uses JSON additionalContext (PostToolUse stdout doesn't reach Claude)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD=$(cat)

# Read a value out of the payload. See consider.sh for why this is not jq.
field() { printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path="$1" 2>/dev/null; }

FILE=$(field tool_input.file_path)
[ -n "$FILE" ] || FILE=$(field tool_input.pathInProject)
[ -n "$FILE" ] || exit 0

# One separator to match against. Windows hands us `docs\guide.md`, and a rule written in forward
# slashes silently declines to fire on half the installs.
FILE=$(printf '%s' "$FILE" | tr '\\' '/')

case "$FILE" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

[ -f "$FILE" ] || exit 0

# `LC_ALL=C` is required, not tidy. The reader decodes UTF-8 itself, so it needs `substr` to hand
# back bytes. Left to the ambient locale, gawk hands back characters and every width comes out wrong.
FOUND=$(LC_ALL=C awk -f "$SCRIPT_DIR/lib/tables.awk" "$FILE" 2>/dev/null)
[ -n "$FOUND" ] || exit 0

# `9 67` for counting, `9, 67` for reading.
set -- $FOUND
COUNT=$#
LINES=$(printf '%s' "$FOUND" | tr '\n' ',' | sed 's/,$//; s/,/, /g')

# Several is the ordinary case, so it is the wording this starts from. One table overrides it.
SUBJECT="$COUNT tables"
VERB="do"
PLACE="lines $LINES"

if [ "$COUNT" = 1 ]; then
  SUBJECT="A table"
  VERB="does"
  PLACE="line $LINES"
fi

# The path lands inside a JSON string, so anything that could end that string early comes out first.
SAFE=$(printf '%s' "$FILE" | tr -d '"\\' | tr -d '[:cntrl:]')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "**Tables**: $SUBJECT in \`$SAFE\` $VERB not line up in a plain text editor ($PLACE). Pad every cell so each pipe sits in the same column down the whole table. Glyphs like \`❌\` and \`✅\` take two columns, not one."
  }
}
EOF
