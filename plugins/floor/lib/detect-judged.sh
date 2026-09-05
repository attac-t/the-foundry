#!/bin/sh
#
# Resolve a repository's judged clauses: what a person or a panel must answer, and what said so.
#
# A gate is answered by running it. A judged clause is answered by somebody who did not produce the
# work. Neither is a scale over the other — RFC-001 says the kinds are not ranked, and a judgement
# raised to a gate wants a command that cannot exist.
#
# Two kinds of line, whitespace separated:
#
#     judge          text...
#     reach  judge   command...
#
# `judge` is who may answer, and it is **one word** — `panel:adversary`, `a-reviewer`. A name holding
# a space would need quoting, and quoting needs a parser this declares none of. A gate's name is one
# word for the same reason.
#
# **A reach says how the runner asks that judge.** Without one a clause still derives, and only a
# person can answer it. With one, `run.sh judged` runs the command and reads what came back — so the
# command is the repository's, pinned in the charter, and never the caller's.
#
# **`reach` is a reserved first word**, and a judge may not be called it. Two record kinds in one
# file need a word to tell them apart, and only the first field can carry it. A clause whose judge is
# named `reach` is read as a reach line, and its command is that clause's own prose.
#
# The command is last for the reason a gate's is: `awk` blanks the leading fields and prints the
# rest, so spaces, quotes and `&&` need no parser and get none. That is also why the clause text
# cannot carry one — a line holds one tail, and the text is already it.
#
# **The name means whatever the repository means by it.** Floor compares it and reads nothing into
# it. One judge, several roles on one model, or several models — each is a repository's choice,
# and none needs a plugin it has not installed.
#
# **There is no source column.** This file is the source, so the charter pins every clause here to
# `.foundry/judged` — exactly as it pins a gate to the file that yielded it. A header once said
# otherwise, a README copied it, and a test wrote a line whose second word became part of the clause.
#
# **There is no detection half.** A repository cannot be guessed into wanting a judgement, and a
# clause nobody asked for is a bar nobody agreed to. Declared, or nothing.
#
# Usage: sh detect-judged.sh <directory>
#

set -u
dir=${1:-.}

# `#` comments and blanks ignored, like `.foundry/gates`. A file naming nothing yields nothing.
#
# A reach goes out as it was written. A clause gets its source inserted, because this file is where
# every clause here came from and the charter pins it there.
declared() {
    [ -f "$dir/.foundry/judged" ] || return 1
    [ -r "$dir/.foundry/judged" ] || return 22

    awk '!/^[ \t]*#/ && NF {
             found = 1
             if ($1 == "reach") { print; next }
             printf "%s .foundry/judged", $1; $1 = ""; print }
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
