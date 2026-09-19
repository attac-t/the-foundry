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
#
# Exit: 0 the audit is warranted, 1 it cannot answer, 3 the comparison could not be made.

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
    cd "$(root)" || exit 3

    changed=$(what_changed) || { note 'audited — the two trees could not be compared'; exit 3; }

    [ -n "$changed" ] || { say 'audited — this branch changes nothing, so nothing to grade'; exit 1; }

    reached=$(what_the_audit_reads "$changed")

    #
    # **Not twenty-five green. Twenty-five ran**, twenty-four graded their full claim, and one
    # graded less. That is a different count, and the delegate approving this said it must be said
    # out loud.
    #
    # **Printed here, so nobody types it.** A waiver a person writes is a waiver a person can
    # soften, and the line is the whole of what a reader has to tell the two apart.
    [ -n "$reached" ] || {
        say "audited — no. Twenty-five gates still run, and one grades a smaller claim,"
        say 'audited — so the record has to say which. Put this line in it, unedited:'
        say ''
        say "ALL GREEN, 25 of 25, audit waived: no file the audit reads ($(one_line "$changed"))"
        exit 1
    }

    say 'audited — yes, the audit can answer. It reads:'
    printf '%s\n' "$reached" | sed 's/^/  /'
    exit 0
}

root() { cd "$(dirname "$0")/.." && pwd; }

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
