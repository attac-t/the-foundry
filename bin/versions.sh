#!/usr/bin/env bash
#
# Fails when a plugin the manifest lists cannot say what version it is.
#
# It used to compare two copies of the same number, because `marketplace.json` carried a version
# beside every plugin. That made one shared line the whole repository edits, so two branches touching
# different plugins collided by construction and work was stacked for packaging reasons.
#
# The field is optional and Claude Code falls back to `plugin.json`, so the second copy is gone and
# there is nothing left to disagree. What remains is the fault that actually breaks an install: a
# listed plugin whose own manifest is missing, malformed, or silent about its version.
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -euo pipefail

cd "$(dirname "$0")/.."

# Depth, counted over a line with its string literals removed. A brace inside a description would
# otherwise move it, and a manifest that reads one level deeper answers about the wrong key.
readonly DEPTH='
  # Quotes alone bound a string. Nothing this repository writes escapes one inside another, and a
  # file that did would leave the braces unbalanced — reported, rather than guessed at.
  function bare(s,   t) { t = s; gsub(/"[^"]*"/, "", t); return t }
  {
    was = depth
    opens = bare($0); closes = opens
    depth += gsub(/[{[]/, "", opens) - gsub(/[]}]/, "", closes)
  }
'

# Whether a plugin says what version it is, at the top level of its own manifest. A `version` nested
# under `metadata` is a different fact, and the installer does not read it.
#
# Exit follows this gate's own codes: 0 it says, 1 it is silent, 3 the braces never balanced — which
# is as far as an awk reader may claim to have understood a file.
says_its_version() {
  awk "$DEPTH"'
    was == 1 && /^[ \t]*"version"[ \t]*:/ { found = 1 }
    END { if (depth != 0) exit 3; exit !found }
  ' "$1"
}

# One line per listed plugin: where it lives, and whether the manifest also states its version.
manifest_entries() {
  awk "$DEPTH"'
    function value(s,   v) { v = s; sub(/^[^:]*:[ \t]*/, "", v); gsub(/^"|"[ \t]*,?[ \t]*$/, "", v); return v }

    was == 1 && /"plugins"[ \t]*:[ \t]*\[/ { listing = 1; next }
    !listing { next }

    was == 2 && depth == 3 { source = ""; carries = 0; next }
    was == 3 && /^[ \t]*"source"[ \t]*:/  { source = value($0) }
    was == 3 && /^[ \t]*"version"[ \t]*:/ { carries = 1 }
    was == 3 && depth == 2 { print source "\t" carries }
    was == 2 && depth == 1 { listing = 0 }

    END { if (depth != 0) exit 3 }
  ' "$1"
}

unreadable() {
  echo "FAIL — $1. This gate read nothing."
  exit 3
}

readonly MANIFEST=.claude-plugin/marketplace.json

# Said plainly, because it is the case a stranger meets: they ran the gate from the wrong directory.
[ -f "$MANIFEST" ] || unreadable "no plugin manifest found"

entries=$(manifest_entries "$MANIFEST") || unreadable "the plugin manifest could not be read"

# An empty list is the same answer one level in: every plugin in it is fine, and there are none.
[ -n "$entries" ] || unreadable "the manifest lists no plugins"

listed=0
silent=""

while IFS=$'\t' read -r source carries; do
  listed=$((listed + 1))
  [ -n "$source" ] || unreadable "a manifest entry names no source"

  # A version here would be a second copy of the same fact, and a line every branch edits.
  if [ "$carries" = 1 ]; then
    echo "FAIL — $source carries a version in the manifest. It belongs in its plugin.json alone."
    exit 1
  fi

  own="$source/.claude-plugin/plugin.json"
  [ -f "$own" ] || unreadable "$source's plugin.json could not be read"

  said=0
  says_its_version "$own" || said=$?
  if [ "$said" -eq 3 ]; then unreadable "$source's plugin.json could not be read"; fi
  if [ "$said" -eq 1 ]; then silent="$silent $source"; fi
done <<< "$entries"

if [ -z "$silent" ]; then
  echo "PASS — $listed plugins each say what version they are."
  exit 0
fi

echo "FAIL — a listed plugin does not say what version it is."
for named in $silent; do
  echo "      $named"
done
exit 1
