#!/bin/bash
# The run model: where a run lives, what it is called, and what making one is allowed to touch.
#
# Run through `sh`, never `bash`. That is the shell hooks.json names, and running these with bash
# would certify syntax the shipped runner cannot use.
#
# Set RUNNER to point these checks at a deliberately broken copy.

set -u

# Pinned, because a glob's order decides which directory `only_slot` yields — and a break whose kill
# depends on the machine's collation is not an oracle.
LC_ALL=C
export LC_ALL

here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

runner="${RUNNER:-$here/bin/run.sh}"
tmp="${TMPDIR:-/tmp}/floor-model-$$"
home="$tmp/home"
mkdir -p "$tmp/bare"
trap 'rm -rf "$tmp"' EXIT

# Run the shipped CLI from a directory, with an explicit home and run variable.
#
# The directory adapter, named rather than detected.
#
# Almost every repository below has a `github.com` origin, so on a machine with `gh` the checks that
# reach `source ask` addressed the real provider about issues that do not exist. `the_other_adapter`
# sets its own and is the only place the GitHub one is exercised.
#
# Beside the runner under test, never beside this file: `wreck_runner` breaks a copy of the plugin and
# points `RUNNER` at it, so naming the original's adapter would hand every mutant an unbroken one.
#
dir_source="$(dirname "$runner")/../lib/source-dir.sh"

floor_as() {
  dir=$1; home_dir=$2; run=$3; shift 3
  ( cd "$dir" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home_dir" FOUNDRY_RUN="$run" FOUNDRY_WHO=""       FOUNDRY_SOURCE="$dir_source" sh "$runner" "$@" 2>/dev/null )
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
    FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO=""       FOUNDRY_SOURCE="$dir_source" sh "$runner" "$@" 2>&1 )
}

# A run someone selected. `new` records whoever the environment names, and a container names nobody —
# so a test about delivery has to say who, because invariant 4 is one of its conjuncts.
floor_new_as() {
  dir=$1; who=$2; shift 2
  ( cd "$dir" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="$who" sh "$runner" new "$@" 2>/dev/null )
}

