#!/bin/bash
# The run model: where a run lives, what it is called, and what making one is allowed to touch.
#
# Run through `sh`, never `bash`. That is the shell hooks.json names, and running these with bash
# would certify syntax the shipped runner cannot use.
#
# Set RUNNER to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

runner="${RUNNER:-$here/bin/run.sh}"
tmp="${TMPDIR:-/tmp}/floor-model-$$"
home="$tmp/home"
mkdir -p "$tmp/bare"
trap 'rm -rf "$tmp"' EXIT

# Run the shipped CLI from a directory, with an explicit home and run variable.
floor_as() {
  dir=$1; home_dir=$2; run=$3; shift 3
  ( cd "$dir" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home_dir" FOUNDRY_RUN="$run" sh "$runner" "$@" 2>/dev/null )
}

# The common case: this suite's home, and no run variable — or a developer with one exported answers
# half these checks with their own run, and the suite passes for the wrong reason on their machine.
floor() { dir=$1; shift; floor_as "$dir" "$home" "" "$@"; }

# Run any of the above and report only its exit code.
code_of() { "$@" >/dev/null 2>&1; printf '%s' "$?"; }

# Make a git repository on a named branch, or say it could not be done.
make_repo() {
  mkdir -p "$1" || return 1
  git init -q "$1" >/dev/null 2>&1 || return 1
  [ -d "$1/.git" ] || return 1
  git -C "$1" symbolic-ref HEAD "refs/heads/$2" >/dev/null 2>&1
}

echo "model"

# --- the home ---

is "home follows FOUNDRY_HOME" "$(floor "$tmp/bare" home)" "$home"

# The documented default, checked without touching the real one.
fake_home="$tmp/fallback"
mkdir -p "$fake_home"
is "home falls back to \$HOME/.foundry" \
   "$( cd "$tmp/bare" && HOME="$fake_home" FOUNDRY_HOME= FOUNDRY_RUN= sh "$runner" home 2>/dev/null )" \
   "$fake_home/.foundry"

# --- making a run ---

first=$(floor "$tmp/bare" new "Test Item")

has    "a run lands under the Foundry home"  "$first" "$home/runs/"
exists "memory is there"                     "$first/memory"
exists "the planning scratch is there"       "$first/planning"
exists "unit 01 is there from the first run" "$first/units/01/memory"

# Reads the file, so it stands in for "the item exists" too.
has "the item holds the title" "$(cat "$first/item.md" 2>/dev/null)" "Test Item"

# A contract holding an absolute path cannot leave the machine that wrote it.
lacks "the item carries no machine-local path" "$(cat "$first/item.md" 2>/dev/null)" "$home"

# --- the id ---

id=$(basename "$first")

has "the id starts with today"   "$id" "$(date +%Y-%m-%d)-"
has "the id carries the slug"    "$id" "-test-item-"

matches "the id ends in a short id" "$id" '-[0-9a-f]{4}$'

# Two checks, not one. "The ids differ" passes without the free-slot loop ever running; naming the
# slot does not, and `-0001` implies the first was `-0000`.
second=$(floor "$tmp/bare" new "Test Item")

differs "two runs from one title do not collide" "$first" "$second"
has     "the second run takes the next slot"     "$(basename "$second")" "-0001"

is "a title of pure punctuation still names a run" \
   "$(basename "$(floor "$tmp/bare" new '!!!')" | sed 's/-[0-9a-f]*$//')" \
   "$(date +%Y-%m-%d)-run"

# --- finding a run ---

is "no run, no answer" "$(floor "$tmp/bare" path)" ""
is "no run exits 1"    "$(code_of floor "$tmp/bare" path)" "1"

if make_repo "$tmp/repo" main; then
  made=$(floor "$tmp/repo" new "In A Repo")

  # Every call above starts a new shell, so finding it again is the fresh-shell gate from #67.
  is "the run is found again from a fresh shell" "$(floor "$tmp/repo" path)" "$made"

  # Inside the git directory is the same statement as "not in the worktree", so it is made once.
  exists "the pointer sits inside the git directory" "$tmp/repo/.git/foundry-run"

  is "the pointer holds the id and nothing else" \
     "$(cat "$tmp/repo/.git/foundry-run" 2>/dev/null)" "$(basename "$made")"

  # And the other half of the pointer's contract: making a run changes nothing in any repository.
  is "making a run leaves the worktree clean" \
     "$(git -C "$tmp/repo" status --porcelain 2>/dev/null)" ""
  is "making a run adds no commit" \
     "$(git -C "$tmp/repo" rev-list --count --all 2>/dev/null)" "0"
else
  skip "the pointer — git could not make a repo here"
fi

if make_repo "$tmp/repo-a" shared && make_repo "$tmp/repo-b" shared; then
  run_a=$(floor "$tmp/repo-a" new "Same Name")
  run_b=$(floor "$tmp/repo-b" new "Same Name")

  differs "two checkouts on one branch name get different runs" "$run_a" "$run_b"

  is "checkout A still finds its own" "$(floor "$tmp/repo-a" path)" "$run_a"
  is "checkout B still finds its own" "$(floor "$tmp/repo-b" path)" "$run_b"
else
  skip "two checkouts on one branch name — git could not make the repos"
fi

# --- what outranks what ---

is "FOUNDRY_RUN outranks the pointer" \
   "$(floor_as "$tmp/repo" "$home" "$first" path)" "$first"

# kernel checks `-d` before it moves memory. floor must agree, or it calls a run active that kernel
# has already fallen back from.
is "a variable pointing at nothing falls through to the pointer" \
   "$(floor_as "$tmp/repo" "$home" "$tmp/never" path)" "$(floor "$tmp/repo" path)"

is "and with no pointer either, it is no run" \
   "$(floor_as "$tmp/bare" "$home" "$tmp/never" path)" ""

# A stale pointer is not a crash. The run it names was deleted; the answer is absence.
if [ -d "$tmp/repo/.git" ]; then
  printf 'no-such-run\n' > "$tmp/repo/.git/foundry-run"
  is "a pointer at a deleted run reads as no run" "$(floor "$tmp/repo" path)" ""
  is "and it exits 1"                             "$(code_of floor "$tmp/repo" path)" "1"
fi

# --- a home that cannot be written ---
#
# A path printed with exit 0 for a directory that was never created leaves every caller downstream
# believing it has a run.

if : > "$tmp/notadir" 2>/dev/null; then
  is "a home that cannot hold a run prints no path" \
     "$(floor_as "$tmp/bare" "$tmp/notadir" "" new "No Room")" ""
  is "and it exits 3" \
     "$(code_of floor_as "$tmp/bare" "$tmp/notadir" "" new "No Room")" "3"
else
  skip "an unwritable home — could not make a file to stand in for one"
fi

# --- the bootstrap target ---
#
# Zero or one. A run started outside a repository is not a broken run.

set_origin() { git -C "$1" remote add origin "$2" >/dev/null 2>&1; }

if make_repo "$tmp/boot" main && set_origin "$tmp/boot" 'https://tok3n:x@github.com/acme/backend.git'; then
  booted=$(floor "$tmp/boot" new "With Origin")

  is "the bootstrap target names the repo and the base ref" \
     "$(cat "$booted/bootstrap" 2>/dev/null)" "https://github.com/acme/backend.git main"

  lacks "and the credential never reaches disk" "$(cat "$booted/bootstrap" 2>/dev/null)" "tok3n"
  is    "bootstrap prints it back" "$(floor "$tmp/boot" bootstrap)" "https://github.com/acme/backend.git main"

  # A password may contain an `@`. Stopping at the first one left the tail of it on disk.
  lacks "no path under the run holds a credential" \
        "$(grep -rh . "$booted/bootstrap" "$booted/units" 2>/dev/null)" "tok3n"
fi

if make_repo "$tmp/atpass" main && set_origin "$tmp/atpass" 'https://u:p@ss@github.com/acme/x.git'; then
  atp=$(floor "$tmp/atpass" new "At In Password")
  is "a password holding an @ is stripped whole" \
     "$(cat "$atp/bootstrap" 2>/dev/null)" "https://github.com/acme/x.git main"
else
  skip "the bootstrap target — git could not make a repo here"
fi

# 0..1, so absence is an answer and not a failure.
outside=$(floor "$tmp/bare" new "No Origin")
absent "a run started outside a repo records no bootstrap target" "$outside/bootstrap"
is     "and asking for it exits 1" "$(code_of floor "$tmp/bare" bootstrap)" "1"

if make_repo "$tmp/noremote" main; then
  none=$(floor "$tmp/noremote" new "No Remote")
  absent "a repo with no origin records none" "$none/bootstrap"
fi

# A path is exactly what a target may not hold, so a path-shaped remote yields nothing.
if make_repo "$tmp/pathremote" main && set_origin "$tmp/pathremote" "$tmp/some/local/clone"; then
  pathy=$(floor "$tmp/pathremote" new "Path Remote")
  absent "a remote that is a local path records none" "$pathy/bootstrap"
fi

# --- unit targets ---
#
# Named through FOUNDRY_RUN rather than a pointer: `$tmp/bare` has no git, so there is nowhere for a
# pointer to live. That is #67's behaviour, not a fault here.

fresh=$(floor "$tmp/bare" new "Targets")
in_run() { floor_as "$tmp/bare" "$home" "$fresh" "$@"; }

is "a fresh unit lists nothing" "$(in_run targets)" ""

in_run targets add 'https://github.com/acme/api.git'   main    >/dev/null
in_run targets add 'git@github.com:acme/web.git'       develop >/dev/null
in_run targets add 'https://u:p@github.com/acme/m.git' v2      >/dev/null

is "three targets list back in order" "$(in_run targets)" \
"https://github.com/acme/api.git main
git@github.com:acme/web.git develop
https://github.com/acme/m.git v2"

exists "they live under the unit" "$fresh/units/01/targets"
absent "and not at the run root"  "$fresh/targets"

is "targets add refuses a local path" \
   "$(code_of in_run targets add "$tmp/some/clone" main)" "4"
is "and writes nothing when it refuses" \
   "$(in_run targets | grep -c "$tmp" || true)" "0"

# `ssh://git@host` carries a login. Dropping it breaks the clone; keeping a password does not.
in_run targets add 'ssh://git@github.com/acme/ssh.git' main >/dev/null
has "an ssh login survives" "$(in_run targets)" "ssh://git@github.com/acme/ssh.git main"

in_run targets add 'ssh://u:secret@github.com/acme/pw.git' main >/dev/null
lacks "but an ssh password does not" "$(in_run targets)" "secret"

# A `/` before the colon is a path, not a host. Without that rule a dotted directory reads as
# scp-style and a local path gets written down.
is "a path with a dotted segment is not scp-style" \
   "$(code_of in_run targets add '/srv/git/v1.2:mirror' main)" "4"

is "FILE:// is refused whatever its case" \
   "$(code_of in_run targets add 'FILE:///srv/git/x.git' main)" "4"

# The ref is the other half of the line, and it was going in unchecked.
is "a ref that is a path is refused" \
   "$(code_of in_run targets add 'https://github.com/acme/a.git' '/home/me/wip')" "4"
is "a ref holding a newline cannot write a second target" \
   "$(code_of in_run targets add 'https://github.com/acme/a.git' 'main
evil')" "4"

is "targets add needs both a repo and a ref" \
   "$(code_of in_run targets add 'https://github.com/acme/api.git')" "2"

before_comment=$(in_run targets | grep -c .)
printf '# a comment\n\n' >> "$fresh/units/01/targets"
is "comments and blank lines are not targets" "$(in_run targets | grep -c .)" "$before_comment"

# The two levels stay apart. Nothing moves an advisory target into a unit — the allowlist that would
# is the next issue.
printf 'targets: https://github.com/attacker/evil.git main\n' >> "$fresh/item.md"
lacks "an advisory target in item.md does not reach the unit" \
      "$(in_run targets)" "attacker/evil"

# No stored line anywhere may hold a machine-local path. Swept over the run that actually has a
# bootstrap file too — naming `$fresh/bootstrap` alone checked a file that cannot exist.
is "no stored line under any run holds a local path" \
   "$(grep -rl "$tmp" "$fresh/units" "${booted:-$fresh}" 2>/dev/null | grep -c . || true)" "0"

# --- asking for the wrong thing ---

is "new with no title exits 2"  "$(code_of floor "$tmp/bare" new)" "2"
is "an unknown command exits 2" "$(code_of floor "$tmp/bare" fly)" "2"

summary "model"
