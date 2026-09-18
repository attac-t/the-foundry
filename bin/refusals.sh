#!/bin/sh
#
# Every place a script stops, as `function<TAB>code<TAB>what it said`.
#
# **A refusal is a site, never a code.** Floor's runner stops eighty-eight times across thirty-six
# codes, so a reader who counts codes counts a third of what is there — and a page keyed on them
# hands a new refusal a row it never earned.
#
# **The three fields are the key, and each was measured before it was chosen.** The message alone
# separates 81 of 88, the function and code 84, and the three together 87. What the third cannot
# separate is two sites that say nothing of their own, which is a fault in the script rather than in
# the key.
#
# **Not a line number.** It moves on every edit above it, and nothing about the refusal changed. A
# reworded message is a new refusal and should cost a row; a shifted line is not and should not.
#
# Usage: sh bin/refusals.sh <script>...
#
# Exit: 0 the sites are on stdout, 2 no script was named, 3 a named script could not be read.

set -eu

TAB=$(printf '\t')

main() {
    [ "$#" -gt 0 ] || fail 2 'name at least one script'

    for script in "$@"; do
        [ -r "$script" ] || fail 3 "[$script] could not be read"
        sites_in "$script"
    done
}

#
# One `awk` and no second pass. A second read would have to find the enclosing function again, and
# the first pass already knows it.
#
# **The message is taken from at most three lines back.** A refusal explains itself where it stops,
# and a note further away belongs to something else — six sites here print nothing that close, and
# calling a stranger's sentence theirs would be worse than saying they are silent.
sites_in() {
    awk '
        /^[a-z_]+\(\) \{/ { fn = $1; sub(/\(\).*/, "", fn) }

        # The whole `note "..."`, never a fragment. A message holding a quote would end early, and a
        # truncated sentence reads like a different refusal.
        match($0, /note "[^"]*"/) { said = substr($0, RSTART + 6, RLENGTH - 7); at = NR }

        #
        # A statement, never prose. `usage` prints `exit 1, 5, 8` and the comments name codes too,
        # and reading either counts a site nobody can reach. The comma after the first number is
        # what tells them apart: a statement ends, a list goes on.
        #
        # **Both shapes, and the second is most of them.** A guard writes `|| { note "…"; exit 2; }`
        # on one line seventy times here, against eighteen standing alone. A reader anchored to the
        # line start finds the eighteen and reports them as the whole.
        {
            line = $0
            sub(/^[ \t]*#.*/, "", line)

            while (match(line, /(^[ 	]*|[;{}&|][ \t]*)exit [0-9]+[ \t]*($|[;}])/)) {
                code = substr(line, RSTART, RLENGTH)
                sub(/^.*exit /, "", code)
                sub(/[^0-9].*/, "", code)

                printf "%s\t%s\t%s\n", fn, code, (NR - at <= 3 ? said : "")
                line = substr(line, RSTART + RLENGTH)
            }
        }
    ' "$1"
}

fail() { printf 'refusals: %s\n' "$2" >&2; exit "$1"; }

main "$@"
