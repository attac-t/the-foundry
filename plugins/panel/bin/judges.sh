#!/usr/bin/env bash
#
# Law 4 as an exit code: a judge never writes what it judges.
#
# Reads a charter's `## Panel` section, resolves every agent named on a gate, and fails unless each
# one restricts its tools to Read, Glob, Grep. `author:` is exempt — the author writes by design.
#
# An allowlist, not a denylist (ADR-001): a denylist is a guess about the tool surface, and the
# surface changes every release. A judge needing a fourth tool fails here and a human decides.
#
# Judges resolve by NAME, never by glob. A README sitting in an agents/ directory is therefore
# invisible to this gate rather than a false positive.
#
# Usage: judges.sh [charter.md]        default: .claude/panel/charter.md
#        PANEL_AGENT_PATH=<dir>        override where agents are looked up
#
# Exit  0  every named judge is eligible
#       1  a named judge is ineligible or unresolvable, or the charter names none
#       2  usage — charter missing, unreadable, or no `## Panel` to parse

set -euo pipefail

CHARTER="${1:-.claude/panel/charter.md}" python - <<'PY'
import os, pathlib, re, sys

ALLOWED = {"Read", "Glob", "Grep"}

charter = pathlib.Path(os.environ["CHARTER"])
if not charter.is_file():
    print(f"USAGE — no charter at {charter.as_posix()}")
    sys.exit(2)

try:
    text = charter.read_text(encoding="utf-8")
except (OSError, UnicodeDecodeError) as unreadable:
    print(f"USAGE — cannot read {charter.as_posix()}: {unreadable}")
    sys.exit(2)

# A charter documents its own format in a fenced example, so the fence must go before the section
# is located — otherwise the example is what gets parsed. This is the defect that let the previous
# `grep -A8 '^## Panel'` gate pass on the flat roster it was written to reject.
unfenced = re.sub(r"^[ \t]*```.*?^[ \t]*```", "", text, flags=re.MULTILINE | re.DOTALL)

sections = re.findall(r"^##\s+Panel\s*$(.*?)(?=^##\s|\Z)", unfenced, re.MULTILINE | re.DOTALL)
if not sections:
    print(f"USAGE — {charter.as_posix()} has no `## Panel` section to parse.")
    sys.exit(2)
if len(sections) > 1:
    # Picking one silently is a second mechanism doing the fence bug's job.
    print(f"USAGE — {charter.as_posix()} has {len(sections)} `## Panel` sections; which one "
          "governs is not decidable.")
    sys.exit(2)
section = sections[0]


def roots():
    override = os.environ.get("PANEL_AGENT_PATH")
    return [pathlib.Path(override)] if override else [pathlib.Path("plugins"),
                                                     pathlib.Path(".claude/agents")]


def locate(name):
    """`plugin:agent` pins the plugin; a bare name is searched wherever agents live.

    A pin that misses returns nothing. Falling through to a search would resolve `pest:adversary`
    to *panel's* adversary — a restricted agent, so the gate would certify the wrong file and exit
    0. A near-miss that passes is worse than one that fails.
    """
    plugin, _, stem = name.rpartition(":")
    for root in roots():
        if not root.is_dir():
            continue
        if plugin:
            pinned = root / plugin / "agents" / f"{stem}.md"
            if pinned.is_file():
                return pinned
            continue
        for found in root.rglob(f"{stem}.md"):
            if found.parent.name == "agents" or root.name == "agents":
                return found
    return None


def declared_tools(path):
    head = re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n", path.read_text(encoding="utf-8"), re.DOTALL)
    if not head:
        return None
    line = re.search(r"^tools:\s*(.+)$", head.group(1), re.MULTILINE)
    return {t.strip() for t in line.group(1).split(",") if t.strip()} if line else None


gates, failures, authored = {}, [], False

NAME = re.compile(r"^[a-z][a-z0-9-]*(:[a-z][a-z0-9-]*)?$")

for line in section.splitlines():
    role = re.match(r"^\s*([A-Za-z][A-Za-z0-9 _-]{0,24})\s*:\s*(\S.*)$", line)
    if not role:
        continue
    label, named = role.group(1).strip(), role.group(2)
    if label.lower() == "author":
        authored = True
        continue
    # `panel:newcomer` ×4 — a gate may seat the same judge repeatedly; the count is not a name.
    # Strip the count before the backticks: it sits outside them, and stripping inward-out leaves
    # a trailing backtick welded to the name.
    # Extend, never assign: a gate may be listed across several lines, and overwriting drops the
    # judges named first — silently, and a writer among them with it.
    gates.setdefault(label, []).extend(
        re.sub(r"\s*[x×]\s*\d+\s*$", "", n, flags=re.IGNORECASE).strip().strip("`")
        for n in named.split(",") if n.strip())

seated = [(label, name) for label, names in gates.items() for name in names]

if not seated:
    # A pre-gate charter lists agents with no labels at all. Say which shape was found, or the
    # only charters in existence fail with advice they cannot act on.
    unlabelled = [ln.strip() for ln in section.splitlines()
                  if ln.strip() and not ln.lstrip().startswith("#")
                  and not re.match(r"^\s*[A-Za-z][A-Za-z0-9 _-]{0,24}\s*:", ln)]
    print(f"FAIL — {charter.as_posix()} seats no judge.")
    print()
    if unlabelled:
        print("  `## Panel` names agents but assigns no gate, so no mandate is recorded:")
        print(f"      {unlabelled[0]}")
        print()
        print("  Give each a moment — a gate says what is certified, the agents say who certifies:")
        print("      author:  panel:author")
        print("      gate 1:  panel:adversary")
        print("      gate 2:  panel:newcomer")
    elif authored:
        print("  Only `author:` is seated. The author writes; nobody is set to judge the writing,")
        print("  which is the one arrangement this plugin exists to refuse.")
    else:
        print("  `## Panel` is empty.")
    sys.exit(1)

for label, name in seated:
    if not NAME.match(name):
        failures.append((label, name, "unresolved",
                         "not an agent name — expected `plugin:agent` or `agent`"))
        continue
    path = locate(name)
    if path is None:
        failures.append((label, name, "unresolved",
                         "no agent of that name — a gate cannot seat what does not exist"))
        continue
    tools = declared_tools(path)
    if tools is None:
        failures.append((label, name, "law4", f"{path.as_posix()} declares no `tools:` — it "
                                              "inherits every tool, Write included"))
    elif not tools <= ALLOWED:
        over = ", ".join(sorted(tools - ALLOWED))
        failures.append((label, name, "law4", f"{path.as_posix()} also holds {over}"))

if not failures:
    print(f"PASS — {len(seated)} judges across {len(gates)} gates; none can write what it judges.")
    sys.exit(0)

print(f"FAIL — {len(failures)} of {len(seated)} seated judges cannot hold a gate.")
print()
for label, name, _, reason in failures:
    print(f"  {label}: {name}")
    print(f"      {reason}")

# Only invoke the law that was actually broken. An unresolvable name is a typo, not a violation.
if any(kind == "law4" for _, _, kind, _ in failures):
    print()
    print("Law 4. A judge that can write what it judges may have written what it approves.")
sys.exit(1)
PY