# Named, because `worker` reads the environment and nothing else can say who produced the work.
floor_worked() {
  dir=$1; said=$2; shift 2
  ( cd "$dir" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" FOUNDRY_WORKER="$said" \
      sh "$runner" "$@" 2>/dev/null )
}

# Everything a gate needs before it can run: a charter, a selection, and a workspace to grade. Four
# calls in every test that reaches the gate stage, and the gate stage is most of them.
ready_run() {
  dir=$1; identity=$2; ref=${3:-main}
  floor_new_as "$dir" ada@example.com "Ready" >/dev/null
  floor "$dir" charter derive >/dev/null 2>&1
  floor "$dir" policy authorize "$identity" >/dev/null 2>&1
  floor "$dir" targets add "$identity" "$ref" >/dev/null 2>&1
  floor "$dir" open >/dev/null 2>&1
}

# The one checkout under a workspace. Its name is the runner's business — a test that recomputed it
# would agree with a wrong answer, which is the whole failure mode here.
only_slot() { set -- "$1"/*/; [ -d "$1" ] && printf '%s' "${1%/}"; }

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


#
# A shell standing inside a run, handed nothing else.
#
# RFC-001 §4 calls this the test of whether the decomposition was right — a person joins by opening a
# shell in the workspace and reading the run. The nouns were right and the verb answered
# nothing: `path` was silent there and `gates` refused.
#
# Last of the three, never first. A named run and a pointed checkout are what a human chose; this is
# where a shell happens to be.
#
a_shell_standing_in_a_run() {
  inside=$( cd "$first/units/01" 2>/dev/null \
            && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" sh "$runner" path 2>/dev/null )

  is "a shell inside a run names it with nothing set" "$inside" "$first"

  outside=$( cd "$tmp" 2>/dev/null \
             && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" sh "$runner" path 2>/dev/null )

  is "and outside every run it is still no run" "$outside" ""

  # A run answers to its own name. A directory copied under another parent keeps the name and passes
  # here, which is the hole `refuse_renamed_run` already records.
  moved="$tmp/moved-run"
  rm -rf "$moved" && cp -R "$first" "$moved"

  renamed=$( cd "$moved" 2>/dev/null \
             && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" sh "$runner" path 2>/dev/null )

  is "a run whose directory was renamed is not one" "$renamed" ""

  # The variable is what a human chose, so it wins over the floor underfoot.
  named=$( cd "$first/units/01" 2>/dev/null \
           && FOUNDRY_HOME="$home" FOUNDRY_RUN="$second" FOUNDRY_WHO="" sh "$runner" path 2>/dev/null )

  is "a named run outranks the one being stood in" "$named" "$second"
}
a_shell_standing_in_a_run
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

  has "the bootstrap target names the repo and the base ref" \
      "$(cat "$booted/bootstrap" 2>/dev/null)" "https://github.com/acme/backend.git main"

  # A repository with no commits has an identity and no base. `policy` still answers for it; only
  # `derive` needs somewhere a requirement could have come from.
  is "a repo with no commits records no base" \
     "$(awk 'NR == 1 { print NF }' "$booted/bootstrap" 2>/dev/null)" "2"

  lacks "and the credential never reaches disk" "$(cat "$booted/bootstrap" 2>/dev/null)" "tok3n"
  has   "bootstrap prints it back" "$(floor "$tmp/boot" bootstrap)" "https://github.com/acme/backend.git main"

  # A password may contain an `@`. Stopping at the first one left the tail of it on disk.
  lacks "no path under the run holds a credential" \
        "$(grep -rh . "$booted/bootstrap" "$booted/units" 2>/dev/null)" "tok3n"
}
the_bootstrap_target

a_password_holding_an_at() {
  make_repo "$tmp/atpass" main && set_origin "$tmp/atpass" 'https://u:p@ss@github.com/acme/x.git' \
    || { skip "a password holding an @ — git could not make a repo here"; return; }

  atp=$(floor "$tmp/atpass" new "At In Password")
  has "a password holding an @ is stripped whole" \
      "$(cat "$atp/bootstrap" 2>/dev/null)" "https://github.com/acme/x.git main"
}
a_password_holding_an_at

# 0..1, so absence is an answer and not a failure.
outside=$(floor "$tmp/bare" new "No Origin")
absent "a run started outside a repo records no bootstrap target" "$outside/bootstrap"
is     "and asking for it exits 1" "$(code_of floor "$tmp/bare" bootstrap)" "1"

#
# Invariant 4: a run exists because a human selected the work item. That act is stamped where the run
# begins, and it is not evidence — it names no clause, so it can satisfy none.
#
the_selection_is_stamped() {
  chose=$( cd "$tmp/bare" 2>/dev/null || exit 9
           FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="ada@example.com" \
           sh "$runner" new "Chosen" 2>/dev/null )

  held=$(cat "$chose/authority" 2>/dev/null)
  matches "the selection names when, who, and the run it authorised" \
          "$held" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z	ada@example.com	$(basename "$chose")$"
  is "three fields, where evidence has seven" \
     "$(printf '%s\n' "$held" | awk -F'\t' 'NF != 3' | grep -c .)" "0"
  is "and it is not in the ledger completion reads" "$(cat "$chose/evidence" 2>/dev/null)" ""
}
the_selection_is_stamped

#
# Nobody is an answer, written as one. `new` changes nothing in any repository, so demanding a name
# here would refuse a local act; the bar belongs at delivery, where an unattributable run matters.
#
a_run_nobody_claims_still_starts() {
  nameless=$( cd "$tmp/bare" 2>/dev/null || exit 9
              HOME="$tmp/nogit" FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
              sh "$runner" new "Unclaimed" 2>/dev/null )

  is "a run with no selector still starts" "$(code_of test -d "$nameless")" "0"
  matches "and the stamp says so, rather than inventing one" \
          "$(cat "$nameless/authority" 2>/dev/null)" "Z		$(basename "$nameless")$"
}
a_run_nobody_claims_still_starts

#
# The other half of `selector`. `FOUNDRY_WHO` is for a harness acting on someone's behalf; git's
# identity is what every checkout already carries, and without a check for it the fallback could be
# deleted and the suite would not notice.
#
git_names_the_selector_when_nothing_else_does() {
  make_repo "$tmp/who" main || { skip "git identity — git could not make a repo here"; return; }
  git -C "$tmp/who" config user.email 'grace@example.com' >/dev/null 2>&1 \
    || { skip "git identity — this git will not hold a config"; return; }

  theirs=$(floor "$tmp/who" new "By Git")
  has "with no FOUNDRY_WHO, the checkout's git identity is the selector" \
      "$(cat "$theirs/authority" 2>/dev/null)" "grace@example.com"
}
git_names_the_selector_when_nothing_else_does

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

  # Granted, and not selected yet. Every guard returns before the append, so the write this is about
  # is only reachable by an add that passes all of them — `sneaky` is refused for want of a grant and
  # `evil` for being selected already, and neither would arrive.
  floor "$tmp/pol" policy authorize 'https://github.com/acme/fresh.git' >/dev/null 2>&1
  grants_before=$(cat "$(policy_for "$polrun")" 2>/dev/null)

  floor "$tmp/pol" targets add 'https://github.com/sneaky/repo.git' main >/dev/null 2>&1
  floor "$tmp/pol" targets add 'https://github.com/acme/fresh.git' main >/dev/null 2>&1

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
# Sequential calls never exercised the claim, because nothing competed for the slot. Eight at once
# did: the chooser asked whether a name was free and created it a moment later, and eight callers
# agreed on three answers. Two runs holding one slot share `policy/runs/<id>/targets`, so a grant a
# human gave to one authorises the other.
#
# Eight because eight is what reproduced it, and this sits below `set_origin` because a function
# called before its definition takes the `|| skip` branch — which reads as a pass.
#
eight_at_once_claim_eight_slots() {
  make_repo "$tmp/race" main && set_origin "$tmp/race" 'https://github.com/acme/race.git' \
    || { skip "concurrent new — git could not make a repo here"; return; }

  for _ in 1 2 3 4 5 6 7 8; do floor "$tmp/race" new "Eight At Once" >/dev/null 2>&1 & done
  wait

  is  "eight concurrent runs claim eight slots" \
      "$(ls "$home/runs" 2>/dev/null | grep -c -- '-eight-at-once-')" "8"
  has "and the slots run unbroken to the eighth" \
      "$(ls "$home/runs" 2>/dev/null | grep -- '-eight-at-once-' | tr '\n' ' ')" "-0007"
}
eight_at_once_claim_eight_slots

#
# `mkdir -p "$RUNS"` succeeds on a `runs/` that already exists and refuses a child, so every claim
# after it fails for a reason counting cannot fix. Advancing on any failure counts for ever.
#
# **Bounded on purpose.** The break this guards against is a hang, not a wrong answer, so a check
# that simply called the runner would take the suite down with it rather than turn it red. `timeout`
# is the harness's, not the plugin's — floor still ships needing only `sh`, `awk` and `git`.
#
a_claim_that_can_never_land_refuses() {
  command -v timeout >/dev/null 2>&1 \
    || { skip "a claim that can never land — no timeout to bound a runner that may not return"; return; }

  make_repo "$tmp/noclaim" main && set_origin "$tmp/noclaim" 'https://github.com/acme/noclaim.git' \
    || { skip "a claim that can never land — git could not make a repo here"; return; }

  shut="$tmp/shut"
  rm -rf "$shut"; mkdir -p "$shut/runs"
  chmod 500 "$shut/runs" 2>/dev/null

  # Windows ignores chmod. Without this probe the check would pass by claiming a slot normally, and
  # report a guard it never reached.
  if mkdir "$shut/runs/probe" 2>/dev/null; then
    rmdir "$shut/runs/probe"; chmod 700 "$shut/runs" 2>/dev/null
    skip "a claim that can never land — this filesystem ignores chmod"
    return
  fi

  ( cd "$tmp/noclaim" 2>/dev/null || exit 9
    FOUNDRY_HOME="$shut" FOUNDRY_RUN="" timeout 20 sh "$runner" new "No Claim" >/dev/null 2>&1 )
  code=$?

  chmod 700 "$shut/runs" 2>/dev/null

  # 124 is `timeout` killing it — the loop counting past a failure it will never fix.
  is "a claim that can never land refuses instead of counting" "$code" "3"
}
a_claim_that_can_never_land_refuses

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

#
# Grants are keyed by the run's id and kept beside the runs, so a renamed directory looks up a key
# nothing holds. It answered exit 0 with the bootstrap alone: authority a human gave, gone, silently.
#
a_renamed_run_refuses_rather_than_losing_its_grants() {
  make_repo "$tmp/ren" main && set_origin "$tmp/ren" 'https://github.com/acme/ren.git' \
    || { skip "renamed run — git could not make a repo here"; return; }

  moved=$(floor "$tmp/ren" new "Rename Me")
  floor "$tmp/ren" policy authorize 'https://github.com/acme/granted.git' >/dev/null
  has "the grant is there to start with" "$(floor "$tmp/ren" policy)" "granted"

  was=$(basename "$moved")
  mv "$moved" "$(dirname "$moved")/renamed-by-hand"
  printf 'renamed-by-hand\n' > "$tmp/ren/.git/foundry-run"

  is  "a renamed run refuses"    "$(code_of floor "$tmp/ren" policy)" "13"
  has "and names where it is"    "$(floor_says "$tmp/ren" policy)" "renamed-by-hand"
  has "and what it calls itself" "$(floor_says "$tmp/ren" policy)" "$was"

  # Every reader of the grants, not the one that happened to be tested. `policy` refusing alone let a
  # rename onto a deleted run's id add a target at exit 0, and let `authorise` freeze a selection
  # whose grants were not there. `gates` is the one that writes, and it stamped a passing record into
  # a run the other four refuse.
  is "targets refuses too"   "$(code_of floor "$tmp/ren" targets)" "13"
  is "and authorise refuses" "$(code_of floor "$tmp/ren" authorise)" "13"
  is "and complete refuses"  "$(code_of floor "$tmp/ren" complete)" "13"
  is "and so does gates, which writes" "$(code_of floor "$tmp/ren" gates)" "13"

  # Moving it back is the remedy, and it costs nothing — the grants were never gone.
  mv "$(dirname "$moved")/renamed-by-hand" "$moved"
  printf '%s\n' "$was" > "$tmp/ren/.git/foundry-run"
  has "moving it back restores the grant" "$(floor "$tmp/ren" policy)" "granted"

  # A run made before this rule has no `id`, and must work exactly as it did. The guard fails open
  # there on purpose — without this check, closing it would break every existing run in silence.
  rm -f "$moved/id"

  is  "a run with no id is left alone"  "$(code_of floor "$tmp/ren" policy)" "0"
  has "and still reads its grants"      "$(floor "$tmp/ren" policy)" "granted"
  is  "targets is left alone too"       "$(code_of floor "$tmp/ren" targets)" "0"
}
a_renamed_run_refuses_rather_than_losing_its_grants

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

# Where a loose object lives, so a test can take one away.
loose_object() { printf '%s/.git/objects/%.2s/%s' "$1" "$2" "${2#??}"; }

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
  # The base commit, not `develop`. A pin naming a branch resolves to whatever that branch points at
  # when it is read, which is how a run came to bless its own work — #99.
  matches "with a pin at the base commit" \
          "$held" "pin $(clause_of tests) https://github.com/acme/ch.git [0-9a-f]{40} Makefile"
  has "and the command it resolved to"      "$held" "gate $(clause_of tests) make test"

  is "a charter whose pins all still derive checks clean" "$(code_of floor "$tmp/ch" charter check)" "0"

  #
  # Authorisation's two refusals. Neither asks anything, which is why they can ship before a work
  # source exists — and why they fire with no human present.
  #
  said=$(floor_says "$tmp/ch" authorise)
  is    "nothing selected, so the clause grades nothing" \
        "$(code_of floor "$tmp/ch" authorise)" "9"
  has   "and says that is what is wrong" "$said" "grades no selected target"
  lacks "and not that something is introduced" "$said" "nothing derives it"

  floor "$tmp/ch" targets add 'https://github.com/acme/ch.git' develop >/dev/null 2>&1
  is "the bootstrap selected and its gate declared authorises" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  # The one derived exception: a `Gate:` clause governs a selected target that declares that gate.
  # The bootstrap is the only target whose declarations are readable, and it declares no `nosuch`.
  #
  # The freeze. Authorising writes the selected set down, and it is the only record of what was
  # selected at that moment — which is what lets a line *removed* afterwards be seen at all. The
  # selection file cannot show an absence; a second record can.
  #
  frozen=$chrun/units/01/selection
  exists "authorising writes the selected set down" "$frozen"
  is "and it holds the lines, not a digest of them" \
     "$(cat "$frozen")" "https://github.com/acme/ch.git develop"

  # A run authorised before the rename. It holds the old name and nothing re-freezes it, so reading
  # the new one would lose the record that makes a *removed* line visible — and exit 10 with it.
  mv "$frozen" "$chrun/units/01/authorised-targets"

  is "a run frozen under the old name still authorises" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  printf 'https://github.com/acme/ch.git main\n' >> "$chrun/units/01/targets"
  is "and a selection that moves under it still refuses" \
     "$(code_of floor "$tmp/ch" authorise)" "10"

  mv "$chrun/units/01/authorised-targets" "$frozen"
  printf 'https://github.com/acme/ch.git develop\n' > "$chrun/units/01/targets"

  is "authorising again over the same selection is not a change" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  floor "$tmp/ch" policy authorize 'https://github.com/acme/second.git' >/dev/null 2>&1
  printf 'https://github.com/acme/second.git main\n' >> "$chrun/units/01/targets"
  is "a target added after the freeze is a different run" \
     "$(code_of floor "$tmp/ch" authorise)" "10"

  # Exactly back, so this proves the comparison and not merely that something was touched.
  printf 'https://github.com/acme/ch.git develop\n' > "$chrun/units/01/targets"
  is "and putting it back exactly authorises again" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  #
  # The half nothing could see before, and it has to be a deletion that leaves the selection
  # standing. Emptying the file is refused whether or not a freeze exists — every clause then grades
  # nothing — so a suite that only empties it proves the ordering and never the absence.
  #
  # A fresh authorisation of a two-target selection. The record has to go, because adding a target
  # to a frozen selection is exactly what exits 10 — which the check above just proved.
  rm -f "$frozen"
  printf 'https://github.com/acme/ch.git develop\nhttps://github.com/acme/second.git main\n' \
    > "$chrun/units/01/targets"
  is "two selected targets authorise" "$(code_of floor "$tmp/ch" authorise)" "0"

  printf 'https://github.com/acme/ch.git develop\n' > "$chrun/units/01/targets"
  is "one of two deleted after the freeze is a different run" \
     "$(code_of floor "$tmp/ch" authorise)" "10"

  # Order is not part of a set, and a refusal that fired on it would teach people to ignore refusals.
  printf 'https://github.com/acme/second.git main\nhttps://github.com/acme/ch.git develop\n' \
    > "$chrun/units/01/targets"
  is "the same two targets in another order are the same selection" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  # `add_target` does not dedupe, so a set is not a list here either.
  printf 'https://github.com/acme/ch.git develop\nhttps://github.com/acme/second.git main\nhttps://github.com/acme/ch.git develop\n' \
    > "$chrun/units/01/targets"
  is "the same target twice is the same selection" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  # A comment is not a target. Without this the whole normalisation could be `cat` and nothing notices.
  printf 'https://github.com/acme/ch.git develop\nhttps://github.com/acme/second.git main\n# a note\n' \
    > "$chrun/units/01/targets"
  is "a comment added after the freeze is not a change" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  #
  # The two arrangements that pin the ordering. Both refuse either way, so only the *code* separates
  # a moved-first gate from a moved-last one — and the whole argument for moving it was that the
  # later checks name remedies the freeze forbids.
  #
  : > "$chrun/units/01/targets"
  is "an emptied selection is a moved one, not a bar that grades nothing" \
     "$(code_of floor "$tmp/ch" authorise)" "10"

  printf 'https://github.com/acme/ch.git develop\nhttps://github.com/acme/never.git main\n' \
    > "$chrun/units/01/targets"
  is "an unauthorised target added after the freeze is a moved selection, not a policy question" \
     "$(code_of floor "$tmp/ch" authorise)" "10"

  printf 'https://github.com/acme/ch.git develop\n' > "$chrun/units/01/targets"
  printf 'https://github.com/acme/ch.git develop\n' > "$frozen"

  #
  # Condition 1. An introduced clause is a bar nobody authorised, so the stage asks and blocks until
  # someone answers. Condition 2 arrives here too: with no judge, every clause the mechanical path
  # cannot establish is introduced.
  #
  floor "$tmp/ch" charter introduce Judged 'the interface is understandable' >/dev/null 2>&1
  is "an introduced clause cannot authorise cleanly" \
     "$(code_of floor "$tmp/ch" authorise)" "11"
  has "and the refusal names the clause and who owns it" \
      "$(floor_says "$tmp/ch" authorise)" "a human owns this"

  grep -v 'the interface is understandable' "$(charter_of "$chrun")" > "$chrun/c.tmp" \
    && mv "$chrun/c.tmp" "$(charter_of "$chrun")"
  is "and authorises again once nothing is introduced" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  #
  # Condition 3, consumed from `underived_gates` rather than asked again. Ahead of the empty-charter
  # refusal: deleting the last clause satisfies both, and only this one is true — exit 8 would answer
  # "declare a gate" where a gate is declared and the clause was removed.
  #
  cp "$(charter_of "$chrun")" "$chrun/charter.keep"
  grep -v '^clause .* Gate tests$' "$chrun/charter.keep" > "$(charter_of "$chrun")"
  is "a still-derived clause that was removed cannot pass" \
     "$(code_of floor "$tmp/ch" authorise)" "12"
  has "and it is reported as still derived, not as an empty charter" \
      "$(floor_says "$tmp/ch" authorise)" "the detector yields Gate tests"

  mv "$chrun/charter.keep" "$(charter_of "$chrun")"
  is "and authorises again once it is back" \
     "$(code_of floor "$tmp/ch" authorise)" "0"

  #
  # An introduced `Gate:` naming a gate nothing declares satisfies both refusals, and provenance is
  # the earlier question. Exit 9's remedy is *declare that gate* — which would coach someone into
  # making a clause nobody authorised into a real bar, and only then tell them it had no provenance.
  #
  # Exit 9 stays reachable and stays checked: the empty-selection case above is a derived clause
  # governing nothing, which is what that refusal is actually for.
  #
  floor "$tmp/ch" charter introduce Gate nosuch >/dev/null 2>&1
  said=$(floor_says "$tmp/ch" authorise)
  is "an introduced Gate is stopped for its provenance, not its coverage" \
     "$(code_of floor "$tmp/ch" authorise)" "11"

  # The exit code alone does not say the later refusal stayed quiet, and a condition that started
  # firing early would take this case with the same code and a remedy that edits the wrong thing.
  has   "and says what it is stopped for"  "$said" "nothing derives it"
  lacks "and never the coverage remedy"    "$said" "grades no selected target"

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
#
# Every other `authorise` check in this suite derives first, so the never-derived path had no reader
# at all — and it is the one that was wrong: `underived_gates` yields `deleted:` for a gate no clause
# exists for, which is every gate when no charter exists. That run was told it had lost a clause
# whose pins never existed.
#
authorising_before_deriving() {
  make_repo "$tmp/pre" main && set_origin "$tmp/pre" 'https://github.com/acme/pre.git' \
    || { skip "authorise before derive — git could not make a repo here"; return; }

  printf 'test:\n\techo ok\n' > "$tmp/pre/Makefile"
  git -C "$tmp/pre" add -A >/dev/null 2>&1 && git -C "$tmp/pre" commit -qm gate >/dev/null 2>&1

  floor "$tmp/pre" new "Before deriving" >/dev/null
  is "authorising before deriving asks for a charter, not for a lost clause" \
     "$(code_of floor "$tmp/pre" authorise)" "1"
  has "and it says which" \
      "$(floor_says "$tmp/pre" authorise)" "this run has no charter"
}
authorising_before_deriving

an_empty_charter_is_refused() {
  # A commit, because a repository with none has no base and so nothing to derive provenance from.
  # No gate in it — that is what this checks.
  make_repo "$tmp/nogate" main && set_origin "$tmp/nogate" 'https://github.com/acme/nogate.git' \
    && commit_file "$tmp/nogate" README 'no gates here
' || { skip "authorise — git could not make a repo here"; return; }

  norun=$(floor "$tmp/nogate" new "No gates")
  is "deriving from a repo with no gate still succeeds" \
     "$(code_of floor "$tmp/nogate" charter derive)" "0"
  is "and the charter it wrote is empty" \
     "$(wc -c < "$(charter_of "$norun")" | tr -d ' ')" "0"
  said=$(floor_says "$tmp/nogate" authorise)
  is    "which authorisation refuses" \
        "$(code_of floor "$tmp/nogate" authorise)" "8"
  has   "and says the charter is what is empty" "$said" "holds no clause"
  lacks "and names no clause of its own"        "$said" "grades no selected target"
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

#
# A run may establish provenance only from its base — RFC-001 invariant 1, issue #99.
#
# Drift already exited 7, and re-deriving was the remedy. That made re-deriving the way to launder a
# worker's edit into authority: commit the rewritten bar, derive again, and `check` passes on a
# requirement no human wrote.
#
a_run_cannot_author_its_own_bar() {
  make_repo "$tmp/own" main && set_origin "$tmp/own" 'https://github.com/acme/own.git' \
    && mkdir -p "$tmp/own/.foundry" \
    && commit_file "$tmp/own" .foundry/gates 'tests  echo HUMAN
' || { skip "same-run authority — git could not make a repo here"; return; }

  base=$(git -C "$tmp/own" rev-parse HEAD 2>/dev/null)
  floor "$tmp/own" new "Own Bar" >/dev/null
  floor "$tmp/own" charter derive >/dev/null 2>&1

  commit_file "$tmp/own" .foundry/gates 'tests  echo WORKER
'

  said=$(floor_says "$tmp/own" charter derive)

  is   "a run refuses to derive from an artifact it changed" \
       "$(code_of floor "$tmp/own" charter derive)" "6"
  has  "and names the artifact"   "$said" ".foundry/gates"
  has  "and the base it moved from" "$said" "$base"
  has  "the bar stays the human's" \
       "$(cat "$(charter_of "$(floor "$tmp/own" path)")" 2>/dev/null)" "echo HUMAN"

  # The next run's base holds the worker's commit, so it derives from it normally. The rule bars a
  # run from blessing its own work, not the work itself.
  floor "$tmp/own" new "After" >/dev/null
  is  "a later run derives from that commit normally" \
      "$(code_of floor "$tmp/own" charter derive)" "0"
  has "with the bar that commit carries" \
      "$(cat "$(charter_of "$(floor "$tmp/own" path)")" 2>/dev/null)" "echo WORKER"
}
a_run_cannot_author_its_own_bar

# Whether `chmod 000` means anything here. Windows records no read bit and root ignores
# the one it finds, so a check about an unreadable file would pass for a
# reason that is not the rule.
records_unreadable() {
  probe="$tmp/read-probe"
  : > "$probe"
  chmod 000 "$probe" 2>/dev/null
  unreadable=1; [ -r "$probe" ] && unreadable=0
  chmod 644 "$probe" 2>/dev/null

  [ "$unreadable" -eq 1 ]
}

#
# A declaration outranks a guess — §3's ladder, level 1 guesses and level 2 corrects it. One that
# cannot be read used to run the ladder backwards: `awk` exits non-zero for a file naming no gate
# and for one it could not open, and `||` read both as nothing declared.
#
# The bar then changed silently. A repository asking for `sh bin/check.sh` was graded with
# `make test`, pinned to the `Makefile` it guessed from — so `check` compared that file ever after
# and the declaration was invisible to everything downstream.
#
a_declaration_it_cannot_read_is_not_a_guess() {
  records_unreadable || { skip "an unreadable declaration — this filesystem records no read bit"; return; }

  make_repo "$tmp/ur" main && set_origin "$tmp/ur" 'https://github.com/acme/ur.git' \
    && mkdir -p "$tmp/ur/.foundry" \
    && commit_file "$tmp/ur" Makefile 'test:
	echo guessed
' \
    && commit_file "$tmp/ur" .foundry/gates 'tests  echo DECLARED
' || { skip "an unreadable declaration — git could not make a repo here"; return; }

  floor "$tmp/ur" new "Unreadable" >/dev/null
  chmod 000 "$tmp/ur/.foundry/gates"

  said=$(floor_says "$tmp/ur" charter derive)
  is  "a declaration that cannot be read refuses"  "$(code_of floor "$tmp/ur" charter derive)" "22"
  has "and names the file"                         "$said" ".foundry/gates"
  lacks "and derives no bar from a guess"          "$said" "make test"

  chmod 644 "$tmp/ur/.foundry/gates"
  is  "and derives normally once it can be read"   "$(code_of floor "$tmp/ur" charter derive)" "0"
  has "with the bar the repository declared" \
      "$(cat "$(charter_of "$(floor "$tmp/ur" path)")" 2>/dev/null)" "echo DECLARED"
}
a_declaration_it_cannot_read_is_not_a_guess

#
# Evidence is stamped, never claimed — RFC-001 §2.5. The recorder takes a command, runs it, and
# records what happened, so a worker proves a gate passed only by making it pass.
#
evidence_is_what_happened() {
  make_repo "$tmp/ev" main && set_origin "$tmp/ev" 'https://github.com/acme/ev.git' \
    && mkdir -p "$tmp/ev/.foundry" \
    && commit_file "$tmp/ev" .foundry/gates 'tests  true
' || { skip "evidence — git could not make a repo here"; return; }

  floor "$tmp/ev" new "Evidence" >/dev/null
  floor "$tmp/ev" charter derive >/dev/null 2>&1
  floor "$tmp/ev" policy authorize 'https://github.com/acme/ev.git' >/dev/null 2>&1
  floor "$tmp/ev" targets add 'https://github.com/acme/ev.git' main >/dev/null 2>&1
  floor "$tmp/ev" open >/dev/null 2>&1

  is "a gate that passes is recorded, and the exit code carries" \
     "$(code_of floor "$tmp/ev" evidence record aside true)" "0"
  is "a gate that fails is recorded too, and so does that" \
     "$(code_of floor "$tmp/ev" evidence record apart false)" "1"

  held=$(floor "$tmp/ev" evidence)
  matches "the passing record says machine, and zero" "$held" "machine.*aside.*	0	"
  matches "the failing record says machine, and one"  "$held" "machine.*apart.*	1	"
  matches "each record names the ref it applies to"   "$held" "	[0-9a-f]{40}	"

  # The shape is the artifact, and nothing reads it yet. Seven fields, in the order §2.5 names.
  is "every record has seven fields" \
     "$(printf '%s\n' "$held" | awk -F'\t' 'NF != 7' | grep -c .)" "0"
  matches "and they are in order — at, trust, unit, name, result, ref" \
          "$held" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z	machine	01	aside	0	[0-9a-f]{40}"
}
evidence_is_what_happened

#
# A name is one line. A newline in it writes a second record whose result and ref the caller chose —
# the one thing this stage exists to make impossible, arrived at through the field that was not
# flattened.
#
a_name_cannot_forge_a_second_record() {

#
# A clause pinned to a command is that command's to answer.
#
# `evidence record gates true` ran `true`, stamped a machine pass under the gate's name, and
# `satisfied` took it. A run that never ran its gate reached complete = 0 — with no
# failing row to contradict it, one honest record stood for a different command.
#
a_pinned_name_is_not_recordable() {
  make_repo "$tmp/ev7" main && set_origin "$tmp/ev7" 'https://github.com/acme/ev7.git' \n    && mkdir -p "$tmp/ev7/.foundry" \n    && commit_file "$tmp/ev7" .foundry/gates 'tests  false
' || { skip "a pinned name — git could not make a repo here"; return; }

  floor "$tmp/ev7" new "Pinned" >/dev/null
  floor "$tmp/ev7" charter derive >/dev/null 2>&1
  floor "$tmp/ev7" policy authorize 'https://github.com/acme/ev7.git' >/dev/null 2>&1
  floor "$tmp/ev7" targets add 'https://github.com/acme/ev7.git' main >/dev/null 2>&1
  floor "$tmp/ev7" open >/dev/null 2>&1

  is "a name the charter pins to a gate is refused" \
     "$(code_of floor "$tmp/ev7" evidence record tests true)" "2"
  has "and says which command owns it" \
      "$(floor_says "$tmp/ev7" evidence record tests true)" "only \`gates\` may answer it"
  is "so nothing was written" "$(floor "$tmp/ev7" evidence)" ""

  # The verb exists for a check no gate expresses, and that is untouched.
  is "a name it does not pin is still recordable" \
     "$(code_of floor "$tmp/ev7" evidence record "a check no gate expresses" true)" "0"
}
a_pinned_name_is_not_recordable

#
# A gate a signal killed is not a gate that failed. The ledger is append-only,
# so a row saying it failed spends that commit for good and the
# work has to move to a new one to be gradeable at all.
#
a_killed_gate_is_not_a_failed_one() {
  make_repo "$tmp/kg" main && set_origin "$tmp/kg" 'https://github.com/acme/kg.git' \
    && mkdir -p "$tmp/kg/.foundry" \
    && commit_file "$tmp/kg" .foundry/gates 'tests  true
' || { skip "a killed gate — git could not make a repo here"; return; }

  floor "$tmp/kg" new "Killed" >/dev/null
  floor "$tmp/kg" charter derive >/dev/null 2>&1
  floor "$tmp/kg" policy authorize 'https://github.com/acme/kg.git' >/dev/null 2>&1
  floor "$tmp/kg" targets add 'https://github.com/acme/kg.git' main >/dev/null 2>&1
  floor "$tmp/kg" open >/dev/null 2>&1

  is "a gate a signal killed answers 21, not a result" \
     "$(code_of floor "$tmp/kg" evidence record "a check no gate expresses" sh -c 'kill -TERM $$')" "21"
  has "and names the signal"  \
      "$(floor_says "$tmp/kg" evidence record "a check no gate expresses" sh -c 'kill -TERM $$')" "signal 15"
  is "and records nothing"    "$(floor "$tmp/kg" evidence)" ""

  # A gate that fails must still spend the ref. That is the completion invariant, and widening the
  # guard past a signal would take it away.
  is "a gate that answers badly is still recorded" \
     "$(code_of floor "$tmp/kg" evidence record "a check no gate expresses" false)" "1"
  matches "with the result it gave" "$(floor "$tmp/kg" evidence)" "	1	"
}
a_killed_gate_is_not_a_failed_one

#
# An idea outside this run's bar is recorded, never a blocker. A run that
# widened itself to act on one would be doing work nobody
# selected, and one that dropped it loses what it learned.
#
an_aside_is_kept_and_blocks_nothing() {
  make_repo "$tmp/as" main && set_origin "$tmp/as" 'https://github.com/acme/as.git' \
    && mkdir -p "$tmp/as/.foundry" \
    && commit_file "$tmp/as" .foundry/gates 'tests  true
' || { skip "an aside — git could not make a repo here"; return; }

  floor "$tmp/as" new "Aside" >/dev/null
  floor "$tmp/as" charter derive >/dev/null 2>&1
  floor "$tmp/as" policy authorize 'https://github.com/acme/as.git' >/dev/null 2>&1
  floor "$tmp/as" targets add 'https://github.com/acme/as.git' main >/dev/null 2>&1
  floor "$tmp/as" open >/dev/null 2>&1

  asrun=$(basename "$(floor "$tmp/as" path)")
  lacks "a run with nothing set aside contributes nothing" "$(floor "$tmp/as" aside)" "$asrun"

  floor "$tmp/as" aside 'the identity rule admits no offline address' >/dev/null 2>&1
  has "and one it kept comes back" "$(floor "$tmp/as" aside)" "no offline address"
  matches "with the run, then when it was set aside" "$(floor "$tmp/as" aside)" "^[^	]+	[0-9]{4}-[0-9]{2}-[0-9]{2}T"

  # The whole point. An aside is not a clause, not evidence and not a grant.
  is "it satisfies nothing"  "$(code_of floor "$tmp/as" complete)" "15"
  is "and grades nothing"    "$(floor "$tmp/as" evidence)" ""

  floor "$tmp/as" gates >/dev/null 2>&1
  is "and a run holding one still completes" "$(code_of floor "$tmp/as" complete)" "0"

  # A second is a second line, because two things learned are two things.
  floor "$tmp/as" aside 'a worktree is not a safe place to grade' >/dev/null 2>&1
  is "two set aside are two lines" \
     "$(floor "$tmp/as" aside | grep -c "^$asrun	")" "2"
}
an_aside_is_kept_and_blocks_nothing

#
# An aside is written for whoever comes next, so a reader who can see one run's has been shown the
# least useful half. Measured before this existed: one aside across every run ever made here, and
# nobody had read it.
#
an_aside_outlives_the_run_that_wrote_it() {
  make_repo "$tmp/as1" main && set_origin "$tmp/as1" 'https://gitlab.com/acme/as1.git' \
    && make_repo "$tmp/as2" main && set_origin "$tmp/as2" 'https://gitlab.com/acme/as2.git' \
    || { skip "asides — git could not make a repo here"; return; }

  first=$(floor "$tmp/as1" new "First")
  floor "$tmp/as1" aside "a worktree is not a safe place to grade" >/dev/null 2>&1

  second=$(floor "$tmp/as2" new "Second")
  floor "$tmp/as2" aside "the second run learned something else" >/dev/null 2>&1

  said=$(floor "$tmp/as2" aside)
  has "a later run reads what an earlier one set aside" "$said" "not a safe place to grade"
  has "and its own"                                     "$said" "learned something else"
  has "and each row names the run it came from"         "$said" "$(basename "$first")"

  # An aside is not a clause, not evidence and not a grant. Reading every run's changes none of that.
  is "reading them all grants nothing"  "$(floor "$tmp/as2" policy)" "$(floor "$tmp/as2" policy)"
  is "and satisfies nothing"            "$(floor "$tmp/as2" evidence)" ""

  # A run that set none still reads the others. The verb answers about the tree, never about one run.
  third=$(floor "$tmp/as1" new "Third")
  has "a run that set none still reads the rest" "$(floor "$tmp/as1" aside)" "$(basename "$second")"
}
an_aside_outlives_the_run_that_wrote_it

#
# Something happened, recorded. Not evidence, not a grant, and not a clause —
# the ledger beside it answers whether a bar was met,
# and this answers only that a thing occurred.
#
an_observation_is_not_evidence() {
  make_repo "$tmp/ob" main && set_origin "$tmp/ob" 'https://github.com/acme/ob.git' \
    && mkdir -p "$tmp/ob/.foundry" \
    && commit_file "$tmp/ob" .foundry/gates 'tests  true
' || { skip "an observation — git could not make a repo here"; return; }

  floor "$tmp/ob" new "Observed" >/dev/null
  floor "$tmp/ob" charter derive >/dev/null 2>&1
  floor "$tmp/ob" policy authorize 'https://github.com/acme/ob.git' >/dev/null 2>&1
  floor "$tmp/ob" targets add 'https://github.com/acme/ob.git' main >/dev/null 2>&1
  floor "$tmp/ob" open >/dev/null 2>&1

  has "a fresh run has already recorded that it began" "$(floor "$tmp/ob" observe)" "run.began"

  floor "$tmp/ob" observe gate.finished result=pass unit=01 >/dev/null 2>&1
  matches "a record says when, where and what" "$(floor "$tmp/ob" observe)" \
          "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z	[^	]+	gate.finished	"
  has "and carries the fields it was given" "$(floor "$tmp/ob" observe)" "result=pass unit=01"

  # Recording that a gate finished says a gate finished. Completion still refuses,
  # because satisfying a clause wants a trusted producer, a ref and a
  # clause — and an observation carries none of the three.
  is "and satisfies nothing"  "$(code_of floor "$tmp/ob" complete)" "15"
  is "and grades nothing"     "$(floor "$tmp/ob" evidence)" ""

  # An event nobody gave a session, a worker or a target is still an event.
  floor "$tmp/ob" observe session.attached >/dev/null 2>&1
  has "a record naming nothing else is still one" "$(floor "$tmp/ob" observe)" "session.attached"

  is "a field that is not key=value refuses" \
     "$(code_of floor "$tmp/ob" observe bad.field notakeyvalue)" "2"
  is "an event holding a newline refuses" \
     "$(code_of floor "$tmp/ob" observe "$(printf 'two\nlines')")" "2"
  is "a row too long to land whole refuses" \
     "$(code_of floor "$tmp/ob" observe long.row "note=$(head -c 4100 /dev/zero | tr '\0' 'x')")" "2"

  # Twenty writers at once, and twenty whole rows. The property is the atomic append
  # rather than this count, and the count is what would notice
  # if the rows grew past it.
  before=$(floor "$tmp/ob" observe | grep -c .)
  i=0
  while [ "$i" -lt 20 ]; do floor "$tmp/ob" observe "race.$i" n="$i" >/dev/null 2>&1 & i=$((i + 1)); done
  wait

  is "twenty writers leave twenty whole rows" \
     "$(floor "$tmp/ob" observe | grep -c .)" "$((before + 20))"
  is "and none of them tore" \
     "$(floor "$tmp/ob" observe | awk -F'\t' 'NF != 4' | grep -c .)" "0"
}
an_observation_is_not_evidence
  make_repo "$tmp/ev4" main && set_origin "$tmp/ev4" 'https://github.com/acme/ev4.git' \
    && mkdir -p "$tmp/ev4/.foundry" \
    && commit_file "$tmp/ev4" .foundry/gates 'tests  true
' || { skip "forged record — git could not make a repo here"; return; }

  floor "$tmp/ev4" new "Forge" >/dev/null
  floor "$tmp/ev4" charter derive >/dev/null 2>&1
  floor "$tmp/ev4" policy authorize 'https://github.com/acme/ev4.git' >/dev/null 2>&1
  floor "$tmp/ev4" targets add 'https://github.com/acme/ev4.git' main >/dev/null 2>&1
  floor "$tmp/ev4" open >/dev/null 2>&1

  forged='tests	0	deadbeef
types'
  is "a name holding a newline is refused" \
     "$(code_of floor "$tmp/ev4" evidence record "$forged" true)" "2"
  is "and nothing was written" "$(floor "$tmp/ev4" evidence)" ""
}
a_name_cannot_forge_a_second_record

#
# The ref is taken before the command runs. A gate that commits would otherwise be recorded against a
# tree that did not exist when it was graded.
#
the_ref_is_what_was_tested() {
  make_repo "$tmp/ev5" main && set_origin "$tmp/ev5" 'https://github.com/acme/ev5.git' \
    && mkdir -p "$tmp/ev5/.foundry" \
    && commit_file "$tmp/ev5" .foundry/gates 'tests  true
' || { skip "ref timing — git could not make a repo here"; return; }

  floor "$tmp/ev5" new "Timing" >/dev/null
  floor "$tmp/ev5" charter derive >/dev/null 2>&1
  floor "$tmp/ev5" policy authorize 'https://github.com/acme/ev5.git' >/dev/null 2>&1
  floor "$tmp/ev5" targets add 'https://github.com/acme/ev5.git' main >/dev/null 2>&1
  floor "$tmp/ev5" open >/dev/null 2>&1
  was=$(git -C "$tmp/ev5" rev-parse HEAD 2>/dev/null)

  floor "$tmp/ev5" evidence record "a check no gate expresses" sh -c \
    "cd '$tmp/ev5' && date > moved && git add -A && git -c user.email=a@b.c -c user.name=a commit -qm moved" \
    >/dev/null 2>&1

  has "the record names the ref that was tested" "$(floor "$tmp/ev5" evidence)" "$was"
}
the_ref_is_what_was_tested

#
# A repository with no commit has nothing to record evidence against. Refused, rather than stamped
# with an empty ref — §2.5's completion invariant matches records to a delivered sha, and a record
# holding none would sit in the ledger looking like one that can be matched.
#
a_record_needs_a_commit_to_apply_to() {
  make_repo "$tmp/ev6" main && set_origin "$tmp/ev6" 'https://github.com/acme/ev6.git' \
    || { skip "unborn HEAD — git could not make a repo here"; return; }

  floor "$tmp/ev6" new "Unborn" >/dev/null

  # A repository with no commit cannot be cloned, so it can hold no workspace, so nothing can be
  # recorded from one. The refusal moved when the tree did: `attached` proves a HEAD before a record
  # is written, which is why nothing downstream tests for a missing one any more.
  is  "a gate recorded before the first commit is refused" \
      "$(code_of floor "$tmp/ev6" evidence record tests true)" "16"
  has "and says why" \
      "$(floor_says "$tmp/ev6" evidence record tests true)" "no workspace holds"
  is  "and nothing was written" "$(floor "$tmp/ev6" evidence)" ""
}
a_record_needs_a_commit_to_apply_to

#
# The property that makes it evidence. There is no argument for a result, so the only way to record a
# pass is to pass — `record()` in §2.5 takes a command and no outcome.
#
a_result_is_not_something_you_pass() {
  make_repo "$tmp/ev2" main && set_origin "$tmp/ev2" 'https://github.com/acme/ev2.git' \
    && mkdir -p "$tmp/ev2/.foundry" \
    && commit_file "$tmp/ev2" .foundry/gates 'tests  true
' || { skip "no result parameter — git could not make a repo here"; return; }

  floor "$tmp/ev2" new "No Claim" >/dev/null
  floor "$tmp/ev2" charter derive >/dev/null 2>&1
  floor "$tmp/ev2" policy authorize 'https://github.com/acme/ev2.git' >/dev/null 2>&1
  floor "$tmp/ev2" targets add 'https://github.com/acme/ev2.git' main >/dev/null 2>&1
  floor "$tmp/ev2" open >/dev/null 2>&1

  is  "a name with no command is refused" "$(code_of floor "$tmp/ev2" evidence record tests)" "2"
  has "and says why" "$(floor_says "$tmp/ev2" evidence record tests)" "a result is not something you pass"
  is  "and nothing was written" "$(floor "$tmp/ev2" evidence)" ""

  # What a caller trying to claim a pass actually gets: `0` is run as a command, and there is no such
  # command. The record says what happened, which is that nothing ran.
  floor "$tmp/ev2" evidence record tests 0 >/dev/null 2>&1
  lacks "a claimed result is never recorded as a pass" "$(floor "$tmp/ev2" evidence)" "	0	"
}
a_result_is_not_something_you_pass

#
# Why the command's own output is kept: a gate that failed and said nothing is a gate nobody can act
# on. Newlines are flattened because one record is one line.
#
a_failure_records_what_the_command_said() {
  make_repo "$tmp/ev3" main && set_origin "$tmp/ev3" 'https://github.com/acme/ev3.git' \
    && mkdir -p "$tmp/ev3/.foundry" \
    && commit_file "$tmp/ev3" .foundry/gates 'tests  true
' || { skip "failure detail — git could not make a repo here"; return; }

  floor "$tmp/ev3" new "Why" >/dev/null
  floor "$tmp/ev3" charter derive >/dev/null 2>&1
  floor "$tmp/ev3" policy authorize 'https://github.com/acme/ev3.git' >/dev/null 2>&1
  floor "$tmp/ev3" targets add 'https://github.com/acme/ev3.git' main >/dev/null 2>&1
  floor "$tmp/ev3" open >/dev/null 2>&1
  floor "$tmp/ev3" evidence record types sh -c 'printf "two\nerrors\n" >&2; exit 1' >/dev/null 2>&1

  held=$(floor "$tmp/ev3" evidence)
  has "the failure keeps what the command said" "$held" "two errors"
  is  "on one line, so one record stays one record" "$(printf '%s' "$held" | wc -l | tr -d ' ')" "0"
}
a_failure_records_what_the_command_said

#
# Gates — RFC-001 §2.4. The command comes from the charter, so a worker cannot name a gate and hand
# it something else to run. `evidence record tests true` writes a pass; this takes no such argument.
#
a_gate_runs_the_command_the_charter_pinned() {
  make_repo "$tmp/g1" main && set_origin "$tmp/g1" 'https://github.com/acme/g1.git' \
    && mkdir -p "$tmp/g1/.foundry" \
    && commit_file "$tmp/g1" .foundry/gates 'tests  true
' || { skip "gates — git could not make a repo here"; return; }

  floor "$tmp/g1" new "Gates" >/dev/null
  floor "$tmp/g1" charter derive >/dev/null 2>&1
  floor "$tmp/g1" policy authorize 'https://github.com/acme/g1.git' >/dev/null 2>&1
  floor "$tmp/g1" targets add 'https://github.com/acme/g1.git' main >/dev/null 2>&1
  floor "$tmp/g1" open >/dev/null 2>&1

  is "a charter whose gates all pass answers 0" "$(code_of floor "$tmp/g1" gates)" "0"

  held=$(floor "$tmp/g1" evidence)
  matches "the record is machine trust, in the charter's words" "$held" "	machine	01	tests	0	"
  matches "and names the ref it applies to" "$held" "	[0-9a-f]{40}	"

  is "and no command is taken from the caller" "$(code_of floor "$tmp/g1" gates true)" "2"
}
a_gate_runs_the_command_the_charter_pinned

#
# A gate that fails is recorded, and the exit code says so. Recording only the passes would leave a
# run that looks unanswered rather than one that was answered badly.
#
a_failing_gate_is_recorded_and_answered() {
  make_repo "$tmp/g2" main && set_origin "$tmp/g2" 'https://github.com/acme/g2.git' \
    && mkdir -p "$tmp/g2/.foundry" \
    && commit_file "$tmp/g2" .foundry/gates 'tests  false
' || { skip "failing gate — git could not make a repo here"; return; }

  floor "$tmp/g2" new "Red" >/dev/null
  floor "$tmp/g2" charter derive >/dev/null 2>&1
  floor "$tmp/g2" policy authorize 'https://github.com/acme/g2.git' >/dev/null 2>&1
  floor "$tmp/g2" targets add 'https://github.com/acme/g2.git' main >/dev/null 2>&1
  floor "$tmp/g2" open >/dev/null 2>&1

  is "a gate that did not pass answers 14" "$(code_of floor "$tmp/g2" gates)" "14"
  matches "and is recorded with what it returned" "$(floor "$tmp/g2" evidence)" "	tests	1	"
}
a_failing_gate_is_recorded_and_answered



#
# The other direction, and the one a substitution gets wrong. **The work is what is graded.** Check
# out the base tree instead of planting the base blob in this one, and the gate grades a repository
# the run never wrote to — where nothing it did can fail, and every run passes.
#
# The base gate asks for a file only the run adds, so it passes for one reason: the base's script
# ran, and it ran against the work.
#
the_substituted_tree_still_holds_the_work() {
  make_repo "$tmp/sub2" main && set_origin "$tmp/sub2" 'https://github.com/acme/sub2.git' \
    && commit_file "$tmp/sub2" check.sh 'test -f added
' && mkdir -p "$tmp/sub2/.foundry" \
    && commit_file "$tmp/sub2" .foundry/gates 'tests  sh check.sh
' || { skip "the work is graded — git could not make a repo here"; return; }

  floor "$tmp/sub2" new "Both" >/dev/null
  floor "$tmp/sub2" charter derive >/dev/null 2>&1
  floor "$tmp/sub2" policy authorize 'https://github.com/acme/sub2.git' >/dev/null 2>&1
  floor "$tmp/sub2" targets add 'https://github.com/acme/sub2.git' main >/dev/null 2>&1
  work=$(only_slot "$(floor "$tmp/sub2" open)")

  is "the base's gate wants what the base does not hold" "$(code_of floor "$tmp/sub2" gates)" "14"

  printf 'ok\n' > "$work/added"
  printf 'exit 1
' > "$work/check.sh"
  git -C "$work" add added
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "the work, and a gate that refuses it"

  is "and the run's work satisfies it, through the base's own script" \
     "$(code_of floor "$tmp/sub2" gates)" "0"
}
the_substituted_tree_still_holds_the_work

#
# A command names one file and reaches others. `sh check.sh` pins nothing about `deeper.sh`, so a run
# rewriting the second file lowered the bar and every pin still matched.
#
# Three deep, because a fixed point is the claim. Two would pass with one step.
#
# `notes.md` is the other half. The base's gate reads it and nothing runs it, so it is the run's own
# work — restoring it would grade this run against a tree it never wrote to.
#
a_gate_grades_from_the_base_however_deep_it_reaches() {
  make_repo "$tmp/cl" main && set_origin "$tmp/cl" 'https://github.com/acme/cl.git' \
    && commit_file "$tmp/cl" check.sh 'sh deeper.sh
' && commit_file "$tmp/cl" deeper.sh 'sh deepest.sh
' && commit_file "$tmp/cl" deepest.sh 'grep -q changed notes.md
' && commit_file "$tmp/cl" notes.md 'original
' && mkdir -p "$tmp/cl/.foundry" \
    && commit_file "$tmp/cl" .foundry/gates 'tests  sh check.sh
' || { skip "the closure — git could not make a repo here"; return; }

  floor "$tmp/cl" new "Closure" >/dev/null
  floor "$tmp/cl" charter derive >/dev/null 2>&1
  floor "$tmp/cl" policy authorize 'https://github.com/acme/cl.git' >/dev/null 2>&1
  floor "$tmp/cl" targets add 'https://github.com/acme/cl.git' main >/dev/null 2>&1
  work=$(only_slot "$(floor "$tmp/cl" open)")

  is "the gate three files down does not pass" "$(code_of floor "$tmp/cl" gates)" "14"

  # Nothing pins `deepest.sh` and no command names it. Two files stand between it and the charter.
  printf 'exit 0\n' > "$work/deepest.sh"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "a file the charter never named"

  is "and rewriting a file it reaches changes nothing" "$(code_of floor "$tmp/cl" gates)" "14"

  # What the gate reads rather than runs. The base's own `deepest.sh` asks for this, and it must see
  # what the run wrote.
  printf 'changed\n' > "$work/notes.md"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "the work the gate reads"

  is "while a file it only reads is still the run's own work" "$(code_of floor "$tmp/cl" gates)" "0"

  # A gate that fails while the run changed a file it runs. The two facts were reported apart, so a
  # gate passing by hand and failing here read as a mystery.
  #
  # The gate has to fail for its own reason: rewriting the file it runs cannot do it, because that
  # file is the one restored.
  printf 'exit 1\n' > "$work/deepest.sh"
  printf 'original\n'  > "$work/notes.md"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "a file the gate runs, and one it reads"

  said=$(floor_says "$tmp/cl" gates)
  has "a failed gate names what came from the base" "$said" "changed a file its own gates run"
  has "and which file it was"                       "$said" "deepest.sh"
  has "and that a bar change is a person's"         "$said" "landed by a person"

  # Said on stderr it died with the run, and a reader re-running the gate at the delivered ref ran a
  # file this run rewrote. They got another exit code and
  # read an honest record as a forged one.
  run=$(floor "$tmp/cl" path)
  has "the record keeps it too" "$(cat "$run/substitutions" 2>/dev/null)" "deepest.sh"

  # `mktemp` built the index here and is not POSIX, while floor declares `sh`, `awk` and `git`. It
  # also made a file only to delete it and keep the name, which is the race refused everywhere else.
  lacks "core reaches for no mktemp" \
        "$(grep -v '^[[:space:]]*#' "$here/bin/run.sh")" "mktemp"
  is "and the index it used is not left behind" \
     "$(ls "$run" | grep -c '^gates-index$')" "0"

  # #313 says a cold reader answers with `ls` and `cat`, so a file the layout never names is one
  # they find and cannot read. Four sat there unnamed: `kind`, `gates-tree`, `asides` and
  # `reconcile-tree`.
  #
  # Read from the code, not from a fixture. Listing a run only tests the names that run happens to
  # hold, and the first version of this check passed with `kind` deleted from the README for exactly
  # that reason.
  #
  # `foundry-run` lives in the checkout's `.git`, and `gates-index` is removed after use. Neither is
  # a run's file, and both are named here so a reader knows they were considered.
  layout=$(sed -n '/^\${FOUNDRY_HOME/,/^```$/p' "$here/README.md")
  unnamed=''
  for held in $(grep -oE "printf '%s/[a-z-]+'" "$here/bin/run.sh" | sed "s|printf '%s/||;s|'||" | sort -u); do
      case "$held" in foundry-run|gates-index) continue ;; esac
      case "$layout" in *"$held"*) ;; *) unnamed="$unnamed $held" ;; esac
  done
  is "every file floor can write is named in the README" "$unnamed" ""
  is  "and names a base the reader can diff against" \
      "$(git -C "$tmp/cl" cat-file -t "$(cut -f1 "$run/substitutions" 2>/dev/null)" 2>/dev/null)" "commit"

  # The quiet half. Nearly every run that substitutes something passes anyway, and a note on each of
  # those is a note people learn to skip.
  printf 'changed\n' > "$work/notes.md"
  printf 'exit 0\n' > "$work/deepest.sh"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "and it passes again"

  lacks "a gate that passed says none of it" "$(floor_says "$tmp/cl" gates)" "landed by a person"

  # A run that puts a gate back substituted nothing, and the last grading's file would say otherwise.
  printf 'grep -q changed notes.md\n' > "$work/deepest.sh"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "the gate, as the base wrote it"
  floor "$tmp/cl" gates >/dev/null 2>&1

  is "putting a gate back clears the record of it" \
     "$(ls "$(floor "$tmp/cl" path)" | grep -c '^substitutions$')" "0"
}
a_gate_grades_from_the_base_however_deep_it_reaches

#
# One ref for the whole set. A gate that commits would otherwise move the tree the gates after it are
# recorded against, and the ledger would name a sha nobody gated.
#
every_gate_is_recorded_against_one_ref() {
  make_repo "$tmp/g3" main && set_origin "$tmp/g3" 'https://github.com/acme/g3.git' \
    && mkdir -p "$tmp/g3/.foundry" \
    && commit_file "$tmp/g3" .foundry/gates 'first   git -c user.email=a@b.c -c user.name=a commit -q --allow-empty -m moved
second  true
' || { skip "one ref — git could not make a repo here"; return; }

  floor "$tmp/g3" new "OneRef" >/dev/null
  floor "$tmp/g3" charter derive >/dev/null 2>&1
  floor "$tmp/g3" policy authorize 'https://github.com/acme/g3.git' >/dev/null 2>&1
  floor "$tmp/g3" targets add 'https://github.com/acme/g3.git' main >/dev/null 2>&1
  floor "$tmp/g3" open >/dev/null 2>&1
  was=$(git -C "$tmp/g3" rev-parse HEAD 2>/dev/null)

  floor "$tmp/g3" gates >/dev/null 2>&1

  held=$(floor "$tmp/g3" evidence)
  is  "two gates ran" "$(printf '%s\n' "$held" | awk -F'\t' 'NF == 7' | grep -c .)" "2"
  is  "and named one ref between them" \
      "$(printf '%s\n' "$held" | awk -F'\t' 'NF == 7 { print $6 }' | sort -u | grep -c .)" "1"
  has "which is the tree they were asked about" "$held" "$was"

  # An absent file is the claim that nothing was substituted, and it is the ordinary case. Writing
  # one every time would teach a reader to skip it.
  is "a run that changed no gate leaves no substitutions" \
     "$(ls "$(floor "$tmp/g3" path)" | grep -c '^substitutions$')" "0"
}
every_gate_is_recorded_against_one_ref

#
# A moved pin is a command nobody authorised, and evidence for it would be indistinguishable from
# evidence for the one they did. So nothing runs, and nothing is written.
#
a_drifted_charter_gates_nothing() {
  make_repo "$tmp/g4" main && set_origin "$tmp/g4" 'https://github.com/acme/g4.git' \
    && mkdir -p "$tmp/g4/.foundry" \
    && commit_file "$tmp/g4" .foundry/gates 'tests  true
' || { skip "drift — git could not make a repo here"; return; }

  floor "$tmp/g4" new "Drift" >/dev/null
  floor "$tmp/g4" charter derive >/dev/null 2>&1
  floor "$tmp/g4" policy authorize 'https://github.com/acme/g4.git' >/dev/null 2>&1
  floor "$tmp/g4" targets add 'https://github.com/acme/g4.git' main >/dev/null 2>&1
  floor "$tmp/g4" open >/dev/null 2>&1

  printf 'tests  false\n' > "$tmp/g4/.foundry/gates"

  is "a charter that drifted from its pins gates nothing" "$(code_of floor "$tmp/g4" gates)" "7"
  is "and records nothing"                               "$(floor "$tmp/g4" evidence)" ""
}
a_drifted_charter_gates_nothing

#
# §2.4: a gate runs with its target's checkout as the working directory. Standing one level down is
# how the ambiguity shows up with a single target — the gate reads a path relative to the root.
#
a_gate_runs_at_the_targets_root() {
  make_repo "$tmp/g5" main && set_origin "$tmp/g5" 'https://github.com/acme/g5.git' \
    && mkdir -p "$tmp/g5/.foundry" "$tmp/g5/deep" \
    && commit_file "$tmp/g5" .foundry/gates 'tests  test -f .foundry/gates
' || { skip "gate cwd — git could not make a repo here"; return; }

  floor "$tmp/g5" new "Deep" >/dev/null
  floor "$tmp/g5" charter derive >/dev/null 2>&1
  floor "$tmp/g5" policy authorize 'https://github.com/acme/g5.git' >/dev/null 2>&1
  floor "$tmp/g5" targets add 'https://github.com/acme/g5.git' main >/dev/null 2>&1
  floor "$tmp/g5" open >/dev/null 2>&1

  is "a gate run from a subdirectory still passes" "$(code_of floor "$tmp/g5/deep" gates)" "0"
}
a_gate_runs_at_the_targets_root

#
# A command pinned under an id the charter names no clause for. `check` cannot see it — it reads the
# detector's gates, and the detector yields nothing once the declaration is gone. So the gate stage
# refuses it itself, rather than stamp a record whose name field is empty and whose bar is unknowable.
#
a_record_that_answers_to_nothing_is_caught() {
  make_repo "$tmp/g6" main && set_origin "$tmp/g6" 'https://github.com/acme/g6.git' \
    && mkdir -p "$tmp/g6/.foundry" \
    && commit_file "$tmp/g6" .foundry/gates 'tests  true
' || { skip "unsound records — git could not make a repo here"; return; }

  d=$(floor "$tmp/g6" new "Hollow")
  floor "$tmp/g6" charter derive >/dev/null 2>&1
  floor "$tmp/g6" policy authorize 'https://github.com/acme/g6.git' >/dev/null 2>&1
  floor "$tmp/g6" targets add 'https://github.com/acme/g6.git' main >/dev/null 2>&1
  floor "$tmp/g6" open >/dev/null 2>&1
  sound=$(cat "$(charter_of "$d")")
  id=$(awk '$1 == "gate" { print $2; exit }' "$(charter_of "$d")")

  # Each tamper on its own, against the charter that derived cleanly. The reader is one awk pass, so
  # a finding that answered for another would say so in its own word.
  tamper() { printf '%s\n' "$sound" > "$(charter_of "$d")"; printf '%s\n' "$1" >> "$(charter_of "$d")"; }

  tamper "gate $id false"
  has "a second command under one id is named" "$(floor "$tmp/g6" charter check 2>&1)" "repeated: gate $id"

  # `0$id` is the same number and a different string. `has_record` compared numerically and a
  # subscript compares as text, so this was pinned to one reader and unheard of by the other.
  tamper "gate 0$id false"
  has "a leading zero is a different gate" "$(floor "$tmp/g6" charter check 2>&1)" "unprovenanced: gate 0$id"

  rogue=$(printf '%s' rogue | cksum | awk '{ print $1 }')
  tamper "clause $rogue Gate rogue
gate $rogue false"
  has "a clause invented whole is named" "$(floor "$tmp/g6" charter check 2>&1)" "unprovenanced: gate $rogue"

  tamper "gate $rogue false"
  has "a gate with no clause is named" "$(floor "$tmp/g6" charter check 2>&1)" "unclaused: gate $rogue"

  tamper "clause $rogue Judged someone read it
pin $rogue $(awk '$1 == "pin" { print $3, $4, $5, $6; exit }' <<EOF
$sound
EOF
)
gate $rogue false"
  has "a gate resting on a clause no command can hold is named" \
      "$(floor "$tmp/g6" charter check 2>&1)" "notagate: Judged $rogue"

  tamper "gate $id false"
  is  "and none of them runs"  "$(code_of floor "$tmp/g6" gates)" "7"
  is  "nor records anything"   "$(floor "$tmp/g6" evidence)" ""
}
a_record_that_answers_to_nothing_is_caught

#
# A gate that names itself and nothing else. `sh -c ""` exits 0, so this would record a pass for a
# bar that runs nothing — and it is one typo in `.foundry/gates` away, not a hand-edited charter.
#
a_gate_with_no_command_is_refused() {
  make_repo "$tmp/g7" main && set_origin "$tmp/g7" 'https://github.com/acme/g7.git' \
    && mkdir -p "$tmp/g7/.foundry" \
    && commit_file "$tmp/g7" .foundry/gates 'tests
' || { skip "empty command — git could not make a repo here"; return; }

  floor "$tmp/g7" new "Empty" >/dev/null

  is "a gate naming no command still derives" "$(code_of floor "$tmp/g7" charter derive)" "0"
  floor "$tmp/g7" policy authorize 'https://github.com/acme/g7.git' >/dev/null 2>&1
  floor "$tmp/g7" targets add 'https://github.com/acme/g7.git' main >/dev/null 2>&1
  floor "$tmp/g7" open >/dev/null 2>&1
  # Its own assertion, or the refusal below could come from `check` calling this drift and the guard
  # that refuses an empty command would never run.
  is "and reads as no drift, not as a moved resolution" \
     "$(code_of floor "$tmp/g7" charter check)" "0"
  is "but is refused rather than run"         "$(code_of floor "$tmp/g7" gates)" "7"
  is "so no pass is recorded for it"          "$(floor "$tmp/g7" evidence)" ""
}
a_gate_with_no_command_is_refused

#
# The pin list is the loop's stdin, so a gate that reads stdin eats the gates after it: they never
# run, are never recorded, and the run answers 0. A gate not run must never read as one that passed.
#
a_gate_cannot_eat_the_gates_after_it() {
  make_repo "$tmp/g8" main && set_origin "$tmp/g8" 'https://github.com/acme/g8.git' \
    && mkdir -p "$tmp/g8/.foundry" \
    && commit_file "$tmp/g8" .foundry/gates 'greedy  cat
second  true
' || { skip "stdin — git could not make a repo here"; return; }

  floor "$tmp/g8" new "Greedy" >/dev/null
  floor "$tmp/g8" charter derive >/dev/null 2>&1
  floor "$tmp/g8" policy authorize 'https://github.com/acme/g8.git' >/dev/null 2>&1
  floor "$tmp/g8" targets add 'https://github.com/acme/g8.git' main >/dev/null 2>&1
  floor "$tmp/g8" open >/dev/null 2>&1
  floor "$tmp/g8" gates >/dev/null 2>&1

  held=$(floor "$tmp/g8" evidence)
  is  "a gate that reads stdin does not consume the ones after it" \
      "$(printf '%s\n' "$held" | awk -F'\t' 'NF == 7' | grep -c .)" "2"
  has "so the gate behind it is recorded" "$held" "	second	"
}
a_gate_cannot_eat_the_gates_after_it

#
# A clause with no words. `clause_id ""` is a value like any other, so its id was honestly made from
# the text it has and `forged_ids` passes it — leaving the gate stage the only thing that can refuse
# a record named whitespace.
#
a_clause_with_no_text_names_no_gate() {
  make_repo "$tmp/g9" main && set_origin "$tmp/g9" 'https://github.com/acme/g9.git' \
    && mkdir -p "$tmp/g9/.foundry" \
    && commit_file "$tmp/g9" NOTES 'kept
' && commit_file "$tmp/g9" .foundry/gates 'tests  true
' || { skip "blank clause — git could not make a repo here"; return; }

  d=$(floor "$tmp/g9" new "Blank")
  floor "$tmp/g9" charter derive >/dev/null 2>&1
  floor "$tmp/g9" policy authorize 'https://github.com/acme/g9.git' >/dev/null 2>&1
  floor "$tmp/g9" targets add 'https://github.com/acme/g9.git' main >/dev/null 2>&1
  floor "$tmp/g9" open >/dev/null 2>&1
  target=$(awk '$1 == "pin" { print $3; exit }' "$(charter_of "$d")")
  ref=$(awk '$1 == "pin" { print $4; exit }' "$(charter_of "$d")")

  # The declaration goes so the detector is silent, and the pin moves to a file that is still there
  # and still matches — local, so `check` verifies it and says nothing, and the name is what refuses
  # rather than the provenance. 4294967295 is `printf '' | cksum`.
  rm -f "$tmp/g9/.foundry/gates"
  printf 'clause 4294967295 Gate \npin 4294967295 %s %s NOTES %s\ngate 4294967295 true\n' \
    "$target" "$ref" "$(git -C "$tmp/g9" hash-object NOTES)" > "$(charter_of "$d")"

  is "a clause whose id was made from no text is not forged" \
     "$(code_of floor "$tmp/g9" charter check)" "0"
  is "and the gate under it is refused rather than run" \
     "$(code_of floor "$tmp/g9" gates)" "7"
  is "so nothing is recorded" "$(floor "$tmp/g9" evidence)" ""
}
a_clause_with_no_text_names_no_gate

#
# A pin's target is self-asserted, and `moved_sources` reports a foreign one uncheckable rather than
# refusing it — right for asking whether the charter is sound, wrong for asking whether a gate can
# run. One checkout exists, so a gate pinned elsewhere has nowhere to run and no bar to be graded by.
#
a_gate_pinned_elsewhere_does_not_run_here() {
  make_repo "$tmp/ga" main && set_origin "$tmp/ga" 'https://github.com/acme/ga.git' \
    && mkdir -p "$tmp/ga/.foundry" \
    && commit_file "$tmp/ga" .foundry/gates 'tests  true
' || { skip "foreign pin — git could not make a repo here"; return; }

  d=$(floor "$tmp/ga" new "Elsewhere")
  floor "$tmp/ga" charter derive >/dev/null 2>&1
  floor "$tmp/ga" policy authorize 'https://github.com/acme/ga.git' >/dev/null 2>&1
  floor "$tmp/ga" targets add 'https://github.com/acme/ga.git' main >/dev/null 2>&1
  floor "$tmp/ga" open >/dev/null 2>&1

  rm -f "$tmp/ga/.foundry/gates"
  away=$(printf '%s' away | cksum | awk '{ print $1 }')
  printf 'clause %s Gate away\npin %s https://github.com/acme/other.git HEAD gone deadbeef\ngate %s true\n' \
    "$away" "$away" "$away" > "$(charter_of "$d")"

  is "a charter pinned to another repository is sound" \
     "$(code_of floor "$tmp/ga" charter check)" "0"
  is "and its gates are refused here"  "$(code_of floor "$tmp/ga" gates)" "7"
  is "so nothing is recorded"          "$(floor "$tmp/ga" evidence)" ""
}
a_gate_pinned_elsewhere_does_not_run_here

#
# Completion — RFC-001 §2.5. A run may deliver only when a human selected it, the charter holds a
# clause, a target is selected, and every clause has satisfying evidence at that target's delivered
# ref. One case, carried forward, with each conjunct met in turn.
#
a_run_completes_only_when_every_clause_is_evidenced() {
  make_repo "$tmp/cp" main && set_origin "$tmp/cp" 'https://github.com/acme/cp.git' \
    && mkdir -p "$tmp/cp/.foundry" \
    && commit_file "$tmp/cp" .foundry/gates 'tests  true
' || { skip "completion — git could not make a repo here"; return; }

  floor_new_as "$tmp/cp" ada@example.com "Complete" >/dev/null
  floor "$tmp/cp" charter derive >/dev/null 2>&1

  is  "a run with no target selected may not deliver" "$(code_of floor "$tmp/cp" complete)" "15"
  has "and says the selection is what is empty" "$(floor_says "$tmp/cp" complete)" "nothing selected"

  floor "$tmp/cp" policy authorize 'https://github.com/acme/cp.git' >/dev/null 2>&1
  floor "$tmp/cp" targets add 'https://github.com/acme/cp.git' main >/dev/null 2>&1
  floor "$tmp/cp" open >/dev/null 2>&1

  is  "a clause nothing has evidenced may not deliver" "$(code_of floor "$tmp/cp" complete)" "15"
  has "and names the clause"                     "$(floor_says "$tmp/cp" complete)" "unmet: [tests]"

  floor "$tmp/cp" gates >/dev/null 2>&1
  is "once the gate has run and passed, it may"  "$(code_of floor "$tmp/cp" complete)" "0"
  is "and has nothing left to say"               "$(floor "$tmp/cp" complete)" ""

  # The bar is met at a sha, not in general. This is the whole of what the invariant adds: gates
  # could pass at commit N, three commits land, and delivery proceed on evidence that no longer
  # applied.
  # The checkout Foundry was invoked from moving changes nothing: the gates graded the workspace, and
  # that is what completion reads. This is the isolation, stated as an outcome.
  commit_file "$tmp/cp" README 'later
'
  is "the source checkout moving does not unmake the delivery" \
     "$(code_of floor "$tmp/cp" complete)" "0"

  # The workspace moving does. A gate could pass at commit N, three commits land, and delivery
  # proceed on evidence that no longer applied.
  slot=$(only_slot "$(floor "$tmp/cp" open)")
  git -C "$slot" -c user.email=w@w.w -c user.name=w commit -q --allow-empty -m later >/dev/null 2>&1

  is  "a commit in the workspace after the gate ran makes it undeliverable again" \
      "$(code_of floor "$tmp/cp" complete)" "15"
  has "because the evidence names a sha this is not" \
      "$(floor_says "$tmp/cp" complete)" "unmet: [tests]"
}
a_run_completes_only_when_every_clause_is_evidenced

#
# Grading a repository and writing to one are different powers, and the allowlist only ever meant the
# first. `is_authorised` passes the bootstrap target because someone invoked Foundry there — standing
# in a repository is not permission to push to it, and a run that widened its own allowlist would
# otherwise have granted itself one.
#
delivering_somewhere_is_a_grant_of_its_own() {
  make_repo "$tmp/dl" main && set_origin "$tmp/dl" 'https://github.com/acme/dl.git' \
    || { skip "delivery grant — git could not make a repo here"; return; }

  floor_new_as "$tmp/dl" ada@example.com "Deliver" >/dev/null

  is "a delivery with nothing to call it is refused" \
     "$(code_of floor "$tmp/dl" deliver)" "2"

  is "the bootstrap target may be graded" \
     "$(code_of floor "$tmp/dl" targets add 'https://github.com/acme/dl.git' main)" "0"
  is  "and may not be delivered to" \
      "$(code_of floor "$tmp/dl" deliver 'a change')" "18"
  has "which says what is missing" \
      "$(floor_says "$tmp/dl" deliver 'a change')" "nobody said this run may deliver"

  floor "$tmp/dl" policy deliver-to 'https://github.com/acme/dl.git' >/dev/null 2>&1
  has "a delivery grant is listed apart from the allowlist" \
      "$(floor "$tmp/dl" policy)" "deliver"

  is "authorising a repo to be graded does not grant delivery" \
     "$(code_of floor "$tmp/dl" policy deliver-to 'https://github.com/acme/other.git')" "0"
  is  "and a repo nobody authorised at all is refused" \
      "$(code_of floor "$tmp/dl" policy deliver-to 'not-a-repo')" "4"
}
delivering_somewhere_is_a_grant_of_its_own

#
# Invariant 4 is a conjunct of the invariant, not a note beside it. A run nobody is recorded as
# having selected has no authority to deliver, however green its gates are.
#
a_run_nobody_selected_may_not_deliver() {
  make_repo "$tmp/cq" main && set_origin "$tmp/cq" 'https://github.com/acme/cq.git' \
    && mkdir -p "$tmp/cq/.foundry" \
    && commit_file "$tmp/cq" .foundry/gates 'tests  true
' || { skip "unauthorised delivery — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/cq" ada@example.com "Unclaimed")
  floor "$tmp/cq" charter derive >/dev/null 2>&1
  floor "$tmp/cq" policy authorize 'https://github.com/acme/cq.git' >/dev/null 2>&1
  floor "$tmp/cq" targets add 'https://github.com/acme/cq.git' main >/dev/null 2>&1
  floor "$tmp/cq" open >/dev/null 2>&1
  floor "$tmp/cq" gates >/dev/null 2>&1

  is "with every gate green it may deliver" "$(code_of floor "$tmp/cq" complete)" "0"

  rm -f "$d/authority"
  is  "and with nobody recorded as selecting it, it may not" \
      "$(code_of floor "$tmp/cq" complete)" "15"
  has "which is what it says" "$(floor_says "$tmp/cq" complete)" "unauthorised"
}
a_run_nobody_selected_may_not_deliver

#
# The publish seam carried a title, so every body was written by hand afterwards. A delivery that has
# to be edited into shape is one the seam did not carry, and the human surface then
# belongs to whoever remembered to run the second command.
#
a_delivery_carries_its_brief() {
  make_repo "$tmp/br" main && set_origin "$tmp/br" 'https://github.com/acme/br.git'     && mkdir -p "$tmp/br/.foundry"     && commit_file "$tmp/br" .foundry/gates 'tests  true
' || { skip "brief — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/br" ada@example.com "Brief")
  floor "$tmp/br" charter derive >/dev/null 2>&1
  floor "$tmp/br" policy authorize 'https://github.com/acme/br.git' >/dev/null 2>&1
  floor "$tmp/br" policy deliver-to 'https://github.com/acme/br.git' >/dev/null 2>&1
  floor "$tmp/br" targets add 'https://github.com/acme/br.git' main >/dev/null 2>&1
  floor "$tmp/br" open >/dev/null 2>&1
  floor "$tmp/br" gates >/dev/null 2>&1

  # A path that is not there is a lie, not an absent brief. One is a mistake and the other is a
  # legal choice, and a source told the first would write a body from nothing.
  is "a brief that is not there is refused"      "$(code_of floor "$tmp/br" deliver 'a change' "$tmp/br/nowhere")" "2"
  has "and it names the path it could not read"       "$(floor_says "$tmp/br" deliver 'a change' "$tmp/br/nowhere")" "no brief to read"

  printf 'Outcome

A reader knows what changed.
' > "$tmp/br-brief.md"
  floor "$tmp/br" deliver 'a change' "$tmp/br-brief.md" >/dev/null 2>&1

  has "the run keeps the brief it was handed" "$(cat "$d/brief" 2>/dev/null)" "A reader knows what changed"
}
a_delivery_carries_its_brief

#
# Two conjuncts that close fail-opens rather than edge cases. Quantified over clauses and over
# targets, the invariant is satisfied by an empty charter and by an empty selection — vacuously, and
# every fresh run has the second.
#
completion_refuses_what_is_only_vacuously_true() {
  make_repo "$tmp/cr" main && set_origin "$tmp/cr" 'https://github.com/acme/cr.git' \
    && mkdir -p "$tmp/cr/.foundry" \
    && commit_file "$tmp/cr" .foundry/gates 'tests  false
' || { skip "vacuous completion — git could not make a repo here"; return; }

  floor_new_as "$tmp/cr" ada@example.com "Vacuous" >/dev/null
  floor "$tmp/cr" policy authorize 'https://github.com/acme/cr.git' >/dev/null 2>&1
  floor "$tmp/cr" targets add 'https://github.com/acme/cr.git' main >/dev/null 2>&1
  floor "$tmp/cr" open >/dev/null 2>&1

  is  "a run with a target and no charter may not deliver" "$(code_of floor "$tmp/cr" complete)" "15"
  has "because nothing grades it" "$(floor_says "$tmp/cr" complete)" "nobar"

  # Opened after the charter exists, because `open` runs `authorise` and a run with no charter has
  # nothing to authorise.
  floor "$tmp/cr" charter derive >/dev/null 2>&1
  floor "$tmp/cr" open >/dev/null 2>&1
  floor "$tmp/cr" gates >/dev/null 2>&1

  is  "a gate that ran and failed leaves its clause unmet" "$(code_of floor "$tmp/cr" complete)" "15"
  has "and the record it wrote does not satisfy it" "$(floor_says "$tmp/cr" complete)" "unmet: [tests]"
}
completion_refuses_what_is_only_vacuously_true

#
# A clause nothing pinned is invariant 1's *introduced*. No ref can satisfy it, because no artifact
# established it — the answer that can is a human's, and the work source that would carry one does
# not exist. Until it does, such a run holds rather than delivers.
#
an_introduced_clause_holds_delivery() {
  make_repo "$tmp/cs" main && set_origin "$tmp/cs" 'https://github.com/acme/cs.git' \
    && mkdir -p "$tmp/cs/.foundry" \
    && commit_file "$tmp/cs" .foundry/gates 'tests  true
' || { skip "introduced clause — git could not make a repo here"; return; }

  floor_new_as "$tmp/cs" ada@example.com "Introduced" >/dev/null
  floor "$tmp/cs" charter derive >/dev/null 2>&1
  floor "$tmp/cs" policy authorize 'https://github.com/acme/cs.git' >/dev/null 2>&1
  floor "$tmp/cs" targets add 'https://github.com/acme/cs.git' main >/dev/null 2>&1
  floor "$tmp/cs" open >/dev/null 2>&1
  floor "$tmp/cs" gates >/dev/null 2>&1

  is "every derived clause evidenced, it may deliver" "$(code_of floor "$tmp/cs" complete)" "0"

  floor "$tmp/cs" charter introduce Decided "ship on friday" >/dev/null 2>&1

  is  "and a clause a human introduced holds it" "$(code_of floor "$tmp/cs" complete)" "15"
  has "named for why no ref can answer it" \
      "$(floor_says "$tmp/cs" complete)" "introduced: [ship on friday]"
}
an_introduced_clause_holds_delivery

#
# The workspace — one isolated checkout per selected target. Isolated means a clone: a worktree
# shares `.git` with the checkout it came from, so a worker could move the source's refs.
#
a_workspace_is_isolated_from_the_checkout() {
  make_repo "$tmp/ws" main && set_origin "$tmp/ws" 'https://github.com/acme/ws.git' \
    && mkdir -p "$tmp/ws/.foundry" \
    && commit_file "$tmp/ws" .foundry/gates 'tests  true
' || { skip "workspace — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/ws" ada@example.com "Workspace")
  floor "$tmp/ws" charter derive >/dev/null 2>&1
  floor "$tmp/ws" policy authorize 'https://github.com/acme/ws.git' >/dev/null 2>&1
  floor "$tmp/ws" targets add 'https://github.com/acme/ws.git' main >/dev/null 2>&1

  where=$(floor "$tmp/ws" open)
  slot=$(only_slot "$where")

  has "the workspace lives under the run"  "$where" "$d"

  # **The digest is the identity; the readable half is decoration.** Folding punctuation to `-` made
  # `acme/a-b`, `a/b`, `a.b` and `a_b` one directory — four repositories, one checkout — and a longer
  # fold would only have moved the collision. The name is asserted for its shape, not its spelling.
  matches "the slot is named by a digest, not by a fold of the identity" \
          "$(basename "$slot")" "-[0-9a-f]{12}$"

  # Published, not assembled: the build path is gone once the slot exists. Without this, a workspace
  # built in place is caught only by whichever directory the glob happens to yield first.
  is "publication leaves nothing beside the slot" \
     "$(set -- "$where"/*/; printf '%s' $#)" "1"
  is  "and holds a checkout of the target" "$(code_of test -d "$slot/.git")" "0"
  is  "opening twice answers the same place, and clones nothing twice" \
      "$(floor "$tmp/ws" open)" "$where"

  # The isolation, by execution rather than by assertion. A file proves only that two working trees
  # differ, which a shared worktree would also pass — so a ref is written too, and refs are the thing
  # a worktree shares.
  printf 'worker\n' > "$slot/WORKER"
  absent "what a worker writes there is not in the checkout it came from" "$tmp/ws/WORKER"

  git -C "$slot" update-ref refs/heads/probe HEAD 2>/dev/null
  is "and a ref it makes is not in that repository either" \
     "$(git -C "$tmp/ws" rev-parse --verify --quiet refs/heads/probe 2>/dev/null)" ""

  # A local clone shares object files unless told not to, and a shared object store is a checkout the
  # workspace cannot be pruned independently of.
  absent "it borrows no objects from that repository" "$slot/.git/objects/info/alternates"

  is "the origin is the target's identity, never this machine's path" \
     "$(git -C "$slot" remote get-url origin 2>/dev/null)" "https://github.com/acme/ws.git"

  # A slot with no checkout in it is a clone that failed, or one another session is still filling.
  # Cloning over it would destroy whichever it is.
  rm -rf "$slot/.git"
  is  "a slot holding no checkout is refused, not cloned over" \
      "$(code_of floor "$tmp/ws" open)" "16"
  has "and says what to do about it" \
      "$(floor_says "$tmp/ws" open)" "remove it and open again"

  # `[ -e ]` follows the link, so a dangling one reads as nothing there. Left to the claim below it,
  # the message would name a session that is not running.
  rm -rf "$slot"
  ln -s /nonexistent-target "$slot" 2>/dev/null || { skip "a dangling slot — this filesystem has no symlinks"; return; }
  has "a slot that is a dangling link is named for what it is" \
      "$(floor_says "$tmp/ws" open)" "remove it and open again"
}
a_workspace_is_isolated_from_the_checkout

#
# §2.4, now that a workspace exists: a gate runs in the checkout the unit owns, and there is no
# falling back to the one Foundry was invoked from. A gate that commits proves it twice — the record
# names the workspace's sha, and the source repository has not moved.
#
a_gate_runs_where_the_unit_owns_the_checkout() {
  make_repo "$tmp/gw" main && set_origin "$tmp/gw" 'https://github.com/acme/gw.git' \
    && mkdir -p "$tmp/gw/.foundry" \
    && commit_file "$tmp/gw" .foundry/gates 'tests  git -c user.email=g@g.g -c user.name=g commit -q --allow-empty -m gated
' || { skip "gate cwd — git could not make a repo here"; return; }

  floor_new_as "$tmp/gw" ada@example.com "Where" >/dev/null
  floor "$tmp/gw" charter derive >/dev/null 2>&1
  floor "$tmp/gw" policy authorize 'https://github.com/acme/gw.git' >/dev/null 2>&1
  floor "$tmp/gw" targets add 'https://github.com/acme/gw.git' main >/dev/null 2>&1

  is  "with no workspace open, a gate refuses rather than grading the wrong checkout" \
      "$(code_of floor "$tmp/gw" gates)" "16"
  has "and says which workspace is missing" "$(floor_says "$tmp/gw" gates)" "no workspace holds"
  is  "recording nothing"                   "$(floor "$tmp/gw" evidence)" ""

  slot=$(only_slot "$(floor "$tmp/gw" open)")
  base=$(git -C "$slot" rev-parse HEAD)

  # The source moves after the workspace was taken — the only way the two shas differ, since a clone
  # starts where the source stood.
  commit_file "$tmp/gw" MOVED 'the source moved on
'
  moved=$(git -C "$tmp/gw" rev-parse HEAD)

  floor "$tmp/gw" gates >/dev/null 2>&1
  held=$(floor "$tmp/gw" evidence)

  has     "the record names the workspace's sha"        "$held" "$base"
  lacks   "and not the source's, which has moved on"    "$held" "$moved"
  is      "a gate that commits does not move the source" "$(git -C "$tmp/gw" rev-parse HEAD)" "$moved"
  differs "though it moved the workspace"                "$(git -C "$slot" rev-parse HEAD)" "$base"

  # The same predicate `open` attaches by. A slot that stopped being this target's is not one to
  # grade — a directory test would have graded it, and recorded a `machine` result for a repository
  # nobody selected.
  git -C "$slot" remote set-url origin 'https://github.com/attacker/evil.git' 2>/dev/null
  is "a workspace that is no longer this target's is not graded" \
     "$(code_of floor "$tmp/gw" gates)" "16"
  git -C "$slot" remote set-url origin 'https://github.com/acme/gw.git' 2>/dev/null

  # Safe to retry: running again grades the workspace as it now stands, and records that too.
  floor "$tmp/gw" gates >/dev/null 2>&1
  is "running the gates again is two records, not a broken one" \
     "$(floor "$tmp/gw" evidence | awk -F'\t' 'NF == 7' | grep -c .)" "2"
  is "and the source still has not moved" "$(git -C "$tmp/gw" rev-parse HEAD)" "$moved"

  # The adapter names the directory. Renamed, a core that computes the name loses a workspace a core
  # that asks still finds — which is what a container or a sandbox would need it to do.
  mv "$slot" "$(dirname "$slot")/named-by-something-else"
  is "the workspace is found wherever it was put, not where core would name it" \
     "$(code_of floor "$tmp/gw" gates)" "0"
}
a_gate_runs_where_the_unit_owns_the_checkout

#
# A gate whose command is not on this host never ran. Recording that as a failure costs the run the
# ref: `satisfied` wants one pass and no failure there, the ledger is append-only, and a new commit
# is the only way out. So the work is unreachable from the commit it was done on.
#
a_gate_the_host_cannot_run() {
  make_repo "$tmp/nr" main && set_origin "$tmp/nr" 'https://github.com/acme/nr.git' \
    && mkdir -p "$tmp/nr/.foundry" \
    && commit_file "$tmp/nr" .foundry/gates 'tests  notonanyhost --run
' || { skip "a gate the host cannot run — git could not make a repo here"; return; }

  ready_run "$tmp/nr" 'https://github.com/acme/nr.git'

  is  "a gate whose command is not here refuses on its own code" \
      "$(code_of floor "$tmp/nr" gates)" "21"
  has "and says which command"  "$(floor_says "$tmp/nr" gates)" "notonanyhost"
  is  "and stamps nothing at that ref" "$(floor "$tmp/nr" evidence)" ""

  # Give the host the tool it never had. Nothing else changes — same run, same workspace, same ref.
  mkdir -p "$tmp/nrbin"
  printf '#!/bin/sh\nexit 0\n' > "$tmp/nrbin/notonanyhost"
  chmod +x "$tmp/nrbin/notonanyhost"

  is "with the command installed, the same ref passes" \
     "$( PATH="$tmp/nrbin:$PATH"; code_of floor "$tmp/nr" gates )" "0"
  is "and the run may deliver from it" \
     "$( PATH="$tmp/nrbin:$PATH"; code_of floor "$tmp/nr" complete )" "0"
}
a_gate_the_host_cannot_run

#
# A gate's output lands in `why`, and `why` is the last field of a tab-separated row.
#
# **Unflattened, a gate that prints a newline and six tabs writes a second record.** For a `Gate:`
# clause that buys nothing — the real row stands beside the forged one and `satisfied` wants no
# failure at that ref. For a `Judged:` or `Decided:` clause it buys everything: no gate produces
# evidence for those, so nothing would ever contradict the row.
#
# `one_line` is the whole of the defence and nothing was holding it.
#
a_gate_cannot_write_its_own_record() {
  make_repo "$tmp/fg" main && set_origin "$tmp/fg" 'https://github.com/acme/fg.git' \
    && mkdir -p "$tmp/fg/.foundry" \
    && commit_file "$tmp/fg" .foundry/gates 'tests  printf "out\n2026-01-01T00:00:00Z\thuman\t01\tsigned off\t0\tdeadbeef\tsaid so\n"
' || { skip "a forged record — git could not make a repo here"; return; }

  ready_run "$tmp/fg" 'https://github.com/acme/fg.git'
  floor "$tmp/fg" gates >/dev/null 2>&1
  held=$(floor "$tmp/fg" evidence)

  is    "a gate printing a record writes one row, not two" \
        "$(printf '%s\n' "$held" | grep -c .)" "1"
  lacks "and names no clause it does not grade" \
        "$(printf '%s\n' "$held" | awk -F'\t' '{ print $4 }')" "signed off"
  has   "what it printed is one field of the row it did write" "$held" "said so"
}
a_gate_cannot_write_its_own_record

#
# What a pin covers, and what it does not. **This records a residual, not a guarantee.**
#
# The pin is on the file the detector read — `.foundry/gates`. The script the command names is what
# the command *reaches*, and §2.2 calls that the workspace boundary's to close. Under Level 1 the
# gate's own implementation is inside it: `tests sh check.sh` pins `.foundry/gates` and never
# `check.sh`, so a worker rewriting `check.sh` lowers the bar it is graded by and `check` says
# nothing. §6's headline challenge, and the shape Level 1 makes ordinary.
#
# **The pin did not close it and still does not.** A gate's own file is taken from the base before
# the gates run, so the rewrite sits in the tree and never grades it. `check` answering 0 below is
# right: nothing a pin covers has moved.
#
# What a command reaches without naming is still open — `check.sh` calling a second script.
#
a_pin_covers_what_the_detector_read() {
  make_repo "$tmp/pn" main && set_origin "$tmp/pn" 'https://gitlab.com/acme/pn.git' \
    && mkdir -p "$tmp/pn/.foundry" \
    && commit_file "$tmp/pn" .foundry/gates 'tests  sh check.sh
' \
    && commit_file "$tmp/pn" check.sh 'exit 1
' || { skip "what a pin covers — git could not make a repo here"; return; }

  ready_run "$tmp/pn" 'https://gitlab.com/acme/pn.git'

  is "the pin names the file the detector read" \
     "$(floor "$tmp/pn" charter | awk '$1 == "pin" { print $5 }')" ".foundry/gates"
  is "and the bar fails as it was authorised" "$(code_of floor "$tmp/pn" gates)" "14"

  # The worker rewrites the script its own gate names. `.foundry/gates` is untouched, so the pin is.
  slot=$(only_slot "$(floor "$tmp/pn" open)")
  printf 'exit 0\n' > "$slot/check.sh"
  git -C "$slot" add -A >/dev/null 2>&1
  git -C "$slot" -c user.email=w@x -c user.name=w commit -qm lowered >/dev/null 2>&1

  is "a rewritten gate script moves no pin"  "$(code_of floor "$tmp/pn" charter check)" "0"
  is "and the bar the worker wrote is not the bar" "$(code_of floor "$tmp/pn" gates)" "14"
  is "so it may not deliver on it"                "$(code_of floor "$tmp/pn" complete)" "15"
}
a_pin_covers_what_the_detector_read

#
# A workspace is where mutation happens, so it may not exist for a run nobody authorised. `authorise`
# holds twelve reasons and this restates none of them.
#
# Nobody is a real answer, and `new` makes the run anyway. It says so first.
#
# `HOME` is emptied because `selector` falls back to `git config user.email`, which reads the global
# file — a developer's own identity would answer here for the container that has none.
#
a_run_nobody_selected_says_so() {
  mkdir -p "$tmp/nohome"
  said=$( cd "$tmp/bare" 2>/dev/null \
          && HOME="$tmp/nohome" FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
             sh "$runner" new "Nobody" 2>&1 >/dev/null )

  has "a run nobody selected says so at new" "$said" "nobody is recorded"
}
a_run_nobody_selected_says_so

# How far each run got, from files other verbs already wrote. The only verb not scoped
# to the active run, and the reason selection could live nowhere but in
# whoever was driving — nothing else could say what work exists.
a_home_says_what_it_holds() {
  make_repo "$tmp/rl" main && set_origin "$tmp/rl" 'https://github.com/acme/rl.git' \
    && mkdir -p "$tmp/rl/.foundry" \
    && commit_file "$tmp/rl" .foundry/gates 'tests  true
' || { skip "what a home holds — git could not make a repo here"; return; }

  empty="$tmp/emptyhome"
  is "a home with no runs answers nothing" \
     "$( cd "$tmp/rl" && FOUNDRY_HOME="$empty" FOUNDRY_RUN="" sh "$runner" runs 2>/dev/null )" ""
  is "and it is not an error"  "$(code_of floor_as "$tmp/rl" "$empty" "" runs)" "0"
  is "runs takes no argument"  "$(code_of floor "$tmp/rl" runs 01)" "2"

  # The ladder, one rung at a time, against the run this walks forward.
  id=$(basename "$(floor_new_as "$tmp/rl" ada@example.com "Ladder")")
  rung() { floor "$tmp/rl" runs | awk -v id="$id" '$2 == id { print $1 }'; }

  is "a run with no charter is new"        "$(rung)" "new"
  floor "$tmp/rl" charter derive >/dev/null 2>&1
  is "a charter makes it charted"          "$(rung)" "charted"
  floor "$tmp/rl" policy authorize 'https://github.com/acme/rl.git' >/dev/null 2>&1
  floor "$tmp/rl" targets add 'https://github.com/acme/rl.git' main >/dev/null 2>&1
  is "a selected target makes it selected"  "$(rung)" "selected"
  floor "$tmp/rl" open >/dev/null 2>&1
  is "a workspace makes it open"            "$(rung)" "open"
  floor "$tmp/rl" gates >/dev/null 2>&1
  is "a stamped gate makes it graded"       "$(rung)" "graded"

  # `delivery` is the source's answer, and nothing else writes it — so this is the one rung a test
  # writes by hand rather than earning. What it proves is the ladder's order, not the delivery.
  printf 'work/x https://example.invalid/1\n' > "$(floor "$tmp/rl" path)/delivery"
  is "and a recorded delivery outranks all of it" "$(rung)" "delivered"
}
a_home_says_what_it_holds

#
a_workspace_needs_authorisation() {
  make_repo "$tmp/wt" main && set_origin "$tmp/wt" 'https://github.com/acme/wt.git' \
    && mkdir -p "$tmp/wt/.foundry" \
    && commit_file "$tmp/wt" .foundry/gates 'tests  true
' || { skip "unauthorised workspace — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/wt" ada@example.com "Unauthorised")
  floor "$tmp/wt" charter derive >/dev/null 2>&1

  differs "a run selecting nothing gets no workspace" \
          "$(code_of floor "$tmp/wt" open)" "0"
  absent "and nothing was checked out" "$d/units/01/workspace"
}
a_workspace_needs_authorisation

#
# §4's join test is the run pointer in each slot's own `.git` — *a person can join by opening a shell
# in the workspace and reading the run*. A write that failed left `open` printing a path and exiting
# 0 over a checkout no later process could attribute to a run.
#
# `records_unreadable` answers for writing too: a filesystem that honours one mode bit honours the
# other, and root ignores both.
#
a_slot_nobody_can_join_is_not_a_workspace() {
  records_unreadable || { skip "an unwritable slot — this filesystem records no mode bits"; return; }

  make_repo "$tmp/nj" main && set_origin "$tmp/nj" 'https://github.com/acme/nj.git' \
    && mkdir -p "$tmp/nj/.foundry" \
    && commit_file "$tmp/nj" .foundry/gates 'tests  true
' || { skip "a slot nobody can join — git could not make a repo here"; return; }

  ready_run "$tmp/nj" 'https://github.com/acme/nj.git'
  slot=$(only_slot "$(floor "$tmp/nj" open)")

  is "the pointer is there to start with" \
     "$(cat "$slot/.git/foundry-run" 2>/dev/null)" "$(basename "$(floor "$tmp/nj" path)")"

  rm -f "$slot/.git/foundry-run"
  chmod 500 "$slot/.git"

  is  "a slot whose pointer cannot be written refuses" "$(code_of floor "$tmp/nj" open)" "16"
  has "and names the workspace"                        "$(floor_says "$tmp/nj" open)" "nobody can join"

  chmod 700 "$slot/.git"
  is "and opens again once it can be written" "$(code_of floor "$tmp/nj" open)" "0"
  is "with the pointer back" \
     "$(cat "$slot/.git/foundry-run" 2>/dev/null)" "$(basename "$(floor "$tmp/nj" path)")"
}
a_slot_nobody_can_join_is_not_a_workspace

#
# A slot can hold a perfectly valid checkout of something else. `open` answered 0 for one holding
# another repository entirely, and every gate after it would have graded that.
#
#
# The shape of a digest proves nothing — a constant is twelve hex characters too. Two repositories,
# two identities, and the names must differ in the half that is not decoration.
#
a_digest_is_derived_from_the_identity_it_names() {
  for n in 1 2; do
    make_repo "$tmp/dg$n" main && set_origin "$tmp/dg$n" "https://github.com/acme/dg$n.git" \
      && mkdir -p "$tmp/dg$n/.foundry" \
      && commit_file "$tmp/dg$n" .foundry/gates 'tests  true
' || { skip "digest derivation — git could not make a repo here"; return; }

    floor_new_as "$tmp/dg$n" ada@example.com "Digest $n" >/dev/null
    floor "$tmp/dg$n" charter derive >/dev/null 2>&1
    floor "$tmp/dg$n" policy authorize "https://github.com/acme/dg$n.git" >/dev/null 2>&1
    floor "$tmp/dg$n" targets add "https://github.com/acme/dg$n.git" main >/dev/null 2>&1
  done

  one=$(basename "$(only_slot "$(floor "$tmp/dg1" open)")")
  two=$(basename "$(only_slot "$(floor "$tmp/dg2" open)")")

  differs "two identities take two digests" "${one#*-}" "${two#*-}"

  # And the other half, or a digest of the run directory would pass the first. A second run over the
  # same target takes the same digest: the identity is what it is made from.
  floor_new_as "$tmp/dg1" ada@example.com "Digest 1 again" >/dev/null
  floor "$tmp/dg1" charter derive >/dev/null 2>&1
  floor "$tmp/dg1" policy authorize 'https://github.com/acme/dg1.git' >/dev/null 2>&1
  floor "$tmp/dg1" targets add 'https://github.com/acme/dg1.git' main >/dev/null 2>&1
  again=$(basename "$(only_slot "$(floor "$tmp/dg1" open)")")

  is "one identity takes one digest, whichever run asks" "${again#*-}" "${one#*-}"
}
a_digest_is_derived_from_the_identity_it_names

a_slot_holding_another_repository_is_refused() {
  make_repo "$tmp/im" main && set_origin "$tmp/im" 'https://github.com/acme/im.git' \
    && mkdir -p "$tmp/im/.foundry" \
    && commit_file "$tmp/im" .foundry/gates 'tests  true
' || { skip "imposter slot — git could not make a repo here"; return; }

  floor_new_as "$tmp/im" ada@example.com "Imposter" >/dev/null
  floor "$tmp/im" charter derive >/dev/null 2>&1
  floor "$tmp/im" policy authorize 'https://github.com/acme/im.git' >/dev/null 2>&1
  floor "$tmp/im" targets add 'https://github.com/acme/im.git' main >/dev/null 2>&1

  slot=$(only_slot "$(floor "$tmp/im" open)")

  git -C "$slot" remote set-url origin 'https://github.com/attacker/evil.git' 2>/dev/null
  is  "a checkout of another repository is not this target's workspace" \
      "$(code_of floor "$tmp/im" open)" "16"
  has "and is named as not being one" "$(floor_says "$tmp/im" open)" "is not a checkout of"

  # The same slot, the right repository, opened for a ref this run did not select.
  git -C "$slot" remote set-url origin 'https://github.com/acme/im.git' 2>/dev/null
  git -C "$slot" config foundry.ref elsewhere 2>/dev/null
  is "nor is one opened for another ref" "$(code_of floor "$tmp/im" open)" "16"
}
a_slot_holding_another_repository_is_refused

#
# `foundry.ref` is compared against the run's frozen selection, never against a constant. A run that
# selected `develop` records `develop`, so a workspace built for another ref cannot pass as this
# run's — which is what makes the comparison worth making at all.
#
the_recorded_ref_is_the_one_the_run_selected() {
  make_repo "$tmp/rf" develop && set_origin "$tmp/rf" 'https://github.com/acme/rf.git' \
    && mkdir -p "$tmp/rf/.foundry" \
    && commit_file "$tmp/rf" .foundry/gates 'tests  true
' || { skip "selected ref — git could not make a repo here"; return; }

  floor_new_as "$tmp/rf" ada@example.com "Selected" >/dev/null
  floor "$tmp/rf" charter derive >/dev/null 2>&1
  floor "$tmp/rf" policy authorize 'https://github.com/acme/rf.git' >/dev/null 2>&1
  floor "$tmp/rf" targets add 'https://github.com/acme/rf.git' develop >/dev/null 2>&1

  slot=$(only_slot "$(floor "$tmp/rf" open)")
  is "the workspace records the ref this run selected" \
     "$(git -C "$slot" config --get foundry.ref 2>/dev/null)" "develop"
}
the_recorded_ref_is_the_one_the_run_selected

#
# Built beside the slot, published into it. A creator that dies leaves recoverable garbage, and never
# a slot another session could read as finished — or delete while the first is still filling it.
#
a_half_built_workspace_is_never_the_workspace() {
  make_repo "$tmp/ab" main && set_origin "$tmp/ab" 'https://github.com/acme/ab.git' \
    && mkdir -p "$tmp/ab/.foundry" \
    && commit_file "$tmp/ab" .foundry/gates 'tests  true
' || { skip "atomic publication — git could not make a repo here"; return; }

  floor_new_as "$tmp/ab" ada@example.com "Atomic" >/dev/null
  floor "$tmp/ab" charter derive >/dev/null 2>&1
  floor "$tmp/ab" policy authorize 'https://github.com/acme/ab.git' >/dev/null 2>&1
  floor "$tmp/ab" targets add 'https://github.com/acme/ab.git' main >/dev/null 2>&1

  slot=$(only_slot "$(floor "$tmp/ab" open)")
  rm -rf "$slot"
  mkdir -p "$slot.building"                       # as a creator killed mid-clone leaves it

  is     "a second opener does not take a slot being built" "$(code_of floor "$tmp/ab" open)" "16"
  has    "and says what to remove if none is" "$(floor_says "$tmp/ab" open)" "if no session is"
  is     "it deletes nothing of the first one's" "$(code_of test -d "$slot.building")" "0"
  absent "and no slot exists to read as finished" "$slot"
}
a_half_built_workspace_is_never_the_workspace

#
# Selecting after the freeze. The set was fixed when it was authorised, so adding to it makes a run
# nobody authorised — §4's remedy is a new run, never this one carrying on.
#
# It used to be reported as an ungradable target, which sent a reader to open a workspace for it. The
# selection moving is the earlier fact and the one with a remedy.
#
a_target_selected_after_the_freeze_is_a_new_run() {
  make_repo "$tmp/ct" main && set_origin "$tmp/ct" 'https://github.com/acme/ct.git' \
    && mkdir -p "$tmp/ct/.foundry" \
    && commit_file "$tmp/ct" .foundry/gates 'tests  true
' || { skip "two targets — git could not make a repo here"; return; }

  floor_new_as "$tmp/ct" ada@example.com "Two" >/dev/null
  floor "$tmp/ct" charter derive >/dev/null 2>&1
  floor "$tmp/ct" policy authorize 'https://github.com/acme/ct.git' >/dev/null 2>&1
  floor "$tmp/ct" targets add 'https://github.com/acme/ct.git' main >/dev/null 2>&1
  floor "$tmp/ct" open >/dev/null 2>&1
  floor "$tmp/ct" gates >/dev/null 2>&1

  is "one target, evidenced, may deliver" "$(code_of floor "$tmp/ct" complete)" "0"

  floor "$tmp/ct" policy authorize 'https://github.com/acme/other.git' >/dev/null 2>&1
  floor "$tmp/ct" targets add 'https://github.com/acme/other.git' main >/dev/null 2>&1

  is  "selecting a second one after the freeze stops delivery" \
      "$(code_of floor "$tmp/ct" complete)" "10"
  has "and says which run this is no longer" \
      "$(floor_says "$tmp/ct" complete)" "no longer the one that was authorised"
}
a_target_selected_after_the_freeze_is_a_new_run


#
# The bar is captured where it will be graded, or not at all.
#
# `bootstrap` records the ref the invoker stood on; the selection names the ref the run chose; the
# charter pins the first and the workspace checks out the second. Nothing compared them, so a run
# derived its definition of good from a tree it would never grade — and invariant 2 read as satisfied
# the whole way, because a pin was captured, just not from there.
#
# Found by the first self-hosted run, which was started on a branch and selected `main`.
#
a_bar_derived_somewhere_else_is_refused() {
  make_repo "$tmp/px" main && set_origin "$tmp/px" 'https://github.com/acme/px.git' \
    && mkdir -p "$tmp/px/.foundry" \
    && commit_file "$tmp/px" .foundry/gates 'tests  true
' || { skip "pinned elsewhere — git could not make a repo here"; return; }

  git -C "$tmp/px" checkout -q -b side 2>/dev/null

  floor_new_as "$tmp/px" ada@example.com "Elsewhere" >/dev/null
  floor "$tmp/px" charter derive >/dev/null 2>&1
  floor "$tmp/px" policy authorize 'https://github.com/acme/px.git' >/dev/null 2>&1

  is "selecting the ref the run was started on is fine" \
     "$(code_of floor "$tmp/px" targets add 'https://github.com/acme/px.git' side)" "0"

  d=$(floor "$tmp/px" path)
  grep -v ' side$' "$d/units/01/targets" > "$d/units/01/t" && mv "$d/units/01/t" "$d/units/01/targets"

  is  "selecting another ref of the same repository is refused" \
      "$(code_of floor "$tmp/px" targets add 'https://github.com/acme/px.git' main)" "4"
  has "and says the bar came from elsewhere" \
      "$(floor_says "$tmp/px" targets add 'https://github.com/acme/px.git' main)" "derived at [side]"
}
a_bar_derived_somewhere_else_is_refused
#
# Every clause is graded against every selected target, so a line put into the file by hand decides
# what the run answers for. `targets` and `authorise` both refuse such a line; the grader read it.
#
a_selection_edited_by_hand_grades_nothing() {
  make_repo "$tmp/cu" main && set_origin "$tmp/cu" 'https://github.com/acme/cu.git' \
    && mkdir -p "$tmp/cu/.foundry" \
    && commit_file "$tmp/cu" .foundry/gates 'tests  true
' || { skip "hand-edited selection — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/cu" ada@example.com "ByHand")
  floor "$tmp/cu" charter derive >/dev/null 2>&1
  floor "$tmp/cu" policy authorize 'https://github.com/acme/cu.git' >/dev/null 2>&1
  floor "$tmp/cu" targets add 'https://github.com/acme/cu.git' main >/dev/null 2>&1
  floor "$tmp/cu" open >/dev/null 2>&1
  floor "$tmp/cu" gates >/dev/null 2>&1

  is "as selected, it may deliver" "$(code_of floor "$tmp/cu" complete)" "0"

  printf 'https://github.com/attacker/evil.git main\n' >> "$d/units/01/targets"
  is  "a target nobody authorised is refused, not graded" \
      "$(code_of floor "$tmp/cu" complete)" "5"
  has "and named" "$(floor_says "$tmp/cu" complete)" "selected but not authorised"
}
a_selection_edited_by_hand_grades_nothing

#
# The same act with nothing left behind. `refuse_unselectable` cannot see an absence, so the frozen
# record is the only thing that still remembers the line was selected — and authorisation was the
# only stage reading it.
#
a_target_deleted_after_the_freeze_is_still_selected() {
  make_repo "$tmp/cw" main && set_origin "$tmp/cw" 'https://github.com/acme/cw.git' \
    && mkdir -p "$tmp/cw/.foundry" \
    && commit_file "$tmp/cw" .foundry/gates 'tests  true
' || { skip "deleted target — git could not make a repo here"; return; }

  d=$(floor_new_as "$tmp/cw" ada@example.com "Deleted")
  floor "$tmp/cw" charter derive >/dev/null 2>&1
  floor "$tmp/cw" policy authorize 'https://github.com/acme/cw.git' >/dev/null 2>&1
  floor "$tmp/cw" policy authorize 'https://github.com/acme/gone.git' >/dev/null 2>&1
  floor "$tmp/cw" targets add 'https://github.com/acme/cw.git' main >/dev/null 2>&1
  floor "$tmp/cw" targets add 'https://github.com/acme/gone.git' main >/dev/null 2>&1
  floor "$tmp/cw" open >/dev/null 2>&1
  floor "$tmp/cw" gates >/dev/null 2>&1

  is "two selected and one ungradable, it may not deliver" \
     "$(code_of floor "$tmp/cw" complete)" "15"

  grep -v 'gone.git' "$d/units/01/targets" > "$d/units/01/rest" \
    && mv "$d/units/01/rest" "$d/units/01/targets"

  is  "deleting the one it cannot grade does not make it deliverable" \
      "$(code_of floor "$tmp/cw" complete)" "10"
  has "and says the selection is no longer the authorised one" \
      "$(floor_says "$tmp/cw" complete)" "no longer the one that was authorised"

  # The recorder too, and for a sharper reason than the grader: `complete` refusing only means the
  # evidence cannot deliver. `gates` writing means the ledger gains a passing row for a run nobody
  # authorised, and the ledger is append-only.
  rows=$(wc -l < "$d/evidence")
  is "and gates refuses rather than recording" "$(code_of floor "$tmp/cw" gates)" "10"
  is "so the ledger did not grow" "$(wc -l < "$d/evidence")" "$rows"
}
a_target_deleted_after_the_freeze_is_still_selected

#
# The same act with a quieter shape. Deleting a level-2 declaration drops detection a level, so the
# clause survives under a different source and every pin that remains still matches — comparing
# pinned sources one by one cannot see a source that stopped being yielded. Only the answer can.
#
a_run_cannot_change_what_the_gates_resolve_to() {
  make_repo "$tmp/drop" main && set_origin "$tmp/drop" 'https://github.com/acme/drop.git' \
    && mkdir -p "$tmp/drop/.foundry" \
    && commit_file "$tmp/drop" Makefile 'test:
	echo weak
' && commit_file "$tmp/drop" .foundry/gates 'tests  echo STRICT
' || { skip "resolution authority — git could not make a repo here"; return; }

  d=$(floor "$tmp/drop" new "Drop")
  base=$(git -C "$tmp/drop" rev-parse HEAD)
  floor "$tmp/drop" charter derive >/dev/null 2>&1
  has "the declared bar is what derives" "$(cat "$(charter_of "$d")" 2>/dev/null)" "echo STRICT"

  git -C "$tmp/drop" rm -q .foundry/gates >/dev/null 2>&1
  git -C "$tmp/drop" -c user.email=a@b.c -c user.name=a commit -qm drop >/dev/null 2>&1

  is  "deleting a declaration to fall back a level is refused" \
      "$(code_of floor "$tmp/drop" charter derive)" "6"
  has "and names the gate whose source moved" \
      "$(floor_says "$tmp/drop" charter derive)" "declares these gates elsewhere"
  has "the bar the human declared still stands" \
      "$(cat "$(charter_of "$d")" 2>/dev/null)" "echo STRICT"

  # A base nobody can read. `refuse_moved_resolution` passes on one — it yields no declaration to
  # compare — and the pin check refuses it instead, reading the same base for a sha it cannot get.
  # That guard is why the fall-through above is safe, so it is checked rather than assumed.
  rm -f "$(loose_object "$tmp/drop" "$base")"

  is  "a base nobody can read is still refused" \
      "$(code_of floor "$tmp/drop" charter derive)" "6"
  has "and says the pin is what refused it" \
      "$(floor_says "$tmp/drop" charter derive)" "pin refused"
}
a_run_cannot_change_what_the_gates_resolve_to

a_pin_that_cannot_be_captured_writes_nothing() {
  make_repo "$tmp/ch4" main && set_origin "$tmp/ch4" 'https://github.com/acme/ch4.git' \
    && commit_file "$tmp/ch4" README.md 'x' || { skip "pin capture — git could not make a repo"; return; }

  p=$(floor "$tmp/ch4" new "Pin")

  # Detected but never committed, so it has no sha at the base ref.
  printf 'test:\n\techo ok\n' > "$tmp/ch4/Makefile"

  is     "a pin with no sha at the base is refused" "$(code_of floor "$tmp/ch4" charter derive)" "6"
  absent "and no charter is written at all"         "$(charter_of "$p")"

  # The reason, not just the code. Exit 6 is shared by every clause refusal, so a runner that pinned
  # `rev-parse`'s error string and one that refused an artifact moved from the base both look alike
  # through the exit code alone.
  has "and says the sha is what is missing" \
      "$(floor_says "$tmp/ch4" charter derive)" "no sha for [Makefile]"
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

#
# `authorise` is the detector's third consumer, and the first that writes its answer down.
#
# Without this guard a run authorised from any directory holding a `.foundry/gates` that named the
# charter's gates — turning a correct refusal into a frozen record. `$tmp/ch2` is a different
# repository, and the message is what is asserted: exit 6 alone would pass for the wrong reason,
# which is the lesson the check above already carries.
#
authorising_needs_the_right_repository() {
  [ -n "${chrun:-}" ] || { skip "authorise wrong repo — no charter run"; return; }

  has "authorising from another repository is refused for being the wrong repository" \
      "$( cd "$tmp/ch2" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$chrun" sh "$runner" authorise 2>&1 )" \
      "run this inside [https://github.com/acme/ch.git]"
}
authorising_needs_the_right_repository

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

# --- the work source ---
#
# RFC-001 §2.1. Four verbs, and the properties that make them a contract rather than a call to one
# provider.
#
# Nothing here names a source. The adapter is chosen by `lib/source.sh`, and with no `gh` on this
# machine the directory answers — needing nothing floor does not already declare, and reading its
# root out of the home this suite already sets. That is the portability claim, executed.

# Where the shipped adapter looks with nothing configured: floor's own home, which this suite sets.
src="$home/source"

# The first run, addressed explicitly. Later checks make a second run in the same checkout, which
# moves the pointer — and every check above it would then quietly be about the wrong run.
ws() { floor_as "$tmp/wsrc" "$home" "$wsrun" "$@"; }

# Where a person leaves an answer. The adapter's own layout, and the suite writes it by hand on
# purpose: a human answering is not something floor can be asked to do.
answer_with() {
  mkdir -p "$src/answers/7"
  printf '%s\n' "$2" > "$src/answers/7/$1"
}

the_work_source() {
  make_repo "$tmp/wsrc" main && set_origin "$tmp/wsrc" 'https://gitlab.com/acme/ws.git' \
    && commit_file "$tmp/wsrc" Makefile 'test:
	echo ok
' || { skip "work source — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Make the thing\n\ntargets: https://gitlab.com/acme/items.git\n' > "$src/items/7"
  printf 'Make another thing\n' > "$src/items/8"

  wsrun=$(floor "$tmp/wsrc" new "Work source")
  wsid=$(basename "$wsrun")

  # Absence first, and against a run that has read nothing: a refused read must leave the run unread,
  # or every check after this one is about an item the source never held.
  is "an item the source does not hold is an absence" "$(code_of ws source read 9)" "1"
  absent "and the run records no item for it" "$wsrun/source"

  has "read carries the item's own words" "$(ws source read 7)" "targets: https://gitlab.com/acme/items.git"
  has "and they land in the run"          "$(cat "$wsrun/item.md" 2>/dev/null)" "Make the thing"

  # There is no parameter for the words — `evidence record`'s shape, one stage over. A worker puts
  # words in `item.md` only by putting them where the source can be asked for them.
  is "read names an item and never says what it holds" "$(code_of ws source read 7 'I say what it is')" "2"
  is "and a run reads one item"                        "$(code_of ws source read 8)" "17"

  #
  # Absent, empty and unreadable are three answers, and the adapter separated two of them. `[ -f ]`
  # asked whether the file exists and `cat` then failed for another reason, so a file that is there
  # and cannot be read was reported as an item nobody filed.
  #
  # #200 taught the other adapter this. RFC-001 §8 says a contract is unproven until two satisfy it.
  #
  if records_unreadable; then
    chmod 000 "$src/items/7"
    is "an item that cannot be read is not one nobody filed" "$(code_of ws source read 7)" "20"
    chmod 644 "$src/items/7"
    is "and it reads normally once it can be"                "$(code_of ws source read 7)" "0"
  else
    skip "an unreadable item — this filesystem records no read bit"
  fi


  #
  # A work source is not a target. An item is written by whoever can file one, so what it names is
  # advisory — the sequence is refused, granted, accepted, because the weak form of this check passes
  # with no policy at all.
  #
  lacks "an item's words authorise no target" "$(ws policy)"  "acme/items"
  lacks "and select none"                     "$(ws targets)" "acme/items"
  is    "so the repository it names is refused" \
        "$(code_of ws targets add https://gitlab.com/acme/items.git main)" "5"

  ws charter derive >/dev/null 2>&1
}
the_work_source

#
# Floor records the moments it already knows. Nothing is kept as a total, so
# how many gates failed before one passed is counted from the rows
# rather than read from a number somebody incremented.
#
a_run_answers_from_its_own_rows() {
  make_repo "$tmp/ans" main && set_origin "$tmp/ans" 'https://github.com/acme/ans.git' \
    && mkdir -p "$tmp/ans/.foundry" \
    && commit_file "$tmp/ans" .foundry/gates 'tests  false
' || { skip "answering from rows — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Count it\n' > "$src/items/61"

  ansrun=$(floor "$tmp/ans" new "Answered")
  floor "$tmp/ans" source read 61 >/dev/null 2>&1
  floor "$tmp/ans" charter derive >/dev/null 2>&1
  floor "$tmp/ans" policy authorize 'https://github.com/acme/ans.git' >/dev/null 2>&1
  floor "$tmp/ans" targets add 'https://github.com/acme/ans.git' main >/dev/null 2>&1
  work=$(only_slot "$(floor "$tmp/ans" open)")

  floor "$tmp/ans" gates >/dev/null 2>&1
  floor "$tmp/ans" gates >/dev/null 2>&1

  mine() { floor "$tmp/ans" observed "$1" | awk -F'\t' -v r="$(basename "$ansrun")" '$1 == r'; }

  has "a run records that it began"  "$(mine run.began)"  "run.began"
  has "and which item it read"       "$(mine item.read)"  "item=61"

  # Counted from the rows. Nothing stores how many failed, so nothing can disagree with them.
  is "two failed gates are two rows" \
     "$(mine gate.finished | grep -c 'result=1')" "2"
  is "and none passed"  "$(mine gate.finished | grep -c 'result=0')" "0"

  printf 'true\n' > "$tmp/ans/.foundry/gates.new"
  printf 'tests  true\n' > "$work/.foundry/gates"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "a gate that passes"
  floor "$tmp/ans" gates >/dev/null 2>&1

  is "and the pass after them is one more row" \
     "$(mine gate.finished | grep -c .)" "3"
}
a_run_answers_from_its_own_rows

#
# Every run this home holds, one row each, with the run named first. Two
# runs over one work item compose here without either
# ever having heard of the other.
#
two_runs_over_one_item_compose() {
  make_repo "$tmp/cmp" main && set_origin "$tmp/cmp" 'https://github.com/acme/cmp.git' \
    || { skip "composing — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Twice\n' > "$src/items/62"

  first=$(floor "$tmp/cmp" new "First")
  floor "$tmp/cmp" source read 62 >/dev/null 2>&1

  second=$( cd "$tmp/cmp" && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
            FOUNDRY_SOURCE="$dir_source" sh "$runner" new "Second" 2>/dev/null )
  ( cd "$tmp/cmp" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$second" FOUNDRY_WHO="" \
    FOUNDRY_SOURCE="$dir_source" sh "$runner" source read 62 >/dev/null 2>&1 )

  is "two runs read one item, and both rows are there" \
     "$(floor "$tmp/cmp" observed item.read | grep -c 'item=62')" "2"
  is "and each row names its own run" \
     "$(floor "$tmp/cmp" observed item.read | awk -F'\t' '/item=62/ { print $1 }' | sort -u | grep -c .)" "2"

  # Neither run ever heard of the other. The home is what holds them, and nothing was coordinated.
  is "and neither run holds the other's row" \
     "$(floor "$tmp/cmp" observe | grep -c 'item=62')" "1"
}
two_runs_over_one_item_compose

#
# Exactly one host may take an item. Two seeing the same one
# and both starting is the failure, and almost never
# is not a claim — it is money spent twice.
#
exactly_one_host_takes_an_item() {
  make_repo "$tmp/clm" main && set_origin "$tmp/clm" 'https://gitlab.com/acme/clm.git' \
    || { skip "the claim — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Race for it\n' > "$src/items/71"
  floor "$tmp/clm" new "Raced for it" >/dev/null 2>&1
  allowed=$(floor "$tmp/clm" policy)

  # Exclusivity is `mkdir` being one step, which POSIX gives and this
  # does not show. Two process races in one suite starve this
  # machine, and a race reporting nothing proves less.

  is "an item nobody took is taken" "$(code_of floor "$tmp/clm" claim 71)" "0"

  # A claim is not authority. It says a host started, never that it may.
  is "and holding it grants nothing" "$(floor "$tmp/clm" policy)" "$allowed"

  # The holder claiming again is the renewal. Without it a claim needs a heartbeat, and a heartbeat
  # is the daemon this refuses to be. `recording_host` is this machine, so a second host is written
  # by hand below — nothing in the environment can pretend to be one.
  printf '2026-01-01T00:00:00Z\t%s\t1767225600\n' "$(uname -n)" > "$src/claims/71/held"
  is "the holder claiming again renews it" "$(code_of floor "$tmp/clm" claim 71)" "0"
  lacks "and the stamp moved" "$(cat "$src/claims/71/held")" "1767225600"

  printf '2026-01-01T00:00:00Z\tOtherHost\t%s\n' "$(date -u +%s)" > "$src/claims/71/held"

  is  "another host's claim is refused" "$(code_of floor "$tmp/clm" claim 71)" "30"
  has "and told who holds it"           "$(floor_says "$tmp/clm" claim 71)" "held by OtherHost"
  has "and keeps what it saw"           "$(floor "$tmp/clm" observe)" "claim.refused	item=71"

  # A host that stopped. Aged out rather than cleared by a person, which is the whole point —
  # nobody is watching to notice it died.
  printf '2026-01-01T00:00:00Z\tOtherHost\t1767225600\n' > "$src/claims/71/held"

  has "a claim past the window says what it broke" \
      "$(floor_says "$tmp/clm" claim 71)" "without a word from OtherHost"
  has "and this host holds it after" "$(cat "$src/claims/71/held")" "$(uname -n)"

  # An age nobody can compute is not an age past the window. Unknown is not stale.
  printf '2026-01-01T00:00:00Z\tOtherHost\n' > "$src/claims/71/held"
  is "a claim with no stamp is never broken" "$(code_of floor "$tmp/clm" claim 71)" "30"

  # An hour is a guess about how often a host wakes, so the caller may say otherwise.
  printf '2026-01-01T00:00:00Z\tOtherHost\t1767225600\n' > "$src/claims/71/held"
  is "a window the caller widens holds the claim" \
     "$(FOUNDRY_CLAIM_TTL=99999999999 code_of floor "$tmp/clm" claim 71)" "30"
  is "and one it narrows to nothing takes it" \
     "$(FOUNDRY_CLAIM_TTL=0 code_of floor "$tmp/clm" claim 71)" "0"

  is "the holder may let go"     "$(code_of floor "$tmp/clm" release 71)" "0"
  is "and nobody holds it after" "$(code_of floor "$tmp/clm" release 71)" "30"
}
exactly_one_host_takes_an_item
#
# What produced this row. A run graded under one implementation
# and completed under another was judged twice, and the two
# holes closed this week are why that is worth knowing.
#
# Recorded and not yet refused. Nothing compares two runtimes,
# and choosing whether to refuse wants rows to argue
# from rather than a guess.
#
a_row_names_the_runtime_that_wrote_it() {
  make_repo "$tmp/rt" main && set_origin "$tmp/rt" 'https://github.com/acme/rt.git' \
    && mkdir -p "$tmp/rt/.foundry" \
    && commit_file "$tmp/rt" .foundry/gates 'tests  true
' || { skip "the runtime — git could not make a repo here"; return; }

  rtrun=$(floor "$tmp/rt" new "Runtime")
  floor "$tmp/rt" charter derive >/dev/null 2>&1
  floor "$tmp/rt" policy authorize 'https://github.com/acme/rt.git' >/dev/null 2>&1
  floor "$tmp/rt" targets add 'https://github.com/acme/rt.git' main >/dev/null 2>&1
  floor "$tmp/rt" open >/dev/null 2>&1
  floor "$tmp/rt" gates >/dev/null 2>&1

  matches "a run says which runtime began it" \
          "$(floor "$tmp/rt" observe | awk -F'\t' '$3 == "run.began"')" "runtime=floor/[0-9]+\.[0-9]+\.[0-9]+"
  matches "and which one graded each gate" \
          "$(floor "$tmp/rt" observe | awk -F'\t' '$3 == "gate.finished"')" "runtime=floor/[0-9]+\.[0-9]+\.[0-9]+"

  # Both rows come from one run, so they agree. Two that disagree are what a later rule would read.
  is "and one run's rows agree on it" \
     "$(floor "$tmp/rt" observe | grep -o 'runtime=[^ ]*' | sort -u | grep -c .)" "1"

  # Nothing refuses on it yet. A run whose runtime moved still completes, and the rows say it moved.
  is "a runtime nobody compares blocks nothing" "$(code_of floor "$tmp/rt" complete)" "0"
}
a_row_names_the_runtime_that_wrote_it

#
# Three facts, and #156 exists because they collapsed into one. The host is where it ran, the
# selector is who permitted it, the worker is what produced it — and a record naming one of the three
# has answered a different question.
#
a_row_names_the_worker_apart_from_the_host() {
  make_repo "$tmp/wk" main && set_origin "$tmp/wk" 'https://gitlab.com/acme/wk.git' \
    || { skip "the worker — git could not make a repo here"; return; }

  ( cd "$tmp/wk" && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="ada@example.com" \
      FOUNDRY_WORKER="Some Model 9" sh "$runner" new "Named" >/dev/null 2>&1 )

  allowed=$(floor "$tmp/wk" policy)
  said=$(floor "$tmp/wk" observe)
  has "a run names the worker that produced it" "$said" "worker=Some Model 9"
  has "and the host it ran on, which is not that" "$said" "$(uname -n)"
  has "while the selector is recorded apart"      "$(cat "$(floor "$tmp/wk" path)/authority")" "ada@example.com"

  # A guessed worker is worse than none. `selector` falls back to a git address because a run with no
  # human may not deliver; a run with no named worker is ordinary.
  ( cd "$tmp/wk" && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="ada@example.com" \
      sh "$runner" new "Unnamed" >/dev/null 2>&1 )

  lacks "an unnamed worker is left out, never guessed" "$(floor "$tmp/wk" observe)" "worker="

  # Naming a worker is not being permitted to do anything, which is the whole of #156's separation.
  is "and naming one grants nothing" "$(floor "$tmp/wk" policy)" "$allowed"
}
a_row_names_the_worker_apart_from_the_host

#
# The middle trust level had no producer, so `judged` was a word in the RFC and nothing wrote it.
# Worse: `satisfied` read the level and never used it, so a gate could answer a clause whose whole
# point is that no command can.
#
a_judged_clause_wants_a_verdict() {
  make_repo "$tmp/jd" main && set_origin "$tmp/jd" 'https://gitlab.com/acme/jd.git' \
    && mkdir -p "$tmp/jd/.foundry" \
    && commit_file "$tmp/jd" .foundry/gates 'tests  true
' || { skip "a verdict — git could not make a repo here"; return; }

  jdrun=$(floor "$tmp/jd" new "Judged")
  floor "$tmp/jd" charter derive >/dev/null 2>&1
  floor "$tmp/jd" policy authorize 'https://gitlab.com/acme/jd.git' >/dev/null 2>&1
  floor "$tmp/jd" targets add 'https://gitlab.com/acme/jd.git' main >/dev/null 2>&1
  floor "$tmp/jd" open >/dev/null 2>&1

  # After the workspace. An introduced clause exits `authorise` at 11, and `open` runs `authorise`.
  floor "$tmp/jd" charter introduce Judged 'the interface is understandable' >/dev/null 2>&1

  is "a verdict on a Gate clause answers nothing" \
     "$(code_of floor "$tmp/jd" evidence verdict 'tests' 'A Reviewer' 'looks right')" "2"
  has "and says which verb does answer it" \
      "$(floor_says "$tmp/jd" evidence verdict 'tests' 'A Reviewer' 'looks right')" "answered by \`gates\`"

  # The whole of what `judged` means. Floor cannot prove who typed it — §2.5 says the file is
  # writable by the same user — so refusing the one name it already knows is what it can do.
  is "a worker may not judge its own work" \
     "$(code_of floor_worked "$tmp/jd" 'Some Model 9' evidence verdict 'the interface is understandable' 'Some Model 9' 'reads fine')" "2"

  # A `Judged:` clause rests on no pin, so invariant 1 reports it `introduced` and nothing reaches
  # satisfaction. A verdict is recorded and cannot yet satisfy — the derivation is what is missing,
  # not the verdict.
  has "a Judged clause rests on no pin, so it is introduced" \
      "$(floor "$tmp/jd" complete 2>&1)" "introduced: [the interface is understandable]"

  is "a verdict from something else is recorded" \
     "$(code_of floor "$tmp/jd" evidence verdict 'the interface is understandable' 'A Reviewer' 'a stranger read it in two minutes')" "0"
  has "as judged, never machine" "$(floor "$tmp/jd" evidence)" "	judged	"
  has "carrying who said it"     "$(floor "$tmp/jd" evidence)" "A Reviewer: a stranger read it"

  # The mirror of the first refusal. An answer here is stamped `human` and satisfaction wants
  # `judged`, so without this the record says a person answered while completion still calls it unmet.
  is "a person may not answer a Judged clause at completion" \
     "$(code_of floor "$tmp/jd" source ask completion 'the interface is understandable' 'Is it?')" "2"
  has "and is told what does answer it" \
      "$(floor_says "$tmp/jd" source ask completion 'the interface is understandable' 'Is it?')" \
      "record a verdict instead"

  # Whether a clause may exist is nobody else's call, whatever kind it is.
  lacks "while authorisation is still every kind's" \
        "$(floor_says "$tmp/jd" source ask authorisation 'the interface is understandable' 'May it?')" \
        "record a verdict instead"
}
a_judged_clause_wants_a_verdict

#
# Whether this host can be replaced. A run holding a workspace has a
# checkout somebody may be writing to, and swapping the
# host under it loses work nobody recorded.
#
# Its own home, because every other fixture here leaves runs behind and a
# host is only settled when nothing at all is in flight.
#
a_host_is_settled_when_no_run_holds_a_workspace() {
  make_repo "$tmp/stl" main && set_origin "$tmp/stl" 'https://github.com/acme/stl.git' \
    && mkdir -p "$tmp/stl/.foundry" \
    && commit_file "$tmp/stl" .foundry/gates 'tests  true
' || { skip "settled — git could not make a repo here"; return; }

  quiet="$tmp/quiethome"
  mkdir -p "$quiet"
  q() { floor_as "$tmp/stl" "$quiet" "$strun" "$@"; }

  is "a home holding no run is settled" \
     "$( cd "$tmp/stl" && FOUNDRY_HOME="$quiet" FOUNDRY_RUN="" FOUNDRY_WHO="" \
         sh "$runner" settled >/dev/null 2>&1; echo $? )" "0"

  strun=$( cd "$tmp/stl" && FOUNDRY_HOME="$quiet" FOUNDRY_RUN="" FOUNDRY_WHO="" \
           FOUNDRY_SOURCE="$dir_source" sh "$runner" new "Settled" 2>/dev/null )
  q charter derive >/dev/null 2>&1

  # A run that only charted holds nothing a worker writes to.
  is "a run with no workspace leaves it settled" "$(code_of q settled)" "0"

  q policy authorize 'https://github.com/acme/stl.git' >/dev/null 2>&1
  q targets add 'https://github.com/acme/stl.git' main >/dev/null 2>&1
  q open >/dev/null 2>&1

  is "a run holding one does not"  "$(code_of q settled)" "29"
  # `floor_as` drops stderr, so a refusal read through it is a refusal nobody heard.
  said=$( cd "$tmp/stl" && FOUNDRY_HOME="$quiet" FOUNDRY_RUN="$strun" FOUNDRY_WHO="" \
          sh "$runner" settled 2>&1 )
  has "and it is named"            "$said" "$(basename "$strun")"
  # Grading changes nothing. The workspace is still there and still being read.
  q gates >/dev/null 2>&1
  is "and grading it does not settle the host" "$(code_of q settled)" "29"
}
a_host_is_settled_when_no_run_holds_a_workspace

#
# One kind, two adapters that spell it differently. A directory carries `kind: defect` in
# frontmatter; GitHub carries a label called `foundry:defect`. Core is told `defect` by both and
# knows neither spelling.
#
a_work_kind_survives_the_adapter() {
  make_repo "$tmp/kd"  main && set_origin "$tmp/kd"  'https://gitlab.com/acme/kd.git'  \
    && make_repo "$tmp/kdq" main && set_origin "$tmp/kdq" 'https://gitlab.com/acme/kdq.git' \
    && make_repo "$tmp/kdp" main && set_origin "$tmp/kdp" 'https://gitlab.com/acme/kdp.git' \
    || { skip "a work kind — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf -- '---\nkind: defect\n---\n\nMend the thing\n'   > "$src/items/31"
  printf 'Mend another thing\n'                            > "$src/items/32"
  printf -- '---\nname: 33\n---\n\nkind: not a label\n'    > "$src/items/33"

  floor "$tmp/kd"  new "Kinds" >/dev/null; floor "$tmp/kd"  source read 31 >/dev/null 2>&1
  floor "$tmp/kdq" new "Quiet" >/dev/null; floor "$tmp/kdq" source read 32 >/dev/null 2>&1
  floor "$tmp/kdp" new "Prose" >/dev/null; floor "$tmp/kdp" source read 33 >/dev/null 2>&1

  is "a directory says what the work is" "$(floor "$tmp/kd" source kind)" "defect"

  # Most sources classify nothing, and a run without a kind is ordinary rather than broken.
  is "and a source that says nothing leaves none" "$(code_of floor "$tmp/kdq" source kind)" "1"

  # `kind:` in the body is the item's prose. Reading it would make a sentence a classification.
  is "a kind below the frontmatter is prose" "$(code_of floor "$tmp/kdp" source kind)" "1"

  # Two labels answer as two lines. Both used to be kept, so `source kind` printed a pair and the
  # reader chose in silence — which is the choice the short inventory exists to avoid.
  printf -- '---\nkind: defect chore\n---\n\nTwo at once\n' > "$src/items/34"

  make_repo "$tmp/kd2" main && set_origin "$tmp/kd2" 'https://gitlab.com/acme/kd2.git' \
    && floor "$tmp/kd2" new "Two kinds" >/dev/null || { skip "two kinds — no repo"; return; }

  is "an item the source calls two things is refused" \
     "$(code_of floor "$tmp/kd2" source read 34)" "31"
  has "and the refusal names both" \
      "$(floor_says "$tmp/kd2" source read 34)" "more than one kind"
  is "and the run keeps no kind at all" "$(code_of floor "$tmp/kd2" source kind)" "1"
}
a_work_kind_survives_the_adapter

#
# Two deliveries against one target, and whether they can be brought together. Nothing coordinates
# them — the source is asked what else is open, and a branch name is all that crosses.
#
# A host nobody answers on, so the fetch fails at once and the tracking refs the clone left behind
# are what answer. That is the offline half of the same path, and it is the half a fixture can run.
#
two_deliveries_reconcile_or_say_they_cannot() {
  make_repo "$tmp/rc" main && set_origin "$tmp/rc" 'https://127.0.0.1:1/acme/rc.git' \
    && commit_file "$tmp/rc" a 'one
' && commit_file "$tmp/rc" b 'one
' && mkdir -p "$tmp/rc/.foundry"     && commit_file "$tmp/rc" .foundry/gates 'tests  true
' || { skip "reconcile — git could not make a repo here"; return; }

  git -C "$tmp/rc" checkout -qb work/apart     >/dev/null 2>&1
  commit_file "$tmp/rc" b 'apart
'
  git -C "$tmp/rc" checkout -qb work/elsewhere main >/dev/null 2>&1
  commit_file "$tmp/rc" a 'elsewhere
'
  git -C "$tmp/rc" checkout -q main >/dev/null 2>&1

  mkdir -p "$src/items" "$src/deliveries"
  printf 'Bring them together\n' > "$src/items/41"

  rc=$(floor "$tmp/rc" new "Reconcile")
  floor "$tmp/rc" source read 41 >/dev/null 2>&1
  floor "$tmp/rc" charter derive >/dev/null 2>&1
  floor "$tmp/rc" policy authorize 'https://127.0.0.1:1/acme/rc.git' >/dev/null 2>&1
  floor "$tmp/rc" targets add      'https://127.0.0.1:1/acme/rc.git' main >/dev/null 2>&1
  work=$(only_slot "$(floor "$tmp/rc" open)")

  printf 'mine\n' > "$work/a"
  git -C "$work" -c user.email=a@b.c -c user.name=a commit -aqm "this run changes a"

  is "with nothing else open, there is nothing to bring together" \
     "$(code_of floor "$tmp/rc" reconcile)" "0"

  # A delivery from a run that is not this one, touching a file this one leaves alone.
  printf 'work/apart\t41\tSomeone else\n' > "$src/deliveries/2026-01-01-item-41-0000"
  is "a delivery that touches other files joins cleanly" \
     "$(code_of floor "$tmp/rc" reconcile)" "0"

  printf 'work/elsewhere\t41\tThe other one\n' > "$src/deliveries/2026-01-02-item-41-0000"
  is "and one that changes the same file cannot" \
     "$(code_of floor "$tmp/rc" reconcile)" "26"
  # The identity is the source's, and a directory's is a path. GitHub hands back a URL, and core
  # prints whichever it was given rather than deciding what a delivery is called.
  has "it says which delivery" \
      "$(floor_says "$tmp/rc" reconcile)" "2026-01-02-item-41-0000"
  has "and names the file rather than the fact" \
      "$(floor_says "$tmp/rc" reconcile)" "both change: a"

  # This run's own delivery is not something to reconcile with.
  printf 'foundry/%s\t41\tThis one\n' "$(basename "$rc")" > "$src/deliveries/$(basename "$rc")"
  is "a run does not reconcile with itself" \
     "$(printf '%s' "$(floor_says "$tmp/rc" reconcile)" | grep -c 'This one')" "0"

  # Never clean when it could not say. A branch nobody can fetch is not a branch that joins.
  printf 'work/nowhere\t41\tNobody can fetch this\n' > "$src/deliveries/2026-01-03-item-41-0000"
  has "a branch nobody could fetch is not one that reconciles" \
      "$(floor_says "$tmp/rc" reconcile)" "could not be fetched"
}
two_deliveries_reconcile_or_say_they_cannot

#
# `foundry:` is what GitHub calls a work kind. Core calls it a kind, and a literal anywhere else is
# portability already leaked — which is the thing to catch rather than the thing to hope for.
#
the_providers_prefix_lives_in_one_file() {
  leaked=$(grep -rl 'foundry:' "$here/bin" "$here/lib" "$here/hooks" 2>/dev/null \
             | grep -v 'source-github\.sh')

  is "the provider's label prefix lives in one file" "$leaked" ""
}
the_providers_prefix_lives_in_one_file

#
# §2.5's `human` evidence, and the stage is what makes it that. The same answer read at authorisation
# says the clause may exist; read at completion it says the clause was met.
#
# The answer names the clause or it is not one. `receive` carries whatever a human wrote — "no"
# included — so an answer satisfying by merely existing would turn every reply into a yes.
#
a_human_answer_can_satisfy_a_clause() {
  make_repo "$tmp/hv" main && set_origin "$tmp/hv" 'https://gitlab.com/acme/hv.git' \
    && commit_file "$tmp/hv" Makefile 'test:
	echo ok
' || { skip "human evidence — git could not make a repo here"; return; }

  mkdir -p "$src/items" && printf 'Ship it\n' > "$src/items/11"

  floor "$tmp/hv" new "Human evidence" >/dev/null
  floor "$tmp/hv" source read 11 >/dev/null 2>&1
  floor "$tmp/hv" charter derive >/dev/null 2>&1
  floor "$tmp/hv" policy authorize 'https://gitlab.com/acme/hv.git' >/dev/null 2>&1
  floor "$tmp/hv" targets add 'https://gitlab.com/acme/hv.git' main >/dev/null 2>&1
  floor "$tmp/hv" open >/dev/null 2>&1

  # After the workspace, and it has to be. An introduced clause exits `authorise` at 11, and `open`
  # runs `authorise` — so a clause introduced first is a run that can never hold a workspace.
  floor "$tmp/hv" charter introduce Decided "pricing copy signed off" >/dev/null 2>&1
  floor "$tmp/hv" source ask completion "pricing copy signed off" "Is it?" >/dev/null 2>&1

  q=$(ls "$src/questions/11" 2>/dev/null | head -1)
  id=$(printf '%s' "pricing copy signed off" | cksum | awk '{ print $1 }')

  mkdir -p "$src/answers/11"
  printf 'no, hold it back\n' > "$src/answers/11/$q"
  floor "$tmp/hv" source receive completion "pricing copy signed off" >/dev/null 2>&1

  is "an answer that does not name the clause satisfies nothing" \
     "$(floor "$tmp/hv" evidence 2>/dev/null | grep -c human)" "0"

  printf 'yes, %s is signed off\n' "$id" > "$src/answers/11/$q"
  floor "$tmp/hv" source receive completion "pricing copy signed off" >/dev/null 2>&1

  is  "an answer that names it is human evidence" \
      "$(floor "$tmp/hv" evidence 2>/dev/null | grep -c human)" "1"
  has "and completion reads it" \
      "$(floor "$tmp/hv" complete 2>&1)" ""
}
a_human_answer_can_satisfy_a_clause

#
# §2.2's authorisation answer. The same channel as satisfaction, and a different meaning: this one
# says the clause may exist, never that it was met.
#
# **The source is the store.** A resumed run re-reads instead of remembering, so replaying changes
# nothing and no second ledger appears — which is what §2.2 refuses.
#
authorisation_asks_and_hears() {
  make_repo "$tmp/aa" main && set_origin "$tmp/aa" 'https://gitlab.com/acme/aa.git' \
    && commit_file "$tmp/aa" Makefile 'test:
	echo ok
' || { skip "authorisation ask — git could not make a repo here"; return; }

  mkdir -p "$src/items" && printf 'Ship it\n' > "$src/items/12"

  floor "$tmp/aa" new "Ask" >/dev/null
  floor "$tmp/aa" source read 12 >/dev/null 2>&1
  floor "$tmp/aa" charter derive >/dev/null 2>&1
  floor "$tmp/aa" policy authorize 'https://gitlab.com/acme/aa.git' >/dev/null 2>&1
  floor "$tmp/aa" targets add 'https://gitlab.com/acme/aa.git' main >/dev/null 2>&1
  #
  # Nothing is introduced yet, and a work source is right there to be asked. **A run that asks when
  # nothing blocks breaks #66's test** — mark work, work runs — and until now nothing here would have
  # noticed: the check that carried this name asserted `charter check` exits 0, which never asks
  # anybody under any circumstances.
  #
  is "a run whose clauses all derive authorises" "$(code_of floor "$tmp/aa" authorise)" "0"
  is "and asks nobody" \
     "$(ls "$src/questions/12" 2>/dev/null | wc -l | tr -d ' ')" "0"

  floor "$tmp/aa" charter introduce Decided "ship on friday" >/dev/null 2>&1

  is "an introduced clause blocks" "$(code_of floor "$tmp/aa" authorise)" "11"
  is "and the question is where the human is" \
     "$(ls "$src/questions/12" 2>/dev/null | wc -l | tr -d ' ')" "1"

  q=$(ls "$src/questions/12" | head -1)
  id=$(printf '%s' "ship on friday" | cksum | awk '{ print $1 }')
  mkdir -p "$src/answers/12"
  #
  # The ask's own words, and nothing read them back. A question carrying no clause, no reason and no
  # way to answer it is one a human cannot act on — and the count above would still say one.
  #
  asked=$(cat "$src/questions/12/$q" 2>/dev/null)
  has "the ask carries the clause"   "$asked" "ship on friday"
  has "and why it blocked"           "$asked" "Nothing derives it"
  has "and what an answer must name" "$asked" "$id"


  # A refused stage banks nothing. One that kept a partial authorisation would carry it into the next
  # attempt, where nobody asked for it — and evidence, a selection and a pending note all land here.
  held=$(ls "$(floor "$tmp/aa" path)" | sort | tr '\n' ' ')

  printf 'no, not friday\n' > "$src/answers/12/$q"
  is "a decline is not approval" "$(code_of floor "$tmp/aa" authorise)" "11"
  is "and it banks nothing"      "$(ls "$(floor "$tmp/aa" path)" | sort | tr '\n' ' ')" "$held"

  printf 'yes, %s may exist\n' "$id" > "$src/answers/12/$q"
  is "an answer naming the clause authorises it" "$(code_of floor "$tmp/aa" authorise)" "0"
  is "and asking again asks nothing new" \
     "$(ls "$src/questions/12" | wc -l | tr -d ' ')" "1"

  # Allowed to exist is not met. A stage that satisfied what it permitted would let a run write its
  # own bar, allow it, and clear it, in three commands nobody else read.
  lacks "and satisfies nothing by permitting it" \
        "$(cat "$(floor "$tmp/aa" path)/evidence" 2>/dev/null)" "$id"

  #
  # Condition 3 refuses and never asks, and **this is the only run that can tell.** Every other run
  # exercising conditions 3 and 4 has no work source at all, so a stray question had nowhere to land
  # and nothing to be counted against.
  #
  aarun=$(floor "$tmp/aa" path)
  cp "$(charter_of "$aarun")" "$aarun/charter.keep"
  grep -v '^clause .* Gate tests$' "$aarun/charter.keep" > "$(charter_of "$aarun")"

  is "a clause the pins still derive, removed, refuses" "$(code_of floor "$tmp/aa" authorise)" "12"
  is "and asks nothing to do it" \
     "$(ls "$src/questions/12" | wc -l | tr -d ' ')" "1"
  cp "$aarun/charter.keep" "$(charter_of "$aarun")"

  #
  # An answer outlives the run that asked, and belongs to it. A second run over the same item derives
  # the same clause and a different question — `run + stage + clause` — so the answer sitting in the
  # source above is not its to read.
  #
  floor "$tmp/aa" new "Ask again" >/dev/null
  floor "$tmp/aa" source read 12 >/dev/null 2>&1
  floor "$tmp/aa" charter derive >/dev/null 2>&1
  floor "$tmp/aa" charter introduce Decided "ship on friday" >/dev/null 2>&1

  is "an answer to an earlier run is not this run's" \
     "$(code_of floor "$tmp/aa" source receive authorisation 'ship on friday')" "1"
}
authorisation_asks_and_hears

#
# The one step a human took that Foundry claimed to own. The item's read shape names `targets[]`, and
# nothing read them.
#
# **Advisory means anyone who can file an item wrote them**, so every one goes through the guards a
# typed target does. The item proposes; the allowlist decides.
#
the_item_names_its_targets() {
  make_repo "$tmp/ad" main && set_origin "$tmp/ad" 'https://gitlab.com/acme/ad.git' \
    && commit_file "$tmp/ad" Makefile 'test:
	echo ok
' || { skip "advised targets — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Ship it\n\ntargets: https://gitlab.com/attacker/evil.git\n' > "$src/items/14"
  printf 'Ship it\n' > "$src/items/15"

  floor "$tmp/ad" new "Advised" >/dev/null
  floor "$tmp/ad" source read 14 >/dev/null 2>&1

  is  "an item advising a repository nobody authorised is refused" \
      "$(code_of floor "$tmp/ad" targets add)" "5"
  has "and names the remedy" \
      "$(floor_says "$tmp/ad" targets add)" "policy authorize"
  is  "and selects nothing" "$(floor "$tmp/ad" targets)" ""

  floor "$tmp/ad" new "Advised none" >/dev/null
  floor "$tmp/ad" source read 15 >/dev/null 2>&1
  is "an item advising nothing says so" "$(code_of floor "$tmp/ad" targets add)" "2"

  printf 'Ship it\n\ntargets: https://gitlab.com/acme/ad.git\n' > "$src/items/16"
  floor "$tmp/ad" new "Advised own" >/dev/null
  floor "$tmp/ad" source read 16 >/dev/null 2>&1
  floor "$tmp/ad" policy authorize 'https://gitlab.com/acme/ad.git' >/dev/null 2>&1

  is  "an authorised one is selected without a human naming it" \
      "$(code_of floor "$tmp/ad" targets add)" "0"
  has "at the ref the bar came from" \
      "$(floor "$tmp/ad" targets)" "https://gitlab.com/acme/ad.git main"
}
the_item_names_its_targets

# A question is `run + stage + clause`, derived and never issued — §2.1. A resumed run recomputes it
# and finds what it already asked, which is why nothing anywhere holds a list of pending questions.
a_question_is_derived_not_issued() {
  [ -n "${wsrun:-}" ] || { skip "questions — no work source run"; return; }

  q=$(ws source ask authorisation tests 'May this clause exist?')

  matches "a question names the run, the stage and the clause" \
          "$q" "^$wsid\.authorisation\.$(clause_of tests)\$"
  is "asking again derives the same question" \
     "$(ws source ask authorisation tests 'May this clause exist?')" "$q"
  is "and the source still holds one" \
     "$(find "$src/questions/7" -type f 2>/dev/null | grep -c .)" "1"

  # Someone may be holding the first. Rewriting it under them is not a resume.
  is "the same question in other words is refused" \
     "$(code_of ws source ask authorisation tests 'Something else entirely?')" "17"

  # A stage is a reader, and there are two. A third is a question that goes out, gets answered, and
  # is never looked at again.
  is "a stage nothing reads is refused"                "$(code_of ws source ask later tests 'x')" "2"
  is "and a clause the charter does not hold is too"   "$(code_of ws source ask authorisation nosuch 'x')" "1"

  #
  # The human is asked where they already are — a file a person can open, in the source. Nothing is
  # written into the run, because a store of outstanding questions is the parallel ledger §2.2
  # refuses, and nothing waits on a terminal.
  #
  exists "the question is in the source, where a person already is" "$src/questions/7/$q"
  is "and the run holds no note that one is outstanding" \
     "$(grep -rl -- "$q" "$wsrun" 2>/dev/null | grep -c .)" "0"
  is "asking reads no terminal" \
     "$( cd "$tmp/wsrc" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$wsrun" FOUNDRY_WHO="" \
         sh "$runner" source ask authorisation tests 'May this clause exist?' </dev/null 2>/dev/null )" "$q"
}
a_question_is_derived_not_issued

# `receive` carries an answer and decides nothing about it. There is no parameter for one, so a
# worker can produce a human's answer only by writing it where a human's answer lives.
an_answer_is_carried_never_minted() {
  [ -n "${q:-}" ] || { skip "answers — no question"; return; }

  is "an unanswered question is not an answer"  "$(code_of ws source receive authorisation tests)" "1"
  is "and it comes back saying nothing at all"  "$(ws source receive authorisation tests)" ""

  answer_with "$q" 'no — not like this'

  is "a human's answer comes back as they wrote it" \
     "$(ws source receive authorisation tests)" "no — not like this"
  is "receive names a stage and a clause, never an answer" \
     "$(code_of ws source receive authorisation tests yes)" "2"
  is "replaying it says the same thing" \
     "$(ws source receive authorisation tests)" "no — not like this"

  # The stage is what keeps an answer permitting a clause from ever saying the clause was met.
  is "an answer at one stage is no answer at the other" \
     "$(code_of ws source receive completion tests)" "1"
}
an_answer_is_carried_never_minted

#
# Silence is not approval, and neither is a refusal, and neither is a yes. Authorisation reads no
# answer yet — this stage carries questions and nothing more — so the only thing that could change
# what a run may do is a human editing an artifact.
#
an_answer_authorises_nothing() {
  [ -n "${wsrun:-}" ] || { skip "authorisation — no work source run"; return; }

  ws charter introduce Judged 'the interface is understandable' >/dev/null 2>&1
  is "an introduced clause leaves the run unauthorised" "$(code_of ws authorise)" "11"

  # The stage asked when it blocked, so nothing here asks again — a second ask in other words under
  # one identity is refused, which is what keeps a resumed run from piling questions up.
  qi=$(ls "$src/questions/7" | head -1)

  answer_with "$qi" 'yes, go ahead'
  is "an approval sitting in the source authorises nothing" "$(code_of ws authorise)" "11"
  is "and it comes back as an answer, no more" \
     "$(ws source receive authorisation 'the interface is understandable')" "yes, go ahead"

  answer_with "$qi" 'no'
  is "a refusal leaves it exactly as unauthorised" "$(code_of ws authorise)" "11"

  # The same code and the same shape for yes and for no. Deciding which one it is is the reader's,
  # and a transport that could tell them apart would be answering for the human.
  is "and comes back the same way an approval does" \
     "$(code_of ws source receive authorisation 'the interface is understandable')" "0"

  lacks "an answer widens no allowlist" "$(ws policy)" "acme/items"
  is    "and grants no target"          "$(code_of ws targets add https://gitlab.com/acme/items.git main)" "5"
}
an_answer_authorises_nothing

# A delivery is addressed to the item and belongs to the run — one item has many runs, and each
# delivers its own.
#
# The run records the identity it was given and refuses a second branch from that, before the source
# is asked at all. The adapter holds the same rule and keeps it, because floor is not its only
# caller — so the record comes off below to reach it.
one_item_has_many_runs() {
  [ -n "${wsrun:-}" ] || { skip "deliveries — no work source run"; return; }

  first=$(ws source publish work/first 'The first attempt')
  exists "publishing answers with the delivery's identity" "$first"
  is "and resuming answers with the same one" "$(ws source publish work/first 'The first attempt')" "$first"

  rm -f "$wsrun/delivery"
  is "a second branch is a second delivery, so it is refused" \
     "$(code_of ws source publish work/second 'The first attempt')" "17"

  unread=$(floor "$tmp/bare" new "Unread")
  is "a run that has read no item can address no delivery" \
     "$(code_of floor_as "$tmp/bare" "$home" "$unread" source publish work/x 'A title')" "1"

  # The second run, in the same checkout. `new` moves the pointer, so everything above this line
  # addressed its run by name.
  second=$(floor "$tmp/wsrc" new "Work source")
  differs "a second run is never the first run's name" "$second" "$wsrun"

  is "a second run reads the same item"      "$(code_of floor "$tmp/wsrc" source read 7)" "0"
  differs "and publishes its own delivery"   "$(floor "$tmp/wsrc" source publish work/second 'The second attempt')" "$first"

  # Run ids are unique over all time, so the first run's key can never be derived again — which is
  # what keeps an answer left in a source from reaching a run that was not asked.
  floor "$tmp/wsrc" charter derive >/dev/null 2>&1
  is "the first run's answer is not the second run's" \
     "$(code_of floor "$tmp/wsrc" source receive authorisation tests)" "1"
}
one_item_has_many_runs

# Grants reserve a name and a run that authorised nothing used to hand its back, so the same base
# minted the same id, the same clause id, and a question byte-identical to one already answered.
a_deleted_run_never_lends_its_name() {
  gone=$(floor "$tmp/bare" new "Never again")
  rm -rf "$gone"
  differs "a deleted run's name is never minted again" "$(floor "$tmp/bare" new "Never again")" "$gone"
}
a_deleted_run_never_lends_its_name

# A source that is not there answers "no item", and no item is what an unread run looks like.
a_missing_source_is_not_silence() {
  [ -n "${wsrun:-}" ] || { skip "missing source — no work source run"; return; }

  is "a work source that is not there stops the command" \
     "$( cd "$tmp/wsrc" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$wsrun" FOUNDRY_SOURCE="$tmp/no-such" \
         sh "$runner" source read 7 >/dev/null 2>&1; printf '%s' "$?" )" "3"
}
a_missing_source_is_not_silence

#
# The second adapter, driven by a `gh` that is not GitHub. It answers from files, so the adapter's
# own conventions run for real — the marker line, the digest, the search for this run's delivery.
#
# **What it cannot say is whether the service behaves that way.** Nothing here has spoken to it, and
# a suite that needs a network and a token is a suite nobody runs.
#
fake_gh() {
  mkdir -p "$1" || return 1
  cat > "$1/gh" <<'STUB'
#!/bin/sh
# Not GitHub. It answers from $GH_STORE so the adapter's conventions can be exercised offline.
set -u
store=${GH_STORE:?}
mkdir -p "$store"

case "$*" in
  # The comments, as `gh` returns them: a list of bodies. **`gh` evaluates `--jq` itself**, so this
  # honours the one expression the adapter sends — a chosen line before each body — and emits bodies
  # alone if it stops asking for one. A fixture that printed the boundary regardless would be
  # agreeing with the adapter instead of the service.
  # Labels a repository already had sit beside the ones Foundry owns. The adapter takes only its
  # own, and the fixture carries both so it can be caught taking more.
  "issue view"*"--json labels"*)   [ -f "$store/reads-fail" ] && { echo "HTTP 401: Bad credentials" >&2; exit 1; }
                            cat "$store/labels" 2>/dev/null ;;
  "issue view"*"--json comments"*) [ -f "$store/reads-fail" ] && { echo "could not resolve host: api.github.com" >&2; exit 1; }
                            case "$*" in *floor-comment*) mark='floor-comment:' ;; *) mark='' ;; esac
                            for body in "$store/comments"/*; do
                                [ -f "$body" ] || continue
                                slot=${body##*/}
                                who=$(cat "$store/authors/$slot" 2>/dev/null || printf 'foundry-run')
                                [ -n "$mark" ] && printf '%s %s\n' "$mark" "$who"
                                cat "$body"
                            done ;;
  # An item nobody filed and a source nobody could ask both fail here, and only the probe below tells
  # them apart. GitHub answers 1 for each.
  "issue view"*)            [ -f "$store/reads-fail" ] && { echo "HTTP 401: Bad credentials" >&2; exit 1; }
                            cat "$store/item" 2>/dev/null ;;
  # The probe. A repository cannot be absent, so failing here is the host and never the item.
  # The stub answers a repository view with a url only when asked for
  # one. Real gh applies the jq itself, so a fixture printing the
  # same field regardless would be agreeing with the adapter.
  "repo view"*"--json url"*)  [ -f "$store/reads-fail" ] && { echo "HTTP 401: Bad credentials" >&2; exit 1; }
                            sed -e 's/\.git$//' "$store/repo" 2>/dev/null ;;
  "repo view"*)             [ -f "$store/reads-fail" ] && { echo "HTTP 401: Bad credentials" >&2; exit 1; }
                            printf '{"name":"gh"}\n' ;;
  # One comment, one body, in order. GitHub keeps a list and the adapter asks for the field, so the
  # fixture keeps a list too — a single file with separators in it would be a rendering nobody serves.
  #
  # A body written here belongs to whoever `api user` names, because that is who is
  # running. A test drops another person's words by writing both files
  # itself, which is the only way two authors exist offline.
  "issue comment"*)         mkdir -p "$store/comments" "$store/authors"
                            slot=$(printf '%03d' "$(find "$store/comments" -type f | grep -c .)")
                            printf '%s\n' "$5" > "$store/comments/$slot"
                            cat "$store/me" 2>/dev/null > "$store/authors/$slot" \
                                || printf 'foundry-run\n' > "$store/authors/$slot" ;;
  # Who this run comments as. `posting_as` fails closed on an empty answer, so a
  # store with no `me` still names somebody — the absent case is its
  # own fixture, set by emptying the file rather than deleting it.
  "api user"*)              [ -f "$store/reads-fail" ] && { echo "HTTP 401: Bad credentials" >&2; exit 1; }
                            cat "$store/me" 2>/dev/null || printf 'foundry-run\n' ;;
  # A read that cannot answer. GitHub fails this way for a network, a token or a rate limit, and none
  # of them mean "nothing is there yet" — which is what both readers below used to conclude.
  # `gh` matches words in a body, so a run made the same day as another comes back on shared tokens.
  # The stub answers the same way, and evaluates the `--jq` the adapter sends rather than
  # filtering for it — a fixture that pre-filtered would grade its own assumption.
  "pr list"*)               [ -f "$store/reads-fail" ] && { echo "could not resolve host: api.github.com" >&2; exit 1; }
                            want=${6%% *}
                            case "$*" in *"floor-run: $want"*) exact=1 ;; *) exact=0 ;; esac
                            awk -v run="$want" -v exact="$exact" '
                              exact && $3 == run                      { print $1, $2; next }
                              !exact && index($3, substr(run, 1, 10)) { print $1, $2 }
                            ' "$store/prs" 2>/dev/null || true ;;
  # `gh` joins the four fields itself, so the fixture holds the answer already joined — the same
  # shape the adapter's `--jq` produces, and one a test can move a head in.
  "pr view"*)               [ -f "$store/reads-fail" ] && { echo "HTTP 502: Bad gateway" >&2; exit 1; }
                            cat "$store/state" 2>/dev/null ;;
  "pr merge"*)              [ -f "$store/reads-fail" ] && { echo "could not resolve host" >&2; exit 1; }
                            printf '%s
