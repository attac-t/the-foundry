#!/usr/bin/env bash
#
# Fails when a plugin component is missing the frontmatter that registers it.
#
# Promoted after `craft-plugin-update` — the one skill CLAUDE.md mandates — was found with no
# frontmatter at all, 1 of 123. It still loaded: the harness falls back to the directory name and
# scrapes a description from the first blockquote. So it registered as "Bump, commit, push. In that
# order." — an epigraph standing in for a description, which is what the model reads when deciding
# whether the skill is relevant. Silent degradation, not a crash, which is why nothing caught it.
#
# A closed predicate: N field comparisons, machine-decidable, no thresholds and no corpus tuning.

set -euo pipefail

cd "$(dirname "$0")/.."

# `python3`, never `python`. See bin/versions.sh for what the bare name cost.
python3 - <<'PY'
import pathlib, re, sys

FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)
failures = []


def fields(path):
    match = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if not match:
        return None
    found = {}
    for line in match.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "\t", "-")):
            key, _, value = line.partition(":")
            found[key.strip()] = value.strip()
    return found


def check(path, expected_name, required):
    found = fields(path)
    if found is None:
        failures.append((path, "no frontmatter — the file does not open with ---"))
        return
    for key in required:
        if not found.get(key):
            failures.append((path, f"missing or empty `{key}:`"))
    actual = found.get("name")
    if expected_name and actual and actual != expected_name:
        failures.append((path, f"`name: {actual}` does not match `{expected_name}`"))


for skill in sorted(pathlib.Path("plugins").glob("*/skills/*/SKILL.md")):
    check(skill, skill.parent.name, ("name", "description"))

for agent in sorted(pathlib.Path("plugins").glob("*/agents/*.md")):
    check(agent, agent.stem, ("name", "description"))

for command in sorted(pathlib.Path("plugins").glob("*/commands/*.md")):
    check(command, None, ("description",))

checked = (
    len(list(pathlib.Path("plugins").glob("*/skills/*/SKILL.md")))
    + len(list(pathlib.Path("plugins").glob("*/agents/*.md")))
    + len(list(pathlib.Path("plugins").glob("*/commands/*.md")))
)

# Nothing to check is not a clean check. `bin/shell.sh` wrote this convention and floor uses it in
# three places: a gate given nothing to read exits 3 and says so.
if not checked:
    print("FAIL — no plugin components found. This gate read nothing.")
    sys.exit(3)

if not failures:
    print(f"PASS — {checked} components carry the frontmatter that registers them.")
    sys.exit(0)

print(f"FAIL — {len(failures)} of {checked} components will register wrong or not at all.")
print()
for path, reason in failures:
    print(f"  {path.as_posix()}")
    print(f"      {reason}")
sys.exit(1)
PY
