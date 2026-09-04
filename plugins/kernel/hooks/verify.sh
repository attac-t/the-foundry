#!/bin/sh
# Stop: hand the turn back when the blueprint still shows work in flight. Once per turn.
#
# A block costs the reader a second reply. One is worth it: the
# reason names work that agent can do: close, defer, or hand
# off. Eight are not, and eight is what it did unguarded.
#
# `stop_hook_active` is set by any plugin's stop hook, not just
# ours, so reading it as a stand down gives up our block now
# and then. A late nag is free. A stuck one costs it all.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")
BLUEPRINT="$MEMORY_DIR/blueprint.md"
PAYLOAD=$(cat)

# Already continuing because of a stop hook? Let this turn end.
CONTINUING=$(printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path=stop_hook_active 2>/dev/null)
[ "$CONTINUING" = "true" ] && exit 0

# No blueprint? Allow stop.
[ -f "$BLUEPRINT" ] || exit 0

# The three states that mean work is still moving.
#
# `craft-blueprint` runs a self task `pending -> in-progress -> done`, and an agent task
# `pending -> delegated -> in-review -> done`. `templates/blueprint.md` adds `deferred` to either.
# Six states, and this read one of them — the self lane. Three agents could be working, or three
# could have reported with nobody looking, and the turn ended clean either way.
#
# `in-review` is the worst of the three to miss: it means output arrived and no one has read it.
#
# Named here rather than counted, because a reader waits on `delegated` and reviews `in-review`.
# A number cannot tell them which.
IN_FLIGHT=
for state in in-progress delegated in-review; do
    grep -q "| $state |" "$BLUEPRINT" 2>/dev/null && IN_FLIGHT="$IN_FLIGHT $state"
done

# Nothing moving? Allow stop. `pending` has not started; `done` and `deferred` have stopped.
[ -n "$IN_FLIGHT" ] || exit 0

cat <<EOF
{
  "decision": "block",
  "reason": "Blueprint shows work in flight:$IN_FLIGHT. Complete it, review it, mark it deferred, or create a handoff before stopping."
}
EOF