' "$3" >> "$store/merged" ;;
  "pr create"*)             [ -f "$store/writes-fail" ] && { echo "GraphQL: Head sha can't be blank (createPullRequest)" >&2; exit 1; }
                            url="https://example.invalid/pr/$(cat "$store/prs" 2>/dev/null | grep -c .)"
                            run=$(printf '%s' "$8" | awk '$1 == "floor-run:" { print $2 }')
                            printf '%s' "$8" | head -1 >> "$store/words"
                            printf '%s %s %s\n' "$4" "$url" "$run" >> "$store/prs"
                            printf '%s\n' "$url" ;;
  *) exit 2 ;;
esac
STUB
  chmod +x "$1/gh"
}

# A person comments, and order is what makes an answer come *after* a question. Numbered the way the
# stub numbers them, because a name that sorts differently is a transcript nobody wrote.
#
# The author is a person, never the run. #373 is what the two being one costs: the run's own
# note, holding a clause number so a person could copy it, was read back as
# that person saying yes. A second author is what tells them apart.
gh_says() { said_by a-person "$1"; }

# The run's own words, in the same place a person's would land. Only a test that means to
# check the refusal calls this — every other comment in this suite is a
# person's, and reads that way.
run_says() { said_by foundry-run "$1"; }

said_by() {
  mkdir -p "$GH_STORE/comments" "$GH_STORE/authors"
  slot=$(printf '%03d' "$(find "$GH_STORE/comments" -type f | grep -c .)")
  printf '%s\n' "$2" > "$GH_STORE/comments/$slot"
  printf '%s\n' "$1" > "$GH_STORE/authors/$slot"
}

