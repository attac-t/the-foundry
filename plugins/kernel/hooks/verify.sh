#!/bin/sh
# Stop: hand the turn back when the blueprint still shows work in flight.
#
# Once per turn, and this is the whole point of the guard below.
#
# `Stop` fires after the reply is written and on screen, so blocking never takes that reply back —
# it adds a second one beside it. One is worth it here, because the reason names work the agent can
# actually do: close the task, defer it, or write the handoff. Eight are not. Without a guard this
# blocked every turn until Claude Code overrode it at the eighth, so the reader paid eight replies
# for one line and the blueprint ended no closer to done.
#
# `stop_hook_active` is true whenever a stop hook is already driving the turn — any plugin's, not
# only this one. Reading it as "stand down" gives up our block to someone else's now and then. That
# trade is the right way round: a nag that arrives one turn late costs nothing, and a nag that
# cannot be turned off costs every turn.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")
BLUEPRINT="$MEMORY_DIR/blueprint.md"
PAYLOAD=$(cat)

# Already continuing because of a stop hook? Let this turn end.
CONTINUING=$(printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path=stop_hook_active 2>/dev/null)
[ "$CONTINUING" = "true" ] && exit 0

# No blueprint? Allow stop.
[ -f "$BLUEPRINT" ] || exit 0

# Count in-progress tasks. `grep -c` exits 1 on no match, so the fallback is the empty count.
IN_PROGRESS=$(grep -c '| in-progress |' "$BLUEPRINT" 2>/dev/null) || IN_PROGRESS=0

# No in-progress tasks? Allow stop.
[ "$IN_PROGRESS" -eq 0 ] && exit 0

cat <<EOF
{
  "decision": "block",
  "reason": "Blueprint shows $IN_PROGRESS task(s) in-progress. Either complete them, mark as deferred, or create a handoff before stopping."
}
EOF
