#!/bin/bash
# The two lib scripts every memory hook leans on.
#
# Run through `sh`, never `bash`. That is the shell hooks.json names, and running these with bash
# would certify syntax the shipped hooks cannot use — which is exactly how `&>` and `[[ =~ ]]`
# survived in here for eight releases.
#
# Set LIB to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

lib="${LIB:-$here/hooks/lib}"
tmp="${TMPDIR:-/tmp}/kernel-memory-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# Resolve the memory directory from a given working directory.
#
# `FOUNDRY_RUN=`, or a developer with one exported has their own run answer every check below and
# the suite certifies nothing about the branch path it exists to test.
resolve() { (cd "$1" && FOUNDRY_RUN= CLAUDE_MEMORY_DIR="$2" sh "$lib/resolve-memory.sh" 2>/dev/null); }

# Resolve with an active run, from a given working directory.
resolve_in_run() { (cd "$1" && FOUNDRY_RUN="$2" CLAUDE_MEMORY_DIR="$3" sh "$lib/resolve-memory.sh" 2>/dev/null); }

# Count the non-empty lines in a value.
lines() { printf '%s\n' "$1" | grep -c .; }

# Read the objective out of a file holding the given text.
objective() { printf '%s\n' "$1" > "$tmp/working.md"; sh "$lib/extract-objective.sh" "$tmp/working.md" 2>/dev/null; }

echo "memory"

# --- outside a repo ---

mkdir -p "$tmp/bare"
is "no repo falls back to the base" "$(resolve "$tmp/bare" "$tmp/mem")" "$tmp/mem"

# --- inside a repo ---

git init -q "$tmp/repo" >/dev/null 2>&1
if [ -d "$tmp/repo/.git" ]; then
  git -C "$tmp/repo" symbolic-ref HEAD refs/heads/feat/api-v2 >/dev/null 2>&1
  is "a repo appends the branch" "$(resolve "$tmp/repo" "$tmp/mem")" "$tmp/mem/feat/api-v2"

  git -C "$tmp/repo" symbolic-ref HEAD 'refs/heads/wip@thing' >/dev/null 2>&1
  is "a branch is sanitised into a path" "$(resolve "$tmp/repo" "$tmp/mem")" "$tmp/mem/wip-thing"
else
  skip "branch resolution — git could not make a repo here"
fi

# --- one line, always ---
#
# The regression guard. `&>` is bash's; dash reads it as "run in the background, then redirect", so
# the guard cannot fail and git's own output reaches stdout ahead of the path. The answer came back
# two lines long with a path to git on top, and every hook downstream believed it.

is "the answer outside a repo is one line" "$(lines "$(resolve "$tmp/bare" "$tmp/mem")")" "1"
[ -d "$tmp/repo/.git" ] \
  && is "the answer inside a repo is one line" "$(lines "$(resolve "$tmp/repo" "$tmp/mem")")" "1"

lacks "the answer never carries a path to git" "$(resolve "$tmp/bare" "$tmp/mem")" "bin/git"

# --- an active run ---

mkdir -p "$tmp/run"

is "an active run outranks the base" \
   "$(resolve_in_run "$tmp/bare" "$tmp/run" "$tmp/mem")" "$tmp/run/memory"

[ -d "$tmp/repo/.git" ] \
  && is "an active run outranks the branch" \
       "$(resolve_in_run "$tmp/repo" "$tmp/run" "$tmp/mem")" "$tmp/run/memory"

is "a run that is gone falls back to the branch" \
   "$(resolve_in_run "$tmp/bare" "$tmp/gone" "$tmp/mem")" "$tmp/mem"

is "an empty run variable changes nothing" \
   "$(resolve_in_run "$tmp/bare" "" "$tmp/mem")" "$tmp/mem"

is "the answer inside a run is one line" \
   "$(lines "$(resolve_in_run "$tmp/bare" "$tmp/run" "$tmp/mem")")" "1"

# --- the objective ---

is "an objective is read"          "$(objective '**Objective**: Ship the harness')" "Ship the harness"
is "leading space is trimmed"      "$(objective '**Objective**:    Ship it')"       "Ship it"
is "a placeholder is not a goal"   "$(objective '**Objective**: [TBD]')"            ""
is "a file with no objective"      "$(objective '# Notes')"                         ""
is "a missing file"                "$(sh "$lib/extract-objective.sh" "$tmp/gone.md" 2>/dev/null)" ""

summary "memory"
