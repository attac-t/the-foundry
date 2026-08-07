"""An approval must show the verdicts it claims.

`craft-verdict` specifies the trail and `adversary.md` assigns the recording to the parent. Both are
instructions to a model that would also have to obey them, and on the only production run in
existence all eight judgements went unwritten.

The trail is scoped to its run. `verdicts/` holds the charter in flight; a closed run is archived to
`verdicts/<slug>/`, and its files stop discharging anybody. Without that, one `001-adversary-verdict.md`
turns the gate green forever — which is the defect it exists to catch, living inside it.

Exit  0 trail complete, or no approval yet
      1 the approval is unproven, or belongs to another charter
      2 usage — no charter, no `## Panel`, no `# Charter:` heading, or seats that collide
"""

import collections
import pathlib
import re
import sys

from charter import FAILED, USAGE, die, panel_section, read, seated, title

# A short SHA carries a digit. Without that requirement, `defaced` is valid hex.
COMMIT = re.compile(r"\b(?=[0-9a-f]*\d)[0-9a-f]{7,40}\b")
VERDICT = re.compile(r"^\d+-(?P<role>[a-z][a-z0-9-]*)-verdict\.md$")


def role_of(name):
    return name.rpartition(":")[2]


def roster(section):
    """[(gate, name, role)], refusing a stem two plugins share.

    `craft-verdict` files by role, so `panel:adversary` and `x:adversary` would be discharged by
    one verdict. Rather than pass silently, say the filename cannot carry the distinction.
    """
    judges = [(gate, name, role_of(name)) for gate, name in seated(section)]
    clash = [role for role, names in
             collections.Counter(role_of(n) for _, n in seated(section)).items() if names > 1]
    collided = {role for role in clash
                if len({name for _, name, stem in judges if stem == role}) > 1}
    if collided:
        die(USAGE, f"USAGE — seats share a role name: {', '.join(sorted(collided))}.",
            "  `NNN-<role>-verdict.md` cannot tell them apart, so one file would discharge both.")
    return judges


def recorded(verdicts):
    """The live trail only. `iterdir` does not descend, so an archived run cannot discharge."""
    if not verdicts.is_dir():
        return set()
    return {found.group("role")
            for entry in verdicts.iterdir()
            for found in [VERDICT.match(entry.name)] if found}


def refuse_foreign(approval, name):
    die(FAILED, f"FAIL — {approval.as_posix()} does not name this charter.", "",
        f"  Expected it to mention: {name}", "",
        "  A closed run's approval left in place discharges the next run for free. Archive it to",
        "  `verdicts/<slug>/` so the charter in flight starts with an empty trail.")


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
    charter = panel / "charter.md"
    verdicts = panel / "verdicts"
    approval = verdicts / "approval.md"

    judges = roster(panel_section(charter))
    name = title(charter)

    if not approval.is_file():
        print(f"PASS — {panel.as_posix()} claims no approval; a run in flight owes no trail.")
        return 0

    claimed = read(approval)

    if name not in claimed:
        refuse_foreign(approval, name)

    if not COMMIT.search(claimed):
        refuse_unanchored(approval)

    on_record = recorded(verdicts)
    if not on_record:
        refuse_empty(approval, verdicts)

    missing = [(gate, role) for gate, _, role in judges if role not in on_record]
    if missing:
        refuse_missing(missing, verdicts)

    print(f"PASS — {len(on_record)} role(s) on record for {name}.")
    return 0


sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ".claude/panel"))
