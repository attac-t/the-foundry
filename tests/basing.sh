#!/bin/bash
# What `bin/basing.sh` names, and what it leaves alone.
#
# **The shape is built from nothing, not read from this repository.** A fixture that watched real
# history would pass on whatever history happened to be, and the fault this catches is a diff
# between two trees that are each fine on their own.
#
# Four branches carried it on the morning of 15 September 2026, in three rounds. Every one was found
# by hand.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "basing"

tmp="${TMPDIR:-/tmp}/basing-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

#
# A repository where `main` landed a file after the branch was cut. That is the whole shape: the
# branch never held `landed.txt`, so git has no reason to complain and the diff removes it.
#
# The identity is set here because a repository this suite makes has no checkout behind it — the one
# exception `identity.md` allows.
a_branch_cut_before_a_merge() {
  d=$tmp/$1
  mkdir -p "$d" || return 1

  git init -q "$d" >/dev/null 2>&1 || return 1
  git -C "$d" config user.email fixture@example.invalid
  git -C "$d" config user.name  fixture
  git -C "$d" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1

  printf 'shared\n' > "$d/shared.txt"
  git -C "$d" add . && git -C "$d" commit -qm base

  git -C "$d" checkout -qb side
  printf 'mine\n' > "$d/mine.txt"
  git -C "$d" add . && git -C "$d" commit -qm mine

  git -C "$d" checkout -q main
  printf 'landed\nand landed\n' > "$d/landed.txt"
  git -C "$d" add . && git -C "$d" commit -qm landed

  git -C "$d" checkout -q side
}

asked() { ( cd "$1" && sh "$root/bin/basing.sh" "${2:-main}" 2>&1 ); }
code_of() { ( cd "$1" && sh "$root/bin/basing.sh" "${2:-main}" >/dev/null 2>&1 ); echo $?; }

# --- the fault ---

a_branch_cut_before_a_merge cut || { printf '  skip  basing — git could not make a repo here\n'; exit 0; }

case $(asked "$tmp/cut") in
  *landed.txt*) ok  "a file the branch never touched is named" ;;
  *)            bad "a file the branch never touched is named — it was not" ;;
esac

[ "$(code_of "$tmp/cut")" = "1" ] \
  && ok  "and the exit code says so" \
  || bad "and the exit code says so — it did not"

case $(asked "$tmp/cut") in
  *mine.txt*) bad "the branch's own file is not named — it was" ;;
  *)          ok  "the branch's own file is not named" ;;
esac

# --- the same branch, once the target is merged in ---

git -C "$tmp/cut" merge --no-edit main >/dev/null 2>&1

[ "$(code_of "$tmp/cut")" = "0" ] \
  && ok  "a branch that carries the target passes" \
  || bad "a branch that carries the target passes — it did not"

# --- a merge left open ---
#
# `HEAD` is the old commit while a merge is unresolved, so the diff names every merge this branch
# predates. On 14 September that read as 99 deletions, every one of them landed work.

a_branch_cut_before_a_merge open || { printf '  skip  basing — git could not make a second repo\n'; exit 1; }

printf 'clash\n' > "$tmp/open/landed.txt"
git -C "$tmp/open" add . && git -C "$tmp/open" commit -qm clash
git -C "$tmp/open" merge main >/dev/null 2>&1

[ "$(code_of "$tmp/open")" = "3" ] \
  && ok  "an unresolved merge is refused, not answered" \
  || bad "an unresolved merge is refused, not answered — it answered"

case $(asked "$tmp/open") in
  *unresolved*) ok  "and it says which state it found" ;;
  *)            bad "and it says which state it found — it did not" ;;
esac

# --- a target that is not here ---

[ "$(code_of "$tmp/cut" no-such-ref)" = "2" ] \
  && ok  "a target that is not a ref is refused" \
  || bad "a target that is not a ref is refused — it was not"

printf '\nbasing — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
