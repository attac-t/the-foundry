#!/bin/bash
# What `bin/unread.sh` names, and what it refuses to say.
#
# **The report lists. It never judges a box.** The owner delegate refused the judging shape on
# 20 September, so half of this suite drives the refusal: no output of it may claim a box is met.
#
# Driven against real trees this suite builds, because the bug the check was born with lived in
# `git log`. `--first-parent` drops the branch commits that carry `Refs #N`, and it measured zero
# and read like an answer. A fixture of commit subjects would never have caught it.
#
# The issue half runs through a `gh` this suite writes. That stub is a shell script, so nothing here
# runs `--jq` — which tick filtering the real call does is proved by running it, not by this.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "unread"

tmp="${TMPDIR:-/tmp}/unread-suite-$$"
mkdir -p "$tmp/bin" "$tmp/fix"
trap 'rm -rf "$tmp"' EXIT

#
# The forge, reduced to the one thing the script asks it for: open issues with an untouched list,
# already as `number<TAB>title`. The real call does that filtering in `--jq`.
cat > "$tmp/bin/gh" <<'STUB'
#!/bin/sh
cat "$FIX/issues" 2>/dev/null
STUB
chmod +x "$tmp/bin/gh"

# A repository whose history is the thing under test.
repo="$tmp/r"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.email fixture@example.invalid
git -C "$repo" config user.name fixture
git -C "$repo" config core.autocrlf false
git -C "$repo" checkout -q -b main

# **The message is the thing under test.** The first version of this wrote the second argument to a
# file and committed a subject alone, so every `Refs` case read an empty history and passed as
# *nothing to read*.
commit() { date >> "$repo/log"; git -C "$repo" add -A; git -C "$repo" commit -qm "$1" -m "$2"; }

printf 'seed\n' > "$repo/log"
git -C "$repo" add -A
git -C "$repo" commit -qm seed