the_other_adapter() {
  make_repo "$tmp/gh" main && set_origin "$tmp/gh" 'https://github.com/acme/gh.git' \
    && commit_file "$tmp/gh" Makefile 'test:
	echo ok
' || { skip "the other adapter — git could not make a repo here"; return; }

  fake_gh "$tmp/ghbin" || { skip "the other adapter — could not put a gh on the path"; return; }
  export GH_STORE="$tmp/ghstore"
  mkdir -p "$GH_STORE"
  printf 'Make the other thing\n\nAnd make it well.\n' > "$GH_STORE/item"
  printf 'foundry:defect\nbug\n' > "$GH_STORE/labels"

  ghrun=$( cd "$tmp/gh" && PATH="$tmp/ghbin:$PATH" FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
           sh "$runner" new "Other adapter" 2>/dev/null )
  gh_floor() { ( cd "$tmp/gh" && PATH="$tmp/ghbin:$PATH" FOUNDRY_HOME="$home" FOUNDRY_RUN="$ghrun" \
                 FOUNDRY_WHO="" sh "$runner" "$@" 2>/dev/null ); }

  has "the other adapter reads an item" "$(gh_floor source read 12)" "And make it well"

  # The same word the directory answered with, and the repository's own `bug` left alone.
  is "and says what the work is, in core's word" "$(gh_floor source kind)" "defect"

  #
  # An item nobody filed, and a source nobody could ask, are two answers. Both used to be *no item*.
  #
  # `gh` exits 1 for each, so the probe is what separates them: the fixture fails a repository read
  # only when it fails everything, which is what a credential GitHub refuses looks like.
  #
  : > "$GH_STORE/reads-fail"
  is "a source that could not be asked refuses" "$(code_of gh_floor source read 12)" "20"

  rm -f "$GH_STORE/reads-fail"
  mv "$GH_STORE/item" "$GH_STORE/away"
  is "and an item nobody filed is still absent" "$(code_of gh_floor source read 12)" "1"
  mv "$GH_STORE/away" "$GH_STORE/item"

  # The run records which item, never which source said it. A run carried to a machine with neither
  # adapter installed still means what it meant, and this file is the only one that could say otherwise.
  is "the run records the item, not the source that answered" "$(cat "$ghrun/source" 2>/dev/null)" "12"

  gh_floor charter derive >/dev/null 2>&1

  gq=$(gh_floor source ask authorisation tests 'May this clause exist?')
  is "and derives the same question there" "$gq" "$(basename "$ghrun").authorisation.$(clause_of tests)"
  is "asking twice is one question"  "$(gh_floor source ask authorisation tests 'May this clause exist?')" "$gq"
  is "and the source holds one"      "$(grep -rl 'floor-question' "$GH_STORE/comments" 2>/dev/null | grep -c .)" "1"
  is "other words under one question are refused" \
     "$(code_of gh_floor source ask authorisation tests 'Something else entirely?')" "17"

  is "an unanswered question is not an answer" "$(code_of gh_floor source receive authorisation tests)" "1"
  # A person comments. No marker — one they have to type is a command language nobody told them.
  gh_says 'yes, go ahead'
  is "and a human's answer comes back as they wrote it" \
     "$(gh_floor source receive authorisation tests)" "yes, go ahead"

  # Two people answer, and both are the answer. `want` survives a comment boundary and only a later
  # question clears it — a reader stopping at the first boundary takes one voice for all of them, and
  # a fixture holding one reply cannot tell.
  gh_says 'and a second person agrees'
  has "everything said after the question comes back, not just the first" \
      "$(gh_floor source receive authorisation tests)" "a second person agrees"
  has "and the first is still there"  \
      "$(gh_floor source receive authorisation tests)" "yes, go ahead"

  # #373. The run posted a note explaining its own question, and the note held the clause number so a
  # person could copy it. That note was read back as the person's yes, and floor stamped
  # a human answer nobody had given. The author was in the data the whole time.
  run_says 'To answer, post the clause number. It is 1234567890.'
  lacks "the run's own comment is not an answer" \
        "$(gh_floor source receive authorisation tests)" "1234567890"
  has "and a person's answer still comes back" \
      "$(gh_floor source receive authorisation tests)" "yes, go ahead"

  # Fails closed, and this is why. An adapter that cannot name itself cannot tell its own words from
  # a person's, so it must refuse. Guessing here means guessing in its own favour.
  : > "$GH_STORE/me"
  is "an adapter that cannot name itself refuses to read an answer" \
     "$(code_of gh_floor source receive authorisation tests)" "20"
  printf 'foundry-run\n' > "$GH_STORE/me"

  # The same rule where an answer is read. This one is fail-safe — the run waits rather than proceeds
  # — and it still reported a human who had not answered when nobody could be asked.
  : > "$GH_STORE/reads-fail"
  is "an answer that could not be read refuses" \
     "$(code_of gh_floor source receive authorisation tests)" "20"
  rm -f "$GH_STORE/reads-fail"

  # One question is asked per unauthorised clause, so several stand open at once. The one below is not
  # an answer to the one above, and the one above is still answered.
  gh_floor source ask completion tests 'And was it met?' >/dev/null 2>&1
  is "a later question is no answer to an earlier one" \
     "$(code_of gh_floor source receive completion tests)" "1"
  has "and the answer above it still stands" \
     "$(gh_floor source receive authorisation tests)" "yes, go ahead"

  gd=$(gh_floor source publish work/other 'The other attempt')
  matches "publishing answers with the delivery's identity" "$gd" '^https://'
  is "and resuming answers with the same one" "$(gh_floor source publish work/other 'The other attempt')" "$gd"

  # Two runs made the same day share three tokens of four, and GitHub matches words. Another run's
  # pull request came back as this one's delivery, so `publish` compared branches,
  # found them different, and refused a run that had never delivered.
  #
  # The day comes from the run under test. Written out, it was true for one
  # day: past midnight the decoy shared no tokens, the adapter
  # answered right for the wrong reason, and main went red.
  day=$(basename "$ghrun" | cut -c1-10)
  decoy="foundry/$day-item-219-0000 https://example.invalid/pr/9 $day-item-219-0000"
  { echo "$decoy"; cat "$GH_STORE/prs"; } > "$GH_STORE/prs.new"
  mv "$GH_STORE/prs.new" "$GH_STORE/prs"
  # The record answers before the source does, so it comes off to reach the adapter at all.
  rm -f "$ghrun/delivery"

  is "a delivery lookup matching another run's tokens is not this run's" \
     "$(code_of gh_floor source publish work/other 'The other attempt')" "0"
  is "and it is still this run's own delivery" \
     "$(gh_floor source publish work/other 'The other attempt')" "$gd"

  #
  # The run answers before the source does. GitHub's body index is eventually consistent, so a lookup
  # seconds after a delivery says *nothing* — truthfully — and nothing is what opens a second one.
  #
  # `reads-fail` makes asking impossible, so an answer below came from the run and nowhere else.
  #
  opened=$(grep -c . "$GH_STORE/prs" 2>/dev/null)
  : > "$GH_STORE/reads-fail"

  is "a run says what it delivered with the source unreachable" \
     "$(gh_floor source publish work/other 'The other attempt')" "$gd"
  is "and opens nothing to find out" "$(grep -c . "$GH_STORE/prs" 2>/dev/null)" "$opened"
  is "a second branch is refused from the run's own record" \
     "$(code_of gh_floor source publish work/third 'The other attempt')" "17"

  # A run made before this rule holds no record, and the source is the right answer for it. Removed by
  # hand below wherever that is the run under test.
  rm -f "$GH_STORE/reads-fail" "$ghrun/delivery"

  is "a run holding no record asks the source instead" \
     "$(gh_floor source publish work/other 'The other attempt')" "$gd"

  rm -f "$ghrun/delivery"
  is "a second branch is refused there too" \
     "$(code_of gh_floor source publish work/third 'The other attempt')" "17"

  #
  # A lookup that failed, and a delivery that is absent, are not the same answer.
  #
  # Empty used to mean *open one*, so a resumed run whose search hit a network, an expired token or a
  # rate limit published a second delivery for work that already had one — the case the run in the
  # body exists to make impossible.
  #
  : > "$GH_STORE/reads-fail"

  is "a delivery lookup that failed refuses"      "$(code_of gh_floor source publish work/other 'The other attempt')" "19"
  is "and opens nothing while it cannot tell"      "$(grep -c . "$GH_STORE/prs" 2>/dev/null)" "$opened"

  # The same shape one function over. Empty is what `put_question` reads as *not asked yet*, and it
  # answers by asking — so a resumed run whose lookup failed put the question to the human twice.
  asked=$(grep -rl 'floor-question' "$GH_STORE/comments" 2>/dev/null | grep -c .)

  is "a question lookup that failed refuses"      "$(code_of gh_floor source ask authorisation tests 'May this clause exist?')" "1"
  is "and asks nobody twice while it cannot tell"      "$(grep -rl 'floor-question' "$GH_STORE/comments" 2>/dev/null | grep -c .)" "$asked"

  rm -f "$GH_STORE/reads-fail"
  is "and the delivery it already had comes back once it can"      "$(gh_floor source publish work/other 'The other attempt')" "$gd"

  # The other half of the same verb.  already exits 19 when the push is refused; the
  # publish half left by exit 1, which reads as no run, no charter, nothing to send —
  # and sends the reader to a remedy for a run that does not exist.
  #
  # Nothing already delivered, or  answers first and the create is never
  # reached. The store is put back because the checks above spent effort filling it.
  mv "$GH_STORE/prs" "$GH_STORE/prs.held"
  rm -f "$ghrun/delivery"
  : > "$GH_STORE/writes-fail"

  is "a delivery the source refused costs what a delivery costs"      "$(code_of gh_floor source publish work/fourth 'The other attempt')" "19"

  rm -f "$GH_STORE/writes-fail"
  mv "$GH_STORE/prs.held" "$GH_STORE/prs"

  #
  # Every delivery above named its item and closed nothing. `Closes` is GitHub's keyword and it
  # shuts the issue on merge, so a run writing it asserts a list it never read.
  #
  is "a delivery names its item" "$(head -1 "$GH_STORE/words")" "Refs #12"

  ghrun=$( cd "$tmp/gh" && PATH="$tmp/ghbin:$PATH" FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO=""            sh "$runner" new "Other adapter, closing" 2>/dev/null )

  is "closing what no run read is refused" "$(code_of gh_floor policy closes)" "2"

  gh_floor source read 12 >/dev/null 2>&1
  gh_floor policy closes  >/dev/null 2>&1
  has "the grant is listed apart from the rest" "$(gh_floor policy)" "12	closes"

  gh_floor source publish work/closing 'The closing attempt' >/dev/null 2>&1
  is "and then a delivery may say the item is finished" "$(tail -1 "$GH_STORE/words")" "Closes #12"

  unset GH_STORE
}
the_other_adapter

