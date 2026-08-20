#!/usr/bin/env bash
#
# Fails when shipped shell takes an `else`, or grows a body you must scroll.
#
# craft-sh states both rules. Nothing enforced them. `authorise` is the third judgment in its file's
# history about a body too long to read, and each one cost a review round.
#
# Reads `plugins/*/bin`, `plugins/*/lib` and `plugins/*/hooks` — what a user runs. Not `tests/`: the
# suites are bash on purpose and hold no such rule. Not `.awk` either, where `else` is idiomatic.
#
# An awk `else` written inside a `.sh` still fails, because this reads files rather than languages.
# An embedded program that wants a branch has outgrown a single-quoted string; move it to `lib`.
#
# The length half gates a number, not the rule. craft-sh says length is the *signal* that another
# function is merited, and no exit code reads a signal. This gates one thing, and says so: no body
# past MAX lines.
#
# No `set -e`. Both halves run, so one break never hides the other.
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -u

# The healthy band here tops out at 28 lines. MAX sits above every body anyone wrote and called
# done, and below both the ones a reviewer has stopped on.
readonly MAX=40

# The two already past MAX — `authorise` at 105 lines, `derive_charter` at 46. Named, not waived by
# lifting MAX above them, which would gate nothing at all.
#
# A name that falls under MAX fails here as a debt already paid, so this list only ever shrinks.
readonly DEBT='plugins/floor/bin/run.sh:authorise
plugins/floor/bin/run.sh:derive_charter'

main() {
    cd "$(dirname "$0")/.." || exit 3

    shipped > "$files"
    [ -s "$files" ] || { printf 'FAIL — no shipped shell found. This gate read nothing.\n'; exit 3; }

    printf '%s\n' "$DEBT" > "$owed"
    measure > "$measured"

    report 'an else is a function nobody named' "$(branches)"
    report "a body past $MAX lines"             "$(overlong)"
    report 'a pipe that hides a failure'        "$(piped)"

    verdict
}

# What a user runs. `find`, not `git ls-files` — the gate reads the same files from a checkout, a
# worktree or a copy inside a container, and git answers for only the first.
shipped() {
    find plugins -type f -name '*.sh' \
        \( -path '*/bin/*' -o -path '*/lib/*' -o -path '*/hooks/*' \) | sort
}

# --- the branch ---

# `else` and `elif` where a command can start, on a line that is not wholly a comment.
#
# Text, not shell, deliberately. A whole-line comment cannot hide code, so skipping one cannot let a
# branch through; anything left that reads as a branch is called one.
#
# Prose survives because prose is never in command position. `elsewhere` and "nothing else." both
# sit mid-sentence, after a letter. The gate that cries wolf is the gate somebody switches off.
#
# The alternation is spelled `el(se|if)` so that this line holds neither word whole. Spelled the
# obvious way, the gate reads its own pattern as a branch — a linter that breaks its own rule is the
# joke that writes itself.
branches() {
    while IFS= read -r file; do
        awk '
            /^[ \t]*#/ { next }
            /(^|[;&|{(])[ \t]*el(se|if)([ \t;&|)}]|$)/ { printf "  %s:%d %s\n", FILENAME, FNR, $0 }
        ' "$file"
    done < "$files"
}

# --- the pipe ---

# A command a pipe reports for, and a failure nobody sees.
#
# A pipeline answers with its last stage, so `gh ... | awk` is awk's verdict — and awk succeeds on
# nothing at all. Seven times across three plugins a read that failed has been taken for an absence,
# and twice the answer to that absence was to write: a second delivery opened, a human asked again.
#
# Only where the tool is not last. `printf | git hash-object` reports git, which is the point of
# writing it that way, and `printf` and `echo` are absent because they cannot fail in a way anyone
# would act on.
#
# `[^|]*\|[^|]` is what tells a pipe from an `||`: the second bar of an `||` has the first before it,
# and `[^|]*` cannot reach past the first to find it.
piped() {
    while IFS= read -r file; do
        awk '
            /^[ \t]*#/ { next }
            /(^|[ \t;&|{(])(gh|git|curl|wget)[ \t][^|]*\|[^|]/ { printf "  %s:%d %s\n", FILENAME, FNR, $0 }
        ' "$file"
    done < "$files"
}

# --- the body ---

# One line per function: body length, then `file:name`.
#
# A body closes on a `}` in column 0, which is how every file here writes one. One that never closes
# runs to the end of the file and fails on its length — a shape this cannot read is reported, never
# skipped.
measure() {
    while IFS= read -r file; do
        awk '
            /^[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(\)[ \t]*\{[ \t]*(#.*)?$/ {
                name = substr($0, 1, index($0, "(") - 1)
                sub(/[ \t]*$/, "", name)
                opened = FNR
                next
            }
            name != "" && /^\}[ \t]*$/ { print FNR - opened - 1, FILENAME ":" name; name = "" }
            END { if (name != "") print FNR - opened, FILENAME ":" name }
        ' "$file"
    done < "$files"
}

# Both directions. A body over MAX that DEBT does not hold is a new one. A name DEBT holds that is
# no longer over MAX is a debt already paid, and that half is why the list can only get shorter.
overlong() {
    awk -v max="$MAX" '
        NR == FNR { owed[$0] = 1; next }

        $1 > max { over[$2] = 1 }
        $1 > max && !($2 in owed) { printf "  %s  %s lines\n", $2, $1 }

        END {
            for (name in owed) {
                if (!(name in over)) printf "  %s  no longer over %s — drop it from DEBT\n", name, max
            }
        }
    ' "$owed" "$measured"
}

# --- the verdict ---

# Silence is a pass. Every finding the halves print is a line the reader can go and open.
report() {
    [ -z "$2" ] && { printf '  PASS  %s\n' "$1"; return; }

    printf '  FAIL  %s\n%s\n' "$1" "$2"
    broken=$((broken + 1))
}

verdict() {
    [ "$broken" -eq 0 ] \
        && { printf '\nPASS — %s shipped scripts read down, not sideways.\n' "$(wc -l < "$files" | tr -d ' ')"; exit 0; }

    printf '\n%d RED\n' "$broken"
    exit 1
}

work=${TMPDIR:-/tmp}/foundry-shell-$$
mkdir -p "$work" || exit 3
trap 'rm -rf "$work"' EXIT

files="$work/files"
owed="$work/owed"
measured="$work/measured"
broken=0

main "$@"
