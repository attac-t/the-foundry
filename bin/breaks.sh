#!/usr/bin/env bash
#
# Drives every gate against a tree that breaks it, and reports what was caught.
#
# A gate reaches this file three ways: broken here, broken by its own `audit`, or broken by a plugin
# suite. `bumps` grades a merge commit, so no file break reaches it and it is driven by hand.
#
# **Nothing may sit outside those places, and the report counts them rather than this sentence.**
# Five gates did until #684, and one had no driver at all — `judged` had only ever been green.
#
# `bumps` is the one gate no break here can reach. It grades a merge, and every break below edits a
# file. The reason and the hand-driven proof sit beside `say_what_drives_itself`.
#
# **Not a gate.** It makes the tree red on purpose, and a gate grading the gates is a loop nothing
# outside it can check. Run by hand, read the count.
#
# **A bad break looks exactly like a blind gate.** Three of the first six here passed, and all three
# were the break's fault. Each one carries the reason it is right.
#
# **So the answer is one of four, and three of them used to read as one.** `caught` is the gate
# refusing the break. `MISSED` is the gate passing it. `MOOT` is a break that changed no bytes, and
# `MUTE` is a gate that answered neither 0 nor 1 — it did not judge, and counting that as a catch
# is how a mangled break line reported success.
#
# Usage: bash bin/breaks.sh
#
# Exit: 0 always. A miss is a report, not a refusal — see #351.

set -u

cd "$(dirname "$0")/.." || exit 3

main() {
    caught=0
    missed=0
    moot=0
    mute=0

    say "clean first"
    every_gate_is_green

    say ""
    say "broken"
    every_break

    # All four, always. A zero beside `mute` says the harness looked, and looking is the whole of
    # what was missing — the state was invisible rather than absent.
    say ""
    say "$caught caught, $missed missed, $moot moot, $mute mute"

    say ""
    say "these drive themselves, and are not run here"
    say_what_drives_itself
    say_what_nothing_accounts_for
}

# A gate already red grades nothing below it, and a break against a red tree reports the old fault.
every_gate_is_green() {
    for gate in frontmatter versions repeats shell; do
        runs "bash bin/$gate.sh" && note green "$gate" || note RED "$gate"
    done

    runs 'bash bin/harness.sh check' && note green harness || note RED harness
}

# Named, never run here. Each is minutes, and a tool people skip because it is slow proves nothing.
# `bumps` cannot be driven here. Every break above edits a file in the working tree, and this gate
# only has an answer on a merge commit — it needs two parents that each moved one version to the
# same place. That is a repository shape, not a file.
#
# Driven by hand instead, 9 September 2026, in a throwaway repository:
#
#   one plugin at 1.0.0, two branches, both writing 1.0.1, merged
#   the merge is clean and exits 0. `bumps.sh` exits 1 and names the plugin and both numbers
#
# Three more shapes, each answered: one side bumping alone passes, a HEAD that is not a merge passes
# and says why, and a directory with no repository above it exits 3.
say_what_drives_itself() {
    say "  self     bytes comments codex host      their own audit, which the gate line passes"
    say "  self     kernel signal panel floor      bash plugins/<name>/tests/run.sh"
    say "  by hand  bumps      needs a merge commit, so no file break reaches it — see the comment above"
    say "  not a gate  harness  the board script. Driven here because nothing else drives it"
}

#
# **One list, checked against the live one.** A gate reaches this file three ways and a name in none
# of them is a gate nobody has proved can fail. That state was invisible: the header said five, the
# file drove nine, and a reader subtracting one from the other got four gates wrong.
#
# Typed, because a `drive` line carries a break name and `shell` has two of them. A derived list
# would have to guess which gate `shell-taper` belongs to, and guessing is what this refuses.
ACCOUNTED="frontmatter versions repeats shell taper hosts providers secrets hooks judged
bytes comments codex host
kernel signal panel floor
bumps"

