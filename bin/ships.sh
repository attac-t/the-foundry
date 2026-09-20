#!/bin/sh
#
# What this repository already ships that answers to a word.
#
# **Written after saying *nothing here retrospects* three weeks after a skill for it shipped.** The
# owner caught it by reloading plugins. I had searched the issue tracker and nowhere else.
#
# **Three homes and I read one.** 27 scripts under `bin`, 138 plugin skills, 12 rules. A capability
# lives in whichever of those fits, and `guidance.md` says which — so a search of one home answers
# about one home.
#
# **The same fault three times in a day.** A grep for a literal filename missed a loop variable. A
# grep for a phrase found one row of six. A search of issues missed a skill. Each time the terms
# were the search, and each time the answer read like an absence.
#
# Usage: sh bin/ships.sh <word> [<word> ...]
#
# Exit: 0 something answers to it, 1 nothing does, 2 no word given.
#
# Not a gate. It answers a question a person asks before claiming an absence.

set -u

#
# **Settable, because a check nobody can point at a fixture cannot be driven.** Its own suite
# builds three homes with known contents and runs this against them, and none of it is in the
# tree.
readonly ROOT="${FOUNDRY_SHIPS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

say() { printf '%s\n' "$*"; }

main() {
    [ "$#" -ge 1 ] || { printf 'ships: name a word to look for\n' >&2; exit 2; }

    found=0

    for word in "$@"; do
        read_every_home "$word" && found=1
    done

    [ "$found" -eq 1 ] && return 0

    say "ships — nothing here answers to that. Now you may say so."
    return 1
}

#
# One word against all three homes. A home that answers prints its rows; one that does not stays
# quiet, because a list of empty headings is what made the last search look thorough.
read_every_home() {
    hits=$( { in_the_scripts "$1"; in_the_skills "$1"; in_the_rules "$1"; } | grep -c . )
    [ "$hits" -eq 0 ] && return 1

    say "ships — [$1] is answered by:"
    { in_the_scripts "$1"; in_the_skills "$1"; in_the_rules "$1"; } | sed 's/^/  /'
    say ''
    return 0
}

#
# A script says what it is in the comment block under its shebang, so the name and that block are
# what a reader meets. The body is where it says how, and how is not this question.
in_the_scripts() {
    for f in "$ROOT"/bin/*.sh; do
        [ -f "$f" ] || continue

        # Never itself. Its header names every word it was written about, so it answers to all of
        # them and says nothing a reader wanted.
        [ "$(basename "$f")" = ships.sh ] && continue

        head -24 "$f" | grep -qi -- "$1" || continue
        printf 'bin/%-18s %s\n' "$(basename "$f")" "$(sed -n '3p' "$f" | sed 's/^# *//')"
    done
}

# A skill's frontmatter says when to invoke it, which is the half a searcher needs.
in_the_skills() {
    for f in "$ROOT"/plugins/*/skills/*/SKILL.md; do
        [ -f "$f" ] || continue

        head -6 "$f" | grep -qi -- "$1" || continue

        plugin=${f#"$ROOT"/plugins/}; plugin=${plugin%%/*}
        skill=${f%/SKILL.md};         skill=${skill##*/}
        printf '%-22s %s\n' "$plugin:$skill" \
               "$(awk -F': ' '/^description:/ { print substr($2, 1, 58); exit }' "$f")"
    done
}

# A rule is one subject per file, and `CLAUDE.md` says what each owns in one line.
in_the_rules() {
    for f in "$ROOT"/.claude/rules/*.md; do
        [ -f "$f" ] || continue

        grep -qi -- "$1" "$f" || continue
        printf 'rules/%-17s %s\n' "$(basename "$f")" "$(sed -n '3p' "$f")"
    done
}

main "$@"
