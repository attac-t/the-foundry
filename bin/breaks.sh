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

# --- saying it ---

runs() { $1 >/dev/null 2>&1; }
note() { printf '  %-7s %s\n' "$1" "$2"; }
say()  { printf '%s\n' "$1"; }

kept=${TMPDIR:-/tmp}/breaks-kept.$$
trap 'rm -f "$kept"' EXIT

main "$@"
