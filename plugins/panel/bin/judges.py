"""Law 4 as an exit code: a judge never writes what it judges.

Exit  0 every named judge is eligible
      1 a named judge is ineligible or unresolvable, or the charter names none
      2 usage — charter missing, unreadable, or no `## Panel` to parse
"""

import os
import pathlib
import re
import sys

from charter import FAILED, die, has_author, panel_section, read, seated, unlabelled

ALLOWED = {"Read", "Glob", "Grep"}
NAME = re.compile(r"^[a-z][a-z0-9-]*(:[a-z][a-z0-9-]*)?$")
FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)
TOOLS = re.compile(r"^tools:\s*(.+)$", re.MULTILINE)

FORMAT = ("      author:  panel:author",
          "      gate 1:  panel:adversary",
          "      gate 2:  panel:newcomer")


def roots():
    override = os.environ.get("PANEL_AGENT_PATH")
    if override:
        return [pathlib.Path(override)]
    return [pathlib.Path("plugins"), pathlib.Path(".claude/agents")]


def locate(name):
    """A pin that misses returns nothing.

    Searching on would resolve `pest:adversary` to *panel's* adversary — restricted, so the gate
    would certify the wrong file and exit 0. A near-miss that passes beats nothing at all.
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
    head = FRONTMATTER.match(read(path))
    if not head:
        return None
    line = TOOLS.search(head.group(1))
    if not line:
        return None
    return {tool.strip() for tool in line.group(1).split(",") if tool.strip()}


def fault(name):
    """Why this judge cannot hold a gate, or None."""
    if not NAME.match(name):
        return "unresolved", "not an agent name — expected `plugin:agent` or `agent`"

    path = locate(name)
    if path is None:
        return "unresolved", "no agent of that name — a gate cannot seat what does not exist"

    tools = declared_tools(path)
    if tools is None:
        return "law4", f"{path.as_posix()} declares no `tools:` — it inherits every tool, Write included"
    if not tools <= ALLOWED:
        return "law4", f"{path.as_posix()} also holds {', '.join(sorted(tools - ALLOWED))}"
    return None


def refuse_empty(charter, section):
    """The only charters in existence are the pre-moments shape. Say which one was found."""
    print(f"FAIL — {charter} seats no judge.")
    print()

    flat = unlabelled(section)
    if flat:
        print("  `## Panel` names agents but assigns no gate, so no mandate is recorded:")
        print(f"      {flat[0]}")
        print()
        print("  Give each a moment — a gate says what is certified, the agents say who certifies:")
        print(*FORMAT, sep="\n")
        sys.exit(FAILED)

    if has_author(section):
        print("  Only `author:` is seated. The author writes; nobody is set to judge the writing,")
        print("  which is the one arrangement this plugin exists to refuse.")
        sys.exit(FAILED)

    print("  `## Panel` is empty.")
    sys.exit(FAILED)


def report(failures, total, gates):
    if not failures:
        print(f"PASS — {total} judges across {gates} gates; none can write what it judges.")
        return 0

    print(f"FAIL — {len(failures)} of {total} seated judges cannot hold a gate.")
    print()
    for gate, name, _, reason in failures:
        print(f"  {gate}: {name}")
        print(f"      {reason}")

    # Only invoke the law that broke. An unresolvable name is a typo, not a violation.
    if any(kind == "law4" for _, _, kind, _ in failures):
        print()
        print("Law 4. A judge that can write what it judges may have written what it approves.")
    return FAILED


def main(charter):
    section = panel_section(charter)
    judges = seated(section)

    if not judges:
        refuse_empty(pathlib.Path(charter).as_posix(), section)

    failures = [(gate, name, *found)
                for gate, name in judges
                for found in [fault(name)] if found]

    gates = len({gate for gate, _ in judges})
    return report(failures, len(judges), gates)


sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ".claude/panel/charter.md"))
