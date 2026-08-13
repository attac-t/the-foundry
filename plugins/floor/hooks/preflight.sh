#!/bin/sh
#
# SessionStart: prove floor can still answer, and say so when it cannot.
#
# floor is silent when it works, so a hook that failed to start looks exactly like a healthy one.
# kernel found that out over eight releases. floor ships the instrument on its first day instead.
#
# Nothing here writes a file — kernel's audit counts probes left in the temp directory.

root="$(cd "$(dirname "$0")/.." && pwd)"

# Determine if the runner still resolves a Foundry home.
answers_home() {
    [ "$(FOUNDRY_HOME=__floor_probe__ sh "$root/bin/run.sh" home 2>/dev/null)" = "__floor_probe__" ]
}

#
# Determine if the runner still says "no run" instead of failing.
#
# The fake home is what makes this safe anywhere. In a checkout that does have a run the pointer
# still resolves, but no run directory can exist under `__floor_probe__`, so the answer is absence
# whatever the user is working on.
#
answers_absence() {
    out=$(FOUNDRY_HOME=__floor_probe__ FOUNDRY_RUN= sh "$root/bin/run.sh" path 2>/dev/null)
    status=$?
    [ "$status" -eq 1 ] || return 1
    [ -z "$out" ]
}

# Tell the user. This is the only line floor ever prints unasked.
warn() { printf '{"systemMessage":"floor: hooks not running — %s"}\n' "$1"; }

answers_home && answers_absence && exit 0

command -v git >/dev/null 2>&1 \
    || { warn "no git on PATH. floor finds the active run through git."; exit 0; }

warn "bin/run.sh did not answer. Reinstall the plugin."
exit 0
