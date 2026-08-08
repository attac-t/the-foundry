#!/usr/bin/env bash
#
# Law 4 as an exit code: a judge never writes what it judges.
#
# Usage: judges.sh [charter.md]     default: .claude/panel/charter.md
#        PANEL_AGENT_PATH=<dir>     where agents are looked up
#
# Exit   0 eligible · 1 ineligible, unresolvable, or none seated · 2 usage

set -euo pipefail

# No bytecode. A .pyc was committed into this plugin once; not writing them at all beats ignoring
# them, and a gate has nothing to gain from a cache.
exec env PYTHONDONTWRITEBYTECODE=1 python "$(dirname "$0")/judges.py" "$@"
