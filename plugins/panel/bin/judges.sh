#!/usr/bin/env bash
#
# Law 4 as an exit code: a judge never writes what it judges.
#
# Usage: judges.sh [charter.md]     default: .claude/panel/charter.md
#        PANEL_AGENT_PATH=<dir>     where agents are looked up
#
# Exit   0 eligible · 1 ineligible, unresolvable, or none seated · 2 usage

set -euo pipefail

exec python "$(dirname "$0")/judges.py" "$@"
