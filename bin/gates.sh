#!/bin/sh
#
# Every product gate. `bin/agree.sh` checks the README and the workflow name these same ones.
#
#   sh bin/gates.sh         run them here
#   sh bin/gates.sh linux   run them where `sh` is dash
#   sh bin/gates.sh list    name them, run nothing
#
# No `set -e`: a gate that fails must not stop the ones after it. One red square names one gate.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

mode=${1:-run}
failed=0

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
    docker run --rm -v "$root:/src:ro" foundry-gates sh -c '
        cp -r /src ~/repo && cd ~/repo
        [ -f .git ] && { rm -f .git; git init -q .; git add -A; }
        git config --global --add safe.directory ~/repo
        sh bin/gates.sh
    '
}

[ "$mode" = linux ] && { on_linux; exit $?; }

# What a gate's exit code means, repo-wide. `bin/shell.sh` named these first; floor's audit answers
# 3 when its experiments never ran. A number is only legible to whoever already knows the table.
why_failed() {
    case "$1" in
        1) printf 'a rule broken'     ;;
        3) printf 'it could not read' ;;
        *) printf 'it did not run'    ;;
    esac
}

# One list, two readers. `agree` compares names against the README and the workflow, and a list it
# could not obtain from here would be a fourth place to keep them in step.
gate() {
    name=$1
    shift

    [ "$mode" = list ] && { printf '%s\n' "$name"; return; }

    "$@" >/dev/null 2>&1 && { printf '  PASS  %s\n' "$name"; return; }

    code=$?

    printf '  FAIL  %s — %s (exit %s)
' "$name" "$(why_failed "$code")" "$code"
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

# The three root files are here because their whole job is to say different things: `CLAUDE.md`
# routes and holds no rules, `CONTRIBUTING` holds procedure, `README` holds the front
# page. Kernel and floor markdown hold 19 repeats and are a lane of their own.
#
# shellcheck disable=SC2046  # the file list is the argument, and none of these paths hold a space
gate repeats     bash bin/repeats.sh \
    $(git ls-files 'plugins/panel/*.md' 'plugins/pest/*.md' 'plugins/signal/*.md' \
                   README.md CONTRIBUTING.md CLAUDE.md)

gate shell       bash bin/shell.sh

for plugin in kernel signal floor panel; do
    gate "$plugin" bash "plugins/$plugin/tests/run.sh"
done

[ "$mode" = list ] && exit 0

printf '\n'

[ "$failed" -eq 0 ] && { printf 'ALL GREEN\n'; exit 0; }
printf '%d RED\n' "$failed"
exit 1
