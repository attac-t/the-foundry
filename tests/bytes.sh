#!/bin/bash
# What `bin/bytes.sh` finds, and what it leaves alone.
#
# The real script is copied into a repository this suite builds, so `root` resolves there and every
# check drives the shipped file. Running it against this checkout would prove only that this
# checkout is clean today.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is() { [ "$2" = "$3" ] && { ok "$1"; return; }; bad "$1 — want [$3], got [$2]"; }
has() { case $2 in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing" ;; esac; }
lacks() { case $2 in *"$3"*) bad "$1 — [$3] is there and should not be" ;; *) ok "$1" ;; esac; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

lost=$(printf '\357\277\275')

# A repository with the gate in it, and nothing else that could fail. The identity is set because a
# fixture repo has no checkout behind it and `git` refuses to commit without one.
a_repo_holding_the_gate() {
    d=$tmp/$1
    mkdir -p "$d/bin"
    cp "$root/bin/bytes.sh" "$d/bin/bytes.sh"
    git -C "$d" init -q
    git -C "$d" config user.email fixture@example.invalid
    git -C "$d" config user.name Fixture
    # Windows would otherwise rewrite the fixture's line endings and warn on every add.
    git -C "$d" config core.autocrlf false
    printf 'clean\n' > "$d/README.md"
    git -C "$d" add -A
    git -C "$d" commit -qm base
    printf '%s' "$d"
}

a_clean_tree_passes() {
    d=$(a_repo_holding_the_gate clean)
    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'a clean tree exits 0' "$rc" 0
    has 'and says so' "$out" 'PASS'
}

a_lost_character_fails() {
    d=$(a_repo_holding_the_gate lost)
    printf 'a dash %s here\n' "$lost" >> "$d/README.md"
    git -C "$d" add -A
    git -C "$d" commit -qm planted

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'a tracked replacement character exits 1' "$rc" 1
    has 'and names the file' "$out" 'README.md'
    has 'and names the line' "$out" 'README.md:2'
}

# `git grep -I` skips what git calls binary. Without it a PNG holding those three bytes by chance
# would fail a gate about prose.
a_binary_file_is_left_alone() {
    d=$(a_repo_holding_the_gate binary)
    printf 'PNG\000%s\000\n' "$lost" > "$d/logo.png"
    git -C "$d" add -A
    git -C "$d" commit -qm binary

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'a binary file exits 0' "$rc" 0
    lacks 'and the file is not named' "$out" 'logo.png'
}

# The working tree is read, so a defect is caught before the commit that carries it. An untracked
# scratch file is nobody's to grade.
an_untracked_file_is_not_graded() {
    d=$(a_repo_holding_the_gate untracked)
    printf 'a dash %s here\n' "$lost" > "$d/scratch.md"

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'an untracked file exits 0' "$rc" 0
    has 'and the tree still passes' "$out" 'PASS'
}

# An uncommitted edit is graded, and that is the point of reading the working tree.
an_uncommitted_edit_is_graded() {
    d=$(a_repo_holding_the_gate staged)
    printf 'a dash %s here\n' "$lost" >> "$d/README.md"

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'an edit to a tracked file exits 1' "$rc" 1
    has 'and names it' "$out" 'README.md'
}

# The other half of the gate. A byte no decoder can read is not a lost character — it is not a
# character at all, and `git grep` cannot see it.
a_file_no_decoder_can_read_fails() {
    d=$(a_repo_holding_the_gate raw)
    printf 'a dash \227 here\n' >> "$d/README.md"
    git -C "$d" add -A
    git -C "$d" commit -qm raw

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'a byte that is not UTF-8 exits 1' "$rc" 1
    has 'and names the file' "$out" 'README.md is not UTF-8'
    has 'and says how to find it' "$out" 'iconv'
}

# Binary is skipped for both halves, or every PNG in the tree fails a gate about prose.
a_binary_file_that_is_not_utf8_is_left_alone() {
    d=$(a_repo_holding_the_gate rawbin)
    printf 'PNG\000\227\000\n' > "$d/logo.png"
    git -C "$d" add -A
    git -C "$d" commit -qm rawbin

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'a binary file that is not UTF-8 exits 0' "$rc" 0
    lacks 'and the file is not named' "$out" 'logo.png'
}

a_tree_that_is_no_checkout_exits_3() {
    d=$tmp/bare
    mkdir -p "$d/bin"
    cp "$root/bin/bytes.sh" "$d/bin/bytes.sh"

    out=$(cd "$d" && sh bin/bytes.sh 2>&1); rc=$?

    is 'no git checkout exits 3' "$rc" 3
    has 'and says it read nothing' "$out" 'read'
}

main() {
    a_clean_tree_passes
    a_lost_character_fails
    a_binary_file_is_left_alone
    a_file_no_decoder_can_read_fails
    a_binary_file_that_is_not_utf8_is_left_alone
    an_untracked_file_is_not_graded
    an_uncommitted_edit_is_graded
    a_tree_that_is_no_checkout_exits_3

    printf '\n%d passed, %d failed\n' "$passed" "$failed"
    [ "$failed" -eq 0 ]
}

main "$@"
