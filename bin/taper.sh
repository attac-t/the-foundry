#!/bin/sh
#
# Fails when a three-line comment paragraph does not narrow by three each time.
#
# `craft-comment` states the shape. `bin/shell.sh` graded shipped shell only, matched no
# indented comment, and lost any paragraph a bare `#` fenced. #369 and #398 own that gap.
#
# Reads every first-party `.sh` and `.awk` under `plugins/` and `bin/`, tests
# included. A comment reads the same way whatever the file around it is for.
#
#   sh bin/taper.sh          grade
#   sh bin/taper.sh write    reflow the paragraphs that fit, in place
#   sh bin/taper.sh debt     print the exemption list this tree needs
#   sh bin/taper.sh audit    break it eight ways, require each to answer
#
# Exit: 0 clean, 1 a paragraph misses and nothing names it, 3 it read nothing

set -u

# Above this a line is prose somebody wrapped at the margin. Nobody hand-shapes
# one that long, so a wide paragraph is left alone.
readonly WIDE=90
readonly STEP=3

#
# The paragraphs this tree cannot fix by reflowing, one per line.
#
# A taper's three lengths sum to three times the middle one, so a split exists only when
# the words fall exactly right. Most never do, and those are reworded rather than reflowed.
#
# Keyed on the opening line, so rewording one drops it from here on its own.
# This list only shrinks. Nothing may be added to it.
readonly DEBT=bin/taper.debt

work=$(mktemp -d) || exit 3
trap 'rm -rf "$work"' EXIT
readonly found="$work/found"
readonly files="$work/files"

main() {
    cd "$(dirname "$0")/.." || exit 3

    [ "${1:-check}" = audit ] && { audit; exit $?; }

    first_party > "$files"
    [ -s "$files" ] || { printf 'FAIL — no first-party shell found. It read nothing.\n'; exit 3; }

    [ "${1:-check}" = write ] && { reflow_each; exit 0; }

    grade_each > "$found"
    [ "${1:-check}" = debt ] && { cut -f1,7 "$found"; exit 0; }

    verdict
}

# --- what it reads ---

# `find`, not `git ls-files`: the gate reads the same files from a checkout, a
# worktree or a copy inside a container, and git answers for only the first.
first_party() {
    find plugins bin -type f \( -name '*.sh' -o -name '*.awk' \) \
        ! -path '*/node_modules/*' ! -path '*/.git/*' | sort
}

# One file at a time. `END` runs once for a whole stream, so one awk over every
# file would read the last and call the rest clean.
grade_each() {
    while read -r file; do
        [ -f "$file" ] && grade_one "$file"
    done < "$files"
}

grade_one() {
    LC_ALL=C awk -v mode=check -v wide="$WIDE" -v step="$STEP" \
        -f "$(dirname "$0")/taper.awk" "$1"
}

# --- write mode ---

reflow_each() {
    while read -r file; do
        [ -f "$file" ] && reflow_one "$file"
    done < "$files"
}

# Built beside the file and copied onto it, so a killed run leaves no half script.
reflow_one() {
    write_one "$1" > "$work/out" || return 1

    cmp -s "$work/out" "$1" && return 0

    cp "$work/out" "$1" && printf '  wrote  %s\n' "$1"
}

# The file as it would be, printed. Nothing on disk moves.
write_one() {
    LC_ALL=C awk -v mode=write -v wide="$WIDE" -v step="$STEP" \
        -f "$(dirname "$0")/taper.awk" "$1"
}

# --- the verdict ---

# A finding nothing names is a break. A list line matching no finding is a
# repair somebody already made, and it goes.
verdict() {
    unnamed > "$work/unnamed"
    stale   > "$work/stale"

    report 'a taper that does not step down by three' "$(cat "$work/unnamed")"
    report 'a named exemption that no longer applies' "$(cat "$work/stale")"

    [ -s "$work/unnamed" ] || [ -s "$work/stale" ] && exit 1

    printf 'PASS — %s files read, %s paragraphs named in %s.\n' \
        "$(lines_in "$files")" "$(lines_in "$DEBT")" "$DEBT"
}

report() {
    [ -z "$2" ] && { printf '  PASS  %s\n' "$1"; return; }

    printf '  FAIL  %s\n%s\n' "$1" "$2"
}

# A finding whose file and opening line the list does not hold.
unnamed() {
    awk -F'\t' -v debt="$DEBT" '
        BEGIN { while ((getline said < debt) > 0) named[said] = 1 }
        !(($1 "\t" $7) in named) {
            printf "    %s:%d  %d %d %d  (steps %d %d, want 3 3) — %s\n",
                $1, $2, $3, $4, $5, $3 - $4, $4 - $5, $6
        }
    ' "$found"
}

stale() {
    awk -F'\t' '
        NR == FNR { seen[$1 "\t" $7] = 1; next }
        !($0 in seen) { printf "    %s — drop it from %s\n", $0, FILENAME }
    ' "$found" "$DEBT"
}

lines_in() { grep -c '' "$1" 2>/dev/null || printf 0; }

# --- break it ---

