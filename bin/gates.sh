#!/bin/sh
#
# Every product gate, in one place.
#
# The README lists these seven. Nothing checks that the two agree — but they are now one file apart,
# which is the smallest a gap can get without a gate for it.
#
# Runs where you are. `bin/gates-in-docker.sh` runs it on Linux, where `sh` is dash.
#
# Usage: sh bin/gates.sh

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

failed=0

gate() {
    name=$1
    shift

    if "$@" >/dev/null 2>&1; then
        printf '  PASS  %s\n' "$name"
    else
        printf '  FAIL  %s (exit %s)\n' "$name" "$?"
        failed=$((failed + 1))
    fi
}

printf 'sh  %s\n' "$(readlink -f /bin/sh 2>/dev/null || echo '?')"
printf 'awk %s\n\n' "$(awk -W version 2>&1 | head -1)"

# `bash`, because every one of these opens `#!/bin/bash` and CI runs them that way. Under dash they
# exit 127 on the first bash-only line, which says nothing about the gate.
#
# The dash coverage is not lost by that. It lands where it belongs: floor's suite is bash, and the
# runner it exercises opens `#!/bin/sh`, so on Linux that runner executes under dash. The harness
# and the shipped code are different languages here on purpose.
gate frontmatter bash bin/frontmatter.sh
gate versions    bash bin/versions.sh

# shellcheck disable=SC2046  # the file list is the argument, and none of these paths hold a space
gate repeats     bash bin/repeats.sh \
    $(git ls-files 'plugins/panel/*.md' 'plugins/pest/*.md' 'plugins/signal/*.md')

for plugin in kernel signal floor panel; do
    gate "$plugin" bash "plugins/$plugin/tests/run.sh"
done

printf '\n'

[ "$failed" -eq 0 ] && { printf 'ALL GREEN\n'; exit 0; }
printf '%d RED\n' "$failed"
exit 1
