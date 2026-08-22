#!/usr/bin/env bash
#
# Fails when a plugin the manifest lists cannot say what version it is.
#
# It used to compare two copies of the same number, because `marketplace.json` carried a version
# beside every plugin. That made one shared line the whole repository edits, so two branches touching
# different plugins collided by construction and work was stacked for packaging reasons.
#
# The field is optional and Claude Code falls back to `plugin.json`, so the second copy is gone and
# there is nothing left to disagree. What remains is the fault that actually breaks an install: a
# listed plugin whose own manifest is missing, malformed, or silent about its version.
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -euo pipefail

cd "$(dirname "$0")/.."

# `python3`, never `python`. The runner image CI uses carries a `python` symlink; macOS dropped it
# in Monterey and Debian never had it. So this gate was green in CI and "command not found" on the
# machine of anyone told by the README to run it first.
python3 - <<'PY'
import json, pathlib, sys

# Read one JSON file, or say which one and leave at 3. Bad JSON
# and a missing key both used to leave by traceback at 1,
# the code this repository reads as a rule broken.
def read_json(path, what):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as why:
        print(f"FAIL — {what} could not be read: {why}. This gate read nothing.")
        sys.exit(3)


def unreadable(what):
    print(f"FAIL — {what}. This gate read nothing.")
    sys.exit(3)


manifest_file = pathlib.Path(".claude-plugin/marketplace.json")

# Said plainly, because it is the case a stranger meets: they ran the gate from the wrong directory.
if not manifest_file.is_file():
    unreadable("no plugin manifest found")

plugins = read_json(manifest_file, "the plugin manifest").get("plugins")

# An empty list is the same answer one level in: every plugin in it is fine, and there are none.
if not plugins:
    unreadable("the manifest lists no plugins")

silent = []

for entry in plugins:
    named = entry.get("source")
    if not named:
        unreadable("a manifest entry names no source")

    source = pathlib.Path(named) / ".claude-plugin/plugin.json"
    if read_json(source, f"{named}'s plugin.json").get("version") is None:
        silent.append(named)

    # A version here would be a second copy of the same fact, and a line every branch edits.
    if "version" in entry:
        print(f"FAIL — {named} carries a version in the manifest. It belongs in its plugin.json alone.")
        sys.exit(1)

if not silent:
    print(f"PASS — {len(plugins)} plugins each say what version they are.")
    sys.exit(0)

print("FAIL — a listed plugin does not say what version it is.")
for named in silent:
    print(f"      {named}")
sys.exit(1)
PY
