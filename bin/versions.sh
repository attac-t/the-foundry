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

manifest_file = pathlib.Path(".claude-plugin/marketplace.json")

# A manifest that is not there used to leave by traceback at exit 1, which this repository reads as
# a rule broken. Nothing was broken and nothing was read. An empty plugin list is the same
# answer one level in: every plugin in it agrees, and there are none.
if not manifest_file.is_file():
    print("FAIL — no plugin manifest found. This gate read nothing.")
    sys.exit(3)

manifest = json.loads(manifest_file.read_text())

if not manifest["plugins"]:
    print("FAIL — the manifest lists no plugins. This gate read nothing.")
    sys.exit(3)

drift = []

for entry in manifest["plugins"]:
    listed = entry.get("version")
    source = pathlib.Path(entry["source"]) / ".claude-plugin/plugin.json"
    actual = json.loads(source.read_text())["version"]
    if listed != actual:
        drift.append((entry["name"], listed, actual))

if not drift:
    print(f"PASS — {len(manifest['plugins'])} plugins agree with the manifest.")
    sys.exit(0)

print("FAIL — the manifest disagrees with the plugin it points at.")
print()
for name, listed, actual in drift:
    print(f"  {name}")
    print(f"      marketplace.json  {listed}")
    print(f"      plugin.json       {actual}")
sys.exit(1)
PY
