#!/usr/bin/env bash
#
# Fails when marketplace.json and a plugin.json disagree about a version.
#
# Promoted after panel was bumped six times in one session and the manifest was synced zero times.
# CLAUDE.md already says to bump on every change; it does not say where, and the second place is
# the one that gets forgotten.
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

# An empty list is the same answer one level in: every plugin in it agrees, and there are none.
if not plugins:
    unreadable("the manifest lists no plugins")

drift = []

for entry in plugins:
    named = entry.get("source")
    if not named:
        unreadable("a manifest entry names no source")

    source = pathlib.Path(named) / ".claude-plugin/plugin.json"
    actual = read_json(source, f"{named}'s plugin.json").get("version")

    # Two files silent about a version agree, and agree about nothing. The
    # manifest may omit one and drift; the plugin it names may
    # not, because that file is where the answer lives.
    if actual is None:
        unreadable(f"{named} declares no version")

    listed = entry.get("version")
    if listed != actual:
        drift.append((entry.get("name", named), listed, actual))

if not drift:
    print(f"PASS — {len(plugins)} plugins agree with the manifest.")
    sys.exit(0)

print("FAIL — the manifest disagrees with the plugin it points at.")
print()
for name, listed, actual in drift:
    print(f"  {name}")
    print(f"      marketplace.json  {listed}")
    print(f"      plugin.json       {actual}")
sys.exit(1)
PY
