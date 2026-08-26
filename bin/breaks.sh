#!/usr/bin/env bash
#
# Drives every gate against a tree that breaks it, and reports what was caught.
#
# Only these five need it. `agree` drives its own six with `agree.sh audit`, and the four plugin
# suites drive theirs — 1351 assertions between them, no mutant unanswered.
#
# **Not a gate.** It makes the tree red on purpose, and a gate grading the gates is a loop nothing
# outside it can check. Run by hand, read the count.
#
# **A bad break looks exactly like a blind gate.** Three of the first six here passed, and all three
# were the break's fault. Each one carries the reason it is right.
#
# Usage: bash bin/breaks.sh
#
# Exit: 0 always. A miss is a report, not a refusal — see #351.

set -u

cd "$(dirname "$0")/.." || exit 3

main() {
    caught=0
    missed=0

    say "clean first"
    every_gate_is_green

    say ""
    say "broken"
    every_break

    say ""
    say "$caught caught, $missed missed"

    say ""
    say "these drive themselves, and are not run here"
    say_what_drives_itself
}

# A gate already red grades nothing below it, and a break against a red tree reports the old fault.
every_gate_is_green() {
    for gate in frontmatter versions repeats shell; do
        runs "bash bin/$gate.sh" && note green "$gate" || note RED "$gate"
    done

    runs 'bash bin/project.sh check' && note green project || note RED project

    # The table tools grade the whole tree, so a break appended to one file is only visible over a
    # clean one. Three `leave_alone` cases read NOISY against a tree nobody had swept — the fault
    # was the baseline, not the tool.
    runs 'sh bin/table-format.sh' && note green table-format || note RED table-format
    runs 'sh bin/table-width.sh'  && note green table-width  || note RED table-width
}

# Named, never run here. Each is minutes, and a tool people skip because it is slow proves nothing.
say_what_drives_itself() {
    say "  self     agree      bash bin/agree.sh audit"
    say "  self     kernel signal panel floor   bash plugins/<name>/tests/run.sh"
}

every_break() {
    # A manifest that cannot say its version is the fault that breaks an install. A version reading
    # oddly is not — `versions.sh` says so, and a break setting one passes correctly.
    drive versions plugins/floor/.claude-plugin/plugin.json \
        "sed -i '/\"version\"/d' plugins/floor/.claude-plugin/plugin.json" \
        'bash bin/versions.sh'

    # A sentence lifted out of a graded file. `repeats` matches capital to full stop and ignores
    # anything under thirty-five characters, so a sentence written fresh here repeats nothing.
    drive repeats CONTRIBUTING.md \
        'a_real_sentence >> CONTRIBUTING.md' \
        'bash bin/repeats.sh'

    # `shell.sh` refuses `else` outright: it is a second job wearing a branch.
    drive shell-else plugins/floor/lib/source.sh \
        'an_else >> plugins/floor/lib/source.sh' \
        'bash bin/shell.sh'

    # Three comment lines that do not step down by three. The gate graded evenness once, and a block
    # dropping eighteen twice went through for weeks.
    drive shell-taper plugins/floor/lib/source.sh \
        'a_wedge >> plugins/floor/lib/source.sh' \
        'bash bin/shell.sh'

    # The generated rules list, never a rule's body. A new rule file changes the list, and no harness
    # file names it — which is the drift this gate exists for.
    drive project .claude/rules/zzz-probe.md \
        'a_new_rule > .claude/rules/zzz-probe.md' \
        'bash bin/project.sh check'

    # Frontmatter is a skill's contract with the loader, and a skill missing its description is one
    # nothing can decide to invoke.
    drive frontmatter plugins/kernel/skills/craft-sh/SKILL.md \
        "sed -i '/^description:/d' plugins/kernel/skills/craft-sh/SKILL.md" \
        'bash bin/frontmatter.sh'

    # Four shapes a table takes when nobody formats it: plain columns, a projection a generator
    # wrote, an em-dash that is three bytes and one character, and a cell wider than its heading.
    #
    # Every one appends to a file git already tracks. The tools read `git ls-files`, so a break
    # writing a new file proves nothing — three of these did, and all three were MISSED by the
    # break rather than by the gate.
    drive table-plain CONTRIBUTING.md \
        'a_ragged_table >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'

    drive table-projected CLAUDE.md \
        "sed -i 's/^| .closing./|  [closing]/' CLAUDE.md" \
        'sh bin/table-format.sh'

    drive table-unicode CONTRIBUTING.md \
        'a_ragged_unicode_table >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'

    drive table-long-cell CONTRIBUTING.md \
        'a_ragged_long_cell >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'

    # A row past the budget, which the formatter refuses to widen and this one names.
    drive table-too-wide CONTRIBUTING.md \
        'a_row_past_the_budget >> CONTRIBUTING.md' \
        'sh bin/table-width.sh'

    # The other half, and this suite had none of it. A gate going red on a pipe inside code blocks
    # good writing, and that failure never appears in a list of the breaks it caught.
    leave_alone table-fenced CONTRIBUTING.md \
        'pipes_inside_a_fence >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'

    leave_alone table-escaped CONTRIBUTING.md \
        'an_escaped_pipe >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'

    # The formatter must not touch what it cannot widen. A row already past the budget stays exactly
    # as written, or the two tools argue over one line and neither can be obeyed.
    leave_alone table-wide-left-alone CONTRIBUTING.md \
        'a_row_past_the_budget >> CONTRIBUTING.md' \
        'sh bin/table-format.sh'
}

