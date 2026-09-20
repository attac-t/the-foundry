#!/bin/sh
#
# Whether floor's audit can change this branch's answer.
#
# The audit clones the branch, mutates `plugins/floor`, and asks if the suite
# notices. **A branch changing nothing there mutates the same bytes as the
# one before**, and pays forty minutes to be told what it already knew.
#
# Measured 19 September: fourteen merges in seventeen hours, one every seventy-six
# minutes. **Ten of the fourteen touched no file under `plugins/`.**
#
# **A check decides, never a worker.** #912 asked for exactly that — a worker
# judging its own branch against the bar is the shape the doctrine refuses.
#
# Usage: sh bin/audited.sh [<target>]     default target: origin/main
#        sh bin/audited.sh audit          drive tests/audited.sh, and read no diff
#
# Exit: 0 the audit is warranted, 1 it cannot answer, 3 the comparison could not be made.
#       Under `audit` the code is the suite's: 0 every case passed, 1 one did not.

set -u

readonly TARGET=${1:-origin/main}

#
# Files outside `plugins/` that still force an audit.
#
# **Typed, and each one says why.** A derived list would have to guess which root file
# reaches a clone, and guessing is what this refuses. `tests/audited.sh` refuses an
# entry with no reason.
#
# **This file is on its own list, and that is the point.** A check that says when the
# bar may be skipped sits under the bar it guards, or it can quietly exempt itself.
FORCES_AN_AUDIT='
.gitattributes  line endings reach every shipped script
.gitignore      what a fresh clone holds at all
bin/gates.sh    it runs the suite, so how could change the answer
bin/audited.sh  it decides whether the audit runs, so the bar it guards holds it too
'

say()  { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }

main() {
    # **Its suite was run by nothing until today.** `tests/audited.sh` held sixteen cases and no
    # gate, hook or verb executed one. `basing` carries the same verb for the same reason, and the
    # collision with a branch called `audit` is the trade it already accepted.
    [ "${1:-}" = audit ] && { cd "$(root)" || exit 3; drive_the_suite; return $?; }

    cd "$(root)" || exit 3

    changed=$(what_changed) || { note 'audited — the two trees could not be compared'; exit 3; }

    [ -n "$changed" ] || { say 'audited — this branch changes nothing, so nothing to grade'; exit 1; }

    reached=$(what_the_audit_reads "$changed")

    #
    # **Not twenty-five green. Twenty-five ran**, twenty-four graded their full claim, and one
    # graded less. That is a different count, and the delegate approving this said it must be said
    # out loud.
    #
    # **This once printed the line for a person to copy into the record, and that was the fault
    # #920 names.** A line a person types is a line a person can soften, and the runner could not
    # produce the state it described — `gate()` read the plugin's exit 3 as a failure, so a branch
    # that correctly skipped reported twenty-four of twenty-five.
    #
    # **The runner prints it now**, because the plugin says *nobody asked* in its own exit code and
    # `bin/gates.sh` reads that. This tells a worker before they spend the time. It decides nothing.
    [ -n "$reached" ] || {
        say 'audited — no. Every gate still runs, and one will grade a smaller claim.'
        say 'audited — the runner prints that line itself. Nothing here is yours to copy.'
        say ''
        say "audited — nothing the audit reads changed: $(one_line "$changed")"
        exit 1
    }

    say 'audited — yes, the audit can answer. It reads:'
    printf '%s\n' "$reached" | sed 's/^/  /'
    exit 0
}

root() { cd "$(dirname "$0")/.." && pwd; }

# Refuses rather than reporting nothing, because a suite that is not there and a suite that passes
# read the same from a caller that only checks the code.
drive_the_suite() {
    [ -f tests/audited.sh ] || { note 'tests/audited.sh is not here, so this read nothing'; exit 2; }

    bash tests/audited.sh
}

# Every changed file on one line, so the waiver is one field a reader can scan.
one_line() { printf '%s' "$1" | tr '\n' ' ' | sed 's/ *$//'; }

#
# Two trees, never three dots. `A...B` compares the merge base, where a file the target
# changed after the cut is simply absent — `basing.md` names that and a fixture caught it.
what_changed() { git diff --name-only "$TARGET" HEAD 2>/dev/null; }

# Every changed file the audit could read: the plugin it mutates, and the few outside it
# that decide what a clone holds.
what_the_audit_reads() {
    printf '%s\n' "$1" | while read -r file; do
        [ -n "$file" ] || continue

        case $file in plugins/*) printf '%s\n' "$file"; continue ;; esac

        forces_an_audit "$file" && printf '%s\n' "$file"
    done
}

#
# **One list, never a loop inside a pipe.** A `while read` on the right of a pipe runs in a
# subshell, so its `exit 0` ends that subshell and the function falls through to the refusal every
# time. The fixture for line endings caught it, which is why the fixture drives real trees.
forces_an_audit() {
    case " $(printf '%s\n' "$FORCES_AN_AUDIT" | awk 'NF { printf "%s ", $1 }') " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

main "$@"
