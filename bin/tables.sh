#!/usr/bin/env bash
#
# Fails when a markdown table's pipes do not line up on screen.
#
# Promoted after a count: 80 of 175 tables were ragged. Eleven of those were padded to the character
# count and drifted anyway, because `❌` and `✅` take one slot in the file and two on screen. Six in
# ten is what a model scores on a rule with one right answer. Padding is arithmetic over the cells,
# so it belongs in code.
#
# The table is judged the way a plain text editor shows it, where nothing hides the pipes.
#
# Usage: bash bin/tables.sh [--fix] [files...]   (defaults to every tracked markdown file)

set -euo pipefail

# No `cd`, unlike its siblings. This gate takes file names, and a relative name belongs to the
# caller. Resolving from the repo root would leave a named file unreadable, and the easy reading of
# unreadable is to skip it — which turns a bad argument into a pass. So a name that does not resolve
# fails here. It is never dropped in silence.

# `python3`, never `python`. See bin/versions.sh for what the bare name cost.
python3 - "$@" <<'PY'
import pathlib, re, subprocess, sys, unicodedata

argv = sys.argv[1:]
fix = "--fix" in argv
named = [arg for arg in argv if arg != "--fix"]


# Every count below can be one, and "1 tables" reads badly in a gate about how text reads.
def tally(n, noun):
    if n == 1:
        return f"{n} {noun}"
    return f"{n} {noun}s"


# The files to read: the ones named on the command line, or every tracked markdown file.
def targets(named):
    if named:
        chosen = [pathlib.Path(name) for name in named]
        missing = [path for path in chosen if not path.is_file()]
        if not missing:
            return chosen
        print(f"FAIL — {tally(len(missing), 'path')} named but not found.")
        for path in missing:
            print(f"  {path}")
        sys.exit(1)

    root = pathlib.Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    )
    tracked = subprocess.run(
        ["git", "-C", root, "ls-files", "*.md"],
        capture_output=True, text=True, check=True,
    ).stdout.split()
    return [root / name for name in tracked if not name.startswith(".claude/")]


paths = targets(named)


# A dash row, and one cell of it. Both must match for a run of rows to count as a table.
DASH_ROW = re.compile(r"\A[\s|:-]+\Z")
DASH_CELL = re.compile(r"\A:?-+:?\Z")


# How many columns a run of text takes on screen.
#
# East Asian Width W and F are the two-column cases. Ambiguous is left at one on purpose: every
# Ambiguous character in this repo is an arrow, an em dash or a box-drawing rule, and each takes one
# column outside a CJK locale. Counting those as two would break the tables that are already right.
def columns_for(char):
    if unicodedata.east_asian_width(char) in "WF":
        return 2
    return 1


def width(text):
    return sum(map(columns_for, text))


# Where the pipes that split cells sit in a row. A backslash shields the next character, so `\|` is
# text inside a cell, not a split. Backticks shield nothing — markdown splits inside code spans too.
#
# One place holds this rule. Everything below asks this function rather than walking the row again.
def splits(row):
    found, shielded = [], False
    for index, char in enumerate(row):
        if shielded:
            shielded = False
            continue
        if char == "\\":
            shielded = True
            continue
        if char == "|":
            found.append(index)
    return found


# The trimmed cells of a row. The first and last pipes fence the row, so the cells sit between them.
def cells(row):
    text = row.strip()
    cuts = splits(text)
    return [text[start + 1:end].strip() for start, end in zip(cuts, cuts[1:])]


# Which screen column each splitting pipe lands in.
def pipe_columns(row):
    text = row.rstrip()
    cuts = set(splits(text))
    columns, position = [], 0
    for index, char in enumerate(text):
        if index in cuts:
            columns.append(position)
        position += width(char)
    return tuple(columns)


