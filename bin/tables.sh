#!/bin/sh
#
# Every Markdown table in this tree, formatted the same way by a program.
#
#   sh bin/tables.sh          name every file that is not canonical, and refuse
#   sh bin/tables.sh write    make them canonical
#   sh bin/tables.sh list     name the files it reads, and read none
#
# `.claude/memory`, `.claude/worktrees` and `.claude/panel` are working state, not documents anyone
# is asked to read. Nothing else is excluded.
#
# The writing rule used to argue that no gate could hold alignment, because `length` counts bytes in
# one locale and characters in another. That is true of `length` and false of the conclusion:
# `tables.awk` counts UTF-8 code points itself, under `LC_ALL=C`, and answers the same everywhere.
#
# Exit: 0 canonical. 1 a file would change. 2 called wrongly. 3 a file could not be read.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

readonly FORMATTER=bin/tables.awk
readonly SCRATCH=${TMPDIR:-/tmp}/tables-$$

mode=${1:-check}
ragged=0

main() {
    refuse_an_unknown_mode
    [ "$mode" = list ] && { files_it_reads; exit 0; }

    trap 'rm -f "$SCRATCH"' EXIT

    for file in $(files_it_reads); do
        format_into "$file" "$SCRATCH"
        [ "$mode" = write ] && { keep_if_it_changed "$file" "$SCRATCH"; continue; }
        name_it_if_it_changed "$file" "$SCRATCH"
    done

    report
}

refuse_an_unknown_mode() {
    case "$mode" in
        check|write|list) return 0 ;;
    esac

    printf 'tables: no such mode [%s] — check, write or list\n' "$mode" >&2
    exit 2
}

# Tracked Markdown only. An untracked file is somebody's draft, and a gate that
# refuses one is a gate that refuses to let them think.
files_it_reads() {
    git ls-files '*.md' \
        | grep -v '^\.claude/memory/' \
        | grep -v '^\.claude/worktrees/' \
        | grep -v '^\.claude/panel/'
}

# `LC_ALL=C` belongs to the run, not to the reader's shell. See the header.
format_into() {
    LC_ALL=C awk -f "$FORMATTER" < "$1" > "$2" || {
        printf 'tables: could not read [%s]\n' "$1" >&2
        exit 3
    }
}

keep_if_it_changed() {
    cmp -s "$2" "$1" && return 0

    cat "$2" > "$1" || { printf 'tables: could not write [%s]\n' "$1" >&2; exit 3; }
    printf '  formatted  %s\n' "$1"
    ragged=$((ragged + 1))
}

name_it_if_it_changed() {
    cmp -s "$2" "$1" && return 0

    printf '  RAGGED  %s%s\n' "$1" "$(first_line_that_differs "$1" "$2")"
    ragged=$((ragged + 1))
}

# The line number is what turns a refusal into a fix. `cmp` reports a byte, so
# the line comes from counting newlines before it.
first_line_that_differs() {
    byte=$(cmp "$1" "$2" 2>/dev/null | sed -n 's/.*byte \([0-9]*\).*/\1/p')
    [ -n "${byte:-}" ] || return 0

    printf ':%s' "$(head -c "$byte" "$1" | wc -l | tr -d ' ')"
}

report() {
    [ "$ragged" -eq 0 ] && { printf 'PASS — every table is canonical.\n'; exit 0; }

    [ "$mode" = write ] && { printf 'WROTE — %s files.\n' "$ragged"; exit 0; }

    printf 'FAIL — %s files hold a table nothing formatted. Run `sh bin/tables.sh write`.\n' "$ragged" >&2
    exit 1
}

main "$@"
