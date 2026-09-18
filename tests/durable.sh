#!/bin/bash
# What `bin/durable.sh` compares, and what it refuses to claim.
#
# **A list nobody checks drifts within a revision or two.** That is #611's fault and #725's answer,
# so the check itself is driven here rather than trusted.
#
# Each break copies the whole tree the script reads — the script, both files and the runner — and
# mutates one. A break that mutated the live tree would leave the repository red on its own suite.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()  { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }

echo "durable"

tmp="${TMPDIR:-/tmp}/durable-suite-$$"
trap 'rm -rf "$tmp"' EXIT

# A tree holding only what the script reads. Copied per break, so one mutation never reaches another.
a_tree() {
  rm -rf "$tmp/$1"
  mkdir -p "$tmp/$1/bin" "$tmp/$1/.foundry" "$tmp/$1/plugins/floor/bin"
  cp "$root/bin/durable.sh"              "$tmp/$1/bin/"
  cp "$root/.foundry/doctrine.md"        "$tmp/$1/.foundry/"
  cp "$root/.foundry/durable.txt"        "$tmp/$1/.foundry/"
  cp "$root/plugins/floor/bin/run.sh"    "$tmp/$1/plugins/floor/bin/"
}

graded() { ( cd "$tmp/$1" && sh bin/durable.sh 2>&1 ); }
code_of() { ( cd "$tmp/$1" && sh bin/durable.sh >/dev/null 2>&1 ); printf '%s' "$?"; }

# --- the tree as it stands ---

a_tree clean
is  "the tree as it stands agrees"  "$(code_of clean)" "0"
has "and says how many kinds"       "$(graded clean)"  "7 durable kinds"

# **The sentence that keeps a green honest.** A check over names cannot reach what a name means, and
# a reader who takes this one for more has been misled by it.
has "and refuses the claim it cannot make" "$(graded clean)" "Meaning is not read"

# --- a kind that left one file ---

a_tree gone
grep -v '^receipt' "$root/.foundry/durable.txt" > "$tmp/gone/.foundry/durable.txt"

is  "a kind dropped from the registry is caught" "$(code_of gone)" "1"
has "and both sets are printed"                  "$(graded gone)"  "doctrine: goal doctrine clause"

# --- a kind that changed halves ---
#
# The design change this exists to catch. A kind that moved from people to machinery, in one file
# only, is a doctrine and a registry disagreeing about who writes the thing.

a_tree moved
sed 's/^pin          machinery/pin          people   /' "$root/.foundry/durable.txt" > "$tmp/moved/.foundry/durable.txt"

is  "a kind that changed halves in one file is caught" "$(code_of moved)" "1"
has "and it says which reading failed"                 "$(graded moved)"  "sits in one half in the doctrine"

# --- a writer that is not there ---

a_tree nowriter
sed 's/^pin          machinery   print_pin/pin          machinery   print_pinn/' \
  "$root/.foundry/durable.txt" > "$tmp/nowriter/.foundry/durable.txt"

is  "a writer the runner does not hold is caught" "$(code_of nowriter)" "1"
has "and it names the kind and the writer"        "$(graded nowriter)"  "print_pinn"

# --- the order they are read in ---
#
# **Order, because a reader meets them in it.** Two files naming one set in two orders read as two
# lists to anyone comparing them by eye.

a_tree reordered
{ grep '^run record' "$root/.foundry/durable.txt"
  grep -v '^run record' "$root/.foundry/durable.txt"; } > "$tmp/reordered/.foundry/durable.txt"

is "a set in a different order is caught" "$(code_of reordered)" "1"

# --- a people-written kind names no writer, and that is the answer ---
#
# Demanding one would invent machinery the doctrine refuses. The clean tree already holds three, and
# this says so rather than leaving it to be read off a pass.

has "a people-written kind needs no writer" "$(graded clean)" "names a writer the runner still holds"

# A suite that ran nothing passes everything.
[ $((passed + failed)) -gt 0 ] || { printf '  FAIL  no check ran\n'; failed=1; }

printf '\ndurable — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