# A table is a run of pipe rows whose second row is the dash row. A flowchart drawn in pipes, or one
# quoted row, is not a table, and repadding either would wreck it.
def tables(lines):
    run, start = [], 0
    for index, line in enumerate(lines + [""]):
        text = line.strip()
        if text.startswith("|") and text.endswith("|") and text.count("|") >= 2:
            if not run:
                start = index
            run.append(line)
            continue
        if len(run) >= 2 and DASH_ROW.match(run[1]) and all(map(DASH_CELL.match, cells(run[1]))):
            yield start, run
        run = []


# Every row must put its pipes in the same screen columns.
def aligned(rows):
    return len({pipe_columns(row) for row in rows}) == 1


# Rebuild a table so every pipe lands in one column down the whole table.
def repad(rows):
    indent = re.match(r"[ \t]*", rows[0]).group()
    grid = [cells(row) for row in rows]
    count = max(len(row) for row in grid)
    for row in grid:
        row += [""] * (count - len(row))

    # A column is as wide as its widest cell. The dash row is left out of that measure — its dashes
    # are output, not content, so counting them would hold every column at its old width. The floor
    # of one keeps the rebuilt dash row at the three characters the format needs.
    body = grid[:1] + grid[2:]
    widths = [max(1, max(width(row[i]) for row in body)) for i in range(count)]

    def padded(values):
        cells = (value + " " * (widths[i] - width(value)) for i, value in enumerate(values))
        return f"{indent}| " + " | ".join(cells) + " |"

    # `:---`, `---:` and `:--:` set the column's alignment, so the colons have to survive the rebuild.
    def dashes(index, marker):
        left, right = marker.startswith(":"), marker.endswith(":")
        return ":" * left + "-" * (widths[index] + 2 - left - right) + ":" * right

    rule = indent + "|" + "|".join(dashes(i, m) for i, m in enumerate(grid[1])) + "|"
    return [padded(grid[0]), rule] + [padded(row) for row in grid[2:]]


here = pathlib.Path.cwd()


# Absolute paths open the file. A path the reader can paste back is what gets printed.
def label(path):
    try:
        return path.relative_to(here).as_posix()
    except ValueError:
        return path.as_posix()


checked, ragged, repaired = 0, [], []

for path in paths:
    lines = path.read_text(encoding="utf-8").split("\n")

    # A fenced block shows tables as specimens, so they are not this gate's business. Blanking the
    # block rather than dropping it keeps every line number honest.
    scanned, fenced = [], False
    for line in lines:
        if line.strip().startswith("```"):
            fenced = not fenced
            scanned.append("")
            continue
        if fenced:
            scanned.append("")
            continue
        scanned.append(line)

    edits = []
    for start, rows in tables(scanned):
        checked += 1
        if aligned(rows):
            continue
        ragged.append(f"{label(path)}:{start + 1}")
        edits.append((start, len(rows), repad(rows)))

    if fix and edits:
        for start, length, rebuilt in reversed(edits):
            lines[start:start + length] = rebuilt
        # `newline=""`, not write_text. write_text grew a newline argument in 3.10, and the python3
        # macOS ships is 3.9. Without it the host's line ending leaks into every line this touches.
        with path.open("w", encoding="utf-8", newline="") as handle:
            handle.write("\n".join(lines))
        repaired.append((label(path), len(edits)))

if fix:
    total = sum(count for _, count in repaired)
    print(f"Repadded {tally(total, 'table')} in {tally(len(repaired), 'file')}, of {checked} read.")
    for name, count in repaired:
        print(f"  {name} — {count}")
    sys.exit(0)

if not ragged:
    print(f"PASS — {tally(checked, 'table')} across {tally(len(paths), 'file')}, all lined up.")
    sys.exit(0)

print(f"FAIL — {len(ragged)} of {tally(checked, 'table')} ragged in a plain text editor.")
print()
for location in ragged:
    print(f"  {location}")
print()
print("Run `bash bin/tables.sh --fix`.")
sys.exit(1)
PY
