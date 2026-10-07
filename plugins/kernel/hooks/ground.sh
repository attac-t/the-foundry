#!/bin/sh
# SessionStart: asks for the ground at a cold start, and after a compaction only if it was lost.
#
# After a compaction the harness restates the skills a session loaded, within a budget that drops
# the oldest first. The ground loads first, so a long session can lose it, and a demand to reload
# it then contradicts a harness that says not to. So that one moment asks, and does not demand. #1109.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD=$(cat)

main() {
    after_a_compaction && { ask_only_if_lost; return; }
    demand_the_ground
}

# Whether the session restarted from a compaction. The payload names its cause in `source`.
after_a_compaction() {
    [ "$(printf '%s' "$PAYLOAD" | awk -f "$SCRIPT_DIR/lib/unjson.awk" -v path=source 2>/dev/null)" = compact ]
}

demand_the_ground() {
    cat <<'EOF'
---
🚨🚨🚨 **GROUND NOW** 🚨🚨🚨

⛔ Invoke `Skill(kernel:ground)` immediately.

- ❌ Do not ask.
- ❌ Do not skip.
- ❌ Do not respond to user until complete.
EOF
}

ask_only_if_lost() {
    cat <<'EOF'
---
🧭 **After a compaction.** The harness restates the skills this session loaded, within a budget.

- The budget drops skills one at a time, so check each `kernel:ground-*` skill on its own.
- If its text is missing, invoke that skill by name before you answer. Load no other.
EOF
}

main "$@"
