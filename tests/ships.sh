#!/bin/bash
# What `bin/ships.sh` finds, and what it refuses to claim.
#
# **Written because a person caught an absence that was not one.** *Nothing here retrospects* was
# said three weeks after a skill for it shipped, and the search had read the issue tracker and none
# of the three homes a capability actually lives in.
#
# Driven against a fixture of all three, because a suite reading the live tree would go red the day
# somebody writes a rule about widgets.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "ships"

tmp="${TMPDIR:-/tmp}/ships-suite-$$"
home="$tmp/home"
mkdir -p "$home/bin" "$home/plugins/kernel/skills/probe" "$home/.claude/rules"
trap 'rm -rf "$tmp"' EXIT

#
# One home per kind, each naming the same word, so a case can tell which of the three answered.
#
# **A script's third line and a skill's description**, because those are what the real ones carry:
# `craft-sh` puts the subject under the shebang and a skill's frontmatter says when to invoke it.
printf '#!/bin/sh\n#\n# A script that knows about widgets.\n#\nset -u\n' > "$home/bin/widget.sh"
printf -- '---\nname: probe\ndescription: Find a widget before it finds you.\n---\n# Probe\n' \
       > "$home/plugins/kernel/skills/probe/SKILL.md"
printf '# Widgets\n\nHow a widget is handled here.\n' > "$home/.claude/rules/widgets.md"

asked()   { FOUNDRY_SHIPS_ROOT="$home" sh "$root/bin/ships.sh" "$@" 2>&1; }
code_of() { FOUNDRY_SHIPS_ROOT="$home" sh "$root/bin/ships.sh" "$@" >/dev/null 2>&1; printf '%s' "$?"; }

# --- all three homes answer ---

said=$(asked widget)

has "a script is named, with what it is"  "$said" "bin/widget.sh"
has "and the line under its shebang"      "$said" "A script that knows about widgets"
has "a skill is named by plugin and name" "$said" "kernel:probe"
has "and what its frontmatter says"       "$said" "Find a widget before it finds you"
has "a rule is named"                     "$said" "rules/widgets.md"
is  "and it exits 0"                      "$(code_of widget)" "0"

# --- a word only one home answers to ---
#
# **A quiet home prints nothing.** A list of empty headings is what makes a thin search look
# thorough, which is the fault this whole check exists to end.

printf '# Barnacles\n\nWhat a barnacle is.\n' > "$home/.claude/rules/barnacles.md"
one=$(asked barnacle)

has   "the one home that answers is named" "$one" "rules/barnacles.md"
lacks "and no heading for the silent ones" "$one" "bin/"

# --- nothing answers ---
#
# **The refusal is the point.** Until this prints, nobody may say the repository lacks a thing.

none=$(asked zzzznothinghere)

has "an absence is said plainly" "$none" "nothing here answers to that"
has "and permission comes with it" "$none" "Now you may say so"
is  "and it refuses with 1"        "$(code_of zzzznothinghere)" "1"

# --- more than one word ---

both=$(asked widget barnacle)

has "each word gets its own answer" "$both" "[widget] is answered by"
has "and so does the next"          "$both" "[barnacle] is answered by"
is  "one hit is enough for 0"       "$(code_of zzzznothinghere widget)" "0"

# --- no word ---

is  "no word refuses with 2"  "$(code_of)" "2"
has "and says what to give it" "$(asked)" "name a word"

# --- it never answers about itself ---
#
# **Its own header names every word it was written about.** Left in, it answers to all of them and
# tells a reader nothing.

cp "$root/bin/ships.sh" "$home/bin/ships.sh"
self=$(asked retrospect)

lacks "it is not its own answer" "$self" "bin/ships.sh"

printf '\nships — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
