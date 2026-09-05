#!/bin/sh
#
# Fails when a tracked text file holds a byte that is not the character somebody meant.
#
# Two faults, and they are not the same one:
#
#   not UTF-8   a byte no decoder can read. `bin/gates.sh` held one — a Windows em dash, 0x97,
#               written raw. Every editor shows it as a question mark and no tool here objected
#   U+FFFD      a character that decodes cleanly and already means *something was lost here*.
#               Eleven reached a branch in one commit, five of them inside messages a person reads
#
# **Neither is ever wanted, so the bar is zero and no threshold has to be argued.**
#
# POSIX plus `git`. `iconv` decides validity because that is its job, and the U+FFFD pattern is
# built by `printf` because `$'...'` is a bashism. `-I` skips what git calls binary, so an image
# can never fail this.
#
# **Tracked files only, working tree.** An untracked scratch file is nobody's to grade, and reading
# the working tree catches the byte before the commit that would carry it.
#
# No `set -e`: `git grep` exits 1 when it matches nothing, and that is this gate passing.
#
# Exit: 0 every tracked text file is clean, 1 at least one is not, 3 the tree could not be read

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

LOST=$(printf '\357\277\275')
unreadable=
lost=

main() {
    ensure_the_tree_reads
    [ "${1:-}" = audit ] && prove_it_can_go_red

    unreadable=$(files_no_decoder_can_read)
    lost=$(lines_that_lost_a_character)
    verdict
}

ensure_the_tree_reads() {
    git rev-parse --git-dir >/dev/null 2>&1 && return 0

    printf 'FAIL — this is not a git checkout, so nothing was read.\n'
    exit 3
}

# A gate that has only ever been green proves nothing about what it would catch. The suite builds a
# repository, plants each byte and reads this script's exit code, so the gate line runs the proof
# and the scan in that order.
prove_it_can_go_red() {
    bash "$root/tests/bytes.sh" || exit 1
    printf '\n'
}

# `git grep -I` names the text files without listing the binaries, so one call decides what is worth
# decoding. Reading them here rather than in `git grep` is the only way: git has no opinion on
# whether a text file decodes.
files_no_decoder_can_read() {
    git grep -I -l '' -- . 2>/dev/null | while read -r file; do
        iconv -f UTF-8 -t UTF-8 < "$file" >/dev/null 2>&1 || printf '%s\n' "$file"
    done
}

lines_that_lost_a_character() {
    git grep -n -I -e "$LOST" -- . 2>/dev/null
}

verdict() {
    [ -z "$unreadable" ] && [ -z "$lost" ] && {
        printf 'PASS — every tracked text file decodes, and none says a character was lost.\n'
        return 0
    }

    report_files_no_decoder_can_read
    report_lines_that_lost_a_character
    return 1
}

report_files_no_decoder_can_read() {
    [ -n "$unreadable" ] || return 0

    printf '%s\n' "$unreadable" | while read -r file; do
        printf '  FAIL  %s is not UTF-8\n' "$file"
    done
    printf '        Find the byte with: iconv -f UTF-8 -t UTF-8 < FILE > /dev/null\n'
}

report_lines_that_lost_a_character() {
    [ -n "$lost" ] || return 0

    printf '%s\n' "$lost"
    printf '        A replacement character only ever means the real one is already gone.\n'
    printf '        Find what it should have been and write it again.\n'
}

main "$@"