#
# `drive` proves a gate notices. This proves it keeps quiet, which is the half
# that decides whether anybody adopts the gate at all.
leave_alone() {
    name=$1; file=$2; write_it=$3; gate=$4

    remember "$file"
    eval "$write_it"

    runs "$gate" && { note quiet "$name"; caught=$((caught + 1)); } \
                 || { note NOISY "$name"; missed=$((missed + 1)); }

    restore "$file"
}

# --- one break ---

# Reverted whatever the gate answered. A harness that leaves the tree dirty when a gate misbehaves is
# worse than no harness at all.
drive() {
    name=$1; file=$2; break_it=$3; gate=$4

    remember "$file"
    eval "$break_it"

    runs "$gate" && { note MISSED "$name"; missed=$((missed + 1)); } \
                 || { note caught "$name"; caught=$((caught + 1)); }

    restore "$file"
}

remember() { [ -e "$1" ] && cp "$1" "$kept"; }

# A file the break created is removed; one it edited comes back. `git checkout` would work for the
# second and would quietly resurrect the first.
restore() {
    [ -e "$kept" ] && { cp "$kept" "$1"; rm -f "$kept"; return 0; }

    rm -f "$1"
}

# --- what a break writes ---

# Taken from a graded file, never invented. Two fresh sentences repeat nothing, and the first
# version of this break reported `repeats` blind when the fault was here.
a_real_sentence() {
    printf '\n'
    awk 'length($0) > 60 && length($0) < 200 && /^[A-Z]/ && /[.]$/ { print; exit }' README.md
}

an_else() {
    printf '\nnoop_for_a_break() {\n    if true; then\n        :\n    else\n        :\n    fi\n}\n'
}

a_wedge() {
    printf '\n# One two three four five six seven eight nine ten eleven twelve thirteen\n'
    printf '# short\n# tiny\nnoop_for_a_wedge() { :; }\n'
}

a_new_rule() { printf '# Probe\n\nA rule no harness file has a row for.\n'; }

# --- what a table break writes ---

a_ragged_table() {
    printf '\n| a | bbbbbbbb |\n|---|---|\n| c | d |\n'
}

# An em-dash is three bytes and one character. A formatter counting bytes puts this row out by two,
# and two machines in different locales disagree about which one is right.
a_ragged_unicode_table() {
    printf '\n| one \342\200\224 two | x |\n|---|---|\n| y | z |\n'
}

a_ragged_long_cell() {
    printf '\n| k | v |\n|---|---|\n| k | a cell far wider than the heading above it |\n'
}

# Past 120 bytes on one row. `table-width` names it; `table-format` leaves it alone rather than
# padding every other row out to match.
a_row_past_the_budget() {
    printf '\n| k | v |\n| - | - |\n| k | '
    awk 'BEGIN { while (i++ < 130) printf "x" }'
    printf ' |\n'
}

# A pipe inside a fence is not a column, and a pipe a backslash escaped is content. Both of these
# are already canonical, so the formatter has to stay quiet about both.
pipes_inside_a_fence() {
    printf '\n```\n| a | b |\n|---|---|\n```\n'
}

# `\|` is two characters wide and one cell. A formatter reading it as a boundary would split the row.
an_escaped_pipe() {
    printf '\n| a   | b   |\n| --- | --- |\n| \\|  | y   |\n'
}

# --- saying it ---

runs() { $1 >/dev/null 2>&1; }
note() { printf '  %-7s %s\n' "$1" "$2"; }
say()  { printf '%s\n' "$1"; }

kept=${TMPDIR:-/tmp}/breaks-kept.$$
trap 'rm -f "$kept"' EXIT

main "$@"
