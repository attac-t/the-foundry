#!/bin/sh
# SessionStart: say which run this checkout is working on. Silent when there is none.
#
# A hook cannot export a variable into the session that started it, so a run found through the
# pointer is a run kernel cannot see. Hence the last two lines.

root="$(cd "$(dirname "$0")/.." && pwd)"

dir=$(sh "$root/bin/run.sh" path 2>/dev/null) || exit 0

printf '🔨 floor: run `%s`\n' "$(basename "$dir")"
printf '   %s\n' "$dir"

[ -n "${FOUNDRY_RUN:-}" ] && exit 0

printf '   FOUNDRY_RUN is not set, so memory still resolves by branch.\n'
printf '   `export FOUNDRY_RUN=%s` before the session to move it.\n' "$dir"