#
# A gate nobody has watched go red is a gate nobody has tested.
#
# Each case is a whole file, never a fragment. The scan reads a paragraph by what sits
# above and below it, so a fragment would answer a question the real thing never puts.
audit() {
    broke=0

    catches 'a three-line block that does not step' a_block_that_misses
    catches 'a block a bare # fences from the code' a_fenced_block
    catches 'an indented block'                     an_indented_block
    catches 'a block above no code at all'          a_floating_block

    catches 'a block whose words are not ASCII'  a_block_in_another_script
    catches 'a block under a comment naming a heredoc' a_block_under_a_mention

    leaves 'a link alone'               a_block_holding_a_link
    leaves 'an indented example alone'  a_block_holding_a_sample
    leaves 'a wrapped paragraph alone'  a_wide_block
    leaves 'a heredoc alone'            a_block_beside_a_heredoc

    reads_beyond_shipped_shell

    reflows_once

    [ "$broke" -eq 0 ] && { printf 'AUDIT PASS — every break answered.\n'; return 0; }
    return 1
}

# Red is the answer. A break this gate reads as clean is a break it cannot see.
catches() {
    "$2" > "$work/case.sh"
    [ -n "$(grade_one "$work/case.sh")" ] && { printf '  ok    %s is caught\n' "$1"; return; }

    printf '  FAIL  %s is not caught\n' "$1"
    broke=1
}

# Green is the answer. A shape a reflow would damage must never be graded.
leaves() {
    "$2" > "$work/case.sh"
    [ -z "$(grade_one "$work/case.sh")" ] && { printf '  ok    %s\n' "$1"; return; }

    printf '  FAIL  %s — it was graded\n' "$1"
    broke=1
}

# --- the fixtures ---

a_block_that_misses() {
    echo '# aaaaaaaaaaaaaaaaaaaa'
    echo '# bbbb'
    echo '# cc'
    echo 'code'
}

# The escape #398 names: a bare hash between paragraphs, hiding the bad one.
a_fenced_block() {
    echo '# first paragraph here'
    echo '#'
    a_block_that_misses
}

an_indented_block() {
    echo 'f() {'
    a_block_that_misses | sed 's/^/    /'
    echo '}'
}

a_floating_block() {
    echo '# aaaaaaaaaaaaaaaaaaaa'
    echo '# bbbb'
    echo '# cc'
}

a_block_holding_a_link() {
    echo '# see https://example.com/a/b for the reason'
    echo '# bbbb'
    echo '# cc'
    echo 'code'
}

a_block_holding_a_sample() {
    echo '# what it prints:'
    echo '#    one two three'
    echo '# cc'
    echo 'code'
}

# Ninety-one bytes on the opener, which is what WIDE calls wrapped prose.
a_wide_block() {
    echo "# $(awk 'BEGIN { while (i++ < 89) printf "a" }')"
    echo '# bbbb'
    echo '# cc'
    echo 'code'
}

# Bytes, not characters. An em-dash costs three it never shows, so a
# paragraph holding one is graded on what a formatter reproduces.
a_block_in_another_script() {
    echo '# aaaa — bbbb — cccc'
    echo '# dddd'
    echo '# ee'
    echo 'code'
}

# A comment naming a heredoc is not one. Reading it as an opener shut every
# block below it, which is the fault this proves.
a_block_under_a_mention() {
    echo '# the body goes in a <<EOF block'
    echo '#'
    a_block_that_misses
}

# A heredoc body is not a comment, whatever it holds.
a_block_beside_a_heredoc() {
    echo 'cat <<EOF'
    echo '# aaaaaaaaaaaaaaaaaaaa'
    echo '# bbbb'
    echo '# cc'
    echo 'EOF'
}

#
# The scope, which is the whole of what #369 measured.
#
# The old check read `plugins/*/bin`, `lib` and `hooks`. A test file and an
# awk program hold comments too, and nothing was reading either.
reads_beyond_shipped_shell() {
    said=$(first_party)

    printf '%s
' "$said" | grep -q '/tests/.*\.sh$'         || { printf '  FAIL  it reads no test file
'; broke=1; return; }

    printf '%s
' "$said" | grep -q '\.awk$'         || { printf '  FAIL  it reads no awk program
'; broke=1; return; }

    printf '  ok    tests and awk are in scope
'
}

# Twelve words that split 25, 22, 19 — wrapped here so that they do not.
a_fixable_block() {
    echo '# one two three'
    echo '# four five six seven eight'
    echo '# nine ten eleven twelve'
    echo 'code'
}

#
# Write mode fixes what fits, and says the same thing twice.
#
# Reflowing is only ever whitespace, so a second pass over its own output has to come
# back byte for byte. A formatter that keeps moving is one nobody can put inside a gate.
reflows_once() {
    a_fixable_block > "$work/fit.sh"
    [ -n "$(grade_one "$work/fit.sh")" ] || { printf '  FAIL  the fixture was already clean\n'; broke=1; return; }

    write_one "$work/fit.sh" > "$work/fit.1"
    write_one "$work/fit.1"  > "$work/fit.2"

    [ -z "$(grade_one "$work/fit.1")" ] || { printf '  FAIL  write mode did not fix it\n'; broke=1; return; }

    cmp -s "$work/fit.1" "$work/fit.2" \
        && { printf '  ok    write mode fixes it, and twice says the same\n'; return; }

    printf '  FAIL  write mode moved on its second pass\n'
    broke=1
}

main "$@"
