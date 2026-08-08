#!/usr/bin/env bash
#
# Fails when marketplace.json and a plugin.json disagree about a version.
#
# Promoted after panel was bumped six times in one session and the manifest was synced zero times.
# CLAUDE.md already says to bump on every change; it does not say where, and the second place is
# the one that gets forgotten.

set -euo pipefail

cd "$(dirname "$0")/.."

# Probe by running, never by locating. macOS ships /usr/bin/python3 as a trampoline that prompts
# for Xcode Command Line Tools instead of executing — `command -v` finds it and it is not Python.
# `python` is absent on stock Debian besides.
for candidate in python3 python; do
  "$candidate" -c "" >/dev/null 2>&1 && PYTHON=$candidate && break
done
: "${PYTHON:?USAGE — needs a working python3. On macOS: xcode-select --install}"

"$PYTHON" - <<'PY'
import json, pathlib, sys

manifest = json.loads(pathlib.Path(".claude-plugin/marketplace.json").read_text())
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
