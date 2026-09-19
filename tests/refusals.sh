#!/bin/bash
# What `bin/refusals.sh` calls a refusal, and what it refuses to call one.
#
# **Every check reads a script this suite writes.** A fixture that is a string on a command line
# stops being shell, and the reader's whole job is reading shell.
#
# The counts here were measured before the reader existed: the message alone separates 81 sites of
# 88, the function and code 84, the three together 87. So the key is the three, and the pair it
# cannot separate is a fault in the script rather than in the key.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()  { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "refusals"

tmp="${TMPDIR:-/tmp}/refusals-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

read_it()  { ( cd "$root" && sh bin/refusals.sh "$@" 2>&1 ); }
code_of()  { ( cd "$root" && sh bin/refusals.sh "$@" >/dev/null 2>&1 ); printf '%s' "$?"; }

# --- the ordinary site ---

cat > "$tmp/one.sh" <<'FIX'
refuse_a_thing() {
    note "it was not there"
    exit 7
}
FIX

is  "a refusal is one row"        "$(read_it "$tmp/one.sh" | grep -c .)" "1"
has "carrying its function"       "$(read_it "$tmp/one.sh")" "refuse_a_thing"
has "its code"                    "$(read_it "$tmp/one.sh")" "7"
has "and what it said"            "$(read_it "$tmp/one.sh")" "it was not there"

# --- prose is not a statement ---
#
# `usage` prints `exit 1, 5, 8, 9, 10, 11 or 12`, and reading it added a site and four codes to a
# count that reached three documents before anyone checked.

cat > "$tmp/prose.sh" <<'FIX'
usage() {
    cat <<'EOF'
  run.sh authorise    refuse a run describing no work —
                      exit 1, 5, 8 or 12
EOF
}
FIX

is "a code printed in usage is no refusal" "$(read_it "$tmp/prose.sh" | grep -c .)" "0"

cat > "$tmp/comment.sh" <<'FIX'
# A gate that did not pass is exit 14, and never exit 21.
f() {
    exit 3
}
FIX

is "a code named in a comment is no refusal either" "$(read_it "$tmp/comment.sh" | grep -c .)" "1"

# --- a message belongs to the site that printed it ---
#
# Six sites in the runner print nothing within three lines. Calling a stranger's sentence theirs
# would read as a different refusal, so they are silent instead.

cat > "$tmp/far.sh" <<'FIX'
f() {
    note "this belongs to the line below it"
    printf 'a\n'
    printf 'b\n'
    printf 'c\n'
    exit 9
}
FIX

lacks "a message four lines back is not this site's" "$(read_it "$tmp/far.sh")" "belongs to the line below"
has   "and the site is still a row"                  "$(read_it "$tmp/far.sh")" "f	9"

# --- the key ---

cat > "$tmp/twice.sh" <<'FIX'
f() {
    note "the first reason"
    exit 6
    note "the second reason"
    exit 6
}
FIX

is "one function exiting one code twice is two rows" "$(read_it "$tmp/twice.sh" | grep -c .)" "2"
is "and the two are told apart"                      "$(read_it "$tmp/twice.sh" | sort -u | grep -c .)" "2"

cat > "$tmp/silent.sh" <<'FIX'
f() {
    helper || { exit 6; }
    other  || { exit 6; }
}
FIX

is "two silent sites on one code cannot be told apart" \
   "$(read_it "$tmp/silent.sh" | sort -u | grep -c .)" "1"
is "and both are still counted"                        "$(read_it "$tmp/silent.sh" | grep -c .)" "2"

# --- a quote inside a message ---

cat > "$tmp/quote.sh" <<'FIX'
f() {
    note "run gates first"
    exit 2
}
FIX

has "a message survives whole" "$(read_it "$tmp/quote.sh")" "run gates first"


# --- both shapes, and each broke the other once ---
#
# The reader found the standalone form first and reported eighteen sites as the whole. Teaching it
# the guard form then dropped the standalone one, because the pattern wanted a delimiter and an
# indented line offers none. Two hundred and nine sites and thirty-seven codes, once both are read.

cat > "$tmp/shapes.sh" <<'FIX'
f() {
    helper || { note "the guard form"; exit 4; }

    note "the standalone form"
    exit 5
}
FIX

is  "both shapes are read"        "$(read_it "$tmp/shapes.sh" | grep -c .)" "2"
has "the guard one"               "$(read_it "$tmp/shapes.sh")" "the guard form"
has "and the standalone one"      "$(read_it "$tmp/shapes.sh")" "the standalone form"

# --- the head is what the site rests on, and only if this file defines it ---
#
# `cd "$tree" || { note "cannot enter"; exit 16; }` sits in two functions here. Reading `cd` as the
# head made them one decision. They are two, and only a file that defines `cd` could say otherwise.

cat > "$tmp/heads.sh" <<'FIX'
helper() {
    note "the helper explains"
    return 1
}

one() {
    helper || exit 5
}

two() {
    helper || exit 5
}

three() {
    cd "$x" || { note "cannot enter"; exit 16; }
}

four() {
    cd "$x" || { note "cannot enter"; exit 16; }
}
FIX

has "a guard on a function this file defines takes its name" "$(read_it "$tmp/heads.sh")" "helper	5"
is  "so two callers of it are one decision" \
    "$(read_it "$tmp/heads.sh" | grep -c 'helper	5')" "2"
is  "and one row"  "$(read_it "$tmp/heads.sh" | grep 'helper	5' | sort -u | grep -c .)" "1"

lacks "a guard on a command it does not define is not a head" "$(read_it "$tmp/heads.sh")" "cd	16"
is    "so those two stay two decisions" \
      "$(read_it "$tmp/heads.sh" | grep '	16	' | sort -u | grep -c .)" "2"

# --- a message is spent by the exit that says it ---
#
# `[ -n "$said" ] || { note "commit names the change"; exit 2; }` sits two lines above
# `dir=$(active_run) || exit 1`. Leaving the message set gave it to both, and the page carried three
# rows pairing a head with a sentence another refusal had already used.

cat > "$tmp/spent.sh" <<'FIX'
f() {
    [ -n "$said" ] || { note "this one names the change"; exit 2; }

    dir=$(helper) || exit 1
}

helper() {
    return 1
}
FIX

has  "the exit that says it keeps it"   "$(read_it "$tmp/spent.sh")" "this one names the change"
is   "and it is said once"              "$(read_it "$tmp/spent.sh" | grep -c 'names the change')" "1"
has  "the next exit is silent"          "$(read_it "$tmp/spent.sh")" "helper	1	"
# --- what it refuses ---

is "naming no script refuses"          "$(code_of)" "2"
has "and says so"                      "$(read_it)" "name at least one script"
is "a script it cannot read refuses"   "$(code_of "$tmp/nope.sh")" "3"
has "and names the one it could not"   "$(read_it "$tmp/nope.sh")" "nope.sh"

# --- more than one script ---

is "two scripts are read in order" \
   "$(read_it "$tmp/one.sh" "$tmp/twice.sh" | grep -c .)" "3"

printf '\nrefusals — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