say_what_nothing_accounts_for() {
    held=" $(printf %s "$ACCOUNTED" | tr "\n" " ") "
    loose=
    held_count=$(printf %s "$held" | wc -w)
    live_count=$(sh bin/gates.sh list | wc -l)

    for gate in $(sh bin/gates.sh list); do
        case $held in *" $gate "*) continue ;; esac
        loose="$loose $gate"
    done

    [ -n "$loose" ] || { say "  $held_count of $live_count gates accounted for, and none left over"; return 0; }

    say "  UNACCOUNTED:$loose — no break here, and nothing says they drive themselves"
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

    # The boundary `run.sh` states twice and nothing read. #299 stands a machine up from Docker, and
    # this is the line that would land in core on the way.
    drive hosts plugins/floor/lib/source.sh \
        'a_host >> plugins/floor/lib/source.sh' \
        'sh bin/hosts.sh'

    # A vendor's name where core decides. The rule held on discipline everywhere but one file,
    # which is where a copy of `remote_is_github` had already landed once.
    drive providers plugins/floor/lib/source-dir.sh \
        'a_vendor >> plugins/floor/lib/source-dir.sh' \
        'sh bin/providers.sh'

    # A value baked into a layer. Deleting it later leaves it in the layer that added it, which is
    # the one mistake a recipe cannot be edited out of.
    drive secrets bin/gates.Dockerfile \
        'a_baked_secret >> bin/gates.Dockerfile' \
        'sh bin/secrets.sh'

    # The pin is this repository's trust decision, and the gate had only ever been green. Editing
    # the adapter moves its digest; the declaration beside it does not move on its own.
    drive judged plugins/floor/adapters/codex/run.sh \
        'a_drifted_adapter >> plugins/floor/adapters/codex/run.sh' \
        'sh bin/judged.sh'

    # A hook that judges nothing. Every suite under `tests/` writes its calls to disk, so this
    # break reaches the hook rather than the harness reading it.
    # A guard that refuses nothing, which looks exactly like a guard that is working.
    #
    # **Edited, never appended.** The first version of this break added a second `main` below the
    # call to the first, so the hook ran unchanged and the harness read MISSED — correctly, and
    # only because it tells a bad break from a blind gate.
    drive hooks .claude/hooks/identity.sh \
        "sed -i 's/^    deny /    allow #/' .claude/hooks/identity.sh" \
        'sh bin/hooks.sh'

    # Three comment lines that do not step down by three. The gate graded evenness once, and a block
    # dropping eighteen twice went through for weeks.
    #
    # **`taper.sh`, never `shell.sh`.** `shell.sh:22` says it left comment shape here, so this
    # break drove a gate that cannot see it and read MISSED. A blind gate and a break aimed
    # elsewhere look the same, which is why this script prints both words.
    drive shell-taper plugins/floor/lib/source.sh \
        'a_wedge >> plugins/floor/lib/source.sh' \
        'bash bin/taper.sh'

    # The generated rules list, never a rule's body. A new rule file changes the list, and no harness
    # file names it — which is the drift this gate exists for.
    drive harness .claude/rules/zzz-probe.md \
        'a_new_rule > .claude/rules/zzz-probe.md' \
        'bash bin/harness.sh check'

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

    judge_it "$name" "$file" "$gate"

    restore "$file"
}

#
# **Four answers, and three of them used to read as one.** Any non-zero counted as a catch, so a
# gate that could not run reported the same word as a gate that refused the break.
#
# Measured 9 September: a `drive` line with a mangled continuation passed its gate argument as a
# command that does not exist. The run printed `caught`, and the summary said nought missed.
#
# `bin/gates.sh` draws this line for every gate here — exit 1 is a rule broken, exit 3 is the gate
# not answering — and this was the one reader that threw it away.
judge_it() {
    the_break_applied "$2" || { note MOOT "$1 — the file did not change"; moot=$((moot + 1)); return; }

    $3 >/dev/null 2>&1
    said=$?

    [ "$said" -eq 0 ] && { note MISSED "$1"; missed=$((missed + 1)); return; }
    [ "$said" -eq 1 ] && { note caught "$1"; caught=$((caught + 1)); return; }

    note MUTE "$1 — the gate answered $said, so it judged nothing"
    mute=$((mute + 1))
}

# A break that changed no bytes proves the gate nothing. `remember` keeps the file as it was, and a
# break creating one leaves nothing to compare — that is a change, and it counts as one.
the_break_applied() {
    [ -e "$kept" ] || return 0

    ! cmp -s "$kept" "$1"
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

# Code, never a comment. `run.sh` already carries two comments naming a container, so a break that
# planted prose would go green against a gate working perfectly.
a_host() { printf '\n[ -f /.dockerenv ] && inside_a_container=1\n'; }

# A vendor named where core decides something, never where a comment explains the seam. The
# resolver may carry this very line; `source-dir.sh` may not.
a_vendor() { printf '\ncase $remote in *github.com*) : ;; esac\n'; }

# A directive, never a comment. The header of `secrets.sh` names a secret four times over, and a
# break planting prose would go green against a gate working perfectly.
a_baked_secret() { printf '\nENV GH_TOKEN=abc123\n'; }

# A line added to a shipped adapter, with the digest beside it left where it was. That is one
# commit away at all times, and it is the whole of what this gate exists to catch.
a_drifted_adapter() { printf '\n# one more line, and nobody moved the pin\n'; }

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
