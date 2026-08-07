"""An approval must show the verdicts it claims.

`craft-verdict` specifies the trail and `adversary.md` assigns the recording to the parent. Both are
instructions to a model that would also have to obey them, and on the only production run in
existence all eight judgements went unwritten.

Exit  0 trail complete, or no approval yet
      1 the approval is unproven
      2 usage — no charter, or no `## Panel` to parse
"""

import pathlib
import sys

import re

from charter import FAILED, die, panel_section, read, seated

# A short SHA carries a digit. Without that requirement, `defaced` is valid hex.
COMMIT = re.compile(r"\b(?=[0-9a-f]*\d)[0-9a-f]{7,40}\b")
VERDICT = re.compile(r"^\d+-(?P<role>[a-z][a-z0-9-]*)-verdict\.md$")


def recorded(verdicts):
    if not verdicts.is_dir():
        return set()
    return {found.group("role")
            for entry in verdicts.iterdir()
            for found in [VERDICT.match(entry.name)] if found}


def owed(section, on_record):
    """Seated judges with nothing filed. A role is a name without its plugin."""
    return [(gate, name.rpartition(":")[2])
            for gate, name in seated(section)
            if name.rpartition(":")[2] not in on_record]


def refuse_unanchored(approval):
    die(FAILED, f"FAIL — {approval.as_posix()} cites no commit.", "",
        "  An approval nobody can anchor cannot be re-read. The next judge has no way to",
        "  reconstruct what this one saw.")


def refuse_empty(approval, verdicts):
    die(FAILED, f"FAIL — {approval.as_posix()} claims a review with no verdict beside it.", "",
        f"  {verdicts.as_posix()} holds no `NNN-<role>-verdict.md`.", "",
        "  Law 5. A verdict that was never written is a review that did not happen — the history",
        "  a later judge reads, and the promotion counter, both operate on nothing.")


def refuse_missing(missing, verdicts):
    print(f"FAIL — {len(missing)} seated judge(s) left no verdict.")
    print()
    for gate, role in missing:
        print(f"  {gate}: {role}")
        print(f"      no {verdicts.as_posix()}/NNN-{role}-verdict.md")
    sys.exit(FAILED)


def main(panel_dir):
    panel = pathlib.Path(panel_dir)
    verdicts = panel / "verdicts"
    approval = verdicts / "approval.md"

    section = panel_section(panel / "charter.md")

    if not approval.is_file():
        print(f"PASS — {panel.as_posix()} claims no approval; a run in flight owes no trail.")
        return 0

    if not COMMIT.search(read(approval)):
        refuse_unanchored(approval)

    on_record = recorded(verdicts)
    if not on_record:
        refuse_empty(approval, verdicts)

    missing = owed(section, on_record)
    if missing:
        refuse_missing(missing, verdicts)

    print(f"PASS — {len(on_record)} role(s) on record; the approval shows its work.")
    return 0


sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ".claude/panel"))
