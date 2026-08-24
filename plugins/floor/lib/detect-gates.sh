#!/bin/sh
#
# Resolve a repository's gates: what it can be checked with, and what said so.
#
# This is the only file in floor that may know an ecosystem exists. The charter records a gate's
# name and what this printed. It never learns why. Adding a language here changes nothing above.
#
# One line per gate, whitespace separated:
#
#     name  source  command...
#
# `source` is the file that yielded the gate. The charter pins it, so a gate whose meaning moved is
# a file whose sha moved — no parser, and no list of ecosystem files kept anywhere else.
#
# A declared file wins over detection. That is §3's ladder: level 1 guesses, level 2 corrects it.
#
# Usage: sh detect-gates.sh <directory>
#

set -u
dir=${1:-.}

# The gates a repository declares: `name command...`, with `#` comments and blanks ignored. A
# file naming no gate yields nothing so detection still runs — returning 0 for one
# that is only comments made an empty declaration outrank every guess, and
# left `check` a charter with nothing to compare.
#
# `-r` as well as `-f`, because `awk` exits non-zero for a file that names no gate and
# for one it could not open, and the caller reads both as nothing declared.
declared() {
    [ -f "$dir/.foundry/gates" ] || return 1
    [ -r "$dir/.foundry/gates" ] || return 22

    awk '!/^[ \t]*#/ && NF { printf "%s .foundry/gates", $1; $1 = ""; print; found = 1 }
         END { exit !found }' "$dir/.foundry/gates"
}

#
# What the repository looks like it can be checked with.
#
# Deliberately crude. `grep` for a script name is not parsing, and being wrong here is cheap: the
# charter pins whatever was read, so a wrong guess is visible, and `.foundry/gates` overrides it.
#
detected() {
    [ -f "$dir/Makefile" ] && grep -q '^test:' "$dir/Makefile" \
        && { echo "tests Makefile make test"; return 0; }

    [ -f "$dir/composer.json" ] && grep -q '"test"' "$dir/composer.json" \
        && { echo "tests composer.json composer test"; return 0; }

    [ -f "$dir/package.json" ] && grep -q '"test"' "$dir/package.json" \
        && { echo "tests package.json npm test"; return 0; }

    return 1
}

# A declaration that is there and cannot be read is neither a declaration nor
# an absence. Falling to `detected` derives a bar the repository never asked for.
refuse_unreadable() {
    printf 'detect-gates: [%s] is there and cannot be read\n' "$dir/.foundry/gates" >&2
    exit 22
}

declared; said=$?

[ "$said" -eq 22 ] && refuse_unreadable
[ "$said" -eq 0 ] && exit 0

detected || exit 1
