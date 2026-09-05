#!/bin/sh
#
# Every product gate. `bin/agree.sh` checks the README and the workflow name these same ones.
#
#   sh bin/gates.sh         run them here
#   sh bin/gates.sh linux   run them where `sh` is dash
#   sh bin/gates.sh list    name them, run nothing
#
# A failing gate's output is kept under `~/.foundry-runs/gates`, one directory per run. Not under
# `linux`: that container is `--rm`, so `FOUNDRY_EPHEMERAL` tells the run inside to keep nothing.
#
# No `set -e`: a gate that fails must not stop the ones after it. One red square names one gate.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

mode=${1:-run}
failed=0

# Empty until a gate fails. `keep` fills it, and nothing else ever makes it.
logs=

#
# The same gates, on Linux. Not a convenience: on macOS and under Git Bash `sh` is bash and takes
# `&>` and `[[ =~ ]]` without a word, and every runner here opens `#!/bin/sh`.
#
# Copied in, not written through the mount — the suites write, and their leavings would land in your
# checkout. `safe.directory` because the copy is owned by whoever built the image.
#
on_linux() {
    # Git Bash says `/c/Users/…`, which Docker on Windows cannot read, and rewrites `/src` on the way
    # in. `cygpath -m` fixes the first, MSYS_NO_PATHCONV stops the second. No-ops anywhere else.
    command -v cygpath >/dev/null 2>&1 && { root=$(cygpath -m "$root"); export MSYS_NO_PATHCONV=1; }

    docker build -q -t foundry-gates -f "$root/bin/gates.Dockerfile" "$root" >/dev/null || return 3

    # `.git` is a file in a worktree, naming a host path the container cannot see, and every gate
    # that shells out to git went red on it. The copy is a copy either way, so the repair is a
    # repository of its own — `repeats` reads `git ls-files` and must list the copy.
    #
    # Two lanes patched around this by hand before anyone wrote it down.
    docker run --rm -v "$root:/src:ro" -e FOUNDRY_EPHEMERAL=1 foundry-gates sh -c '
        cp -r /src ~/repo && cd ~/repo
        [ -f .git ] && { rm -f .git; git init -q .; git add -A; }
        git config --global --add safe.directory ~/repo
        sh bin/gates.sh
    '
}

[ "$mode" = linux ] && { on_linux; exit $?; }

# What a gate's exit code means, repo-wide. A number is only legible to whoever already knows the
# table.
#
# **Three means two things, and the word has to hold both.** Four gates answer 3 when they could not
# read what they needed; floor's audit answers 3 when its mutants never ran. `it could not read` sent
# a reader after a missing file for an hour, and the file was there.
#
# So the word says what both have in common: **the gate did not answer.** Which of the two it was is
# in the gate's own output, where the detail belongs. Floor's audit already ends `PROVED NOTHING`.
why_failed() {
    case "$1" in
        1) printf 'a rule broken'     ;;
        3) printf 'it proved nothing' ;;
        *) printf 'it did not run'    ;;
    esac
}

# One directory per run, under the live run home — or the checkout, when a stripped environment has
# no `$HOME`. #40 folds `~/.foundry-runs` into `~/.foundry`, and `gates/` moves with it.
#
# Named for when it failed, the commit it graded and the run's own pid — two runs failing in the
# same second would otherwise overwrite one another, and `mkdir -p` would say nothing.
log_dir() {
    when=$(date -u +%Y%m%dT%H%M%SZ)
    commit=$(git rev-parse --short HEAD 2>/dev/null || echo no-commit)

    printf '%s/.foundry-runs/gates/%s-%s-%s' "${HOME:-$root}" "$when" "$commit" "$$"
}

# What the gate said, one file per gate. Made on the first failure and never before, which is why
# the output waits in a variable: a green run must leave nothing behind, and it leaves nothing.
#
# `FOUNDRY_EPHEMERAL` says the filesystem dies with the run, so keeping there is a claim rather
# than a cost. Nothing is written, and `kept in` goes with it because the directory never appears.
#
# It says so under the FAIL, because somebody who exported it months ago will not remember, and a
# run that silently kept nothing is the fault this whole change exists to end.
keep() {
    [ -n "${FOUNDRY_EPHEMERAL:-}" ] \
        && { printf '        nothing kept — FOUNDRY_EPHEMERAL is set\n'; return; }

    [ -n "$logs" ] || logs=$(log_dir)
    kept=$logs/$1.log

    mkdir -p "$logs" && printf '%s\n' "$2" > "$kept" && return

    printf '        %s could not be written\n' "$kept"
}

# One list, two readers. `agree` compares names against the README and the workflow, and a list it
# could not obtain from here would be a fourth place to keep them in step.
#
# Held, not discarded. `/dev/null` threw away the only account of a failure anyone had, and the
# reader was left re-running a gate that takes a quarter of an hour to answer again.
gate() {
    name=$1
    shift

    [ "$mode" = list ] && { printf '%s\n' "$name"; return; }

    said=$("$@" 2>&1) && { printf '  PASS  %s\n' "$name"; return; }

    code=$?

    printf '  FAIL  %s — %s (exit %s)
' "$name" "$(why_failed "$code")" "$code"
    keep "$name" "$said"
    failed=$((failed + 1))
}

[ "$mode" = list ] || printf 'sh  %s\nawk %s\n\n' \
    "$(readlink -f /bin/sh 2>/dev/null || echo '?')" "$(awk -W version 2>&1 | head -1)"

# `bash`, because every one of these opens `#!/bin/bash` and CI runs them that way. Under dash they
# exit 127 on the first bash-only line, which says nothing about the gate.
#
# The dash coverage is not lost by that. It lands where it belongs: floor's suite is bash, and the
# runner it exercises opens `#!/bin/sh`, so on Linux that runner executes under dash. The harness
# and the shipped code are different languages here on purpose.
gate frontmatter bash bin/frontmatter.sh
gate versions    bash bin/versions.sh

gate repeats     bash bin/repeats.sh

gate shell       bash bin/shell.sh

gate taper       sh   bin/taper.sh

#
# The audit, not the read. `bin/comments.sh` reaches GitHub, and a gate that needs the network
# is one that goes red on a train. Its suite drives it through a `gh` it writes itself, so this
# proves the detector. **Nothing runs it against a live thread.** No gate, no workflow and no
# step in the delivery path calls `bin/comments.sh read`, so the detection is built and unscheduled.
gate comments    sh   bin/comments.sh audit

#
# The adapter, not the harness. It reaches a vendor and turns what came back into a receipt, and its
# suite drives it through a `codex` the suite writes. **Nothing here reaches a network.** Four faults
# in its readers were found by a judge rather than a check, which is why this line exists.
#
# It ships inside floor now, outside floor core, and a repository authorises it by digest. So this
# gate reads a file no consumer owns a copy of — a fix here reaches all of them.
gate codex-exec  sh   plugins/floor/adapters/codex-exec/run.sh audit

for plugin in kernel signal floor panel; do
    gate "$plugin" bash "plugins/$plugin/tests/run.sh"
done

[ "$mode" = list ] && exit 0

printf '\n'

[ "$failed" -eq 0 ] && { printf 'ALL GREEN\n'; exit 0; }

printf '%d RED\n' "$failed"
[ -d "$logs" ] && printf 'kept in %s\n' "$logs"
exit 1
