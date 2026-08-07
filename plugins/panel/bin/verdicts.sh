#!/usr/bin/env bash
#
# An approval must show the verdicts it claims.
#
# Usage: verdicts.sh [panel-dir]    default: .claude/panel
#
# Exit   0 trail complete, or no approval yet · 1 approval unproven · 2 usage

set -euo pipefail

exec python "$(dirname "$0")/verdicts.py" "$@"
