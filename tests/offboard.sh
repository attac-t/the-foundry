#!/bin/bash
# What `bin/offboard.sh` names, and what it refuses to claim.
#
# **The refusal is the point.** A project read is GraphQL, and a refused one comes back empty — the
# same shape as a board carrying nothing. Reporting every open issue as missing is the loudest way
# to be wrong, so an empty board refuses instead.
#
# The forge runs through a `gh` this suite writes. That stub is a shell script, so nothing here runs
# `--jq`, and which items the real call filters is proved by running it, not by this.
#
# The owner is read from a real `origin`, because the point of reading it is that no account is
# written down.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "offboard"

tmp="${TMPDIR:-/tmp}/offboard-suite-$$"
mkdir -p "$tmp/bin" "$tmp/fix"
trap 'rm -rf "$tmp"' EXIT

#
# The forge, reduced to the two questions the script asks. It branches on the query because the
# answers are different shapes: the board hands back numbers, the issues hand back a number and a
# title.
cat > "$tmp/bin/gh" <<'STUB'
#!/bin/sh
case "$*" in
    *"item-list"*)    cat "$FIX/board"  2>/dev/null ;;
    *state=open*)     cat "$FIX/issues" 2>/dev/null ;;
esac
STUB
chmod +x "$tmp/bin/gh"

TAB="$(printf '\t')"

board()  { printf '%s\n' "$@" > "$tmp/fix/board"; }
issues() { printf '%s\n' "$@" > "$tmp/fix/issues"; }

# **A file holding one blank line is not an empty file**, and the guard below reads size.
nothing_on_the_board() { : > "$tmp/fix/board"; }

#
# A repository, because the owner is read from `origin` rather than written down. The remote never
# answers: only its spelling is under test.
repo="$tmp/r"
mkdir -p "$repo"
git -C "$repo" init -q 2>/dev/null || { echo "  n/a   git could not make a repository here"; exit 0; }
git -C "$repo" remote add origin https://github.com/an-owner/a-repo.git

said()    { ( cd "$repo" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/offboard.sh" 2>&1 ); }
code_of() { ( cd "$repo" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/offboard.sh" >/dev/null 2>&1; printf '%s' "$?" ); }

# --- an issue the board never took ---

board  "41"
issues "$(printf '41\ton the board')" "$(printf '77\tfiled and invisible')"

out=$(said)

has   "an open issue the board lacks is named" "$out" "#77"
has   "and its title comes with it"            "$out" "filed and invisible"
lacks "one the board carries is not named"     "$out" "#41"
is    "and it refuses with 1"                  "$(code_of)" "1"

# --- newest first ---
#
# **A run at the top is the shape this fault takes.** Somebody files and moves on, so the missing
# numbers are the newest ones and a reader should meet them first.

board  "41"
issues "$(printf '41\ton the board')" "$(printf '50\tolder gap')" "$(printf '99\tnewest gap')"

order=$(said | grep -oE '#[0-9]+' | head -1)
is "the newest missing issue is first" "$order" "#99"

# --- nothing missing ---

board  "41" "77"
issues "$(printf '41\tone')" "$(printf '77\ttwo')"

clean=$(said)

has "a board carrying everything says so plainly" "$clean" "Nothing is filed and invisible"
is  "and it exits 0"                              "$(code_of)" "0"

# --- a board that answered with nothing ---
#
# A refused GraphQL read and a board holding nothing are the same bytes. Reporting every issue as
# missing is the loudest way to be wrong.

nothing_on_the_board
issues "$(printf '41\tone')"

is  "an empty board refuses rather than blaming every issue" "$(code_of)" "3"
has "and says the read may have been refused"                "$(said)" "the read was refused"

# --- the refusals ---

board "41"

noforge() { ( cd "$repo" && FIX="$tmp/fix" PATH=/usr/bin:/bin sh "$root/bin/offboard.sh" 2>&1 ); }
has "with no forge it says both halves need one" "$(noforge)" "an adapter is the whole of it"

bare="$tmp/bare"
mkdir -p "$bare"
git -C "$bare" init -q 2>/dev/null
noowner() { ( cd "$bare" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/offboard.sh" 2>&1 ); }
nocode()  { ( cd "$bare" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/offboard.sh" >/dev/null 2>&1; printf '%s' "$?" ); }

has "a repository with no origin is told why" "$(noowner)" "does not say who owns"
is  "and that refuses with 3"                 "$(nocode)" "3"

# --- it names no account ---
#
# The whole reason the owner is read from `origin`. A name written into the file would ship one
# repository's account to everybody who installs this.

lacks "the script carries no account name" "$(cat "$root/bin/offboard.sh")" "attac-t"

printf '\noffboard — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
