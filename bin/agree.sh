#!/bin/sh
#
# The README, the workflow and `bin/gates.sh` must name the same gates.
#
# A meta-check, not a product gate. It grades the other seven and is not one of them, so adding it to
# CI does not make the count it checks disagree with itself.
#
# Identities, never counts. The README claimed seven and the workflow ran six for days: same shape of
# defect a count would have shown, but a count cannot say `panel` was the one missing, and cannot see
# a gate swapped for another.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:-check}
cd "$root" || exit 1

# What runs. The one list the other two are graded against.
runs() { sh bin/gates.sh list; }

# What contributors are promised. The rows of the table under the gate heading, first cell only.
readme() {
    awk '
        /^\| Gate \| Fails when \|/ { inside = 1; next }
        inside && !/^\|/            { exit }
        inside && /^\| `/           { gsub(/[`|]/, "", $2); print $2 }
    ' README.md
}

# What CI would run. The scripts by name, and the plugins the matrix expands.
workflow() {
    awk '
        /bash bin\/[a-z]+\.sh/ { match($0, /bin\/[a-z]+\.sh/)
                                 name = substr($0, RSTART + 4, RLENGTH - 7)
                                 print name }
        /plugin: \[/           { gsub(/.*\[|\].*|,/, " ")
                                 for (i = 1; i <= NF; i++) print $i }
    ' .github/workflows/gates.yml
}

report() {
    missing=$(printf '%s\n' "$2" | sort -u | comm -23 - "$tmp/runs")
    extra=$(printf '%s\n' "$2" | sort -u | comm -13 - "$tmp/runs")

    [ -z "$missing" ] && [ -z "$extra" ] && { printf '  PASS  %s\n' "$1"; return; }

    [ -z "$extra" ]   || printf '  FAIL  %s does not name: %s\n' "$1" "$(echo $extra)"
    [ -z "$missing" ] || printf '  FAIL  %s names what nothing runs: %s\n' "$1" "$(echo $missing)"
    failed=$((failed + 1))
}

#
# Break it four ways and require each to go red. A check nobody has watched fail is one the next edit
# deletes for free.
#
# It runs the real check against mutated copies and reads the exit code, rather than asking anything
# to grade itself.
#
audit() {
    lab=${TMPDIR:-/tmp}/foundry-agree-audit-$$
    trap 'rm -rf "$lab"' EXIT

    caught "a gate missing from CI" \
        's/plugin: \[kernel, signal, floor, panel\]/plugin: [kernel, signal, floor]/' workflows
    caught "a gate swapped for another, same count" \
        's/plugin: \[kernel, signal, floor, panel\]/plugin: [kernel, signal, floor, pest]/' workflows
    caught "a duplicate hiding a gate, same count" \
        's/plugin: \[kernel, signal, floor, panel\]/plugin: [kernel, signal, floor, floor]/' workflows
    caught "a gate dropped from the README" '/^| `versions` |/d' readme

    [ "$broken" -eq 0 ] && { printf 'THE CHECK CAN FAIL\n'; exit 0; }
    exit 1
}

# One break, one copy, one exit code.
caught() {
    rm -rf "$lab"; mkdir -p "$lab" || { printf '  FAIL  %s — no lab\n' "$1"; broken=1; return; }
    cp -R "$root"/. "$lab"/ 2>/dev/null

    target="$lab/README.md"
    [ "$3" = workflows ] && target="$lab/.github/workflows/gates.yml"

    sed -i "$2" "$target" 2>/dev/null || { printf '  FAIL  %s — sed did not apply\n' "$1"; broken=1; return; }

    sh "$lab/bin/agree.sh" >/dev/null 2>&1 \
        && { printf '  FAIL  %s — agreed anyway\n' "$1"; broken=1; return; }

    printf '  ok    %s\n' "$1"
}

broken=0
[ "$mode" = audit ] && audit

tmp=${TMPDIR:-/tmp}/foundry-agree-$$
mkdir -p "$tmp" || exit 3
trap 'rm -rf "$tmp"' EXIT

runs | sort -u > "$tmp/runs"

[ -s "$tmp/runs" ] || { printf '  FAIL  bin/gates.sh named no gate at all\n'; exit 1; }

failed=0
report README "$(readme)"
report workflow "$(workflow)"

[ "$failed" -eq 0 ] && { printf 'AGREED — %s gates\n' "$(wc -l < "$tmp/runs" | tr -d ' ')"; exit 0; }
exit 1
