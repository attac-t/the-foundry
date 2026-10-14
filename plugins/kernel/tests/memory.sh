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

inside_a_repo() {
  git init -q "$tmp/repo" >/dev/null 2>&1
  [ -d "$tmp/repo/.git" ] || { skip "branch resolution — git could not make a repo here"; return; }

  git -C "$tmp/repo" symbolic-ref HEAD refs/heads/feat/api-v2 >/dev/null 2>&1
  is "a repo appends the branch" "$(resolve "$tmp/repo" "$tmp/mem")" "$tmp/mem/feat/api-v2"

  git -C "$tmp/repo" symbolic-ref HEAD 'refs/heads/wip@thing' >/dev/null 2>&1
  is "a branch is sanitised into a path" "$(resolve "$tmp/repo" "$tmp/mem")" "$tmp/mem/wip-thing"
}
inside_a_repo

# --- one line, always ---
#
# The regression guard. resolve-memory.sh's header names the bashism. It shipped, the answer came
# back two lines long with a path to git on top, and every hook downstream believed it.

is "the answer outside a repo is one line" "$(lines "$(resolve "$tmp/bare" "$tmp/mem")")" "1"

the_answer_inside_a_repo() {
  [ -d "$tmp/repo/.git" ] || { skip "the answer inside a repo — git could not make a repo here"; return; }
  is "the answer inside a repo is one line" "$(lines "$(resolve "$tmp/repo" "$tmp/mem")")" "1"
}
the_answer_inside_a_repo

lacks "the answer never carries a path to git" "$(resolve "$tmp/bare" "$tmp/mem")" "bin/git"

# --- an active run ---

mkdir -p "$tmp/run"

is "an active run outranks the base" \
   "$(resolve_in_run "$tmp/bare" "$tmp/run" "$tmp/mem")" "$tmp/run/memory"

an_active_run_outranks_the_branch() {
  [ -d "$tmp/repo/.git" ] || { skip "an active run outranks the branch — git could not make a repo here"; return; }
  is "an active run outranks the branch" \
     "$(resolve_in_run "$tmp/repo" "$tmp/run" "$tmp/mem")" "$tmp/run/memory"
}
an_active_run_outranks_the_branch

is "a run that is gone falls back to the branch" \
   "$(resolve_in_run "$tmp/bare" "$tmp/gone" "$tmp/mem")" "$tmp/mem"

is "an empty run variable changes nothing" \
   "$(resolve_in_run "$tmp/bare" "" "$tmp/mem")" "$tmp/mem"

is "the answer inside a run is one line" \
   "$(lines "$(resolve_in_run "$tmp/bare" "$tmp/run" "$tmp/mem")")" "1"

# --- the session's folder named ---
#
# The desktop app runs every hook in the main checkout, and only the payload names the worktree.
# So the folder named is where git is asked, and the answer is a full path under it. #1137.

# Resolve for a named folder, from a given working directory, with a run if one is given.
resolve_for() { (cd "$1" && FOUNDRY_RUN="${4:-}" CLAUDE_MEMORY_DIR="$3" sh "$lib/resolve-memory.sh" "$2" 2>/dev/null); }

a_session_named() {
  a_checkout_and_its_worktree "$tmp/main" "$tmp/wt" \
    || { skip "a session named — git could not make a worktree here"; return; }
  mkdir -p "$tmp/wt/src"

  is "named a worktree from the main checkout, it answers the repository's store for that branch" \
     "$(resolve_for "$tmp/main" "$tmp/wt" .claude/memory)" "$tmp/main/.claude/memory/feat/wt"
  is "an active run still outranks a folder named" \
     "$(resolve_for "$tmp/main" "$tmp/wt" .claude/memory "$tmp/run")" "$tmp/run/memory"
  is "an absolute base stays as given" \
     "$(resolve_for "$tmp/main" "$tmp/wt" "$tmp/mem")" "$tmp/mem/feat/wt"
  is "and a drive-letter base too" \
     "$(resolve_for "$tmp/main" "$tmp/wt" 'C:\mem')" 'C:\mem/feat/wt'
  is "and a UNC base, which leaves whole wherever echo reads escapes" \
     "$(resolve_for "$tmp/main" "$tmp/wt" '\\srv\mem')" '\\srv\mem/feat/wt'
  is "and a rooted one" \
     "$(resolve_for "$tmp/main" "$tmp/wt" '\mem')" '\mem/feat/wt'
  is "a folder that is gone answers the base joined to it" \
     "$(resolve_for "$tmp/main" "$tmp/gone" .claude/memory)" "$tmp/gone/.claude/memory"
  is "a subdirectory named answers the same store, never a folder under itself" \
     "$(resolve_for "$tmp/main" "$tmp/wt/src" .claude/memory)" "$tmp/main/.claude/memory/feat/wt"

  # Where a hook already runs in the folder the session works in, as the CLI's do, it is one store.
  is "named the folder it runs in, a relative base answers the store too" \
     "$(resolve_for "$tmp/wt" "$tmp/wt" .claude/memory)" "$tmp/main/.claude/memory/feat/wt"
  is "and an absolute base answers exactly what it does today" \
     "$(resolve_for "$tmp/wt" "$tmp/wt" "$tmp/mem")" "$(resolve "$tmp/wt" "$tmp/mem")"
}
a_session_named

