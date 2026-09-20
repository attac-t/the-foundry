#!/bin/bash
# What `bin/unlisted.sh` names, and what it refuses to claim.
#
# **The subject is a join.** A closed issue with no list is not a finding on its own — forty-eight
# of them here are history. It becomes one when open work still points at it, so every case below
# drives both halves against each other.
#
# The forge runs through a `gh` this suite writes, and that stub is a shell script. So nothing here
# runs `--jq`, and **which closed issues the real call filters out is proved by running it, not by
# this** — the same compromise `tests/unread.sh` makes, for the same reason.
#
# The tracked-page half is real: `git grep` runs in a repository this suite builds.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "unlisted"

tmp="${TMPDIR:-/tmp}/unlisted-suite-$$"
mkdir -p "$tmp/bin" "$tmp/fix"
trap 'rm -rf "$tmp"' EXIT

#
# The forge, reduced to the two questions the script asks it. It branches on the query because the
# script asks twice and the answers are different shapes — closed ones carry a title, open ones
# carry the number they point at.
cat > "$tmp/bin/gh" <<'STUB'
#!/bin/sh
case "$*" in
    *state=closed*) cat "$FIX/closed" 2>/dev/null ;;
    *state=open*)   cat "$FIX/open"   2>/dev/null ;;
esac
STUB
chmod +x "$tmp/bin/gh"

TAB="$(printf '\t')"

closed() { printf '%s\n' "$@" > "$tmp/fix/closed"; }
opened() { printf '%s\n' "$@" > "$tmp/fix/open"; }

# **A file holding one blank line is not an empty file**, and the guard this drives reads size.
# `printf '%s\n' ""` writes a byte, so the first draft of the case below earned a clean bill.
nothing_closed() { : > "$tmp/fix/closed"; }

#
# A repository, because `git grep` is the second source and a fixture of strings would never run it.
# One commit, so a page is tracked rather than merely present.
make_repo() {
    rm -rf "$tmp/repo"
    mkdir -p "$tmp/repo"
    git -C "$tmp/repo" init -q 2>/dev/null || return 1
    printf '%s\n' "${1:-nothing points anywhere}" > "$tmp/repo/page.md"
    git -C "$tmp/repo" add -A 2>/dev/null
    git -C "$tmp/repo" -c user.name=t -c user.email=t@t commit -qm seed 2>/dev/null
}

said()    { ( cd "$tmp/repo" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/unlisted.sh" 2>&1 ); }
code_of() { ( cd "$tmp/repo" && FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/unlisted.sh" >/dev/null 2>&1; printf '%s' "$?" ); }

make_repo || { echo "  n/a   git could not make a repository here"; exit 0; }

# --- the join, both ways round ---

closed "41${TAB}a closed page nobody recorded" \
       "77${TAB}a closed page nothing names"
opened "41${TAB}#500"

one=$(said)

has   "a closed empty issue something points at is named" "$one" "#41"
has   "and the title comes with it"                       "$one" "a closed page nobody recorded"
has   "and so does who points"                            "$one" "#500"
lacks "one nothing names is not named"                    "$one" "#77"
is    "and it refuses with 1"                             "$(code_of)" "1"

# --- ranking ---
#
# **Most pointed-at first.** The failure signal the reports here share is a list that passes twenty
# and nobody opens, so the order is the thing that keeps it readable.

closed "41${TAB}named once" "42${TAB}named twice"
opened "42${TAB}#500" "42${TAB}#501" "41${TAB}#502"

order=$(said | grep -E '^ +[0-9]+ +#4')
is "the most pointed-at is first" "$(printf '%s\n' "$order" | head -1 | grep -o '#4[0-9]')" "#42"

# --- a pointer is a pointer, wherever it is written ---

closed "41${TAB}named only by a page"
opened ""
make_repo 'the answer to that is #41, and it closed'

page=$(said)

has "a tracked page counts as a pointer" "$page" "a tracked page"
has "and the issue is named"             "$page" "#41"

# --- nothing to report ---
#
# **A clean answer is a sentence, never an empty page.** Silence reads the same as a broken run.

make_repo
closed "41${TAB}a closed page nothing names"
opened ""

clean=$(said)

has "a clean repository says so plainly"  "$clean" "Nobody is relying on silence"
is  "and it exits 0"                      "$(code_of)" "0"

# --- it lists, and never judges ---
#
# A report that says *this looks met* is how a box gets ticked without being checked.

closed "41${TAB}a closed page nobody recorded"
opened "41${TAB}#500"

verdict=$(said)

lacks "it never says a claim is met"   "$verdict" "met"
lacks "nor that anything is satisfied" "$verdict" "satisfied"
has   "it says what the reader must do" "$verdict" "read each against the tree"

# --- the refusals ---

nothing_closed
opened "41${TAB}#500"

is  "a closed half that reads nothing refuses"  "$(code_of)" "3"
has "and says the forge may have said nothing"  "$(said)" "the forge said nothing"

#
# **A path with a shell and no `gh`.** Emptying `PATH` takes `sh` with it, and the case then reports
# a missing shell rather than what the script said.
noforge() { ( cd "$tmp/repo" && FIX="$tmp/fix" PATH=/usr/bin:/bin sh "$root/bin/unlisted.sh" 2>&1 ); }

closed "41${TAB}a closed page nobody recorded"

has "with no forge it says both halves need one" "$(noforge)" "a forge adapter is the whole of it"

printf '\nunlisted — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
