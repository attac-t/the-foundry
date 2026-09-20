#!/bin/bash
# What `bin/reading.sh` counts, and what it refuses to claim.
#
# **Through a `gh` this suite writes.** The real one answers about a live repository, so a case
# driving it would measure a different number every day and prove nothing about the arithmetic.
#
# The arithmetic is the whole subject. A percentile over an unsorted list has the right shape and no
# meaning, and nothing in the output would say so.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "reading"

tmp="${TMPDIR:-/tmp}/reading-suite-$$"
mkdir -p "$tmp/bin" "$tmp/fix"
trap 'rm -rf "$tmp"' EXIT

#
# The forge, reduced to the three questions this asks. It tells them apart by the path, because all
# three return the same shape — one word count per line.
cat > "$tmp/bin/gh" <<'STUB'
#!/bin/sh
case "$*" in
    *"/issues?state=all"*)   cat "$FIX/issues"   2>/dev/null ;;
    *"/pulls?state=all"*)    cat "$FIX/requests" 2>/dev/null ;;
    *"/issues/comments"*)    cat "$FIX/comments" 2>/dev/null ;;
esac
STUB
chmod +x "$tmp/bin/gh"

bodies() { printf '%s\n' "$@" > "$tmp/fix/$kind"; }

# A file holding one blank line is not an empty file, and the guard below reads lines.
nothing_of() { : > "$tmp/fix/$1"; }

said()    { ( FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/reading.sh" "$@" 2>&1 ); }
code_of() { ( FIX="$tmp/fix" PATH="$tmp/bin:$PATH" sh "$root/bin/reading.sh" "$@" >/dev/null 2>&1; printf '%s' "$?" ); }

# --- the arithmetic ---
#
# **Ten numbers, chosen so every column has one right answer.** The median is the fifth, the 75th
# the seventh, the 90th the ninth, and two are over 300 with one of those over 600.

kind=issues   bodies 10 20 30 40 50 60 70 80 301 700
kind=requests bodies 5
kind=comments bodies 5

out=$(said)

has "the median is the middle of the sample"  "$out" "issues         50"
has "and the columns sit in one row"          "$out" "50    70   301      700     2     1"
is  "and a measure that ran exits 0"          "$(code_of)" "0"

# --- order does not decide the answer ---
#
# **Unsorted input is the case that reads as working.** Every column would still print, and the
# number would be whichever body happened to arrive fifth.

kind=issues bodies 700 301 80 70 60 50 40 30 20 10

has "an unsorted sample gives the same median" "$(said)" "issues         50"

# --- a half that says nothing ---

nothing_of requests
kind=issues bodies 10 20 30

has "a kind with no bodies says so"     "$(said)" "requests    nothing to read"
lacks "and it does not print a zero row" "$(said)" "requests         0"
is   "and the run still exits 0"        "$(code_of)" "0"

# --- the sample size is the caller's ---

kind=requests bodies 10 20 30
has "the count it was given is named" "$(said 25)" "the last 25 of each"
has "and the default is the first measure's sample" "$(said)" "the last 100 of each"

# --- no forge ---

noforge() { ( FIX="$tmp/fix" PATH=/usr/bin:/bin sh "$root/bin/reading.sh" 2>&1 ); }
nocode()  { ( FIX="$tmp/fix" PATH=/usr/bin:/bin sh "$root/bin/reading.sh" >/dev/null 2>&1; printf '%s' "$?" ); }

has "with no forge it says nothing was measured" "$(noforge)" "Nothing was measured"
is  "and that refuses with 3"                    "$(nocode)" "3"

# --- it claims nothing ---
#
# A count that ends in a verdict is a gate, and `writing.md` says no exit code can judge prose.

lacks "it never calls a number a pass" "$(said)" "PASS"
lacks "nor a failure"                  "$(said)" "FAIL"
has   "and it says what a count is"    "$(said)" "a count is an alert"

printf '\nreading — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