# --- one store per repository, #1161 ---

# Memory a worktree already holds is read where it is, until the store has a folder for the branch.
memory_already_in_a_worktree() {
  a_checkout_and_its_worktree "$tmp/kept" "$tmp/kept-wt" \
    || { skip "memory in a worktree — git could not make a worktree here"; return; }
  mkdir -p "$tmp/kept/src" "$tmp/kept-wt/.claude/memory/feat/wt"

  is "the main checkout and its subdirectory name one store" \
     "$(resolve_for "$tmp/kept/src" "$tmp/kept/src" .claude/memory)" "$tmp/kept/.claude/memory/main"
  is "a worktree's own memory is read where it is, while the store has none for its branch" \
     "$(resolve_for "$tmp/kept-wt" "$tmp/kept-wt" .claude/memory)" "$tmp/kept-wt/.claude/memory/feat/wt"

  mkdir -p "$tmp/kept/.claude/memory/feat/wt"
  is "and once the store has the branch, the store wins" \
     "$(resolve_for "$tmp/kept-wt" "$tmp/kept-wt" .claude/memory)" "$tmp/kept/.claude/memory/feat/wt"
}
memory_already_in_a_worktree

# The README's command, run as a person runs it, so a removed worktree keeps nothing the store needs.
a_person_moves_it() {
  a_checkout_and_its_worktree "$tmp/moved" "$tmp/moved-wt" \
    && mkdir -p "$tmp/moved-wt/.claude/memory/feat/wt" \
    && printf 'Ship it\n' > "$tmp/moved-wt/.claude/memory/feat/wt/working.md" \
    || { skip "a person's move — git could not make a worktree here"; return; }

  ( cd "$tmp/moved-wt" \
    && b=$(git branch --show-current) && m=$(git rev-parse --path-format=absolute --git-common-dir) && m=${m%/.git} \
    && mkdir -p "$(dirname "$m/.claude/memory/$b")" && mv ".claude/memory/$b" "$m/.claude/memory/$b" )
  git -C "$tmp/moved" worktree remove --force "$tmp/moved-wt" >/dev/null 2>&1

  is "a worktree moved by the README's command and removed keeps its memory in the store" \
     "$(cat "$tmp/moved/.claude/memory/feat/wt/working.md" 2>/dev/null)" "Ship it"
}
a_person_moves_it

# Two bare repositories side by side, each with a worktree on `main`.
two_bare_repositories() {
  for r in one two; do
    git init -q --bare "$tmp/bares/$r.git" \
      && git clone -q "$tmp/bares/$r.git" "$tmp/seed-$r" >/dev/null 2>&1 \
      && git -C "$tmp/seed-$r" -c user.email=a@b.c -c user.name=a commit -q --allow-empty -m x \
      && git -C "$tmp/seed-$r" push -q origin HEAD:main >/dev/null 2>&1 \
      && git -C "$tmp/bares/$r.git" worktree add "$tmp/bare-wt-$r" main >/dev/null 2>&1 || return 1
  done
}

# Two submodules of one project, each on a branch.
two_submodules() {
  for r in one two; do
    git init -q "$tmp/sub-src-$r" \
      && git -C "$tmp/sub-src-$r" -c user.email=a@b.c -c user.name=a commit -q --allow-empty -m x || return 1
  done
  git init -q "$tmp/super" || return 1
  for r in one two; do
    git -C "$tmp/super" -c protocol.file.allow=always submodule add "$tmp/sub-src-$r" "$r" >/dev/null 2>&1 \
      && git -C "$tmp/super/$r" checkout -q -B main || return 1
  done
}

two_repositories_never_share_one() {
  if two_bare_repositories; then
    is "two bare repositories' worktrees each name their own store" \
       "$(resolve_for "$tmp/bare-wt-one" "$tmp/bare-wt-one" .claude/memory) $(resolve_for "$tmp/bare-wt-two" "$tmp/bare-wt-two" .claude/memory)" \
       "$tmp/bare-wt-one/.claude/memory/main $tmp/bare-wt-two/.claude/memory/main"
  else
    skip "two bare repositories — git could not make them here"
  fi

  two_submodules || { skip "two submodules — git could not make them here"; return; }
  is "two submodules of one project each name their own store" \
     "$(resolve_for "$tmp/super/one" "$tmp/super/one" .claude/memory) $(resolve_for "$tmp/super/two" "$tmp/super/two" .claude/memory)" \
     "$tmp/super/one/.claude/memory/main $tmp/super/two/.claude/memory/main"
}
two_repositories_never_share_one

# --- the objective ---

is "an objective is read"          "$(objective '**Objective**: Ship the harness')" "Ship the harness"
is "leading space is trimmed"      "$(objective '**Objective**:    Ship it')"       "Ship it"
is "a placeholder is not a goal"   "$(objective '**Objective**: [TBD]')"            ""
is "a file with no objective"      "$(objective '# Notes')"                         ""
is "a missing file"                "$(sh "$lib/extract-objective.sh" "$tmp/gone.md" 2>/dev/null)" ""

summary "memory"
