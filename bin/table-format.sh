#!/bin/sh
#
# Every Markdown table in this tree, in the one shape `bin/table-format.awk` gives it.
#
#   sh bin/table-format.sh          name every file that is not canonical, and refuse
#   sh bin/table-format.sh write    make them canonical
#   sh bin/table-format.sh list     name the files it reads, and read none
#
# **Shape only.** Whether a row is too wide to read belongs to `bin/table-width.sh`, which runs
# after this one and answers a different question.
#
# `.claude/memory`, `.claude/worktrees` and `.claude/panel` hold working state, not documents anyone
# is asked to read. Nothing else is excluded. Tracked files only, so a draft nobody added is left
# alone — which also means a new file is unseen until `git add`.
#
# Exit: 0 canonical. 1 a file would change. 2 called wrongly. 3 a file could not be read.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

readonly FORMATTER=bin/table-format.awk
readonly SCRATCH=${TMPDIR:-/tmp}/table-format-$$
readonly LIST=${TMPDIR:-/tmp}/table-format-list-$$

mode=${1:-check}
ragged=0

main() {
    refuse_an_unknown_mode
    [ "$mode" = list ] && { files_it_reads; exit 0; }

    trap 'rm -f "$SCRATCH" "$LIST"' EXIT

    # Read from a file, never through a pipe. A `while` after a pipe runs in a subshell: its counter
    # dies there, and the EXIT trap the subshell inherited deletes the scratch on the way out.
    files_it_reads > "$LIST" || exit 3
    while_each_file < "$LIST"
    report
}

refuse_an_unknown_mode() {
    case "$mode" in
        check|write|list) return 0 ;;
    esac

    printf 'table-format: no such mode [%s] — check, write or list\n' "$mode" >&2
    exit 2
}

files_it_reads() {
    git ls-files -z '*.md' \
        | tr '\0' '\n' \
        | grep -v '^\.claude/memory/' \
        | grep -v '^\.claude/worktrees/' \
        | grep -v '^\.claude/panel/'
}

# `read -r` with an empty `IFS`, so a path holding a space stays one path. `for f in $(...)` splits
# on it.
while_each_file() {
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        format_into "$file" "$SCRATCH"

        [ "$mode" = write ] && { keep_if_it_changed "$file" "$SCRATCH"; continue; }
        name_it_if_it_changed "$file" "$SCRATCH"
    done
}

# `LC_ALL=C` belongs to the run, never to the reader's shell. See the formatter's header.
format_into() {
    LC_ALL=C awk -f "$FORMATTER" < "$1" > "$2" || {
        printf 'table-format: could not read [%s]\n' "$1" >&2
        exit 3
    }
}

keep_if_it_changed() {
    cmp -s "$2" "$1" && return 0

    cat "$2" > "$1" || { printf 'table-format: could not write [%s]\n' "$1" >&2; exit 3; }
    printf '  formatted  %s\n' "$1"
    ragged=$((ragged + 1))
}

name_it_if_it_changed() {
    cmp -s "$2" "$1" && return 0

    printf '  RAGGED  %s%s\n' "$1" "$(first_line_that_differs "$1" "$2")"
    ragged=$((ragged + 1))
}

# The line number is what turns a refusal into a fix. `cmp` names a byte, so the line comes from
# counting newlines before it.
first_line_that_differs() {
    byte=$(cmp "$1" "$2" 2>/dev/null | sed -n 's/.*byte \([0-9]*\).*/\1/p')
    [ -n "${byte:-}" ] || return 0

    printf ':%s' "$(head -c "$byte" "$1" | wc -l | tr -d ' ')"
}

report() {
    [ "$ragged" -eq 0 ] && { printf 'PASS — every table is canonical.\n'; exit 0; }
    [ "$mode" = write ] && { printf 'WROTE — %s files.\n' "$ragged"; exit 0; }

    printf 'FAIL — %s files hold a table nothing formatted. Run `sh bin/table-format.sh write`.\n' \
        "$ragged" >&2
    exit 1
}

main "$@"