#
# An item filed in a repository, advising that same repository. The bootstrap
# authorises it because the run stands there, so nothing else
# would stop advice alone from selecting it.
#
# A human naming it still can. The refusal is about the path nobody
# typed, not about the repository, and self-hosting is
# exactly this shape done deliberately.
#
advice_may_not_make_the_source_a_target() {
  make_repo "$tmp/sn" main && set_origin "$tmp/sn" 'https://github.com/acme/sn.git' \
    && commit_file "$tmp/sn" Makefile 'test:
	echo ok
' || { skip "source as a target — git could not make a repo here"; return; }

  fake_gh "$tmp/snbin" || { skip "source as a target — could not put a gh on the path"; return; }
  store="$tmp/snstore"
  mkdir -p "$store"
  printf 'Mend it\n\ntargets: https://github.com/acme/sn.git\n' > "$store/item"
  printf 'https://github.com/acme/sn.git\n'                     > "$store/repo"

  sn() { ( cd "$tmp/sn" && PATH="$tmp/snbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
           FOUNDRY_RUN="$snrun" FOUNDRY_WHO=a@b sh "$runner" "$@" 2>/dev/null ); }
  sn_says() { ( cd "$tmp/sn" && PATH="$tmp/snbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
                FOUNDRY_RUN="$snrun" FOUNDRY_WHO=a@b sh "$runner" "$@" 2>&1 ); }
  snrun=$( cd "$tmp/sn" && PATH="$tmp/snbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
           FOUNDRY_RUN="" FOUNDRY_WHO=a@b sh "$runner" new "Source" 2>/dev/null )

  sn source read 12 >/dev/null 2>&1
  sn policy authorize 'https://github.com/acme/sn.git' >/dev/null 2>&1

  is  "advice naming the item's own repository is refused" "$(code_of sn targets add)" "28"
  has "and says which path may still name it" "$(sn_says targets add)" "targets add"
  is  "so nothing is selected"                "$(sn targets)" ""

  is "a human naming it is not advice, and holds" \
     "$(code_of sn targets add 'https://github.com/acme/sn.git' main)" "0"
}
advice_may_not_make_the_source_a_target

