#!/bin/sh
#
# SessionStart: prove signal can still judge, and say so when it cannot.
#
# Every other way signal fails is quiet. No `awk`, a lib that did not ship, a clone that rewrote the
# line endings — each one ends with the Stop hook reading an empty reply and exiting 0, which is the
# same thing it does when your writing was fine. A gate that cannot tell you it has stopped guarding
# is worse than no gate, because you believe you are covered.
#
# So we run the shipped code against known input and check the answer, once, at the top of the
# session. Silent when it works. One line when it does not.
#

root="$(cd "$(dirname "$0")/.." && pwd)"

# The dials stay at their defaults here, so a project that loosens them cannot turn this check into
# a false alarm.
blocking='Fundamentally, the comprehensive implementation demonstrates extraordinarily sophisticated architectural considerations.'

# Determine if the scorer still blocks prose it must block.
scores() { printf '%s' "$blocking" | awk -f "$root/lib/score.awk" >/dev/null 2>&1; [ $? -eq 2 ]; }

# Determine if the reader still finds a value in a hook payload.
reads() { [ "$(printf '{"a":1,"b":"yes"}' | awk -f "$root/lib/unjson.awk" -v key=b 2>/dev/null)" = "yes" ]; }

# Determine if the sanitiser still strips what would break our JSON.
cleans() { [ "$(printf 'a"b\\c' | awk -f "$root/lib/jsonsafe.awk" 2>/dev/null)" = "abc" ]; }

# Tell the user. This is the only line signal ever prints unasked.
warn() { printf '{"systemMessage":"signal: not running — %s"}\n' "$1"; }

scores && reads && cleans && exit 0

command -v awk >/dev/null 2>&1 \
  || { warn "no awk on PATH. signal needs bash and awk, nothing else."; exit 0; }

warn "awk is there but lib/ did not answer. Reinstall the plugin."
exit 0
