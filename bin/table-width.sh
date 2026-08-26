#!/bin/sh
#
# Refuses a table row that is too wide to read where it is read.
#
#   sh bin/table-width.sh          name every row over the budget, and refuse
#   sh bin/table-width.sh list     name the files it reads, and read none
#
# **It measures the source line, after formatting.** Padding makes a row as wide as its widest cell,
# so one long cell drags every row out with it. A row nobody can read unrendered is the thing this
# refuses, and `bin/table-format.sh` is what made the row that wide.
#
# The two run in that order and answer different questions. Shape first, then whether the shape is
# usable. Either runs alone.
#
# Bytes, not code points. A budget is about a line fitting a window, and every byte over the budget
# is a byte the reader scrolls past. Under `LC_ALL=C` so the number means one thing.
#
# Exit: 0 within budget. 1 a row is over it. 2 called wrongly. 3 a file could not be read.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

# 120 is the wrap this tree already writes prose to. A table row is read the same way and in the
# same window, so it gets the same number rather than a second one to remember.
readonly BUDGET=120
readonly LIST=${TMPDIR:-/tmp}/table-width-list-$$

mode=${1:-check}
over=0

main() {
    refuse_an_unknown_mode
    [ "$mode" = list ] && { files_it_reads; exit 0; }

    trap 'rm -f "$LIST"' EXIT

    # From a file, never through a pipe. `table-format.sh` says why.
    files_it_reads > "$LIST" || exit 3
    while_each_file < "$LIST"
    report
}

refuse_an_unknown_mode() {
    case "$mode" in
        check|list) return 0 ;;
    esac

    printf 'table-width: no such mode [%s] — check or list\n' "$mode" >&2
    exit 2
}

files_it_reads() { sh bin/table-format.sh list; }

# A path holding a space stays one path. See `table-format.sh` for why that is written out.
while_each_file() {
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        name_the_wide_rows_in "$file"
    done
}

# A divider row is as wide as the row it divides and carries no words, so naming it as well would
# double every finding without adding one.
name_the_wide_rows_in() {
    found=$(LC_ALL=C awk -v budget="$BUDGET" '
        /^[ \t]*(```|~~~)/ { fenced = !fenced }
        fenced                          { next }
        /^[ \t]*\|/ && !/^[ \t]*\|[ :-]*\|/ && length($0) > budget {
            printf "  %s:%d  %d bytes\n", FILENAME, FNR, length($0)
        }
    ' "$file") || { printf 'table-width: could not read [%s]\n' "$file" >&2; exit 3; }

    [ -n "$found" ] || return 0

    printf '%s\n' "$found"
    over=$((over + $(printf '%s\n' "$found" | wc -l)))
}

report() {
    [ "$over" -eq 0 ] && { printf 'PASS — every table row fits %s bytes.\n' "$BUDGET"; exit 0; }

    printf 'FAIL — %s rows are wider than %s bytes. Shorten a cell, or link out of it.\n' \
        "$over" "$BUDGET" >&2
    exit 1
}

main "$@"
