#!/bin/sh
#
# `CONTRIBUTING.md`, the workflow and `bin/gates.sh` name the same gates.
#
#   sh bin/agree.sh         check
#   sh bin/agree.sh audit   break it four ways, require each to go red

set -u

main() {
    cd "$(root)" || exit 3

    [ "${1:-check}" = audit ] && { audit; exit $?; }

    gates_run > "$listed" \
        || { printf 'FAIL — no gates run here. This gate read nothing.\n'; exit 3; }

    disagree CONTRIBUTING "$(named_in_contributing)"
    disagree workflow "$(named_in_workflow)"

    projections_agree

    verdict
}

root() { cd "$(dirname "$0")/.." && pwd; }

# --- the three lists ---

# A list that could not be produced is not a list nobody disagrees with. Two empty lists have
# nothing in one and not the other, so `disagree` passed both and `verdict` printed AGREED
# over an empty set. Captured before the pipe, which reports `sort` and not `sh`.
gates_run() {
    said=$(sh bin/gates.sh list) || return 1
    [ -n "$said" ] || return 1

    printf '%s\n' "$said" | sort -u
}

# The rows of the table under the gate heading, first cell only.
#
# Matched on the cells, never on the spacing between them. This wanted
# `| Gate | Fails when |` byte for byte, so the day `bin/table-format.sh`
# aligned that table the header stopped matching.
#
# It then listed no gate at all and said nothing about it. A silent empty list
# is the worst shape a check can take.
named_in_contributing() {
    awk '
        /^\| *Gate *\| *Fails when *\|/ { table = 1; next }
        table && !/^\|/                 { exit }
        table && /^\| *`/               { gsub(/[`|]/, "", $2); print $2 }
    ' CONTRIBUTING.md
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

# The same question one layer out. `CONTRIBUTING` and the workflow name the gates; a harness file
# names the rules, and every harness has its own
# name for that file.
#
# One source, so no harness owns the table and none of them can drift alone.
projections_agree() {
    bash bin/project.sh check >/dev/null 2>&1 && { printf '  PASS  %s
' "harness files"; return; }

    printf '  FAIL  a harness file drifted from .claude/rules — run bin/project.sh
'
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
    caught "the lab agrees before anything is broken" 0 none ''

    caught "a gate missing from CI"                1 workflow 's/, panel\]/]/'
    caught "a gate swapped for another"            1 workflow 's/panel\]/pest]/'
    caught "a duplicate hiding a gate"             1 workflow 's/, panel\]/, floor]/'
    caught "a gate dropped from CONTRIBUTING"      1 contributing '/^| `versions` |/d'

    # A gate list that could not be produced is not a list nobody disagrees with, and it is not a
    # rule broken either. The two exits are different remedies: one edits a document, the other
    # says the list itself did not come.
    caught "a gate list that could not be produced" 3 gates '1a exit 9'

    # The projection half. A row edited by hand in one harness file and nowhere else is the drift
    # this exists to catch.
    caught "a harness file edited by hand"        1 agents 's/Anything written down/something else/'

    [ "$disagreed" -eq 0 ] || return 1
    printf 'THE CHECK CAN FAIL\n'
}

# `sed` to a new file: the in-place flag is GNU's, and BSD reads its argument as a backup suffix.
caught() {
    name=$1; want=$2; target=$3; mutation=$4

    fresh_lab || { note_failure "$name — no lab"; return 1; }

    [ "$target" = none ] || break_it "$target" "$mutation" \
        || { note_failure "$name — the break did not apply"; return 1; }

    sh "$lab/bin/agree.sh" >/dev/null 2>&1; agreed=$?

    [ "$agreed" -eq "$want" ] || { note_failure "$name — exited $agreed, not $want"; return 1; }
    printf '  ok    %s\n' "$name"
}

note_failure() {
    printf '  FAIL  %s\n' "$1"
    disagreed=$((disagreed + 1))
}

fresh_lab() {
    rm -rf "$lab" && mkdir -p "$lab" && cp -R "$(root)"/. "$lab"/ 2>/dev/null
}

# Which file a break edits. Named rather than branched: a third target turned two `&&` lines into a
# ladder.
broken_file() {
    case "$1" in
        workflow) printf '%s' "$lab/.github/workflows/gates.yml" ;;
        gates)    printf '%s' "$lab/bin/gates.sh" ;;
        agents)   printf '%s' "$lab/AGENTS.md" ;;
        *)        printf '%s' "$lab/CONTRIBUTING.md" ;;
    esac
}

break_it() {
    file=$(broken_file "$1")

    sed "$2" "$file" > "$file.broken" && mv "$file.broken" "$file"
}

work=${TMPDIR:-/tmp}/foundry-agree-$$
mkdir -p "$work" || exit 3
trap 'rm -rf "$work"' EXIT

listed="$work/listed"
lab="$work/lab"
disagreed=0

main "$@"