read_it()  { ( cd "$repo" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" sh "$root/bin/unread.sh" "$@" 2>&1 ); }
code_of()  { ( cd "$repo" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" sh "$root/bin/unread.sh" "$@" >/dev/null 2>&1 ); printf '%s' "$?"; }

issues() { printf '%s\n' "$@" > "$tmp/fix/issues"; }

# --- an issue the history names ---

issues "$(printf '0	41	a list nobody read')"
commit "fix the thing" "Refs #41"

out=$(read_it)
has  "an issue merged work names is listed"     "$out" "#41"
has  "and the title comes with it"              "$out" "a list nobody read"
is   "and it exits 1, because something owes a reading" "$(code_of)" "1"

# --- both halves, counted ---
#
# **One number hid a pass.** On 20 September ten issues were read and nine gained a first tick, and
# the untouched count fell by one because eight issues were filed the same day. A reader of that
# alone would have said nothing happened.

issues "$(printf '0	41	untouched')" "$(printf '1	42	already ticked')" "$(printf '0	43	untouched too')"
both=$(read_it)

has "the summary counts every open list"   "$both" "3 open lists"
has "and says how many carry a tick"       "$both" "1 carry a tick"
has "and how many carry none"              "$both" "2 carry none"
lacks "and a ticked list is not on the report" "$both" "#42"


# --- an issue nothing names ---

issues "$(printf '0	41	a list nobody read')" "$(printf '0	99	nobody ever mentioned this')"
out=$(read_it)
lacks "an issue no commit names is not on the report" "$out" "#99"

# --- the evidence is shown ---

sha=$(git -C "$repo" rev-parse --short HEAD)
has "the commit it found is printed, so the claim can be argued with" "$(read_it)" "$sha"

# --- more evidence than fits ---

issues "$(printf '0	41	a list nobody read')"
commit "second"  "Refs #41"
commit "third"   "Refs #41"
commit "fourth"  "Refs #41"
commit "fifth"   "Refs #41"

out=$(read_it)
has "five commits are counted as five" "$out" "    5  #41"
has "and the rest are summarised"      "$out" "and 2 more"

# --- one commit, named twice ---

repeat="$tmp/r2"
mkdir -p "$repeat"
git -C "$repeat" init -q
git -C "$repeat" config user.email fixture@example.invalid
git -C "$repeat" config user.name fixture
git -C "$repeat" config core.autocrlf false
git -C "$repeat" checkout -q -b main
printf 'seed\n' > "$repeat/log"
git -C "$repeat" add -A
git -C "$repeat" commit -qm "#41 in the subject" -m "and #41 again in the body"

twice=$( cd "$repeat" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" sh "$root/bin/unread.sh" 2>&1 )
has "a commit naming one issue twice counts once" "$twice" "    1  #41"

# --- the bug this check was born with ---
#
# **A merge commit carries the request number and nothing else.** `Refs #N` sits on the branch
# commit it folds in, so `--first-parent` never sees it. This case is the whole reason the log is
# read without it.

merged="$tmp/r3"
mkdir -p "$merged"
git -C "$merged" init -q
git -C "$merged" config user.email fixture@example.invalid
git -C "$merged" config user.name fixture
git -C "$merged" config core.autocrlf false
git -C "$merged" checkout -q -b main
printf 'seed\n' > "$merged/log"
git -C "$merged" add -A
git -C "$merged" commit -qm seed
git -C "$merged" checkout -q -b side
printf 'work\n' >> "$merged/log"
git -C "$merged" add -A
git -C "$merged" commit -qm "do the work" -m "Refs #41"
git -C "$merged" checkout -q main
git -C "$merged" merge -q --no-ff side -m "Merge pull request #700 from fixture/side"

folded=$( cd "$merged" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" sh "$root/bin/unread.sh" 2>&1 )
has "a Refs folded in by a merge is still found" "$folded" "#41"

# --- it never judges ---

#
# **The rows alone, never the whole output.** The script's own closing line says *none of that says
# a box is met*, so a search of everything it printed matches its own disclaimer and fails a check
# that should pass. The claim under test is what a row says.
rows=$(read_it | grep -E '^ +[0-9]+ +#')

has   "it says what it does claim"        "$(read_it)" "work landed and the list was never read"
lacks "no row claims a box is met"        "$rows" "met"
lacks "and no row says anything is likely" "$rows" "look"

# --- the floor ---

issues "$(printf '0	41	a list nobody read')"
under=$( cd "$repo" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" FOUNDRY_UNREAD_FLOOR=99 sh "$root/bin/unread.sh" 2>&1 )
lacks "a floor above the count drops the row"  "$under" "#41"
has   "and says so rather than printing nothing" "$under" "has been read"
is    "and that is exit 0"                     "$( cd "$repo" && PATH="$tmp/bin:$PATH" FIX="$tmp/fix" FOUNDRY_UNREAD_FLOOR=99 sh "$root/bin/unread.sh" >/dev/null 2>&1; printf '%s' "$?")" "0"

# --- nothing to read ---

issues "$(printf '0	99	nobody ever mentioned this')"
none=$(read_it)
has "no issue with work behind it reads as finished, not as broken" "$none" "has been read"
is  "and exits 0"                                                   "$(code_of)" "0"

# --- a target that is not here ---

issues "$(printf '0	41	a list nobody read')"
gone=$(read_it no-such-branch)
has "a target that is not a ref is named"  "$gone" "no-such-branch"
is  "and refuses with 3"                   "$(code_of no-such-branch)" "3"

# --- a named target is honoured ---

git -C "$repo" checkout -q -b later
commit "on later only" "Refs #41"
git -C "$repo" checkout -q main

has "a target given as an argument is the one read" "$(read_it later)" "#41"

# --- no forge ---

# A PATH holding a shell and no forge. Emptying it takes `sh` with it, and 127 is not this refusal.
noforge=/usr/bin:/bin

blind=$( cd "$repo" && PATH="$noforge" FIX="$tmp/fix" sh "$root/bin/unread.sh" 2>&1 )
has "with no forge it says which half still works" "$blind" "git and runs anywhere"
has "and which half cannot"                        "$blind" "cannot be read"
is  "and refuses with 3, never a clean empty list"  \
    "$( cd "$repo" && PATH="$noforge" FIX="$tmp/fix" sh "$root/bin/unread.sh" >/dev/null 2>&1; printf '%s' "$?")" "3"

# --- a reading that had nothing to tick ---
#
# **Three issues were read here on 20 September and every box came back unreachable.** Ticking one
# would have been a lie and leaving them made a queue that never shortens. So a box naming one of
# `closing.md`'s four states counts as read, the same four `bin/unticked.sh` already reads.

issues "$(printf '0\t41\tuntouched')" "$(printf '2\t44\tread, and nothing could be ticked')"

# **The history has to name it, or the case passes because nothing reached the report.** Driven: a
# break letting a read list rank like an untouched one went green until this line existed.
commit "answer the other thing" "Refs #44"

stated=$(read_it)

has   "a list saying why a box cannot be met is counted apart" "$stated" "1 say why a box cannot be met"
has   "and it still counts toward every open list"             "$stated" "2 open lists"
lacks "and it is off the report, like a ticked one"            "$stated" "#44"
has   "while an untouched one stays on it"                     "$stated" "#41"

printf '\nunread — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
