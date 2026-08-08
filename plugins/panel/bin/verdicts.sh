#!/usr/bin/env bash
#
# An approval must show the verdicts it claims.
#
# Usage: verdicts.sh [panel-dir]    default: .claude/panel
#
# Exit   0 trail complete, or no approval yet · 1 approval unproven · 2 usage

set -euo pipefail

# No bytecode. A .pyc was committed into this plugin once; not writing them at all beats ignoring
# them, and a gate has nothing to gain from a cache.
exec env PYTHONDONTWRITEBYTECODE=1 python "$(dirname "$0")/verdicts.py" "$@"
