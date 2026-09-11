#!/bin/sh
#
# Fails when floor's core names a judge.
#
# Core holds the clause and an adapter holds the judge. `bin/providers.sh` says the same of a work
# source and has done since `join.sh` kept a copy of `remote_is_github`. **The judge seam was held on
# discipline alone**, and one line in core already names a vendor — which is how this was found.
#
# **Not folded into `providers`.** That gate grades one rule with one exception list, and its own
# header says why `hosts` is separate: a gate grading two rules under one name is what
# `vocabulary.md` refuses. This rule has a different exception and a different reason.
#
# **An adapter needs no exemption here.** It lives under `adapters/`, which is not core, so the file
# that must name a judge is already outside what this reads.
#
# **Nothing is exempt, and nothing needs to be.** The file that must name a judge is the adapter, and
# an adapter lives under `adapters/` — which is not core, so this never reads it.
#
# **A comment may name a judge**, for the reason `hosts` and `providers` both give: the sentence
# explaining a seam contains the word the check forbids.
#
# Usage: sh bin/judges.sh
#
# Exit: 0 core names no judge, 1 a name is in code, 3 the gate could not read
#
set -u

cd "$(dirname "$0")/.." || exit 3

# Four judges anyone might reach for. Each is a whole word nothing else contains, because a forbidden
# name hiding inside an ordinary one has already cost this repository a day.
#
# **One name is deliberately absent.** The harness is called the same thing as a judge, and floor's
# core reads the harness's own directories — `.claude-plugin/plugin.json` is where every plugin here
# keeps its manifest. Nine such lines exist and every one is legitimate.
#
# **So this gate holds the judge seam and not the harness seam.** They are two rules, and #700 owns
# the second. A gate grading both under one name is what `vocabulary.md` refuses.
JUDGES='codex|openai|anthropic|gemini'

CORE='plugins/floor/bin plugins/floor/lib plugins/floor/hooks'

ALLOWED=''

say()  { printf '%s\n' "$1"; }
fail() { printf 'judges: %s\n' "$1" >&2; exit 3; }
fail() { printf 'judges: %s' "$1" >&2; printf '
' >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    core_is_here || fail 'floor ships no bin, lib or hooks here'

    caught=$(judge_names_in_code)

    [ -z "$caught" ] || refuse "$caught"

    say "judges     core names no judge"
}

core_is_here() {
    for dir in $CORE; do
        [ -d "$dir" ] || return 1
    done
}

judge_names_in_code() {
    for dir in $CORE; do
        for file in "$dir"/*.sh; do
            [ -f "$file" ] || continue
            may_name_one "$file" && continue

            name_the_lines "$file"
        done
    done
}

# By basename. A path would tie this to one layout, and the file is what it is wherever floor puts it.
may_name_one() {
    for allowed in $ALLOWED; do
        [ "${1##*/}" = "$allowed" ] && return 0
    done

    return 1
}

# A line whose first character is a hash is prose. The sentences explaining this seam name the very
# judges it refuses, and a check reading those as violations would gate the opposite.
name_the_lines() {
    awk -v file="$1" -v judges="$JUDGES" '
        { bare = $0; sub(/^[[:space:]]+/, "", bare) }

        bare ~ /^#/            { next }
        tolower(bare) ~ judges { print "           " file ":" NR "  " bare }
    ' "$1"
}

# Every line, never the first. Three in a file is three edits, and a gate naming one sends the
# reader back twice for what it already knew.
refuse() {
    say "$1"
    say "judges     a judge is named in code. An adapter may; core may not."
    exit 1
}

main "$@"
