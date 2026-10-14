#!/bin/sh
#
# Fails when floor's code names a file under `.foundry/` that `deliver` does not refuse to carry.
#
# `deliver` refuses a run whose diff touches a file a pass reads its rules from, named in one line of
# `rules_changed_between`. #1101. Floor's readers name the same files, and nothing tied the two.
#
# So a fourth file a pass obeys would be named where it is read and never refused, and nothing would
# say so. This says so. #1184.
#
# **One list is what floor's code names, and the other is the refusal.** A file only the refusal
# names fails safe, since deliver then refuses more than anything reads, so it is never named here.
#
# **A line whose first non-blank character is `#` names nothing**, on either side, as `providers`
# reads one. On floor's side a comment after code sits on a code line, and counts.
#
# **The refusal is its pathspec**: the names after ` -- `, up to a redirect, a comment or a separator.
# A name anywhere else in that function, in a note or a guard, refuses nothing.
#
# **A name is taken whole**, so `.foundry/gates2` is not `gates`. A path whose name is not spelled
# out fails, since nothing can say whether a name it cannot read is refused.
#
# Every file in floor's `bin`, `lib`, `hooks` and `adapters`, whatever its extension, and no `tests/`.
#
# POSIX `sh` and `awk`. `audit` also needs `bash`, because the suite is bash like every suite here.
#
# Usage: sh bin/rulefiles.sh
#        sh bin/rulefiles.sh audit   drive tests/rulefiles.sh first, then the check
#
# Exit: 0 deliver refuses every file floor's code names, 1 one it does not, 3 the gate could not read
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

FLOOR=plugins/floor
PARTS='bin lib hooks adapters'
REFUSAL=rules_changed_between

main() {
    [ "${1:-}" = audit ] && prove_it_can_go_red

    ensure_floor_is_here
    refused=$(names_in "$FLOOR/bin/run.sh" "$REFUSAL" | cut -f1 | sort -u)
    ensure_the_refusal_was_read

    named=$(names_floor_code_holds)
    wrong=$(each_name_not_refused)
    verdict
}

# Every name floor's files hold, as `<name>\t<file>:<line>`.
names_floor_code_holds() {
    floor_files | while IFS= read -r file; do
        names_in "$file" ''
    done
}

floor_files() {
    for part in $PARTS; do
        find "$FLOOR/$part" -type f ! -path '*/tests/*'
    done | sort
}

# A part that is not there would be read as clean, since `find` fails inside the pipe that lists them.
ensure_floor_is_here() {
    for part in $PARTS; do
        [ -d "$FLOOR/$part" ] && continue
        printf 'FAIL — floor ships no `%s` here, so it was not read.\n' "$part"
        exit 3
    done
}

names_in() { awk -v within="$2" -f bin/rulefiles.awk "$1"; }

ensure_the_refusal_was_read() {
    [ -n "$refused" ] && return 0
    printf 'FAIL — `%s` names no file under `.foundry/`, so nothing can be held to it.\n' "$REFUSAL"
    exit 3
}

# One line a name, where it is named, so a reader goes straight to it.
each_name_not_refused() {
    printf '%s\n' "$named" | awk -F'\t' -v refused="$(printf '%s ' $refused)" '
        BEGIN                     { n = split(refused, list, " "); for (i = 1; i <= n; i++) held[list[i]] = 1 }
        $1 == "?"                 { printf "%s  a `.foundry/` path whose name is not spelled out\n", $2; next }
        $1 != "" && !($1 in held) { printf "%s  `.foundry/%s`, which deliver does not refuse\n", $2, $1 }'
}

verdict() {
    [ -z "$wrong" ] && { printf 'PASS — deliver refuses every file under `.foundry/` that floor names: %s\n' "$(echo $refused)"; exit 0; }

    printf 'FAIL — floor names a file under `.foundry/` that deliver does not refuse:\n'
    printf '%s\n' "$wrong" | sed 's/^/  /'
    exit 1
}

# A gate that has only ever been green proves nothing about what it would catch. The suite plants
# each fault in a copy and reads this script's exit and words.
prove_it_can_go_red() {
    command -v bash >/dev/null 2>&1 || {
        printf 'FAIL — bash is not on this host, so the suite did not run.\n'
        exit 3
    }
    bash "$root/tests/rulefiles.sh" || exit 1
    printf '\n'
}

main "$@"
