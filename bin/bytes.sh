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
#   a return     a carriage return, which decodes fine and stops a shipped script running. `bash`
#               reads it as part of the last word, so a hook dies mid-parse and exits 2
#
# **Neither is ever wanted, so the bar is zero and no threshold has to be argued.**
#
# POSIX plus `git`, and `iconv`, which decides validity because that is its job. The U+FFFD
# pattern is built by `printf` because `$'...'` is a bashism. `audit` also needs `bash`, because
# the suite is bash like every other suite here.
#
# `-I` skips what git calls binary, and git calls a file binary on a NUL near its start. **So a
# UTF-16 file is text a person reads and this gate never grades it.** That is the known gap, and
# it costs nothing here because nothing in this tree is UTF-16.
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
text=
unreadable=
lost=
returned=

main() {
    ensure_the_tree_reads
    ensure_iconv_is_here
    [ "${1:-}" = audit ] && prove_it_can_go_red

    text=$(tracked_text_files)
    ensure_something_was_read

    unreadable=$(files_no_decoder_can_read)
    lost=$(lines_that_lost_a_character)
    returned=$(files_holding_a_carriage_return)
    verdict
}

ensure_the_tree_reads() {
    git rev-parse --git-dir >/dev/null 2>&1 && return 0

    printf 'FAIL — this is not a git checkout, so nothing was read.\n'
    exit 3
}

# Absent, every `iconv` call fails and the gate names the whole tree as broken — then tells the
# reader to run the tool that is missing.
ensure_iconv_is_here() {
    command -v iconv >/dev/null 2>&1 && return 0

    printf 'FAIL — iconv is not on this host, so nothing was decoded.\n'
    exit 3
}

# Nothing to check is not a clean check. An empty list means `git grep` answered nothing, and a
# PASS over that says only that the gate ran.
ensure_something_was_read() {
    [ -n "$text" ] && return 0

    printf 'FAIL — no tracked text file was read.\n'
    exit 3
}

# A gate that has only ever been green proves nothing about what it would catch. The suite builds a
# repository, plants each byte and reads this script's exit code, so the gate line runs the proof
# and the scan in that order.
prove_it_can_go_red() {
    command -v bash >/dev/null 2>&1 || {
        printf 'FAIL — bash is not on this host, so the suite did not run.\n'
        exit 3
    }

    bash "$root/tests/bytes.sh" || exit 1
    printf '\n'
}

# `git grep -I` names the text files without listing the binaries, so one call decides what is
# worth decoding.
tracked_text_files() {
    git grep -I -l '' -- . 2>/dev/null
}

# Decoding happens here rather than in `git grep`, because git has no opinion on whether a text
# file decodes. The list is the one already read, so a gate cannot grade a different set than the
# one it counted.
files_no_decoder_can_read() {
    printf '%s\n' "$text" | while read -r file; do
        [ -n "$file" ] || continue
        iconv -f UTF-8 -t UTF-8 < "$file" >/dev/null 2>&1 || printf '%s\n' "$file"
    done
}

#
# `.gitattributes` pins `eol=lf` in the working tree and cannot speak for what was committed. This
# reads what was committed.
#
# **No pattern.** `tr` deletes the byte and `cmp` says whether anything went, so nothing here
# holds an escape a shell could eat — which is exactly how one got into a shipped script.
#
# **It costs two processes a file.** On this tree that is 23 seconds to 88 on Git Bash, and about
# a second under WSL, where the gate runs. A single `awk` would do it in one process and would
# need the escape back.
#
files_holding_a_carriage_return() {
    printf '%s\n' "$text" | while read -r file; do
        [ -n "$file" ] || continue
        tr -d '\r' < "$file" | cmp -s - "$file" || printf '%s\n' "$file"
    done
}

lines_that_lost_a_character() {
    git grep -n -I -e "$LOST" -- . 2>/dev/null
}

verdict() {
    [ -z "$unreadable" ] && [ -z "$lost" ] && [ -z "$returned" ] && {
        printf 'PASS — %d tracked text files decode, hold no carriage return, and say no character was lost.\n' \
            "$(printf '%s\n' "$text" | wc -l)"
        return 0
    }

    report_files_no_decoder_can_read
    report_lines_that_lost_a_character
    report_files_holding_a_carriage_return
    return 1
}

report_files_no_decoder_can_read() {
    [ -n "$unreadable" ] || return 0

    printf '%s\n' "$unreadable" | while read -r file; do
        printf '  FAIL  %s is not UTF-8\n' "$file"
    done
    printf '        Find the byte with: iconv -f UTF-8 -t UTF-8 < FILE > /dev/null\n'
}

report_files_holding_a_carriage_return() {
    [ -n "$returned" ] || return 0

    printf '%s\n' "$returned" | while read -r file; do
        printf '  FAIL  %s holds a carriage return\n' "$file"
    done
    printf '        A shipped script does not run with one: bash reads it as part of the last\n'
    printf '        word, and a hook that dies mid-parse exits 2. See .gitattributes.\n'
}

report_lines_that_lost_a_character() {
    [ -n "$lost" ] || return 0

    printf '%s\n' "$lost"
    printf '        A replacement character only ever means the real one is already gone.\n'
    printf '        Find what it should have been and write it again.\n'
}

main "$@"
