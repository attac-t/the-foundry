#!/bin/sh
#
# Resolve a repository's judged clauses: what a person or a panel must answer, and what said so.
#
# A gate is answered by running it. A judged clause is answered by somebody who did not produce the
# work. Neither is a scale over the other — RFC-001 says the kinds are not ranked, and a judgement
# raised to a gate wants a command that cannot exist.
#
# One line per clause, whitespace separated:
#
#     judge  source  text...
#
# `judge` is who may answer, and it is **one word** — `panel:adversary`, `a-reviewer`. A name holding
# a space would need quoting, and quoting needs a parser this declares none of. A gate's name is one
# word for the same reason.
#
# `source` is the file that yielded it, so the charter can pin it exactly as it pins a gate.
#
# **There is no detection half.** A repository cannot be guessed into wanting a judgement, and a
# clause nobody asked for is a bar nobody agreed to. Declared, or nothing.
#
# Usage: sh detect-judged.sh <directory>
#

set -u
dir=${1:-.}

# `#` comments and blanks ignored, like `.foundry/gates`. A file naming nothing yields nothing.
declared() {
    [ -f "$dir/.foundry/judged" ] || return 1
    [ -r "$dir/.foundry/judged" ] || return 22

    awk '!/^[ \t]*#/ && NF { printf "%s .foundry/judged", $1; $1 = ""; print; found = 1 }
         END { exit !found }' "$dir/.foundry/judged"
}

# A declaration that is there and cannot be read is not an absence. Carrying on
# would derive a charter missing a bar the repository asked for.
refuse_unreadable() {
    printf 'detect-judged: [%s] is there and cannot be read\n' "$dir/.foundry/judged" >&2
    exit 22
}

declared; said=$?

[ "$said" -eq 22 ] && refuse_unreadable
exit "$said"
