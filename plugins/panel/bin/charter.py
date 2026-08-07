"""Reading a charter's `## Panel` section.

Shared by judges.py and verdicts.py: who is seated on a gate is exactly who owes a verdict, so a
second parser would be a second answer to one question.
"""

import pathlib
import re
import sys

USAGE, FAILED = 2, 1

ROLE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9 _-]{0,24})\s*:\s*(\S.*)$")
REPEAT = re.compile(r"\s*[x×]\s*\d+\s*$", re.IGNORECASE)
SECTION = re.compile(r"^##\s+Panel\s*$(.*?)(?=^##\s|\Z)", re.MULTILINE | re.DOTALL)
FENCE = re.compile(r"^[ \t]*```.*?^[ \t]*```", re.MULTILINE | re.DOTALL)


def die(code, *lines):
    print("\n".join(lines))
    sys.exit(code)


def read(path):
    try:
        return pathlib.Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as unreadable:
        die(USAGE, f"USAGE — cannot read {pathlib.Path(path).as_posix()}: {unreadable}")


def panel_section(path):
    """The section, never the fenced example of it that every charter also carries."""
    charter = pathlib.Path(path)
    if not charter.is_file():
        die(USAGE, f"USAGE — no charter at {charter.as_posix()}")

    found = SECTION.findall(FENCE.sub("", read(charter)))
    if not found:
        die(USAGE, f"USAGE — {charter.as_posix()} has no `## Panel` section to parse.")
    if len(found) > 1:
        # Choosing one silently is a second mechanism doing the fence bug's job.
        die(USAGE, f"USAGE — {charter.as_posix()} has {len(found)} `## Panel` sections; "
                   "which one governs is not decidable.")
    return found[0]


def _names(field):
    for name in field.split(","):
        name = REPEAT.sub("", name).strip().strip("`")
        if name:
            yield name


def seated(section):
    """[(gate, name)] for every judge. `author:` is exempt — it writes, it does not judge."""
    judges = []
    for line in section.splitlines():
        role = ROLE.match(line)
        if not role:
            continue
        gate = role.group(1).strip()
        if gate.lower() == "author":
            continue
        judges.extend((gate, name) for name in _names(role.group(2)))
    return judges


def has_author(section):
    return any(role.group(1).strip().lower() == "author"
               for line in section.splitlines()
               for role in [ROLE.match(line)] if role)


def unlabelled(section):
    """Lines naming agents with no gate — the pre-moments roster shape."""
    return [line.strip() for line in section.splitlines()
            if line.strip() and not line.lstrip().startswith("#") and not ROLE.match(line)]
