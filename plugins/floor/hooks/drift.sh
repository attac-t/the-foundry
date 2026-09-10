#!/bin/sh
# SessionStart: say when this session could load a plugin the marketplace no longer ships.
#
# A skill is read from a cache keyed by its version, so a rule can land on `main` and change nothing
# in the session that wrote it. **Nothing said so unless somebody ran a command**, and #559 wants a
# session told without being asked.
#
# **Quiet by design.** `plugins.sh host` reports everywhere this host ever registered anything, and
# on the machine this was written on that is two shouting lines about worktrees deleted weeks ago.
# A hook that speaks twice a day about nothing is one nobody reads by the end of the week.
#
# So it asks the narrow half: what could a session standing *here* load. That turned fifty-two rows
# into two and left one line — a plugin registered at two versions for the same checkout.
#
# Silent outside a repository, because there is no *here* to ask about.

#
# **Exit 0 on every path, and the `exit` is the whole reason this is two lines.** `session` answers
# 1 when it found drift, which is exactly when this has something to say — so passing its status on
# made the hook fail whenever it was working.
#
# A hook exiting non-zero is a non-blocking error, and what it printed may never reach the session.
# Every other hook floor ships ends the same way.
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

sh "$(dirname "$0")/../lib/plugins.sh" session "$root"

exit 0