#
# A source that answers `read` and nothing else. §2.1 proposes four
# operations and this has one, which the goal calls valid, so the
# contract admits a source that is less than four verbs.
#
# The run reads its item and then cannot ask. Both facts matter:
# a source this small still carries work, and every
# verb it lacks says which one and why.
#
a_source_that_can_only_be_read() {
  make_repo "$tmp/ro" main && set_origin "$tmp/ro" 'https://gitlab.com/acme/ro.git' \
    && commit_file "$tmp/ro" Makefile 'test:
	echo ok
' || { skip "a read-only source — git could not make a repo here"; return; }

  mkdir -p "$src/items"
  printf 'Mend it\n\nAnd say nothing back.\n' > "$src/items/51"

  only_read="$(dirname "$runner")/../lib/source-read-only.sh"
  ro() { ( cd "$tmp/ro" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$rorun" FOUNDRY_WHO="" \
           FOUNDRY_SOURCE="$only_read" sh "$runner" "$@" 2>/dev/null ); }
  ro_says() { ( cd "$tmp/ro" && FOUNDRY_HOME="$home" FOUNDRY_RUN="$rorun" FOUNDRY_WHO="" \
                FOUNDRY_SOURCE="$only_read" sh "$runner" "$@" 2>&1 ); }

  rorun=$( cd "$tmp/ro" && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
           FOUNDRY_SOURCE="$only_read" sh "$runner" new "Read only" 2>/dev/null )

  has "a source with one verb still carries the work" "$(ro source read 51)" "say nothing back"

  ro charter derive >/dev/null 2>&1
  ro charter introduce Decided 'pricing copy signed off' >/dev/null 2>&1

  is  "and asking it refuses"       "$(code_of ro source ask authorisation 'pricing copy signed off' 'May it?')" "27"
  has "naming the source's shape"       "$(ro_says source ask authorisation 'pricing copy signed off' 'May it?')" "can only be read"

  # The same rule where a delivery is reported. A source that cannot be written to cannot be told.
  is "and telling it about a delivery refuses too" \
     "$(code_of ro source publish work/ro 'The work')" "27"

  # Authorisation is where a person notices. It blocks on an introduced clause, and the
  # reason it gives has to be the shape of the source rather
  # than a fault it should retry.
  has "an introduced clause blocks, and says the source cannot ask" \
      "$(ro_says authorise)" "can only be read"
}
a_source_that_can_only_be_read

#
# **The thing merged must be the thing graded.** Every other refusal here is worth less than that
# one: a head that moved after grading is a tree nothing answered for, and landing it puts work in
# the trunk no gate ever saw.
#
# Provider permission is not authority. Anything that can run `gh` can merge whatever the practice
# says, so this grants intent and withholds nothing — which is why it is a grant of its own.
#
a_merge_lands_only_what_was_graded() {
  make_repo "$tmp/mg" main && set_origin "$tmp/mg" 'https://github.com/acme/mg.git' \
    && mkdir -p "$tmp/mg/.foundry" \
    && commit_file "$tmp/mg" .foundry/gates 'tests  true
' || { skip "merge — git could not make a repo here"; return; }

  fake_gh "$tmp/mgbin" || { skip "merge — could not put a gh on the path"; return; }
  store="$tmp/mgstore"
  mkdir -p "$store"
  printf 'Land it

And only what was graded.
' > "$store/item"

  mg() { ( cd "$tmp/mg" && PATH="$tmp/mgbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
           FOUNDRY_RUN="$mgrun" FOUNDRY_WHO=a@b sh "$runner" "$@" 2>/dev/null ); }
  mgrun=$( cd "$tmp/mg" && PATH="$tmp/mgbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
           FOUNDRY_RUN="" FOUNDRY_WHO=a@b sh "$runner" new "Merge" 2>/dev/null )

  mg source read 12 >/dev/null 2>&1
  mg charter derive >/dev/null 2>&1
  mg policy authorize  'https://github.com/acme/mg.git' >/dev/null 2>&1
  mg policy deliver-to 'https://github.com/acme/mg.git' >/dev/null 2>&1
  mg targets add       'https://github.com/acme/mg.git' main >/dev/null 2>&1
  work=$(only_slot "$(mg open)")
  mg gates >/dev/null 2>&1

  is "a run that may deliver may not merge" "$(code_of mg merge)" "23"

  mg policy merge-to 'https://github.com/acme/mg.git' >/dev/null 2>&1
  is "and a run that delivered nothing has nothing to land" "$(code_of mg merge)" "24"

  mg source publish work/mg 'The work' >/dev/null 2>&1
  graded=$(git -C "$work" rev-parse HEAD)

  # The first falsifier. Grade one commit, move the delivery to another, merge.
  printf '0000000000000000000000000000000000000000 OPEN MERGEABLE NONE\n' > "$store/state"
  is "a delivery whose head moved is refused" "$(code_of mg merge)" "24"
  is "and nothing was landed"                 "$(cat "$store/merged" 2>/dev/null)" ""

  printf '%s OPEN MERGEABLE FAILURE\n' "$graded" > "$store/state"
  is "a check that did not pass is refused"   "$(code_of mg merge)" "24"

  # A pending rollup carries no failure, so a reader looking for one finds an empty list and calls it
  # clean. Named separately because that is the shape it fails in.
  printf '%s OPEN MERGEABLE PENDING\n' "$graded" > "$store/state"
  is "and one that has not answered is not one that passed" "$(code_of mg merge)" "24"

  printf '%s OPEN CONFLICTING NONE\n' "$graded" > "$store/state"
  is "a source that will not take it is refused" "$(code_of mg merge)" "24"

  printf '%s CLOSED MERGEABLE NONE\n' "$graded" > "$store/state"
  is "and a delivery nobody left open is not merged" "$(code_of mg merge)" "24"

  printf '%s OPEN MERGEABLE SUCCESS,SUCCESS\n' "$graded" > "$store/state"
  is "the thing that was graded is merged" "$(code_of mg merge)" "0"
  matches "and the source was told to land it" "$(cat "$store/merged" 2>/dev/null)" "^https://"

  # A retry after a merge that landed. Refusing would read as a merge that never happened, and
  # merging again is not something a source forgives twice.
  printf '%s MERGED MERGEABLE SUCCESS\n' "$graded" > "$store/state"
  is "a retry settles rather than landing twice" "$(code_of mg merge)" "0"
  is "and the source was asked once"  "$(grep -c . "$store/merged" 2>/dev/null)" "1"

  # Fail-safe, and the one that has to be said out loud: nobody answering is not the source saying
  # yes.
  : > "$store/reads-fail"
  is "a lookup that failed never reads as safe to merge" "$(code_of mg merge)" "25"
  rm -f "$store/reads-fail"

  # A second run, its own delivery, and the first one may not land it. The adapter finds
  # a delivery by the run written into its body, so one run reaching
  # another's is a shape the key does not have.
  #
  # Held by construction and never tested, which is the same as untested.
  printf 'Land it\n\nAnd only what was graded.\n' > "$store/item"
  other=$( cd "$tmp/mg" && PATH="$tmp/mgbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
           FOUNDRY_RUN="" FOUNDRY_WHO=a@b sh "$runner" new "Another" 2>/dev/null )
  theirs() { ( cd "$tmp/mg" && PATH="$tmp/mgbin:$PATH" GH_STORE="$store" FOUNDRY_HOME="$home" \
               FOUNDRY_RUN="$other" FOUNDRY_WHO=a@b sh "$runner" "$@" 2>/dev/null ); }

  theirs source read 12 >/dev/null 2>&1
  theirs charter derive >/dev/null 2>&1
  theirs policy authorize  'https://github.com/acme/mg.git' >/dev/null 2>&1
  theirs policy deliver-to 'https://github.com/acme/mg.git' >/dev/null 2>&1
  theirs policy merge-to   'https://github.com/acme/mg.git' >/dev/null 2>&1
  theirs targets add       'https://github.com/acme/mg.git' main >/dev/null 2>&1
  theirs open  >/dev/null 2>&1
  theirs gates >/dev/null 2>&1

  is "a run that delivered nothing may not land what another did" \
     "$(code_of theirs merge)" "24"
  is "and the source was still asked once" \
     "$(grep -c . "$store/merged" 2>/dev/null)" "1"
}
a_merge_lands_only_what_was_graded

# Level 1 has two halves and this is the second one: a repository whose remote is GitHub, on a
# machine with no `gh`, still has a work source. Skipped where a real `gh` would answer instead.
a_remote_with_no_gh_still_has_a_source() {
  [ -n "${ghrun:-}" ] || { skip "no gh — the other adapter did not run"; return; }
  command -v gh >/dev/null 2>&1 && { skip "a remote with no gh — this machine has one"; return; }

  mkdir -p "$src/items"
  printf 'Read from a directory\n' > "$src/items/12"

  # Not through `floor_as`, which names the adapter. Detection is the whole of what this asks about,
  # and a check that pins the answer it is testing for passes whether or not detection still works.
  has "with no gh, a directory answers for a GitHub remote" \
      "$( cd "$tmp/gh" 2>/dev/null \
          && FOUNDRY_HOME="$home" FOUNDRY_RUN="$ghrun" FOUNDRY_WHO="" \
             sh "$runner" source read 12 2>/dev/null )" \
      "Read from a directory"

  # And says which half is missing. A directory answering *no item* for a GitHub remote is right about
  # the directory and wrong about the item, and only this line lets a reader tell.
  has "and says which half of level 1 is missing" \
      "$( cd "$tmp/gh" 2>/dev/null \
          && FOUNDRY_HOME="$home" FOUNDRY_RUN="$ghrun" FOUNDRY_WHO="" \
             sh "$runner" source read 12 2>&1 >/dev/null )" \
      "gh is not here"
}
a_remote_with_no_gh_still_has_a_source

# --- asking for the wrong thing ---

is "new with no title exits 2"  "$(code_of floor "$tmp/bare" new)" "2"
is "an unknown command exits 2" "$(code_of floor "$tmp/bare" fly)" "2"

#
# Standing authority — §2.3's allowlist declared once instead of granted per run.
#
# **Read at the base commit, never the working tree.** A worker can edit the file, and editing it
# must grant nothing: invariant 1's rule that a run's own work may invalidate authority and never
# create it.
#
practice_grants_without_asking_again() {
  make_repo "$tmp/st" main && set_origin "$tmp/st" 'https://gitlab.com/acme/st.git' \
    && mkdir -p "$tmp/st/.foundry" \
    && commit_file "$tmp/st" .foundry/practice 'grade    https://gitlab.com/acme/friend.git
grade    https://gitlab.com/acme/second.git
' || { skip "standing authority — git could not make a repo here"; return; }

  # The base, taken before the worker's commit below moves HEAD off it.
  base=$(git -C "$tmp/st" rev-parse HEAD)

  floor "$tmp/st" new "Standing" >/dev/null

  is "a repository the practice grades needs no per-run grant" \
     "$(code_of floor "$tmp/st" targets add 'https://gitlab.com/acme/friend.git' main)" "0"
  is "one it does not name is still refused" \
     "$(code_of floor "$tmp/st" targets add 'https://gitlab.com/acme/nope.git' main)" "5"
  has "and names the one command that grants it" \
      "$(floor_says "$tmp/st" targets add 'https://gitlab.com/acme/nope.git' main)" "policy authorize"

  # The same-run attack. A worker owns the checkout, so it can write anything into the file — and the
  # run reads the base, where a human put what a human meant.
  printf 'grade    https://gitlab.com/acme/nope.git\n' >> "$tmp/st/.foundry/practice"
  is "a worker adding itself to the practice grants nothing" \
     "$(code_of floor "$tmp/st" targets add 'https://gitlab.com/acme/nope.git' main)" "5"

  # And committing it. Owning the checkout means owning its history too, so every commit-based read
  # except the base's grants this — which is the whole of why the base is what gets read.
  commit_file "$tmp/st" .foundry/practice 'grade    https://gitlab.com/acme/friend.git
grade    https://gitlab.com/acme/nope.git
'
  is "nor does committing it" \
     "$(code_of floor "$tmp/st" targets add 'https://gitlab.com/acme/nope.git' main)" "5"

  # A practice nobody can read is not a practice granting nothing. Refusing either way is right; the
  # human told to grant what they already granted goes and grants it, and the broken base stays broken.
  #
  # `second.git` because the practice grants it and no check above has selected it — a repository
  # already selected is refused for that first, and would prove nothing about reading the practice.
  rm -f "$(loose_object "$tmp/st" "$base")"

  said=$(floor_says "$tmp/st" targets add 'https://gitlab.com/acme/second.git' main)
  is  "a practice that cannot be read still refuses" \
      "$(code_of floor "$tmp/st" targets add 'https://gitlab.com/acme/second.git' main)" "5"
  has "and says what git said about it" "$said" "could not read the practice"
}
practice_grants_without_asking_again

#
# One repository, selected once. Nothing deduped, so `ungradable_targets` reported it twice and every
# clause was graded against it twice — invisible until something counted.
#
a_repository_is_selected_once() {
  make_repo "$tmp/dp" main && set_origin "$tmp/dp" 'https://gitlab.com/acme/dp.git' \
    || { skip "duplicate selection — git could not make a repo here"; return; }

  floor "$tmp/dp" new "Twice" >/dev/null

  is  "the first selection is taken" \
      "$(code_of floor "$tmp/dp" targets add 'https://gitlab.com/acme/dp.git' main)" "0"
  is  "the second is refused" \
      "$(code_of floor "$tmp/dp" targets add 'https://gitlab.com/acme/dp.git' main)" "4"
  has "and names what is already there" \
      "$(floor_says "$tmp/dp" targets add 'https://gitlab.com/acme/dp.git' main)" "already selected"
  is  "and the file is left as it was" "$(floor "$tmp/dp" targets | wc -l | tr -d ' ')" "1"
}
a_repository_is_selected_once

#
# Silence read as success. Derive on a repository declaring no gate wrote an empty charter and said
# nothing, so *found nothing* and *worked* looked the same — and the refusal arrived two stages later
# about a file the reader thought was fine.
#
derive_says_what_it_found() {
  make_repo "$tmp/sd" main && set_origin "$tmp/sd" 'https://gitlab.com/acme/sd.git' \
    && commit_file "$tmp/sd" README.md 'nothing here declares a gate
' || { skip "derive says — git could not make a repo here"; return; }

  floor "$tmp/sd" new "Silent" >/dev/null

  is  "an empty charter is not a refusal" "$(code_of floor "$tmp/sd" charter derive)" "0"
  has "and it says the charter is empty" \
      "$(floor_says "$tmp/sd" charter derive)" "the charter is empty"
  has "and names what puts a bar in it" \
      "$(floor_says "$tmp/sd" charter derive)" "charter introduce"

  floor "$tmp/sd" charter introduce Decided 'ship it' >/dev/null 2>&1
  has "one clause is one clause" \
      "$(floor_says "$tmp/sd" charter derive)" "holds one clause"
}
derive_says_what_it_found

#
# A yes and a no at one ref. §7 q10 held this open while every record was a command's exit code — one
# tree gives one answer, so a second record could only repeat the first. A human can answer now, and
# a second human can disagree.
#
a_disagreement_is_not_a_satisfaction() {
  make_repo "$tmp/dg" main && set_origin "$tmp/dg" 'https://gitlab.com/acme/dg.git' \
    && mkdir -p "$tmp/dg/.foundry" \
    && commit_file "$tmp/dg" .foundry/gates 'tests  true
' || { skip "disagreement — git could not make a repo here"; return; }

  ready_run "$tmp/dg" 'https://gitlab.com/acme/dg.git'
  floor "$tmp/dg" gates >/dev/null 2>&1
  is "a gate that passed satisfies its clause" "$(code_of floor "$tmp/dg" complete)" "0"

  # The same tree, answered twice and differently. Written by hand: nothing floor ships can produce
  # it, which is the point — the second answer is a human's.
  d=$(floor "$tmp/dg" path)
  ref=$(awk -F'\t' 'NR == 1 { print $6 }' "$d/evidence")
  printf '%s\thuman\t01\ttests\t1\t%s\tnot in my view\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ref" >> "$d/evidence"

  is  "a no at the same ref stops it" "$(code_of floor "$tmp/dg" complete)" "15"
  has "and names the clause nobody agrees on" \
      "$(floor_says "$tmp/dg" complete)" "unmet: [tests]"
}
a_disagreement_is_not_a_satisfaction

#
# A clone that cannot finish, and what floor says about it.
#
# **Delete an object the checkout needs.** The workspace is cloned from the checkout, which is a
# repository by construction, so nothing about the target can make the clone fail. `rm` bites on every
# platform; `chmod` does not bite on Windows, and an empty repository clones fine.
#
# The blob is named rather than whichever object came first, so the failure is the same one twice.
#
a_failed_clone_says_what_git_said() {
  make_repo "$tmp/bc" main && set_origin "$tmp/bc" 'https://gitlab.com/acme/bc.git'     && commit_file "$tmp/bc" Makefile 'test:
	echo ok
' || { skip "a failed clone — git could not make a repo here"; return; }

  floor_new_as "$tmp/bc" ada@example.com "Broken clone" >/dev/null
  floor "$tmp/bc" charter derive >/dev/null 2>&1
  floor "$tmp/bc" policy authorize 'https://gitlab.com/acme/bc.git' >/dev/null 2>&1
  floor "$tmp/bc" targets add 'https://gitlab.com/acme/bc.git' main >/dev/null 2>&1

  rm -f "$(loose_object "$tmp/bc" "$(git -C "$tmp/bc" rev-parse HEAD:Makefile)")"

  is  "a clone that cannot finish refuses" "$(code_of floor "$tmp/bc" open)" "16"
  has "and carries git's own words"        "$(floor_says "$tmp/bc" open)" "fatal"
}
a_failed_clone_says_what_git_said

#
# A question that could be put nowhere.
#
# `mkdir` refuses a directory where a file already is, on every platform — `chmod` does not bite on
# Windows. Its own home, because the file this needs where a directory belongs would break every other
# check reading the shared one.
#
a_question_that_never_arrived_is_not_asked() {
  h2="$tmp/home2"
  mkdir -p "$h2/source/items" && printf 'Ship it
' > "$h2/source/items/12"
  printf '' > "$h2/source/questions"

  make_repo "$tmp/nq" main && set_origin "$tmp/nq" 'https://gitlab.com/acme/nq.git'     && commit_file "$tmp/nq" Makefile 'test:
	echo ok
' || { skip "a question that never arrived — git could not make a repo here"; return; }

  nq() { floor_as "$tmp/nq" "$h2" "" "$@"; }
  nq new "No question" >/dev/null
  nq source read 12 >/dev/null 2>&1
  nq charter derive >/dev/null 2>&1
  nq policy authorize 'https://gitlab.com/acme/nq.git' >/dev/null 2>&1
  nq targets add 'https://gitlab.com/acme/nq.git' main >/dev/null 2>&1
  nq charter introduce Decided 'ship on friday' >/dev/null 2>&1

  said=$( cd "$tmp/nq" 2>/dev/null           && FOUNDRY_HOME="$h2" FOUNDRY_RUN="" FOUNDRY_WHO="" sh "$runner" authorise 2>&1 )

  is    "a question that can be put nowhere refuses"    "$(code_of nq authorise)" "1"
  has   "and says the source could not carry it"        "$said" "could not carry"
  lacks "and sends nobody to answer where it is not"    "$said" "Answer where the item is"
}
a_question_that_never_arrived_is_not_asked

#
# A work source named rather than detected.
#
# `FOUNDRY_SOURCE` was already there and nothing used it, so nothing held it. Detection is level 1 and
# stays the default — but with no way to override it, which adapter answers rests on what the machine
# happens to have installed, and this suite's own checks changed answer on a machine with `gh`.
#
a_named_source_answers() {
  make_repo "$tmp/ns" main && set_origin "$tmp/ns" 'https://github.com/acme/ns.git' \
    || { skip "a named source — git could not make a repo here"; return; }

  printf '#!/bin/sh\nprintf "a source nobody detected\n"\n' > "$tmp/named-source.sh"
  floor "$tmp/ns" new "Named" >/dev/null

  is "a named source answers instead of the detected one" \
     "$( cd "$tmp/ns" 2>/dev/null \
         && FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
            FOUNDRY_SOURCE="$tmp/named-source.sh" sh "$runner" source read 1 2>/dev/null )" \
     "a source nobody detected"
}
a_named_source_answers

#
# A delivery that succeeds, which nothing has ever checked.
#
# `deliver` appears twice above and both are refusals, so `send_delivery` — the push, the branch it
# derives, and the publish that follows — has never run here. It is the only verb that writes to a
# repository other people can see.
#
# It was untestable for a reason: `point_at_origin` sets the workspace's origin to the target's
# identity, and §2.3 refuses a local path as a target, so there was nowhere to push. `pushInsteadOf`
# sends the push somewhere else and leaves `get-url` alone — `insteadOf` rewrites that too, and floor
# would then see a local path and refuse its own target.
#
#
# Provenance: what a delivery carries that the run did not make.
#
# The base is recorded at `open`, `commit` records what it makes, and anything
# else in `base..head` is unaccounted for.
#
a_delivery_carrying_a_commit_nobody_recorded() {
  git init -q --bare "$tmp/pvremote.git" 2>/dev/null     || { skip "provenance — git could not make a bare repo here"; return; }

  make_repo "$tmp/pv" main && set_origin "$tmp/pv" 'https://github.com/acme/pv.git'     && mkdir -p "$tmp/pv/.foundry"     && commit_file "$tmp/pv" .foundry/gates 'tests  true
' || { skip "provenance — git could not make a repo here"; return; }

  mkdir -p "$src/items" && printf 'Account for it
' > "$src/items/43"

  pvrun=$(floor_new_as "$tmp/pv" ada@example.com "Provenance")
  floor "$tmp/pv" source read 43 >/dev/null 2>&1
  floor "$tmp/pv" charter derive >/dev/null 2>&1
  floor "$tmp/pv" policy authorize  'https://github.com/acme/pv.git' >/dev/null 2>&1
  floor "$tmp/pv" policy deliver-to 'https://github.com/acme/pv.git' >/dev/null 2>&1
  floor "$tmp/pv" targets add       'https://github.com/acme/pv.git' main >/dev/null 2>&1
  floor "$tmp/pv" authorise >/dev/null 2>&1

  ws=$(floor "$tmp/pv" open) || { skip "provenance — no workspace"; return; }
  co=$(find "$ws" -maxdepth 1 -mindepth 1 -type d | head -1)
  git -C "$co" config "url.$tmp/pvremote.git.pushInsteadOf" 'https://github.com/acme/pv.git'

  # 1. `open` records the base, once, per target.
  base=$(cut -d' ' -f2 "$ws/../base" 2>/dev/null)
  is "open records the base it started from" "$base" "$(git -C "$co" rev-parse HEAD)"
  is "and records one line for one target"   "$(wc -l < "$ws/../base" 2>/dev/null | tr -d ' ')" "1"

  floor "$tmp/pv" open >/dev/null 2>&1
  is "opening again does not move it" "$(cut -d' ' -f2 "$ws/../base" 2>/dev/null)" "$base"

  # 2. A commit floor made is accounted for; the run may deliver.
  printf 'one
' > "$co/made.txt"
  git -C "$co" add made.txt >/dev/null 2>&1
  mine=$(floor "$tmp/pv" commit 'chore: a commit floor made')
  is "commit records the sha it made" "$mine" "$(git -C "$co" rev-parse HEAD)"

  floor "$tmp/pv" gates >/dev/null 2>&1
  is "a recorded commit delivers" "$(code_of floor "$tmp/pv" deliver 'Accounted for')" "0"

  # 3. A commit made outside that operation is foreign, and refuses.
  printf 'two
' > "$co/outside.txt"
  git -C "$co" add outside.txt >/dev/null 2>&1
  git -C "$co" -c user.email=a@b.c -c user.name=a commit -qm 'chore: nobody recorded this' >/dev/null 2>&1
  stranger=$(git -C "$co" rev-parse HEAD)

  floor "$tmp/pv" gates >/dev/null 2>&1
  said=$(floor_says "$tmp/pv" deliver 'Carrying a stranger')

  is  "foreign ancestry alone refuses delivery"       "$(code_of floor "$tmp/pv" deliver 'Carrying a stranger')" "27"
  has "and it names the commit it could not account for" "$said" "$stranger"

  # 4. An override for the wrong sha changes nothing.
  floor "$tmp/pv" reconcile accept "$base" 'the base is not the stranger' >/dev/null 2>&1
  is "an override naming another commit still refuses"      "$(code_of floor "$tmp/pv" deliver 'Carrying a stranger')" "27"

  # 5. An override naming it permits delivery, and stays readable.
  floor "$tmp/pv" reconcile accept "$stranger" 'a fix this branch needed' >/dev/null 2>&1
  is  "the override alone permits delivery"       "$(code_of floor "$tmp/pv" deliver 'Carrying a stranger')" "0"
  has "and the record names who and why"       "$(cat "$ws/../accepted" 2>/dev/null)" "a fix this branch needed"
  has "and it names the commit"          "$(cat "$ws/../accepted" 2>/dev/null)" "$stranger"

  # 6. Fail closed: no base to read.
  cp "$ws/../base" "$tmp/pv-base-kept" && rm -f "$ws/../base"
  is  "a base it cannot read refuses"       "$(code_of floor "$tmp/pv" deliver 'No base')" "26"
  has "and says what it wanted" "$(floor_says "$tmp/pv" deliver 'No base')" "wanted a sha"
  cp "$tmp/pv-base-kept" "$ws/../base"

  # 7. Fail closed: a base no repository holds.
  printf '%s deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
' "$(cut -d' ' -f1 "$ws/../base")" > "$ws/../base"
  is "a range it cannot walk refuses" "$(code_of floor "$tmp/pv" deliver 'No range')" "26"
  cp "$tmp/pv-base-kept" "$ws/../base"

  # 8. The production record is what accounts for a commit, not the message.
  printf 'three
' > "$co/footer.txt"
  git -C "$co" add footer.txt >/dev/null 2>&1
  git -C "$co" -c user.email=a@b.c -c user.name=a commit -qm 'chore: says it belongs

Refs #43
' >/dev/null 2>&1
  is "a footer naming the run's own item accounts for nothing"      "$(code_of floor "$tmp/pv" deliver 'A footer is not provenance')" "27"
}
a_delivery_carrying_a_commit_nobody_recorded

a_delivery_that_succeeds() {
  git init -q --bare "$tmp/dvremote.git" 2>/dev/null \
    || { skip "a delivery that succeeds — git could not make a bare repo here"; return; }

  make_repo "$tmp/dv" main && set_origin "$tmp/dv" 'https://github.com/acme/dv.git' \
    && mkdir -p "$tmp/dv/.foundry" \
    && commit_file "$tmp/dv" .foundry/gates 'tests  true
' || { skip "a delivery that succeeds — git could not make a repo here"; return; }

  mkdir -p "$src/items" && printf 'Deliver it\n' > "$src/items/42"

  # Named, not inherited. `complete` refuses a run nobody selected, and `floor` runs with an empty
  # `FOUNDRY_WHO` — so this passed on my machine, which has a git identity, and refused on one that
  # does not. The same defect #176 is about, written into a check for it.
  dvrun=$(floor_new_as "$tmp/dv" ada@example.com "Delivering")
  floor "$tmp/dv" source read 42 >/dev/null 2>&1
  floor "$tmp/dv" charter derive >/dev/null 2>&1
  floor "$tmp/dv" policy authorize  'https://github.com/acme/dv.git' >/dev/null 2>&1
  floor "$tmp/dv" policy deliver-to 'https://github.com/acme/dv.git' >/dev/null 2>&1
  floor "$tmp/dv" targets add       'https://github.com/acme/dv.git' main >/dev/null 2>&1
  floor "$tmp/dv" authorise >/dev/null 2>&1

  ws=$(floor "$tmp/dv" open) || { skip "a delivery that succeeds — no workspace"; return; }
  co=$(find "$ws" -maxdepth 1 -mindepth 1 -type d | head -1)

  # The clone has its own config, so the redirect is set where the push happens.
  git -C "$co" config "url.$tmp/dvremote.git.pushInsteadOf" 'https://github.com/acme/dv.git'

  floor "$tmp/dv" gates >/dev/null 2>&1
  is "with its gate green it may deliver" "$(code_of floor "$tmp/dv" complete)" "0"

  is    "and delivering answers" "$(code_of floor "$tmp/dv" deliver 'A change worth reading')" "0"
  has   "the commit reached the remote" \
        "$(git -C "$tmp/dvremote.git" branch --format='%(refname:short)' 2>/dev/null)" \
        "foundry/$(basename "$dvrun")"
  is    "and delivering again answers the same way" \
        "$(code_of floor "$tmp/dv" deliver 'A change worth reading')" "0"

  #
  # What `merge` refuses on, written down. The head is read after the push, so the record names what
  # landed rather than what the workspace held.
  #
  landed=$(cut -d' ' -f2 "$dvrun/delivery")

  is "the record names the commit it pushed" \
     "$landed" "$(git -C "$co" rev-parse HEAD)"
  is "and it is the commit the gate graded" \
     "$landed" "$(awk -F'\t' 'NR == 1 { print $6 }' "$dvrun/evidence")"

  # A run that delivered before floor kept a commit. Two fields, and it still answers.
  printf 'foundry/%s https://example.invalid/9\n' "$(basename "$dvrun")" > "$dvrun/delivery"

  is "an older record still answers with its delivery" \
     "$(floor "$tmp/dv" source publish "foundry/$(basename "$dvrun")" 'A change')" \
     "https://example.invalid/9"
}
a_delivery_that_succeeds

summary "model"
