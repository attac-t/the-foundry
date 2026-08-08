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
# Probe by running, never by locating. macOS ships /usr/bin/python3 as a trampoline that prompts
# for Xcode Command Line Tools instead of executing — `command -v` finds it and it is not Python.
# `python` is absent on stock Debian besides.
for candidate in python3 python; do
  "$candidate" -c "" >/dev/null 2>&1 && PYTHON=$candidate && break
done
: "${PYTHON:?USAGE — needs a working python3. On macOS: xcode-select --install}"

exec env PYTHONDONTWRITEBYTECODE=1 "$PYTHON" "$(dirname "$0")/judges.py" "$@"
