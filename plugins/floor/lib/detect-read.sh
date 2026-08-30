#!/bin/sh
#
# Resolve the artefacts a repository says must be read cold before they ship.
#
# A gate is answered by running it. A judged clause is answered by somebody who did not produce the
# work. **A cold read is the second kind**, so this yields judged clauses and nothing new: every
# refusal Floor already makes then applies unchanged.
#
# One line per artefact, whitespace separated:
#
#     reader  path
#
# `reader` is who may answer, one word, exactly as in `.foundry/judged`. `path` is the file that has
# to be understood by somebody who was not there.
#
# **The clause is pinned to the artefact, not to the declaration.** Change the file and the verdict
# about it is about an older file — Floor already refuses that at 35. Staleness costs no new rule.
#
# **Selective, never every file.** A repository names the few whose meaning has to survive a cold
# read. A bar over the whole tree is a bar nobody meets.
#
# Usage: sh detect-read.sh <directory>
#

set -u
dir=${1:-.}

# `#` comments and blanks ignored, like `.foundry/gates`. A file naming nothing yields nothing.
declared() {
    [ -f "$dir/.foundry/read" ] || return 1
    [ -r "$dir/.foundry/read" ] || return 22

    awk 'BEGIN { found = 0 }
         !/^[ \t]*#/ && NF >= 2 {
             printf "%s %s [%s] was understood by somebody who did not write it\n", $1, $2, $2
             found = 1
         }
         END { exit !found }' "$dir/.foundry/read"
}

# A declaration that is there and cannot be read is not an absence. Carrying on
# would derive a charter missing a bar the repository asked for.
refuse_unreadable() {
    printf 'detect-read: [%s] is there and cannot be read\n' "$dir/.foundry/read" >&2
    exit 22
}

declared; said=$?

[ "$said" -eq 22 ] && refuse_unreadable
exit "$said"
