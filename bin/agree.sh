#!/bin/sh
#
# The README, the workflow and `bin/gates.sh` name the same gates.
#
#   sh bin/agree.sh         check
#   sh bin/agree.sh audit   break it four ways, require each to go red

set -u

main() {
    cd "$(root)" || exit 3

    [ "${1:-check}" = audit ] && { audit; exit $?; }

    gates_run > "$listed"
    disagree README  "$(named_in_readme)"
    disagree workflow "$(named_in_workflow)"

    verdict
}

root() { cd "$(dirname "$0")/.." && pwd; }

# --- the three lists ---

gates_run() { sh bin/gates.sh list | sort -u; }

# The rows of the table under the gate heading, first cell only.
named_in_readme() {
    awk '
        /^\| Gate \| Fails when \|/ { table = 1; next }
        table && !/^\|/             { exit }
        table && /^\| `/            { gsub(/[`|]/, "", $2); print $2 }
    ' README.md
}

#
# Any `bin/` script CI invokes, whatever the interpreter, and the plugins the matrix fills in.
#
# Matching one spelling of one interpreter excluded this check by accident rather than by rule. The
# exclusions are by name: `agree` grades the gates and `gates` runs them.
#
named_in_workflow() {
    awk '
        /bin\/[a-z-]+\.sh/ {
            match($0, /bin\/[a-z-]+\.sh/)
            name = substr($0, RSTART + 4, RLENGTH - 7)
            if (name !~ /^(agree|gates)$/) print name
        }

        # The step that runs the suites, not the matrix that declares them. Delete the step and keep
        # the matrix and CI runs none of them, which reading the declaration alone calls agreement.
        /plugins\/\$\{\{ matrix\.plugin \}\}\/tests\/run\.sh/ { step = 1 }
        /plugin: \[/ { gsub(/.*\[|\].*|,/, " "); for (i = 1; i <= NF; i++) held[$i] = 1 }
        END { if (step) for (name in held) print name }
    ' .github/workflows/gates.yml
}

# --- grading ---

# Identities, never counts. A count cannot say which gate is missing, nor see one swapped for another.
disagree() {
    absent=$(printf '%s\n' "$2" | sort -u | comm -13 - "$listed")
    unrun=$( printf '%s\n' "$2" | sort -u | comm -23 - "$listed")

    [ -z "$absent$unrun" ] && { printf '  PASS  %s\n' "$1"; return; }

    [ -z "$absent" ] || printf '  FAIL  %s does not name: %s\n' "$1" "$absent"
    [ -z "$unrun" ]  || printf '  FAIL  %s names what nothing runs: %s\n' "$1" "$unrun"
    disagreed=$((disagreed + 1))
}

verdict() {
    [ "$disagreed" -eq 0 ] || exit 1
    printf 'AGREED — %s gates\n' "$(wc -l < "$listed" | tr -d ' ')"
}

# --- the audit ---

#
# The real check against mutated copies, reading its exit code. Nothing grades itself.
#
# The clean copy first: `caught` reads any non-zero exit as proof, so a lab that never assembled
# would report every break caught and exit 0.
#
audit() {
    caught "the lab agrees before anything is broken" none '' \
        || { printf '  FAIL  the lab does not work, so nothing below proves anything\n'; return 1; }

    caught "a gate missing from CI"                workflow 's/, panel\]/]/'
    caught "a gate swapped for another"            workflow 's/panel\]/pest]/'
    caught "a duplicate hiding a gate"             workflow 's/, panel\]/, floor]/'
    caught "a gate dropped from the README"        readme   '/^| `versions` |/d'

    [ "$disagreed" -eq 0 ] || return 1
    printf 'THE CHECK CAN FAIL\n'
}

# `sed` to a new file: the in-place flag is GNU's, and BSD reads its argument as a backup suffix.
caught() {
    fresh_lab || { printf '  FAIL  %s — no lab\n' "$1"; disagreed=$((disagreed + 1)); return 1; }

    [ "$2" = none ] || break_it "$2" "$3" \
        || { printf '  FAIL  %s — the break did not apply\n' "$1"; disagreed=$((disagreed + 1)); return 1; }

    sh "$lab/bin/agree.sh" >/dev/null 2>&1; agreed=$?
    [ "$2" = none ] && { want=0; } || { want=1; }

    [ "$agreed" -ne "$want" ] && { printf '  FAIL  %s\n' "$1"; disagreed=$((disagreed + 1)); return 1; }
    printf '  ok    %s\n' "$1"
}

fresh_lab() {
    rm -rf "$lab" && mkdir -p "$lab" && cp -R "$(root)"/. "$lab"/ 2>/dev/null
}

break_it() {
    file="$lab/README.md"
    [ "$1" = workflow ] && file="$lab/.github/workflows/gates.yml"

    sed "$2" "$file" > "$file.broken" && mv "$file.broken" "$file"
}

work=${TMPDIR:-/tmp}/foundry-agree-$$
mkdir -p "$work" || exit 3
trap 'rm -rf "$work"' EXIT

listed="$work/listed"
lab="$work/lab"
disagreed=0

main "$@"
