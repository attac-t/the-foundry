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

# Like `floor`, but keeps what the CLI said while refusing. Every refusal explains itself on stderr,
# and `floor_as` drops it — so an outer `2>&1` at the call site captures nothing and the check reads
# as if the runner said nothing at all.
floor_says() {
  dir=$1; shift
  ( cd "$dir" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home" FOUNDRY_RUN="" sh "$runner" "$@" 2>&1 )
}

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

the_pointer() {
  make_repo "$tmp/repo" main || { skip "the pointer — git could not make a repo here"; return; }

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
}
the_pointer

two_checkouts_on_one_branch_name() {
  make_repo "$tmp/repo-a" shared && make_repo "$tmp/repo-b" shared \
    || { skip "two checkouts on one branch name — git could not make the repos"; return; }

  run_a=$(floor "$tmp/repo-a" new "Same Name")
  run_b=$(floor "$tmp/repo-b" new "Same Name")

  differs "two checkouts on one branch name get different runs" "$run_a" "$run_b"

  is "checkout A still finds its own" "$(floor "$tmp/repo-a" path)" "$run_a"
  is "checkout B still finds its own" "$(floor "$tmp/repo-b" path)" "$run_b"
}
two_checkouts_on_one_branch_name

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
a_pointer_at_a_deleted_run() {
  [ -d "$tmp/repo/.git" ] || { skip "a pointer at a deleted run — git could not make a repo here"; return; }

  printf 'no-such-run\n' > "$tmp/repo/.git/foundry-run"
  is "a pointer at a deleted run reads as no run" "$(floor "$tmp/repo" path)" ""
  is "and it exits 1"                             "$(code_of floor "$tmp/repo" path)" "1"
}
a_pointer_at_a_deleted_run

# A path printed with exit 0 for a directory that was never created leaves every caller downstream
# believing it has a run.

a_home_that_cannot_be_written() {
  : > "$tmp/notadir" 2>/dev/null \
    || { skip "an unwritable home — could not make a file to stand in for one"; return; }

  is "a home that cannot hold a run prints no path" \
     "$(floor_as "$tmp/bare" "$tmp/notadir" "" new "No Room")" ""
  is "and it exits 3" \
     "$(code_of floor_as "$tmp/bare" "$tmp/notadir" "" new "No Room")" "3"
}
a_home_that_cannot_be_written

# Zero or one. A run started outside a repository is not a broken run.

set_origin() { git -C "$1" remote add origin "$2" >/dev/null 2>&1; }

# It had no `else` at all, so a git failure here skipped four checks in silence — which lib.sh calls
# the way a suite ends up certifying a platform it never tested.
the_bootstrap_target() {
  make_repo "$tmp/boot" main && set_origin "$tmp/boot" 'https://tok3n:x@github.com/acme/backend.git' \
    || { skip "the bootstrap target — git could not make a repo here"; return; }

  booted=$(floor "$tmp/boot" new "With Origin")

  is "the bootstrap target names the repo and the base ref" \
     "$(cat "$booted/bootstrap" 2>/dev/null)" "https://github.com/acme/backend.git main"

  lacks "and the credential never reaches disk" "$(cat "$booted/bootstrap" 2>/dev/null)" "tok3n"
  is    "bootstrap prints it back" "$(floor "$tmp/boot" bootstrap)" "https://github.com/acme/backend.git main"

  # A password may contain an `@`. Stopping at the first one left the tail of it on disk.
  lacks "no path under the run holds a credential" \
        "$(grep -rh . "$booted/bootstrap" "$booted/units" 2>/dev/null)" "tok3n"
}
the_bootstrap_target

a_password_holding_an_at() {
  make_repo "$tmp/atpass" main && set_origin "$tmp/atpass" 'https://u:p@ss@github.com/acme/x.git' \
    || { skip "a password holding an @ — git could not make a repo here"; return; }

  atp=$(floor "$tmp/atpass" new "At In Password")
  is "a password holding an @ is stripped whole" \
     "$(cat "$atp/bootstrap" 2>/dev/null)" "https://github.com/acme/x.git main"
}
a_password_holding_an_at

# 0..1, so absence is an answer and not a failure.
outside=$(floor "$tmp/bare" new "No Origin")
absent "a run started outside a repo records no bootstrap target" "$outside/bootstrap"
is     "and asking for it exits 1" "$(code_of floor "$tmp/bare" bootstrap)" "1"

a_repo_with_no_origin() {
  make_repo "$tmp/noremote" main || { skip "a repo with no origin — git could not make a repo here"; return; }

  none=$(floor "$tmp/noremote" new "No Remote")
  absent "a repo with no origin records none" "$none/bootstrap"
}
a_repo_with_no_origin

# A path is exactly what a target may not hold, so a path-shaped remote yields nothing.
a_remote_that_is_a_local_path() {
  make_repo "$tmp/pathremote" main && set_origin "$tmp/pathremote" "$tmp/some/local/clone" \
    || { skip "a remote that is a local path — git could not make a repo here"; return; }

  pathy=$(floor "$tmp/pathremote" new "Path Remote")
  absent "a remote that is a local path records none" "$pathy/bootstrap"
}
a_remote_that_is_a_local_path

# --- unit targets ---
#
# Named through FOUNDRY_RUN rather than a pointer: `$tmp/bare` has no git, so there is nowhere for a
# pointer to live. That is #67's behaviour, not a fault here.

# The third entry point behind the same no-run guard. `path` and `bootstrap` each had a check; this
# one did not, so softening its guard alone would have gone unnoticed — the break that covers all
# three cannot tell you which of them holds.
is "targets with no run exits 1" "$(code_of floor "$tmp/bare" targets)" "1"

fresh=$(floor "$tmp/bare" new "Targets")
in_run() { floor_as "$tmp/bare" "$home" "$fresh" "$@"; }

# `$tmp/bare` has no git, so this run gets no bootstrap and its allowlist starts empty. The checks
# below are about identity and refs, so the ones that expect to succeed grant first. The ones that
# expect a refusal still refuse for their own reason: identity and ref are read before policy is.
allow_and_add() { in_run policy authorize "$1" >/dev/null && in_run targets add "$1" "$2" >/dev/null; }

is "a fresh unit lists nothing" "$(in_run targets)" ""

allow_and_add 'https://github.com/acme/api.git'   main
allow_and_add 'git@github.com:acme/web.git'       develop
allow_and_add 'https://u:p@github.com/acme/m.git' v2

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
allow_and_add 'ssh://git@github.com/acme/ssh.git' main
has "an ssh login survives" "$(in_run targets)" "ssh://git@github.com/acme/ssh.git main"

# Both halves, because `lacks` alone cannot tell a stripped password from a target never written.
allow_and_add 'ssh://u:secret@github.com/acme/pw.git' main
has   "but an ssh password does not" "$(in_run targets)" "ssh://u@github.com/acme/pw.git main"
lacks "and the password is nowhere"  "$(in_run targets)" "secret"

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

#
# The selection is read far more often than it is written, and only the write was guarded. Every
# charter clause is graded against every selected target, so a line put here by hand changes what
# the run answers for — and re-deriving the charter cannot see it, because the charter did not move.
#
# The file is restored after each check: these run against the same run as everything above.
#
selection=$fresh/units/01/targets
intact=$(cat "$selection")
listed_before=$(in_run targets)
restore_selection() { printf '%s\n' "$intact" > "$selection"; }

printf 'https://github.com/attacker/evil.git main\n' >> "$selection"
is "a target appended by hand is refused on read" \
   "$(code_of in_run targets)" "5"
is "and the same edit stops targets add" \
   "$(code_of in_run targets add 'https://github.com/acme/api.git' main)" "5"
restore_selection

is "the selection lists unchanged once the hand-added line is gone" \
   "$(in_run targets)" "$listed_before"

# A repo authorised for this run may be selected by hand: policy permits it, and selecting is the
# other act. Without this the check would be refusing the allowlist rather than reading it.
in_run policy authorize 'https://github.com/acme/later.git' >/dev/null
printf 'https://github.com/acme/later.git main\n' >> "$selection"
is "a hand-added line that policy already allows is not refused" \
   "$(code_of in_run targets)" "0"
restore_selection

# A line is a repo and a ref. One field is not a target, and neither is three.
printf 'https://github.com/acme/api.git\n' >> "$selection"
is "a line missing its ref is refused" "$(code_of in_run targets)" "5"
restore_selection

printf 'https://github.com/acme/api.git main extra\n' >> "$selection"
is "a line carrying a third field is refused" "$(code_of in_run targets)" "5"
restore_selection

# --- policy ---
#
# Policy is not a security boundary. A worker holding a shell as the same user can edit the grants
# directly. What it buys is that no accident widens authority: nothing grants but `policy authorize`.

policy_for() { printf '%s/policy/runs/%s/targets' "$home" "$(basename "$1")"; }

the_bootstrap_is_authorised_without_a_grant() {
  make_repo "$tmp/pol" main && set_origin "$tmp/pol" 'https://github.com/acme/boot.git' \
    || { skip "policy — git could not make a repo here"; return; }

  polrun=$(floor "$tmp/pol" new "Policy")

  is "the bootstrap lists as bootstrap, not as a grant" \
     "$(floor "$tmp/pol" policy)" "$(printf 'https://github.com/acme/boot.git\tbootstrap')"

  absent "and no grants file was written" "$(policy_for "$polrun")"

  is "the bootstrap can be added as a target" \
     "$(code_of floor "$tmp/pol" targets add 'https://github.com/acme/boot.git' main)" "0"
}
the_bootstrap_is_authorised_without_a_grant

#
# The advisory proof, by sequence rather than by absence.
#
# The weak form — name it in `item.md`, watch it never arrive — passes with no policy at all, because
# nothing reads advisory targets. Refused, then granted, then accepted is the only shape that fails
# if policy does nothing.
#
an_item_grants_nothing() {
  [ -n "${polrun:-}" ] || { skip "the advisory proof — no run with a bootstrap"; return; }

  printf 'targets: https://github.com/attacker/evil.git main\n' >> "$polrun/item.md"

  is "a repo named only in item.md is refused" \
     "$(code_of floor "$tmp/pol" targets add 'https://github.com/attacker/evil.git' main)" "5"

  lacks "and nothing about it reached the unit" "$(floor "$tmp/pol" targets)" "attacker/evil"

  floor "$tmp/pol" policy authorize 'https://github.com/attacker/evil.git' >/dev/null

  is "once authorised, the same call succeeds" \
     "$(code_of floor "$tmp/pol" targets add 'https://github.com/attacker/evil.git' main)" "0"

  has "and only then is it a target" "$(floor "$tmp/pol" targets)" "attacker/evil"
}
an_item_grants_nothing

a_refusal_writes_nothing() {
  [ -n "${polrun:-}" ] || { skip "the refusal proof — no run with a bootstrap"; return; }

  before=$(cat "$polrun/units/01/targets" 2>/dev/null)
  floor "$tmp/pol" targets add 'https://github.com/nobody/asked.git' main >/dev/null 2>&1

  is "a refused target leaves the unit file byte-identical" \
     "$(cat "$polrun/units/01/targets" 2>/dev/null)" "$before"
}
a_refusal_writes_nothing

#
# The discriminator. Without it the sequence above would still pass while authority widened itself.
#
targets_add_never_grants() {
  [ -n "${polrun:-}" ] || { skip "the self-authorisation proof — no run with a bootstrap"; return; }

  grants_before=$(cat "$(policy_for "$polrun")" 2>/dev/null)

  # Both paths. A refused add returns before the append, so only the second one — already granted
  # above, so it succeeds — reaches the line where a write to the grants could actually happen.
  floor "$tmp/pol" targets add 'https://github.com/sneaky/repo.git' main >/dev/null 2>&1
  floor "$tmp/pol" targets add 'https://github.com/attacker/evil.git' main >/dev/null 2>&1

  is "targets add cannot add to the allowlist" \
     "$(cat "$(policy_for "$polrun")" 2>/dev/null)" "$grants_before"
}
targets_add_never_grants

#
# The other half of the stored line.
#
# `grep -Fxq` reads a pattern holding a newline as a list of patterns and matches when any one line
# does, so one grant authorised a second repo and the append wrote both down. `..` is refused for a
# different reason: git resolves dot segments, so the line clones one repo and reads as another.
#
a_repo_argument_cannot_carry_a_second_line() {
  [ -n "${polrun:-}" ] || { skip "the newline proof — no run with a bootstrap"; return; }

  smuggle=$(printf 'https://github.com/acme/boot.git\nhttps://github.com/smuggled/in.git')

  is "a repo argument holding a newline is refused" \
     "$(code_of floor "$tmp/pol" targets add "$smuggle" main)" "4"
  lacks "and nothing was smuggled into the unit" "$(floor "$tmp/pol" targets)" "smuggled"

  is "policy authorize refuses one too" \
     "$(code_of floor "$tmp/pol" policy authorize "$smuggle")" "4"
  lacks "and grants nothing from it" "$(floor "$tmp/pol" policy)" "smuggled"

  is "a dot-dot segment is refused" \
     "$(code_of floor "$tmp/pol" targets add 'https://github.com/acme/../evil/x.git' main)" "4"
}
a_repo_argument_cannot_carry_a_second_line

#
# Grants outlive the run directory, and run ids are reclaimed. Until the slot chooser read both, a
# `rm -rf` handed the next run an allowlist nobody granted it.
#
a_reclaimed_slot_inherits_no_grants() {
  make_repo "$tmp/pol3" main && set_origin "$tmp/pol3" 'https://github.com/acme/three.git' \
    || { skip "slot reuse — git could not make a repo here"; return; }

  gone=$(floor "$tmp/pol3" new "Reuse")
  floor "$tmp/pol3" policy authorize 'https://github.com/acme/inherited.git' >/dev/null
  rm -rf "$gone"

  floor "$tmp/pol3" new "Reuse" >/dev/null

  has   "a run made after a deletion still has its own bootstrap" \
        "$(floor "$tmp/pol3" policy)" "acme/three.git"
  lacks "but inherits no grant from the run it replaced" \
        "$(floor "$tmp/pol3" policy)" "inherited"
}
a_reclaimed_slot_inherits_no_grants

a_grant_is_scoped_to_one_run() {
  make_repo "$tmp/pol2" main && set_origin "$tmp/pol2" 'https://github.com/acme/other.git' \
    || { skip "grant scope — git could not make a second repo"; return; }

  floor "$tmp/pol2" new "Other" >/dev/null

  is "a grant for one run does not authorise another" \
     "$(code_of floor "$tmp/pol2" targets add 'https://github.com/attacker/evil.git' main)" "5"
}
a_grant_is_scoped_to_one_run

a_run_with_no_bootstrap_allows_nothing() {
  norun=$(floor "$tmp/bare" new "No Boot")

  # Empty output is what a `policy` that printed nothing at all also looks like, so the run that does
  # have one answers in the same breath.
  is "with no bootstrap the allowlist is empty" \
     "$(floor_as "$tmp/bare" "$home" "$norun" policy)" ""
  differs "while a run that has one says so" \
     "$(floor "$tmp/pol" policy)" ""

  is "and every target is refused" \
     "$(code_of floor_as "$tmp/bare" "$home" "$norun" targets add 'https://github.com/any/thing.git' main)" "5"
}
a_run_with_no_bootstrap_allows_nothing

#
# Policy state outlives the run that wrote it and gets read by eye. A password or a machine-local
# path in there is a leak whatever the allowlist then decides, so neither may be stored at all.
#
policy_stores_only_portable_identities() {
  [ -n "${polrun:-}" ] || { skip "policy storage — no run with a bootstrap"; return; }

  floor "$tmp/pol" policy authorize 'https://u:hunter2@github.com/acme/creds.git' >/dev/null

  has   "a grant stores the stripped identity" \
        "$(cat "$(policy_for "$polrun")")" "https://github.com/acme/creds.git"
  lacks "and never the password" "$(cat "$(policy_for "$polrun")")" "hunter2"

  is "policy authorize refuses a local path" \
     "$(code_of floor "$tmp/pol" policy authorize "$tmp/some/clone")" "4"
  lacks "and stores nothing for it" "$(cat "$(policy_for "$polrun")")" "$tmp"
}
policy_stores_only_portable_identities

# The bootstrap is an effective grant, not a stored one. Copying it would outlive the run's own
# `bootstrap` file and make the two disagree about what a run may reach.
authorizing_the_bootstrap_copies_nothing() {
  [ -n "${polrun:-}" ] || { skip "the bootstrap copy proof — no run with a bootstrap"; return; }

  # Byte-identical, not merely `lacks`: an empty file lacks everything.
  before=$(cat "$(policy_for "$polrun")" 2>/dev/null)
  floor "$tmp/pol" policy authorize 'https://github.com/acme/boot.git' >/dev/null

  is "an explicit grant for the bootstrap writes nothing" \
     "$(cat "$(policy_for "$polrun")" 2>/dev/null)" "$before"
}
authorizing_the_bootstrap_copies_nothing

# A bootstrap file exists but names nothing. Two readers, one file — they have to agree it is empty,
# or `policy` lists an entry that authorises nothing and reads as though it does.
a_nameless_bootstrap_is_no_bootstrap() {
  make_repo "$tmp/pol4" main && set_origin "$tmp/pol4" 'https://github.com/acme/four.git' \
    || { skip "empty bootstrap — git could not make a repo here"; return; }

  blank=$(floor "$tmp/pol4" new "Blank")
  : > "$blank/bootstrap"

  is "a bootstrap naming nothing lists nothing" "$(floor "$tmp/pol4" policy)" ""
  is "and authorises nothing" \
     "$(code_of floor "$tmp/pol4" targets add 'https://github.com/acme/four.git' main)" "5"
}
a_nameless_bootstrap_is_no_bootstrap

# Policy and targets share one normalisation, so two spellings are two identities. Recorded as the
# behaviour it is, not asserted as the behaviour anyone wants.
two_spellings_are_two_identities() {
  [ -n "${polrun:-}" ] || { skip "identity spelling — no run with a bootstrap"; return; }

  is "an ssh spelling of a granted https repo is still refused" \
     "$(code_of floor "$tmp/pol" targets add 'git@github.com:attacker/evil.git' main)" "5"
}
two_spellings_are_two_identities

# Last, so it sweeps policy state too. Nothing floor writes anywhere under the home may hold a
# machine-local path — grants outlive the run that made them and travel with the home.
is "nothing floor stored holds a local path" \
   "$(grep -rl "$tmp" "$home" 2>/dev/null | grep -c . || true)" "0"

# --- charter ---
#
# The charter lives in the run, so nothing can inherit one. Grants live beside the runs and could,
# which is why `slot_is_free` reads both — see the policy section.

charter_of() { printf '%s/charter' "$1"; }

# `make_repo` leaves no commit, and a pin is a blob at a ref. Nothing to pin without one.
commit_file() {
  printf '%s' "$3" > "$1/$2" || return 1
  git -C "$1" add "$2" >/dev/null 2>&1 || return 1
  git -C "$1" -c user.email=a@b.c -c user.name=a commit -qm x >/dev/null 2>&1
}

a_charter_derives_from_the_repository_it_is_run_in() {
  make_repo "$tmp/ch" develop && set_origin "$tmp/ch" 'https://github.com/acme/ch.git' \
    && commit_file "$tmp/ch" Makefile 'test:
	echo ok
' || { skip "charter — git could not make a repo here"; return; }

  chrun=$(floor "$tmp/ch" new "Charter")
  floor "$tmp/ch" charter derive >/dev/null 2>&1

  exists "the charter is a file in the run" "$(charter_of "$chrun")"

  # `absent "$home/charter"` passed against the one mutation aimed at this, which writes
  # `charter-<id>`. Anything charter-shaped beside the runs is what must not exist.
  is "and nothing charter-shaped sits beside the runs" \
     "$(find "$home" -maxdepth 1 -name 'charter*' 2>/dev/null | grep -c .)" "0"

  held=$(cat "$(charter_of "$chrun")" 2>/dev/null)
  has "a detected gate becomes a clause"    "$held" "clause $(clause_of tests) Gate tests"
  has "with a pin at its own target's ref"  "$held" "pin $(clause_of tests) https://github.com/acme/ch.git develop Makefile"
  has "and the command it resolved to"      "$held" "gate $(clause_of tests) make test"

  is "a run whose clauses all derive asks nobody" "$(code_of floor "$tmp/ch" charter check)" "0"

  #
  # Authorisation's two refusals. Neither asks anything, which is why they can ship before a work
  # source exists — and why they fire with no human present.
  #
  is "nothing selected, so the clause grades nothing" \
     "$(code_of floor "$tmp/ch" authorise)" "8"

  floor "$tmp/ch" targets add 'https://github.com/acme/ch.git' develop >/dev/null 2>&1
  is "the bootstrap selected and its gate declared authorises" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  # The one derived exception: a `Gate:` clause governs a selected target that declares that gate.
  # The bootstrap is the only target whose declarations are readable, and it declares no `nosuch`.
  floor "$tmp/ch" charter introduce Gate nosuch >/dev/null 2>&1
  is "a Gate naming an undeclared gate grades nothing" \
     "$(code_of floor "$tmp/ch" authorise)" "8"

  # Refusing must not be the answer to everything: the run above still holds a clause that does
  # govern, so a green authorise has to be reachable again once the ungoverning one is gone.
  grep -v ' Gate nosuch$' "$(charter_of "$chrun")" > "$chrun/charter.tmp" \
    && mv "$chrun/charter.tmp" "$(charter_of "$chrun")"
  is "and authorises again once that clause is gone" \
     "$(code_of floor "$tmp/ch" authorise)" "0"
}

#
# A charter with no clause grades nothing at all. Its own repository is the case: the detector reads
# three things and Foundry declares its gates in none of them, so this is the default run, not a
# contrived one.
#
an_empty_charter_is_refused() {
  make_repo "$tmp/nogate" main && set_origin "$tmp/nogate" 'https://github.com/acme/nogate.git' \
    || { skip "authorise — git could not make a repo here"; return; }

  norun=$(floor "$tmp/nogate" new "No gates")
  is "deriving from a repo with no gate still succeeds" \
     "$(code_of floor "$tmp/nogate" charter derive)" "0"
  is "and the charter it wrote is empty" \
     "$(wc -c < "$(charter_of "$norun")" | tr -d ' ')" "0"
  is "which authorisation refuses" \
     "$(code_of floor "$tmp/nogate" authorise)" "8"
}

an_empty_charter_is_refused

# The id is the meaning. Recomputed here rather than read back, so a test cannot agree with a wrong
# id by copying it.
clause_of() { printf '%s' "$1" | cksum | awk '{ print $1 }'; }

a_charter_derives_from_the_repository_it_is_run_in

the_three_kinds_stay_apart() {
  [ -n "${chrun:-}" ] || { skip "clause kinds — no charter run"; return; }

  floor "$tmp/ch" charter introduce Judged  'adversary approves' >/dev/null 2>&1
  floor "$tmp/ch" charter introduce Decided 'refund copy signed off' >/dev/null 2>&1

  held=$(cat "$(charter_of "$chrun")")
  has "Gate survives a write and a read"    "$held" "Gate tests"
  has "Judged survives too"                 "$held" "Judged adversary approves"
  has "and Decided"                         "$held" "Decided refund copy signed off"

  is "an unknown kind is refused" \
     "$(code_of floor "$tmp/ch" charter introduce Hoped 'it works')" "2"
}
the_three_kinds_stay_apart

an_introduced_clause_stays_introduced() {
  [ -n "${chrun:-}" ] || { skip "introduction — no charter run"; return; }

  #
  # Both halves. Carrying introduced clauses forward is what makes `derive` *work*; the drop guard
  # is what makes it safe. Assert only the content and removing the carry looks fine — the guard
  # catches the loss, refuses, and leaves the charter exactly as the content check wants it.
  #
  is "re-deriving over an introduced clause succeeds" \
     "$(code_of floor "$tmp/ch" charter derive)" "0"

  held=$(cat "$(charter_of "$chrun")")
  has "and keeps the clause nothing derived" "$held" "Decided refund copy signed off"
  is  "and never gives it a pin" \
      "$(awk -v id="$(clause_of 'refund copy signed off')" '$1 == "pin" && $2 == id' "$(charter_of "$chrun")" | grep -c .)" "0"
}
an_introduced_clause_stays_introduced

a_clause_cannot_be_weakened() {
  [ -n "${chrun:-}" ] || { skip "monotonicity — no charter run"; return; }

  before=$(cat "$(charter_of "$chrun")")

  is "turning a Gate into a Decided is refused" \
     "$(code_of floor "$tmp/ch" charter introduce Decided tests)" "6"
  is "and the charter is byte-identical after" \
     "$(cat "$(charter_of "$chrun")")" "$before"

  #
  # Both directions, because the kinds are not a scale.
  #
  # An earlier version ranked them and allowed the "raise", which let a human claim a requirement was
  # mechanically established without anything establishing it. `Judged: the interface is
  # understandable` raised to `Gate:` is the case that shows the rank was never real.
  #
  is "raising a Decided to a Gate is refused too" \
     "$(code_of floor "$tmp/ch" charter introduce Gate 'refund copy signed off')" "6"
  is "the kind is still what it was" \
     "$(awk -v id="$(clause_of 'refund copy signed off')" '$1 == "clause" && $2 == id { print $3 }' "$(charter_of "$chrun")")" \
     "Decided"

  is "re-stating a clause unchanged is not a change" \
     "$(code_of floor "$tmp/ch" charter introduce Decided 'refund copy signed off')" "0"
}
a_clause_cannot_be_weakened

a_clause_is_one_line() {
  [ -n "${chrun:-}" ] || { skip "one line — no charter run"; return; }

  lines_before=$(grep -c . "$(charter_of "$chrun")")
  floor "$tmp/ch" charter introduce Decided "$(printf 'one\ntwo')" >/dev/null 2>&1

  is "a clause holding a newline cannot become two records" \
     "$(grep -c . "$(charter_of "$chrun")")" "$lines_before"
}
a_clause_is_one_line

deletion_and_drift_are_visible() {
  make_repo "$tmp/ch2" main && set_origin "$tmp/ch2" 'https://github.com/acme/ch2.git' \
    && commit_file "$tmp/ch2" Makefile 'test:
	echo ok
' || { skip "drift — git could not make a repo here"; return; }

  d=$(floor "$tmp/ch2" new "Drift")
  floor "$tmp/ch2" charter derive >/dev/null 2>&1

  # Deletion, by removing the clause the way a worker would.
  grep -v '^clause' "$(charter_of "$d")" > "$tmp/ch2.cut" && cp "$tmp/ch2.cut" "$(charter_of "$d")"
  has "deleting a clause is detectable"  "$(floor "$tmp/ch2" charter check 2>&1)" "deleted: Gate tests"
  is  "and check says so with exit 7"    "$(code_of floor "$tmp/ch2" charter check)" "7"

  # A moved source, with the clause restored.
  floor "$tmp/ch2" charter derive >/dev/null 2>&1
  commit_file "$tmp/ch2" Makefile 'test:
	echo moved
'
  has "a pinned source that moved is detectable" \
      "$(floor "$tmp/ch2" charter check 2>&1)" "moved: Makefile"
}
deletion_and_drift_are_visible

a_gate_that_resolves_elsewhere_is_visible() {
  make_repo "$tmp/ch3" main && set_origin "$tmp/ch3" 'https://github.com/acme/ch3.git' \
    && commit_file "$tmp/ch3" Makefile 'test:
	echo ok
' || { skip "resolution drift — git could not make a repo here"; return; }

  r=$(floor "$tmp/ch3" new "Resolve")
  floor "$tmp/ch3" charter derive >/dev/null 2>&1

  # A declared file the detector prefers. Every pinned sha still matches; the answer moved anyway.
  mkdir -p "$tmp/ch3/.foundry" && printf 'tests true\n' > "$tmp/ch3/.foundry/gates"

  has "a gate resolving to a new command is detectable" \
      "$(floor "$tmp/ch3" charter check 2>&1)" "resolves elsewhere: tests"
}
a_gate_that_resolves_elsewhere_is_visible

a_pin_that_cannot_be_captured_writes_nothing() {
  make_repo "$tmp/ch4" main && set_origin "$tmp/ch4" 'https://github.com/acme/ch4.git' \
    && commit_file "$tmp/ch4" README.md 'x' || { skip "pin capture — git could not make a repo"; return; }

  p=$(floor "$tmp/ch4" new "Pin")

  # Detected but never committed, so it has no sha at the base ref.
  printf 'test:\n\techo ok\n' > "$tmp/ch4/Makefile"

  is     "a pin with no sha at the base is refused" "$(code_of floor "$tmp/ch4" charter derive)" "6"
  absent "and no charter is written at all"         "$(charter_of "$p")"
}
a_pin_that_cannot_be_captured_writes_nothing

deriving_needs_the_right_repository() {
  [ -n "${chrun:-}" ] || { skip "wrong repo — no charter run"; return; }

  #
  # `$tmp/ch2` is a different repository. The run points at `acme/ch.git`.
  #
  # The message, not the code. Deriving here also fails for an unrelated reason — `develop:Makefile`
  # does not resolve in a repository sitting on `main` — so exit 6 alone passed with the guard
  # removed entirely.
  #
  has "deriving from another repository is refused for being the wrong repository" \
      "$( cd "$tmp/ch2" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$chrun" sh "$runner" charter derive 2>&1 )" \
      "run this inside [https://github.com/acme/ch.git]"
}
deriving_needs_the_right_repository

a_clause_may_span_two_targets() {
  [ -n "${chrun:-}" ] || { skip "two targets — no charter run"; return; }

  # Written by hand: deriving a second target needs a checkout of it, which is the workspace seam.
  # What is tested here is that the shape holds two pins on different refs, and `check` reads both.
  id=$(clause_of 'the feature works end to end')
  {
    printf 'clause %s Judged the feature works end to end\n' "$id"
    printf 'pin %s https://github.com/acme/ch.git develop Makefile %s\n' \
           "$id" "$(git -C "$tmp/ch" rev-parse develop:Makefile)"
    printf 'pin %s https://github.com/acme/other.git release Makefile %s\n' \
           "$id" "$(git -C "$tmp/ch" rev-parse develop:Makefile)"
  } >> "$(charter_of "$chrun")"

  is "two pins on one clause are both kept" \
     "$(awk -v id="$id" '$1 == "pin" && $2 == id' "$(charter_of "$chrun")" | grep -c .)" "2"
  is "and they carry different refs" \
     "$(awk -v id="$id" '$1 == "pin" && $2 == id { print $4 }' "$(charter_of "$chrun")" | sort -u | grep -c .)" "2"

  # `check` must actually run, or this asserts a shape nothing reads. A pin on another repository
  # cannot be verified from this one: `git rev-parse` would answer from whatever checkout it stands
  # in, inventing a pass or a failure for a repository nobody read.
  out=$(floor "$tmp/ch" charter check 2>&1)
  has   "a pin on another repository is named uncheckable" "$out" "uncheckable: Makefile at https://github.com/acme/other.git"
  lacks "and never reported as moved"                      "$out" "moved: Makefile at https://github.com/acme/other.git"
}
a_clause_may_span_two_targets

a_clause_with_no_pin_at_all_is_reported() {
  make_repo "$tmp/ch5" main && set_origin "$tmp/ch5" 'https://github.com/acme/ch5.git' \
    && commit_file "$tmp/ch5" Makefile 'test:
	echo ok
' || { skip "unpinned — git could not make a repo here"; return; }

  u=$(floor "$tmp/ch5" new "Unpinned")
  floor "$tmp/ch5" charter derive >/dev/null 2>&1

  # A gate that resolves but whose pin was removed. Distinct from an introduced clause, which has no
  # resolution either — this one claims a gate and rests on nothing.
  grep -v '^pin' "$(charter_of "$u")" > "$tmp/ch5.cut" && cp "$tmp/ch5.cut" "$(charter_of "$u")"

  has "a gate clause with no pin is reported" \
      "$(floor "$tmp/ch5" charter check 2>&1)" "unpinned: Gate tests"
}
a_clause_with_no_pin_at_all_is_reported

#
# Derivation may add or tighten. It may never remove.
#
# The draft is built from nothing, so a clause the detector stops yielding simply fails to reappear.
# That emptied a charter at exit 0, and `check` then had nothing to iterate over and said so with
# silence.
#
derivation_never_removes() {
  make_repo "$tmp/ch6" main && set_origin "$tmp/ch6" 'https://github.com/acme/ch6.git' \
    && commit_file "$tmp/ch6" Makefile 'test:
	echo ok
' || { skip "removal — git could not make a repo here"; return; }

  g=$(floor "$tmp/ch6" new "Gone")
  floor "$tmp/ch6" charter derive >/dev/null 2>&1
  before=$(cat "$(charter_of "$g")")

  # The gate stops resolving. A human deleting a requirement is a human act, not a consequence.
  rm -f "$tmp/ch6/Makefile"

  is "deriving refuses to drop a clause that no longer derives" \
     "$(code_of floor "$tmp/ch6" charter derive)" "6"
  is "and the charter is byte-identical after" \
     "$(cat "$(charter_of "$g")")" "$before"
  has "and it names what would have been lost" \
      "$(floor_says "$tmp/ch6" charter derive)" "Gate tests"
}
derivation_never_removes

# `introduce` then `derive` re-appended the pin-less record beside the pinned one — a duplicate that
# also read as having provenance nobody gave it.
introducing_then_deriving_leaves_one_record() {
  make_repo "$tmp/ch7" main && set_origin "$tmp/ch7" 'https://github.com/acme/ch7.git' \
    && commit_file "$tmp/ch7" Makefile 'test:
	echo ok
' || { skip "duplicate — git could not make a repo here"; return; }

  d=$(floor "$tmp/ch7" new "Dup")
  floor "$tmp/ch7" charter introduce Decided tests >/dev/null 2>&1
  floor "$tmp/ch7" charter derive >/dev/null 2>&1

  is "one clause record, not two" \
     "$(awk -v id="$(clause_of tests)" '$1 == "clause" && $2 == id' "$(charter_of "$d")" | grep -c .)" "1"

  #
  # Provenance arriving is not promotion.
  #
  # The clause was introduced because nothing established it. Something does now, and derivation is
  # the only thing permitted to say so — which is why a human is refused the same edit above.
  #
  is "derivation may set the kind a human may not" \
     "$(awk -v id="$(clause_of tests)" '$1 == "clause" && $2 == id { print $3 }' "$(charter_of "$d")")" "Gate"
  is "and it now carries a pin" \
     "$(awk -v id="$(clause_of tests)" '$1 == "pin" && $2 == id' "$(charter_of "$d")" | grep -c .)" "1"
}
introducing_then_deriving_leaves_one_record

#
# `cksum` is 32 bits, so two meanings can land on one id.
#
# Forced by hand rather than by hunting a real CRC collision: what matters is that the path is
# reachable and refuses, not that two English sentences happen to collide today.
#
one_id_means_one_thing() {
  make_repo "$tmp/ch8" main && set_origin "$tmp/ch8" 'https://github.com/acme/ch8.git' \
    && commit_file "$tmp/ch8" README.md 'x' || { skip "collision — git could not make a repo"; return; }

  c=$(floor "$tmp/ch8" new "Collide")
  floor "$tmp/ch8" charter introduce Decided 'the first meaning' >/dev/null 2>&1

  # The same id, a different meaning. This is what a collision looks like on disk.
  id=$(clause_of 'the first meaning')
  before=$(cat "$(charter_of "$c")")

  has "the charter holds it once to begin with" "$before" "Decided the first meaning"

  # The same id, a different meaning. This is what a collision looks like on disk.
  printf 'clause %s Decided a different meaning entirely\n' "$id" >> "$(charter_of "$c")"

  has "a charter naming two meanings on one id says so" \
      "$(floor "$tmp/ch8" charter check 2>&1)" "ambiguous: id $id names two meanings"
  is  "and check refuses to call that clean" \
      "$(code_of floor "$tmp/ch8" charter check)" "7"
}
one_id_means_one_thing

#
# The resolver is an adapter, so another one must work without editing anything above it.
#
# This one knows no ecosystem at all — it answers for a repository holding none of the files the
# shipped detector looks for. If the charter still records a gate, nothing above the seam learned
# which resolver answered.
#
another_resolver_needs_no_change_above_it() {
  make_repo "$tmp/ch9" main && set_origin "$tmp/ch9" 'https://github.com/acme/ch9.git' \
    && commit_file "$tmp/ch9" thing.rs 'fn main() {}' || { skip "resolver seam — git could not make a repo"; return; }

  printf '#!/bin/sh\necho "checks thing.rs cargo test"\n' > "$tmp/rustish.sh"

  r=$(floor "$tmp/ch9" new "Other Resolver")
  ( cd "$tmp/ch9" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$r" FOUNDRY_GATES="$tmp/rustish.sh" \
      sh "$runner" charter derive >/dev/null 2>&1 )

  held=$(cat "$(charter_of "$r")" 2>/dev/null)
  has "a replacement resolver's gate becomes a clause" "$held" "Gate checks"
  has "pinned to what that resolver read"              "$held" "thing.rs"
  has "and its command recorded"                       "$held" "gate $(clause_of checks) cargo test"

  is "the shipped resolver finds nothing here" \
     "$(sh "$here/lib/detect-gates.sh" "$tmp/ch9" | grep -c .)" "0"
}
another_resolver_needs_no_change_above_it

#
# Three tampers that every earlier check passed.
#
# Each edits the charter and nothing else — no pin touched, no sha moved. They passed because every
# finding was gated on a record the tamper removes, or on an id nothing recomputed.
#
a_tampered_charter_is_visible() {
  make_repo "$tmp/tam" main && set_origin "$tmp/tam" 'https://github.com/acme/tam.git' \
    && commit_file "$tmp/tam" Makefile 'test:
	echo ok
' || { skip "tamper — git could not make a repo here"; return; }

  m=$(floor "$tmp/tam" new "Tamper")
  rm -f "$(charter_of "$m")"; floor "$tmp/tam" charter derive >/dev/null 2>&1
  id=$(clause_of tests)

  # The text rewritten under its id. Every other record still matches, so nothing else notices.
  sed "s|^clause $id Gate tests\$|clause $id Gate anything at all|" "$(charter_of "$m")" > "$tmp/t1" \
    && cp "$tmp/t1" "$(charter_of "$m")"
  has "a clause whose text was rewritten under its id is caught" \
      "$(floor "$tmp/tam" charter check 2>&1)" "forged: id $id"

  # The pin and the resolution deleted. The clause stays, and used to read as satisfied.
  rm -f "$(charter_of "$m")"; floor "$tmp/tam" charter derive >/dev/null 2>&1
  grep -v '^pin \|^gate ' "$(charter_of "$m")" > "$tmp/t2" && cp "$tmp/t2" "$(charter_of "$m")"
  out=$(floor "$tmp/tam" charter check 2>&1)
  has "a Gate whose pin was deleted is caught"        "$out" "unpinned: Gate tests"
  has "and one whose resolution was deleted as well"  "$out" "unresolved: Gate tests"

  # The clause deleted outright, leaving pin and gate behind.
  rm -f "$(charter_of "$m")"; floor "$tmp/tam" charter derive >/dev/null 2>&1
  grep -v '^clause ' "$(charter_of "$m")" > "$tmp/t3" && cp "$tmp/t3" "$(charter_of "$m")"
  has "a deleted clause is caught even with its records left behind" \
      "$(floor "$tmp/tam" charter check 2>&1)" "deleted: Gate tests"

  # One word. A pin's target is what it says it is, so relabelling it made a local pin read foreign
  # — reported as uncheckable, never compared, and never counted.
  rm -f "$(charter_of "$m")"; floor "$tmp/tam" charter derive >/dev/null 2>&1
  sed 's|^\(pin [0-9]* \)https://github.com/acme/tam.git|\1https://github.com/acme/elsewhere.git|' \
    "$(charter_of "$m")" > "$tmp/t4" && cp "$tmp/t4" "$(charter_of "$m")"

  has "a pin relabelled onto another repository is caught" \
      "$(floor "$tmp/tam" charter check 2>&1)" "unpinned: Gate tests"
  is  "and it fails rather than reading uncheckable" \
      "$(code_of floor "$tmp/tam" charter check)" "7"
}

# The detector answers for the repository, never for the directory you happen to stand in.
deriving_from_a_subdirectory_is_the_same_answer() {
  make_repo "$tmp/sub" main && set_origin "$tmp/sub" 'https://github.com/acme/sub.git' \
    && commit_file "$tmp/sub" Makefile 'test:
	echo ok
' || { skip "subdirectory — git could not make a repo here"; return; }
  mkdir -p "$tmp/sub/deep"

  s=$(floor "$tmp/sub" new "Deep")
  floor_as "$tmp/sub/deep" "$home" "$s" charter derive >/dev/null 2>&1

  has "deriving one level down finds the same gate" \
      "$(cat "$(charter_of "$s")" 2>/dev/null)" "clause $(clause_of tests) Gate tests"
}
deriving_from_a_subdirectory_is_the_same_answer
a_tampered_charter_is_visible

# `introduce` replaces the record for a meaning. Appending left the first one winning for every
# reader, so the second was accepted and changed nothing.
introducing_twice_leaves_one_record() {
  [ -n "${chrun:-}" ] || { skip "one record — no charter run"; return; }

  floor "$tmp/ch" charter introduce Judged 'said once' >/dev/null 2>&1
  floor "$tmp/ch" charter introduce Judged 'said once' >/dev/null 2>&1

  is "the same clause twice is one record" \
     "$(awk -v id="$(clause_of 'said once')" '$1 == "clause" && $2 == id' "$(charter_of "$chrun")" | grep -c .)" "1"
}
introducing_twice_leaves_one_record

# A resolver that is not there answers "no gates", which is what a clean charter looks like.
a_missing_resolver_is_not_silence() {
  [ -n "${chrun:-}" ] || { skip "missing resolver — no charter run"; return; }

  is "a resolver that is not there stops the command" \
     "$( cd "$tmp/ch" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$chrun" FOUNDRY_GATES="$tmp/no-such" \
         sh "$runner" charter check >/dev/null 2>&1; printf '%s' "$?" )" "3"
}
a_missing_resolver_is_not_silence

is "charter with no run exits 1" "$(code_of floor "$tmp/bare" charter)" "1"

# --- asking for the wrong thing ---

is "new with no title exits 2"  "$(code_of floor "$tmp/bare" new)" "2"
is "an unknown command exits 2" "$(code_of floor "$tmp/bare" fly)" "2"

summary "model"
