#!/bin/sh
#
# Resolve a repository's gates: what it can be checked with, and what said so.
#
# **This is the only file in floor that may know an ecosystem exists.** The charter records a gate's
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

# The gates a repository declares for itself. `name command...`, `#` comments, blanks ignored.
declared() {
    [ -f "$dir/.foundry/gates" ] || return 1
    awk '!/^[ \t]*#/ && NF { printf "%s .foundry/gates", $1; $1 = ""; print }' "$dir/.foundry/gates"
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

declared || detected || exit 1
