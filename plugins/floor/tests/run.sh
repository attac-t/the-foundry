#!/bin/bash
#
# Run every suite, then check the suites can fail.
#
# The second half is the part that matters. A green suite proves nothing until you have watched it
# go red, so we break the plugin one rule at a time and each break must take a suite down with it.
#

# The pool waits with `jobs -pr`, which is bash's. Under dash it answers zero without complaining, so
# nothing waits, every mutant starts at once, and all of them report MOOT — a machine too small is
# what that reads like, not a caller in the wrong shell.
#
# Measured: 144 MOOT under dash and 0 under bash, with the suite saying `PROVED NOTHING` both times
# and never naming the shell. `bin/gates.sh` always invokes it correctly. A person at a prompt does
# not, and it cost several days of believing this machine could not run them.
# Asked, not assumed. `BASH_VERSION` is an environment variable and a parent can leave one behind,
# so the pool's own question is the one worth putting: start a job, and see whether it is counted.
sleep 1 &
counted=$(jobs -pr 2>/dev/null | wc -l)
wait

[ "${counted:-0}" -ge 1 ] 2>/dev/null || {
  printf 'this suite is bash — its mutant pool waits with `jobs -pr`, and this shell counts none\n' >&2
  printf '  bash %s\n' "$0" >&2
  exit 2
}

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/floor-audit-$$"
mkdir -p "$tmp/verdict"
trap 'rm -rf "$tmp"' EXIT

# **Git transport isolation, and nothing wider.** `tests/isolate.sh` holds the mechanism and the
# exact claim; `tests/transport.sh` proves it and proves that removing any part of it is caught.
#
# Fixtures address `github.com`, and one of them pushes. Without this, that push resolves a name and
# waits on a credential helper — a hang, which no exit code tells apart from a slow machine.
. "$root/tests/isolate.sh"
isolate_git_transport "$tmp" || { printf 'could not isolate the git transport\n' >&2; exit 2; }

failed=0

# Two ways an audit ends badly, and they take different remedies.
#
# `bad` is a rule broken: a break survived, or a suite went red. `moot` is an experiment that never
# ran — a sed that matched nothing, a mutant that came out empty, a worker that died. The audit says
# which in words already; these are what carry it to the exit code.
#
# Neither is a pass, and a `moot` never downgrades a `bad`.
bad()  { failed=1; printf '  FAIL  %s\n' "$1"; }
kept() { unanswered=0; printf '  ok    %s\n' "$1"; }

# A mutant that never answered, and the run of them that means the machine stopped answering.
#
# One moot is an experiment that missed. Ten in a row is not ten experiments — it is a machine
# that has run out of something, and every mutant after them misses the same way.
unanswered=0

# The total, which never resets. `unanswered` is the run and `kept` clears it.
never_ran=0
moot() {
  [ "$failed" -eq 0 ] && failed=3
  never_ran=$((never_ran + 1))
  printf '  MOOT  %s\n' "$1"

  unanswered=$((unanswered + 1))
  [ "$unanswered" -lt 10 ] && return

  # Twelve hours on 1 September 2026 reached 87 of 192. Twenty-one in a row answered nothing,
  # and the audit kept going, because nothing here read its own run of silence.
  # Stopping at ten spends two and a half hours of the twenty-six it would have taken.
  printf '\nSTOPPED — ten mutants in a row never answered.\n'
  printf 'The machine stopped answering, so the rest would prove nothing either.\n'
  exit 3
}

#
# The line that ends a suite is its last line.
#
# A file grows at its end, and the end is below the line that ends it. Eight breaks sat below this
# file's `exit` across seven pull requests, and `model.sh`'s tally sat ninety-nine lines above its own
# last case — so that suite exited with the last check's status and never the tally's, and no failure
# it printed could reach the gate.
#
# Nothing else notices. Both were found by reading, twice, months apart.
#
ends_on() {
  [ "$(awk '!/^[ \t]*#/ && NF { last = $0 } END { print last }' "$1")" = "$2" ]
}

# One recorder, run over a verdict already there, and what it leaves for `exit`.
leaves() {
  ( failed="$2"; "$1" - >/dev/null; exit "$failed" )
  left=$?

  [ "$left" = "$3" ] || { bad "$1 over $2 left $left, not $3"; return; }
  printf '  ok    %s over %s leaves %s
' "$1" "$2" "$3"
}

# The audit's two failures stay two. Every line above says which in words; `bin/gates.sh` branches on
# the number, so collapsing them back into one exit code is the change nothing else would notice.
audit_says_which() {
  leaves moot 0 3
  leaves bad  0 1
  leaves moot 1 1
}
audit_says_which

ends_on "$root/tests/run.sh"     'exit $failed'      || bad "tests/run.sh declares breaks below its exit, and nothing runs them"
ends_on "$root/tests/transport.sh" '[ "$failed" -eq 0 ] || exit 1' || bad "tests/transport.sh runs cases below its exit, and nothing counts them"
ends_on "$root/tests/model.sh"   'summary "model"'   || bad "tests/model.sh runs cases below its tally, and nothing counts them"
ends_on "$root/tests/install.sh" 'summary "install"' || bad "tests/install.sh runs cases below its tally, and nothing counts them"
ends_on "$root/tests/host.sh"    'summary "host"'    || bad "tests/host.sh runs cases below its tally, and nothing counts them"
ends_on "$root/tests/say.sh"     'summary "say"'     || bad "tests/say.sh runs cases below its tally, and nothing counts them"

#
# The clean suite's own time. **Every deadline below is measured from it.**
#
# 300 seconds was one machine's number, and the same suite takes minutes on another — so two breaks
# exceeded it there and, inverted, read as caught. A mutant is either caught early by `FOUNDRY_FAIL_FAST`
# or runs about as long as a clean pass. Anything far past that is stuck on any machine.
#
for suite in transport model install host say; do
  began=$(date +%s)
  bash "$root/tests/$suite.sh" || failed=1
  [ "$suite" = model ] && clean=$(( $(date +%s) - began ))
  echo
done

# Five clean passes, and never under two minutes.
#
# A mutant runs alone here and under the pool's load there, so the measure needs headroom: `gateref`
# takes 226s by itself on a machine whose clean pass is about 535s, and past 300s once two workers
# share the machine. Generous on purpose — **a deadline reached too early is a `MOOT` nobody earned**,
# and the thing it guards against is rare.
deadline=$(( ${clean:-0} * 5 ))
[ "$deadline" -lt 120 ] && deadline=120

#
# And a ceiling, because the floor alone is half a bound.
#
# `clean` is measured on whatever else the machine was doing, so a contended run bought itself a
# longer wait: 62,185 seconds once, which is seventeen hours. A mutant hung under it and nothing
# was ever going to kill it.
#
# **A mutant is caught early by `FOUNDRY_FAIL_FAST` or it runs about as long as a clean pass.** The
# slowest legitimate one measured here is 226 seconds. Fifteen minutes is six times that, and it is
# the difference between a hang that answers MOOT and a hang that answers tomorrow.
#
ceiling=${FOUNDRY_AUDIT_CEILING:-900}
[ "$deadline" -gt "$ceiling" ] && deadline=$ceiling

#
# Nothing is audited while the suite is red.
#
# Every mutant runs the model suite under `FOUNDRY_FAIL_FAST`, and a red suite stops at its own
# failure — which this file reads as *the suite noticed the break*. **Forty mutants would report a
# success none of them earned**, and the audit that grades every other gate would be the greenest
# thing in the repository.
#
refuse_to_audit_a_red_suite() {
    [ "${failed:-0}" -eq 0 ] && return 0

    printf 'audit — not run. A suite above is red, and every mutant would pass on that failure.
'
    printf 'PROVED NOTHING
'
    exit 1
}
refuse_to_audit_a_red_suite

#
# And the deadline has to outlast the thing it times.
#
# A mutant is caught early or it runs about as long as a clean pass. So a deadline under `clean`
# answers nothing about a break only reached near the end — that mutant is killed before it speaks,
# and MOOT then reports the clock rather than the code.
#
# It is the ceiling that does this. A 5,940s clean pass under a 900s ceiling gets three per cent of
# what `clean * 5` asked for, and five mutants went MOOT there for no other reason.
#
# **One clean pass, and an adversary argued for two.** The file's own numbers refuse that: `gateref`
# is the slowest honest mutant at 226s solo and past 300s under load, on a machine whose clean pass
# is 535s. That is **0.56 of a pass**, so one pass is already close to twice the worst mutant — and
# two passes would refuse the very 535s machine this design was sized against, which worked.
#
# The bar is the thing measured, never a multiple that reads well.
#
# **The ceiling is named with its cost, never as advice.** Raising it makes this refusal false
# without making the deadline sound, and the run it then permits is the seventeen-hour one recorded
# above. So the hours are printed before the knob is.
#
refuse_a_deadline_too_short_to_answer() {
    headroom=${clean:-0}
    [ "$deadline" -ge "$headroom" ] && return 0

    printf 'audit — not run. A mutant has %ss, and a clean pass took %ss.\n' "$deadline" "$clean"
    printf 'audit — one caught late needs a whole pass, and more again under pool load.\n'
    printf 'audit — grade where the suite is faster. FOUNDRY_AUDIT_CEILING=%s would run it,\n' "$headroom"
    printf 'audit — and 192 mutants at that deadline is %sh of mutant time, before the pool\n' \
           "$(( headroom * 192 / 3600 ))"
    printf 'audit — divides it. That is two ways on the machine this refusal fires on.\n'
    printf 'PROVED NOTHING\n'
    exit 3
}
refuse_a_deadline_too_short_to_answer

# --- break the runner ---

# What this run is about to cost, before it spends it.
#
# The deadline is five clean passes, and a clean pass here is `$clean`. When that is far above
# the 535s this file was sized against, the machine is slow or busy, and mutants caught late in
# the suite will be killed before they answer.
#
# **Two nights were spent blaming memory for exactly that.** The numbers were always here;
# nothing printed them. It says the pool size too, below, once there is one — two bounds choose that
# number now, and a log that prints neither cannot say which did.

#
# How many breaks run at once.
#
# Git Bash forks by copying its own heap, and one worker per processor exhausts it: `dofork: child
# died unexpectedly`, then `fork: Resource temporarily unavailable`, and the audit stops having
# reported nothing at all. Twelve killed it in seconds; four ran five minutes clean. Two, because
# what a high guess costs is every verdict, and the clock this pool exists for is Docker's.
#
# `getconf` knows the processor count on Linux and macOS, where `nproc` is GNU only; busybox knows it
# the other way round. Either can answer with a word rather than a number, so the answer is read
# before it becomes a pool size.
#
# How many workers this machine's memory allows, at 128 MB each.
#
# A model suite costs **44 MB**, measured 3 September by sampling `MemAvailable` once a second while
# one ran on Linux. Twelve of those is 530 MB and the machine had 2.6 GB free, so the pool was never
# the memory fault here — the `msys` branch below holds the platform where it was.
#
# 128 is the measured 44 with room, because one number from one machine is not a floor.
#
# **Four things this does not know, and each could make it wrong:**
#
# - 44 MB is the first worker alone. **The number the bound wants is the twelfth under load**, and
#   nothing has measured that
# - a one-second sample sees no peak shorter than a second
# - `/proc/meminfo` is not namespaced. Inside the `docker run` this repository grades Linux in, it
#   **reports the host and not the container's limit**
# - it is read once, at the start of a run measured in hundreds of seconds. The pool does not shrink
#   when the machine fills
#
# **Only Linux answers at all.** macOS has no `/proc/meminfo`, and MSYS2 has the file without a
# `MemAvailable` line. Both fall through to the processor count — the number they get today, and no
# worse. The `msys` branch below returns before either can matter, and this holds if it ever does not.
#
workers_memory_allows() {
  local fits
  [ -r /proc/meminfo ] || return 1

  fits=$(awk '/^MemAvailable:/ { print int($2 / 131072) }' /proc/meminfo)
  case "$fits" in ''|*[!0-9]*) return 1 ;; esac

  [ "$fits" -lt 1 ] && fits=1
  printf '%s' "$fits"
}

worker_count() {
  local count allowed
  case "${OSTYPE:-}" in msys*|cygwin*) printf '2'; return ;; esac

  count=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null)
  case "$count" in ''|*[!0-9]*|0) count=4 ;; esac

  allowed=$(workers_memory_allows) || { printf '%s' "$count"; return; }
  [ "$allowed" -lt "$count" ] && count=$allowed
  printf '%s' "$count"
}

workers=${FOUNDRY_AUDIT_WORKERS:-$(worker_count)}

printf 'audit — break the runner, the model suite must notice. A mutant has %ss, %s at a time.\n' \
       "$deadline" "$workers"

queued=0
reported=0

#
# Run a command with a deadline, and answer **2 when the deadline passed** — never the command's own
# status, because a command that never answered did not answer badly.
#
# `timeout` exits 124 when it kills one. `!` used to invert that to 0, which is this file's word for
# *the suite noticed the break*, so **a mutant that hung was recorded `ok`** — a false green in the
# thing that grades every other gate.
#
bounded() {
  local seconds="$1"
  shift

  command -v timeout >/dev/null 2>&1 && { timed "$seconds" "$@"; return; }

  polled "$seconds" "$@"
}

timed() {
  local seconds="$1" said
  shift

  timeout "$seconds" "$@" >/dev/null 2>&1
  said=$?

  [ "$said" -eq 124 ] && return 2
  return "$said"
}

# The same deadline without `timeout`. **macOS is the platform that needs this** — it ships no
# `timeout` unless someone installed GNU coreutils, and without one there is no bound at all.
#
# Polled the way `await_a_free_worker` polls: `wait -n` with a deadline is bash 4.3, and macOS ships
# 3.2. The same platform, twice, for the same reason.
polled() {
  local seconds="$1" job waited=0
  shift

  "$@" >/dev/null 2>&1 &
  job=$!

  while kill -0 "$job" 2>/dev/null; do
    [ "$waited" -ge "$seconds" ] && { kill -9 "$job" 2>/dev/null; wait "$job" 2>/dev/null; return 2; }
    sleep 1
    waited=$((waited + 1))
  done

  wait "$job"
}

#
# What a deadline answers, and it is not what an answer answers. Three seconds, and the only check
# here that grades this file rather than the plugin.
#
a_deadline_is_not_an_answer() {
  bounded 5 true;     answered 0 "a command that passes"
  bounded 5 false;    answered 1 "a command that fails"
  bounded 2 sleep 30; answered 2 "a command that never answers"
}

#
# Does a suite fail against a broken copy of the plugin?
#
#   0  caught · 1  it passed against a broken one · 2  the mutant never answered
#
# **One function, because both audits below were wrong in the same two ways.** `bounded` was called
# in a single place, so seventeen mutants here and in the join audit ran with no deadline at all.
# Giving them one as `! bounded …` was worse: a timeout answers 2, `!` turns 2 into 0, and a mutant
# that hung reported *caught* — the false green `a_deadline_is_not_an_answer` exists to refuse.
#
# `env`, because `bounded` runs its arguments and an inline assignment would not reach them.
#
suite_caught() {
  local said
  bounded "$deadline" env PLUGIN_ROOT="$1" bash "$2"
  said=$?

  [ "$said" -eq 2 ] && return 2
  [ "$said" -eq 0 ] && return 1

  return 0
}

#
# And the same three answers from `suite_caught`, which reads a whole suite rather than a command.
#
# It is one function so this proves both audits at once. A stand-in suite, because what is under
# test is how an exit code is read — never what a real suite finds.
a_suite_that_never_answered_caught_nothing() {
  local held=$deadline

  printf '#!/bin/sh
exit 1
' > "$tmp/red.sh"
  printf '#!/bin/sh
exit 0
' > "$tmp/green.sh"
  printf '#!/bin/sh
sleep 30
' > "$tmp/slow.sh"

  suite_caught x "$tmp/red.sh";   answered 0 "a suite that goes red on the break"
  suite_caught x "$tmp/green.sh"; answered 1 "a suite that stays green against a broken one"

  deadline=2
  suite_caught x "$tmp/slow.sh";  answered 2 "a suite that never answers"
  deadline=$held
}

# `$?` from the line above. Called immediately after `bounded`, because anything between them is the
# status this would read instead.
answered() {
  local got=$?

  [ "$got" = "$1" ] || { bad "$2 left $got, not $1"; return; }
  printf '  ok    %s leaves %s\n' "$2" "$1"
}
# A run of silence is not a run of experiments.
#
# Ten that never answer mean the machine stopped answering, so the audit stops. Nine do not,
# and one that answers puts the count back to nought — the run must be unbroken to mean this.
a_run_of_silence_stops_the_audit() {
  silence() { local i=0; while [ "$i" -lt "$1" ]; do moot "silence $i"; i=$((i + 1)); done; }

  # Each in its own subshell. `moot` exits, and the count it keeps must not follow it out.
  ( silence 9 )                    >/dev/null 2>&1; answered 0 "nine that never answered"
  ( silence 10 )                   >/dev/null 2>&1; answered 3 "ten that never answered"
  ( silence 9; kept x; silence 9 ) >/dev/null 2>&1; answered 0 "a run one answer broke"
}
a_deadline_is_not_an_answer
a_suite_that_never_answered_caught_nothing
a_run_of_silence_stops_the_audit

#
# Does the model suite fail against a broken runner?
#
#   0  caught · 1  it passed against a broken one · 2  the mutant never answered
#
# `env`, because `bounded` runs its arguments and an inline assignment would not reach them.
#
model_caught() {
  local said
  bounded "$deadline" env RUNNER="$1/bin/run.sh" FOUNDRY_FAIL_FAST=1 bash "$root/tests/model.sh"
  said=$?

  [ "$said" -eq 2 ] && return 2
  [ "$said" -eq 0 ] && return 1

  return 0
}

#
# Break one rule in the runner — or in a file the runner resolves through — and require the model
# suite to notice. It speaks and does not count: `bad`'s counter dies with the process, so the line
# it prints is the whole of what a break returns.
#
# Three ways a mutant proves nothing, all seen for real in this repo: sed fails, the output comes
# out empty, or the pattern never matched. `cmp` alone catches only the third — an empty file
# differs from the original too.
#
# The last argument names the file, because an adapter carries rules of its own and a rule only the
# caller can break is one the adapter is free to drop.
#
break_verdict() {
  local slot="$1" name="$2" tag="$3" mutation="$4" file="${5:-bin/run.sh}"
  local mutant="$tmp/$slot-$tag"

  rm -rf "${mutant:?}" && cp -R "$root" "$mutant" || { moot "$name — could not copy the plugin"; return; }
  sed "$mutation" "$root/$file" > "$mutant/$file" || { moot "$name — sed failed, so this proves nothing"; return; }
  [ -s "$mutant/$file" ] || { moot "$name — the mutant is empty, so the suite failed for the wrong reason"; return; }
  cmp -s "$mutant/$file" "$root/$file" && { moot "$name — the break did not apply, so this proves nothing"; return; }
  model_caught "$mutant"; local answer=$?
  [ "$answer" -eq 2 ] && { moot "$name — killed at ${deadline}s, and a clean pass took ${clean}s"; return; }
  [ "$answer" -eq 0 ] || { bad "$name — the suite passed against a broken runner"; return; }

  printf '  ok    %s\n' "$name"
}

#
# Report one break's verdict, and count it.
#
# The verdict is the line the break wrote, never `wait`'s exit code: `wait` answers for one job out
# of many, and a status read from the wrong break is a verdict invented for it. Anything but the two
# words a break can print counts as a rule broken, so a format changed here goes red and loud.
#
report_verdict() {
  local verdict
  verdict=$(cat "$tmp/verdict/$1")

  printf '%s\n' "$verdict"
  case "$verdict" in
      '  ok    '*) return ;;
      '  MOOT  '*) [ "$failed" -eq 0 ] && failed=3; return ;;
  esac

  failed=1
}

# Hold the pool to its size. `wait -n` would say the moment a worker came free and is bash 4.3 —
# macOS ships 3.2 — so the running count is polled. Waiting in batches instead would idle the whole
# pool on every batch's slowest break, and the breaks run from under a second to half a minute.
await_a_free_worker() {
  while [ "$(jobs -pr | wc -l)" -ge "$workers" ]; do sleep 1; done
}

# Report every break, in the order they were declared rather than the order they finished. The same
# eight gates have to read the same way twice.
report_breaks() {
  wait

  while [ "$reported" -lt "$queued" ]; do
    reported=$((reported + 1))
    report_verdict "$reported"
  done
}

#
# Start a break, once a worker is free. A break's verdict rests on nothing another break did, which
# is what lets them run at once — and the slot it is handed, rather than its tag, is what keeps its
# mutant its own. Two breaks are tagged `elsewhere`, and one directory for two workers is one worker
# reading a tree the other is deleting.
#
# The verdict on disk reads *reported nothing* until the break replaces it, and the replacement is a
# rename, so it lands whole or not at all. A worker killed at any point leaves the first verdict
# standing — **a lost process reads as an experiment that never ran, and never as a pass.**
#
wreck_runner() {
  await_a_free_worker

  queued=$((queued + 1))
  printf '  MOOT  %s — the break reported nothing\n' "$1" > "$tmp/verdict/$queued"

  ( break_verdict "$queued" "$@" > "$tmp/verdict/$queued.said" 2>&1
    mv "$tmp/verdict/$queued.said" "$tmp/verdict/$queued" ) &
}

#
# Three breaks on one claim, and they are three: this one blinds it to everything, `notatomic` to a
# directory already there, `inherit` below to grants alone.
#
wreck_runner "a runner that stops checking for a free path is caught" \
  collide 's#slot_is_reserved "$1" \&\& return 1#:#; s#mkdir "$RUNS/$1" 2>/dev/null#mkdir -p "$RUNS/$1" 2>/dev/null#'

#
# The defect this replaced, put back exactly: `-p` succeeds on a directory that already exists, so
# the claim reports a collision as a win and two runs share a slot. Nothing else in the suite can
# see it — sequential `new` calls never race — so this mutant and `eight_at_once` stand or fall
# together.
#
wreck_runner "a claim that tolerates an existing directory is caught" \
  notatomic 's#mkdir "$RUNS/$1" 2>/dev/null#mkdir -p "$RUNS/$1" 2>/dev/null#'

# Counting past a failure that counting cannot fix. `mkdir -p "$RUNS"` succeeds on a `runs/` that
# refuses a child, so the loop runs for ever on a directory it will never create.
#
# The break is a hang rather than a wrong answer, so the check that catches it bounds the runner with
# `timeout`. Without that this mutant would stop the audit instead of failing it.
#
# Gated on the same condition as the check itself. Windows ignores chmod, so no directory there
# refuses a child, the check skips, and running the mutant anyway would report *untestable here* as
# *broken*.
chmod_bites() {
  probe="$tmp/chmod-probe"
  rm -rf "$probe"; mkdir -p "$probe"
  chmod 500 "$probe" 2>/dev/null

  if mkdir "$probe/child" 2>/dev/null; then
    chmod 700 "$probe" 2>/dev/null
    return 1
  fi

  chmod 700 "$probe" 2>/dev/null
}

# Asked once. Two calls could disagree, and then the mutant is neither run nor skipped — a hole in
# an audit whose whole premise is that a green suite proves nothing until you watch it go red.
chmod_bites; bites=$?

[ "$bites" -eq 0 ] || printf '  skip  a loop that counts past a failure it cannot fix — this filesystem ignores chmod\n'
[ "$bites" -eq 0 ] && wreck_runner "a loop that counts past a failure it cannot fix is caught" \
  spins 's#slot_is_taken "$candidate" || return 1#:#'

# In the worktree the pointer gets committed, and a run id in someone else's clone names a directory
# that was never on their machine.
wreck_runner "a pointer written into the worktree is caught" \
  worktree 's|printf .%s/foundry-run. "$git_dir"|printf "%s" "foundry-run"|'

wreck_runner "a runner that ignores FOUNDRY_HOME is caught" \
  nohome 's|\[ -n "${FOUNDRY_HOME:-}" \] |\[ -z "${FOUNDRY_HOME:-}" \] |'

# Exit 0 with nothing lets a caller read "no run" as "the run is at the empty path".
#
# Three lines, and deliberately so: `path`, `bootstrap` and `targets` open with the same guard, and
# the rule is that no entry point softens it. It does not prove any one of the three alone is caught.
wreck_runner "a runner that exits 0 on no run is caught" \
  softno 's|dir=$(active_run) \|\| exit 1|dir=$(active_run) \|\| exit 0|'

wreck_runner "a layout with no units level is caught" \
  flatten 's|"$1/units/01/memory"||'

#
# Both guards in one mutation: either alone catches the only failure this suite can force. They are
# still not redundant — `build_layout` also covers a `mkdir` that succeeds partway down — but that
# permission shape cannot be arranged portably, so it goes untested rather than pretended.
#
# `#` as the delimiter: the text being removed is a `||`, and sed reads the first one as the end of
# the pattern.
#
# Every guard reachable from `new`, and the count is the point. A mutant removing only the ones it
# knew about is one the runner survives — the guard it missed exits 3 on its behalf and the break
# proves nothing. It went red on Linux once, where nobody had run an audit in days; the selection
# stamp caught it a second time. **Add a write to `new`, add a clause here.**
#
# `write_bootstrap`'s is included though the audit runs where `bootstrap_here` returns before it. A
# rule stated unconditionally and applied selectively is the shape that let the other two through.
wreck_runner "a runner that ignores a home it cannot write to is caught" \
  blind 's# *|| die_unwritable "$dir/item.md"$##; s# *|| die_unwritable "$dir"$##; s# *|| die_unwritable "$RUNS"$##; s# *|| die_unwritable "$1/id"##; s# *|| die_unwritable "$(authority_file "$1")"$##; s# *|| die_unwritable "$1/bootstrap"$##; s# *|| die_unwritable "$GRANTS/$id"$##'

wreck_runner "a runner that trusts an unset run directory is caught" \
  ghostvar 's|\[ -n "${FOUNDRY_RUN:-}" \] && \[ -d "$FOUNDRY_RUN" \]|\[ -n "${FOUNDRY_RUN:-}" \]|'

# A credential written into a run directory is a secret on disk that nobody meant to put there.
wreck_runner "an identity that keeps its credentials is caught" \
  creds 's#sed .s|://\[^/\]\*@|://|.#cat#'

# A path is the one thing a target may not hold. Accepting it makes the run unusable elsewhere and
# says nothing at the time.
#
# Anchored on the whole line. `*) return 1 ;; esac` alone matches the path guard below it too, and a
# mutation that fires in two places is testing neither of them.
wreck_runner "an identity that accepts a local path is caught" \
  localpath 's|case "$1" in \*:\*) ;; \*) return 1 ;; esac|case "$1" in *:*) ;; *) return 0 ;; esac|'

# The Critical. `[^/@]*@` stops at the first `@`, so a password containing one leaves its tail on
# disk — and every `new` writes it, unasked.
wreck_runner "a userinfo strip that stops at the first @ is caught" \
  firstat 's|://\[^/\]\*@|://[^/@]*@|'

# `ssh://git@host` carries a login. Stripping it writes an identity nobody can clone.
wreck_runner "an identity that strips an ssh login is caught" \
  sshuser '\|ssh://\*) strip_ssh_password|d'

# A `/` before the colon means a path. Without the rule, a dotted directory reads as scp-style.
wreck_runner "a path mistaken for scp-style is caught" \
  scpish 's|case "$host" in \*/\*) return 1 ;; esac||'

# The ref is half the line, and it went in unchecked.
wreck_runner "a ref that is never validated is caught" \
  anyref 's|/\* \| \*\[!-A-Za-z0-9_./\]\*)|/no-such-guard)|'

# Targets belong to the unit. At the run root they move the day a second unit exists.
wreck_runner "targets stored at the run root are caught" \
  flat 's|%s/units/01/targets|%s/targets|'

# 0..1, not exactly one. A bootstrap written when no identity could be derived is a target invented
# out of nothing.
wreck_runner "a bootstrap written without an identity is caught" \
  alwaysboot 's|line=$(bootstrap_here) \|\| return 0|line=$(bootstrap_here); line="${line:-unknown unknown}"|'

# The whole point of the allowlist. A run that may reach anything makes every check below decorative.
wreck_runner "an allowlist that authorises anything is caught" \
  openbar 's|\[ "$(bootstrap_identity "$1")" = "$2" \] && return 0|[ -n "$2" ] \&\& return 0|'

#
# The authority invariant: nothing widens a run's reach except `policy authorize`.
#
# Aimed at the append, not the guard. Weakening the guard only makes a refusal louder or quieter —
# the first version of this break added a condition that was always false, so the refusal still
# fired, the mutant behaved identically, and the audit reported a suite that had noticed nothing.
#
wreck_runner "targets add that grants itself is caught" \
  selfgrant 's|printf .%s %s\\n. "$identity" "$ref" >> "$file"|printf "%s\\n" "$identity" >> "$(grants_file "$dir")"; printf "%s %s\\n" "$identity" "$ref" >> "$file"|'

# Reporting success while writing nothing is worse than refusing: the caller carries on.
wreck_runner "a refusal that exits 0 is caught" \
  quietno 's|^        exit 5$|        exit 0|'

#
# The other half of the same invariant, and the half that shipped unguarded: `targets add` refused a
# repo policy never allowed, and then anything could append one by hand.
#
# Two breaks because the read makes two findings. Blinding the authorisation test leaves a selection
# nobody granted; blinding the arity test leaves a line that is not a target at all. A suite that
# notices one and not the other is covering half the read.
#
wreck_runner "a selection read without checking policy is caught" \
  trustfile 's#is_authorised "$dir" "$identity" ||#true ||#'

wreck_runner "a selection line that is not a repo and a ref is caught" \
  anyshape 's#NF && NF != 2#NF \&\& 0#'

# A pin captured somewhere the gates will never run. The charter reads as provenanced throughout —
# a real artifact at a real commit — so nothing downstream can tell.
wreck_runner "a bar derived off the graded ref is caught" \
  elsewhere 's#    refuse_second_ref "$dir" "$identity" "$ref"#    :#'

#
# Authorisation refuses a run that describes no work. Two refusals, two breaks: an empty charter
# grades nothing at all, and a clause that governs no selected target is a bar over nothing. A
# refusal nobody can break is a refusal that was never doing anything.
#
wreck_runner "an empty charter that authorises anyway is caught" \
  emptybar 's|\[ "$(clause_count "$charter_path")" -gt 0 \]|true|'

wreck_runner "a clause grading nothing that authorises anyway is caught" \
  nobar 's|ungoverned=$(ungoverning_clauses "$run_dir" "$charter_path" "$selection_path")|ungoverned=|'

#
# The freeze. Five breaks, because it makes five separate promises: the set is written down, a
# moved set is refused, the record holds the lines, and the stages that grade and record both read it.
#
# `unfrozen` is aimed at the write. Blinding the comparison alone leaves a suite that would still
# pass if nothing were ever recorded — the comparison has nothing to disagree with.
#
wreck_runner "a selected set that is never written down is caught" \
  unfrozen 's|    freeze_selection "$run_dir" "$selection_path"|    :|'

wreck_runner "a selection that moved and authorises anyway is caught" \
  drifted 's|\[ "$(normalised_selection "$2")" = "$(cat "$frozen")" \] && return 0|return 0|'
# `drifted` blinds the comparison itself. These blind one call site each, and each is a different
# claim — so each sed is anchored to the function it is about. Unanchored, one break would blind
# every caller and stop being a claim about any of them.
#
# `complete` and `deliver` share this guard: one decides whether a run may deliver and the other acts
# on that answer, so a freeze either binds both or is worth nothing.
wreck_runner "readers of the invariant that skip the freeze are caught" \
  livesel '/^refuse_unreadable_run()/,/^}/ s#    refuse_moved_selection "$1" "$(unit_targets_file "$1")" || exit 10#    :#'

#
# The recorder reads it too. A grader that misreads answers wrongly once; a recorder writes a row the
# ledger keeps, so it needs the guard for a reason the grader does not have.
#
wreck_runner "a recorder that stamps for a moved selection is caught" \
  movedgate '/^gates()/,/^}/ s#    refuse_moved_selection "$dir" "$(unit_targets_file "$dir")" || exit 10#    :#'

# A digest answers "something moved" where a diff answers "what". The record has to hold the lines.
#
# `#` as the delimiter: the text being replaced contains a pipe, and `\|` inside a `|`-delimited
# expression is alternation to GNU sed and a literal elsewhere — a mutation that means two things is
# not a mutation.
wreck_runner "a freeze that records a digest instead of the lines is caught" \
  digested 's#| LC_ALL=C sort -u; }#| LC_ALL=C sort -u | cksum; }#'

# Sorting and `-u` are the two halves of "a set". Reordering or repeating a target is not a change,
# and a refusal on either would teach people to ignore refusals.
#
# Both aim at the tail of the pipeline rather than the whole function body: the body has grown twice
# already, and a mutation quoting it in full stops applying every time it does. A break that no
# longer applies is a break that proves nothing, and the harness can only tell you so afterwards.
wreck_runner "a freeze that reads the selection as a list is caught" \
  aslist 's#| LC_ALL=C sort -u; }#; }#'

# The detector answers for the directory you stand in. `derive` and `check` both guard that; the
# third consumer did not, so a directory declaring the charter's gates authorised a run that the
# bootstrap refuses — and wrote the frozen record on the way out.
wreck_runner "authorising for whatever repository you stand in is caught" \
  anywhere 's|    refuse_wrong_repository "$run_dir"|    :|'

#
# Conditions 1 and 3, the two signals authorisation consumes rather than computes.
#
# Blinding either lets a run authorise on a bar nobody set: `introduced` on a clause nothing derives,
# the other on a gate the detector yields with no clause for it. Both aim at the capture, not the
# test — a test that always passes leaves the capture running and the mutant reading identically.
#
wreck_runner "a run that authorises over introduced meaning is caught" \
  ownbar 's|    introduced=$(unauthorised_clauses "$run_dir" "$charter_path")|    introduced=|'

# The whole line, anchored: the capture holds a pipe, and a `|`-delimited expression would end at it.
# The guard that keeps a never-derived run from being told it lost a clause. It had no break, and a
# rule with no break is a rule the next edit deletes for free.
wreck_runner "authorising before deriving, reported as a lost clause, is caught" \
  nocharter 's#\[ -f "$charter_path" \]#true#'

wreck_runner "a run that authorises after a derived clause was removed is caught" \
  lowered 's#^    gates_with_no_clause=.*#    gates_with_no_clause=#'

# One allowlist for every run is one run's grant handed to all of them.
#
# Also caught by the credential check, which shares the grants file — so a red here does not on its
# own point at scoping. Kept because it is the only break aimed at that line.
wreck_runner "a grant shared across runs is caught" \
  global 's@printf .%s/%s/targets. "$GRANTS" "${1##\*/}"@printf "%s/targets" "$GRANTS"@'

# A newline turns `grep -Fxq` into a pattern list, so one grant matches a second repo and the append
# writes both. The whole exploit is one unguarded argument.
wreck_runner "an identity that may hold a newline is caught" \
  smuggle 's|\*\[!-A-Za-z0-9_.:/@~+%\]\* \| \*/../\* \| \*/..)|no-such-shape)|'

# Grants outlive the run directory, so a slot chooser that reads only `runs/` inherits an allowlist.
# The half `collide` cannot tell you about.
wreck_runner "a slot reclaimed with grants behind it is caught" \
  inherit 's#slot_is_reserved() { \[ -e "$GRANTS/$1" \]; }#slot_is_reserved() { false; }#'

# The bootstrap is an effective grant. Copied, it becomes a second place the truth lives — and the
# short-circuit this blinds is the one both grants share, so it catches any grant recorded twice.
wreck_runner "a bootstrap copied into the grants is caught" \
  copyboot 's|"$holds" "$dir" "$identity" && return 0|"$holds" "$dir" "$identity" \&\& [ 1 -eq 0 ] \&\& return 0|'

# A bootstrap file naming nothing must read as no bootstrap, or `policy` lists a nameless entry.
wreck_runner "a bootstrap that names nothing is caught" \
  blankboot 's|NR == 1 && $1 != "" { printf "%s", $1; found = 1 } END { exit !found }|NR == 1 { printf "%s", $1; exit }|'

# Policy state is read by eye and outlives the run. A password stored here is a password on disk.
wreck_runner "a grant that stores credentials is caught" \
  grantcreds 's|record_grant "$file" "$identity"|record_grant "$file" "$repo"|'

# The charter lives in the run, so nothing can inherit one. Move it beside the runs and a reclaimed
# slot would carry a dead run's definition of good — the bug policy shipped with.
wreck_runner "a charter kept outside the run is caught" \
  loosech 's|charter_file() { printf .%s/charter. "$1"; }|charter_file() { printf "%s/charter-%s" "$HOME_DIR" "$(basename "$1")"; }|'

#
# The bug this break exists because of.
#
# `git rev-parse main:Makefile` sends its `fatal:` to stderr and echoes the unresolved argument to
# stdout, so dropping stderr leaves a string that looks exactly like a sha. It was pinned.
#
wreck_runner "a sha that is really an error message is caught" \
  fakesha 's|git rev-parse --verify --quiet "$1:$2"|git rev-parse "$1:$2"|'

#
# The other one.
#
# Folding the kind into the id gave `Gate: tests` and `Decided: tests` different ids, so the
# weakening check searched for a clause that could not be there and monotonicity did nothing.
#
wreck_runner "an id that includes the kind is caught" \
  kindid 's|clause_id() { printf .%s. "$1"|clause_id() { printf "%s %s" "$1" "${2:-}"|'

#
# Only derivation may set a kind.
#
# This replaced a break against a numeric ranking of the kinds. There is no ranking now — the kinds
# say how truth is established, not how much, so a human editing one is claiming provenance that
# nothing established rather than tightening or weakening anything.
#
wreck_runner "a human allowed to change a clause's kind is caught" \
  kindedit 's#^    \[ -z "$was" \] .* {$#    [ 1 -eq 1 ] || {#'

# A clause is one line of a line-oriented file. Accepting a newline makes one clause into two records.
#
# `#` as the delimiter, because the text being replaced contains `||` and sed reads the first `|` as
# the end of the pattern. The audit caught this as *sed failed* rather than passing — twice.
wreck_runner "clause text that may hold a newline is caught" \
  twoline 's#^is_one_line() {#is_one_line() { return 0; :#'

# Re-deriving must not drop what nothing derived. Losing them makes `derive` a silent deletion.
wreck_runner "a re-derivation that drops introduced clauses is caught" \
  dropintro 's|^    keep_introduced .*$|    :|'

# Deriving from the wrong repository pins another repo's files under this run's target.
wreck_runner "deriving from a repository the run does not name is caught" \
  wrongrepo 's#^refuse_wrong_repository() {#refuse_wrong_repository() { return 0; :#'

#
# Every finding `check` exists to make, one break each.
#
# Two of these named readers that no longer exist. `unpinned_clauses` and `deleted_clauses` were
# each gated on a record a tamper deletes — no `gate` record meant no unpinned finding — so both
# were replaced by `underived_gates`, which asks the detector what should be there and then looks.
#
wreck_runner "a check blind to a gate resting on nothing is caught" \
  blindgates 's|^        underived_gates "$file"$|        :|'
wreck_runner "a check blind to a rewritten clause is caught" \
  blindforge 's|^        forged_ids "$file"$|        :|'
# Re-deriving was the remedy for drift, which made it the way to launder a worker's edit into
# authority: commit the rewritten bar, derive again, and `check` passes on a requirement no human
# wrote. Issue #99.
wreck_runner "a run allowed to derive from what it changed is caught" \
  samerun 's#refuse_moved_from_base "$source" "$sha" "$ref" || return 1#:#'

# Comparing pinned sources one by one cannot see a source that stopped being yielded. Delete a
# level-2 declaration and detection falls back a level, so the clause survives under a different
# source and every remaining pin still matches.
wreck_runner "a run allowed to change what the gates resolve to is caught" \
  resolution 's#refuse_moved_resolution "$ref" || exit 6#:#'

# The rule the rest rests on. Derive through the branch and every guard below still passes, because
# the base it compares against is whatever the worker last committed.
wreck_runner "a base read from the branch instead of the commit is caught" \
  branchbase 's#ref=$(bootstrap_base "$dir")#ref=$(awk "NR == 1 { print \\$2; exit }" "$dir/bootstrap")#'

# The pin names a commit, so comparing the artifact against that ref compares it with itself and
# always answers "unchanged". Drift is the checkout differing from what was pinned.
wreck_runner "a drift check that compares the base with itself is caught" \
  selfsame 's#\[ "$(worktree_sha "$source")" = "$sha" \] \&\& continue#[ "$(blob_sha "$ref" "$source")" = "$sha" ] \&\& continue#'

#
# The one property that makes a ledger evidence: the recorder runs the command. Take the result from
# the caller instead and the ledger records what a worker says happened.
#
wreck_runner "a recorder that takes the result from its caller is caught" \
  claimed 's#why=$("$@" </dev/null 2>&1); result=$?#result=$1; why=""#'

# A record with no ref cannot be matched to a delivered sha, and §2.5's completion invariant
# quantifies over the delivered ref of every selected target.
wreck_runner "evidence stamped without the ref it applies to is caught" \
  noref 's#stamp "$dir" machine "$name" "$result" "$ref" "$why"#stamp "$dir" machine "$name" "$result" "" "$why"#'

# `why` is flattened and a name is refused. Let a name through raw and a newline in it writes a
# second record whose result and ref the caller chose — a caller supplying an outcome, by the field
# that was not guarded.
wreck_runner "a gate name that can hold a newline is caught" \
  forgedname 's#    is_one_line "$name" || { note "a gate.s name is one line: \[$name\]"; exit 2; }##'

# Taken after the command, a gate that commits is recorded against a tree that did not exist when it
# was graded.
wreck_runner "a ref read after the command ran is caught" \
  lateref 's#stamp "$dir" machine "$name" "$result" "$ref" "$why"#stamp "$dir" machine "$name" "$result" "$(delivered_ref)" "$why"#'

# Said on stderr and nowhere else, it dies with the run. A reader re-running the gate at the
# delivered ref then runs a file the run rewrote, gets another exit code, and reads an honest record
# as a forged one.
wreck_runner "a substitution the record never keeps is caught" \
  quietsub 's#    record_the_substitution "$1" "$moved"##'

# An answer stamped `human` against a clause satisfaction wants `judged` for. The record says a
# person answered and completion still calls it unmet, with nothing joining the two.
wreck_runner "a person allowed to answer a Judged clause is caught" \
  personjudge 's#    refuse_a_kind_a_person_cannot_answer "$1" "$2" "$3"##'

# `unbornref` stood here: without a guard, a repository with no commit recorded a gate against an
# empty ref. The guard is gone and so is the break, because the case moved rather than closed — a
# repository with no commit can hold no workspace, and `attached` proves a HEAD before any tree is
# named. `a_record_needs_a_commit_to_apply_to` asserts the refusal at its new place.

# Grants are keyed by the run's id, so a renamed directory looks up a key nothing holds and `policy`
# answered exit 0 with the bootstrap alone. Authority a human gave, gone, without a word.
#
# Every command that acts on the run, blinded at once. It does not prove any one of them is caught —
# `model.sh` asserts each separately for that, and `namedgate` below takes the one that writes.
wreck_runner "a renamed run that loses its grants in silence is caught" \
  renamed 's#    refuse_renamed_run "$dir"##; s#    refuse_renamed_run "$run_dir"##'

# The recorder alone. `renamed` blinds every caller, so it is killed by whichever check runs first
# and says nothing about the stage that stamps a row into a run the others refuse.
wreck_runner "a recorder that stamps into a renamed run is caught" \
  namedgate '/^gates()/,/^}/ s#    refuse_renamed_run "$dir"#    :#'

# The other direction. Failing open on a missing `id` is what lets a run made before this rule keep
# working, and closing it breaks every one of them at once — silently, because nothing asked.
wreck_runner "a guard that refuses a run made before it is caught" \
  nogrand 's#named=$(recorded_id "$1") || return 0#named=$(recorded_id "$1") || exit 13#'

#
# Grading a repository and writing to one are two powers, and one break covers every way the second
# collapses into the first — a grant that forgives the bootstrap target and a grant nothing reads
# both make `may_deliver_to` true, and one assertion kills both. A second break was written and
# deleted: it failed on the same three checks with the same values.
#
# **What the assertion's position does, the break cannot.** Every run is bootstrapped somewhere, so
# delivery inheriting the allowlist would grant delivery everywhere — and a check made *after* a
# grant exists cannot see that. `model.sh` asks before granting for exactly this reason.
#
wreck_runner "a delivery nobody granted is caught" \
  ungranted '/^may_deliver_to()/,/^}/ s#    \[ -f "$file" \] || return 1#    return 0#'

wreck_runner "a check blind to a gate resolving elsewhere is caught" \
  blindres   's|^        moved_resolutions "$file"$|        :|'
wreck_runner "a check blind to a pinned file that moved is caught" \
  blindmoved 's|^        moved_sources "$file"$|        :|'
wreck_runner "a check blind to one id naming two meanings is caught" \
  blindambig 's|^        ambiguous_ids "$file"$|        :|'

# The detector must answer for the repository, not for the directory you stand in. One level down it
# found nothing, wrote an empty charter, and exited 0.
wreck_runner "a detector run against the working directory is caught" \
  cwdgates 's|sh "$(gate_resolver)" "$(repo_root)"|sh "$(gate_resolver)" .|'

# A pin's target is self-asserted, so accepting any pin carrying the id let one relabelled word make
# a local pin read foreign — reported uncheckable, never compared, never counted.
wreck_runner "a gate satisfied by a pin on another repository is caught" \
  anypin 's|has_local_pin "$1" "$id" "$here"|has_record "$1" pin "$id"      |'

# Anchored, because the dispatch line holds the same call and blanking both would break `charter
# check` as well — one break, or the mutant proves whichever failure the suite noticed first.
wreck_runner "gates run against a charter that drifted from its pins are caught" \
  nodrift 's#^    check_charter "$dir"$##'

# The ref per gate rather than per run. A gate that commits moves the tree, and every gate after it
# is recorded against a sha that was never the one they were asked about.
wreck_runner "a ref taken once per gate is caught" \
  gateref 's#stamp_command "$dir" "$ref" "$name" sh -c "$command"#stamp_command "$dir" "$(delivered_ref)" "$name" sh -c "$command"#'

# §2.4's rule is the whole of what makes a gate unambiguous in a workspace. Without it a gate reads
# whichever directory the caller happened to stand in.
wreck_runner "a gate run somewhere other than its target's root is caught" \
  gatecwd 's#    cd "$tree" || { note "cannot enter \[$tree\]"; exit 16; }##'

# The fallback that looked defensible. The checkout Foundry was invoked from is a checkout of the
# target, so grading it passes — for a tree the worker never wrote to.
wreck_runner "gates falling back to the invoking checkout are caught" \
  fallback 's#    note "no workspace holds \[$2\] at \[$3\].*#    { printf "%s" "$(repo_root)"; return 0; }#'

# The predicate that makes a workspace this unit's. Accept any directory holding a checkout and a
# gate grades one built for another target, or another ref.
wreck_runner "a gate grading any checkout it finds is caught" \
  anytree 's#        attached "${slot%/}" "$2" "$3" && { printf .%s. "${slot%/}"; return 0; }#        [ -d "${slot%/}" ] \&\& { printf "%s" "${slot%/}"; return 0; }#'

# Core naming the directory is core reaching for `git hash-object` — a container adapter would have
# to be git to put its workspace where core looks. It asks each checkout instead.
wreck_runner "core computing the workspace path rather than asking is caught" \
  namedslot 's#    for slot in "$(unit_workspace "$1")"/\*/; do#    for slot in "$(unit_workspace "$1")/$(target_slot "$2")"; do#'

# Green regardless. The records still land, so only the exit code carries the answer — and a caller
# that branches on it would ship a red run as a finished one.
wreck_runner "a gate run that answers 0 whatever happened is caught" \
  greengate 's#    \[ "$failed" -eq 0 \] \&\& return 0#    return 0#'

# `%` for the delimiter: the argument count holds the one sed would otherwise end on.
wreck_runner "a gate run that takes a command from the caller is caught" \
  callercmd 's%    \[ "$#" -eq 0 \] || { usage; exit 2; }%%'

# Two guards, two breaks. A record with no name cannot be matched to a bar; a record with no command
# is a pass for having run nothing. One mutant each, or whichever fires first hides the other.
wreck_runner "a gate recorded under no clause name is caught" \
  noname 's#    \[ -n "$name" \] || { note "the charter pins a command under \[$id\] and names no clause for it"; exit 7; }##'

wreck_runner "a gate with no command recorded as a pass is caught" \
  emptycmd 's#    \[ -n "$command" \] || { note "the charter pins no command for \[$name\]"; exit 7; }##'

# The count that made `emptycmd` equivalent. Blanking two fields of a two-field record leaves one
# space, `check` read it as a command, and the spurious drift refused the run before the guard above
# could — a mutant killed by a refusal that had nothing to do with it.
# Two functions strip the same way, so each break names the field count before it. Matching
# `sub(/^ +/` alone would blank both and prove whichever failure the suite noticed first.
wreck_runner "a pinned command read as a space when it is empty is caught" \
  spacecmd 's#$2 = ""; sub(/^ +/, "")#$2 = ""; sub(/^  /, "")#'

wreck_runner "a clause read as spaces when it has no text is caught" \
  spacetext 's#$2 = ""; $3 = ""; sub(/^ +/, "")#$2 = ""; $3 = ""; sub(/^   /, "")#'

# One appended line, no pin edited. `check` compares the first record for an id and never sees the
# second, so without this the charter reads clean and runs a command nothing validated.
# The reader that judges the charter's records as records. Without it every file-only tamper — a
# repeat, an invented clause, a gate resting on a `Judged` one — reads as a sound charter.
wreck_runner "a check that never reads its own records is caught" \
  unsound 's#        unsound_records "$file"##'

# One notion of identity, and it is the string. Coerce the subscript and `0123` becomes `123`: the
# repeat that is not one is reported, and the gate nothing pinned is not.
wreck_runner "a gate id compared as a number is caught" \
  numericid 's#held\[$2\]++#held[$2 + 0]++#'

# A pin's target is self-asserted and `moved_sources` will not refuse a foreign one. Without this a
# charter pinned to another repository runs its gates against this checkout.
wreck_runner "a gate run against a repository it was not pinned to is caught" \
  elsewhere 's#    refuse_gates_from_elsewhere "$dir" "$pins" || exit 7##'

# The list the loop reads is the command's stdin. A gate that reads it swallows the gates behind it,
# and they read as never having failed.
# The whole of what the completion invariant adds. Gates could pass at commit N, three commits land,
# and delivery proceed on evidence that no longer applied.
wreck_runner "evidence that no longer applies to the delivered ref is caught" \
  staleref 's# || $6 "" != ref ""##'

# `satisfying` evidence is a record whose answer is yes. A record that a gate failed is a record.
wreck_runner "a failing gate counted as satisfying its clause is caught" \
  anyresult 's#        $5 != "0"                             { no = 1; next }#        $5 != "0" { yes = 1 }#'

# Quantified over clauses and over targets, so each empty set satisfies it for free. These two are
# the fail-opens, and neither is an edge case: every fresh run has an empty selection.
wreck_runner "an empty charter delivering vacuously is caught" \
  vacuousbar 's#    empty_bar "$1"##'

wreck_runner "an empty selection delivering vacuously is caught" \
  vacuousselection 's#    empty_selection "$1"##'

wreck_runner "a run nobody selected delivering anyway is caught" \
  unclaimed 's#    unauthorised_run "$1"##'

# Quantified over every selected target, and one checkout answers for one. Without this the second
# is graded by nothing and the run delivers on evidence that never mentioned it.
wreck_runner "a second selected target graded by nothing is caught" \
  onetarget 's#    ungradable_targets "$1"##'

# `targets` and `authorise` refuse a hand-edited selection. The grader read it, and every clause is
# graded against every selected target.
wreck_runner "a grader reading a selection nobody authorised is caught" \
  ungrated 's#    refuse_unselectable "$1" "$(unit_targets_file "$1")" || exit 5##'

# Three ways a clause is not met, and they take different remedies. Collapse the first into the
# second and an introduced clause reads as one belonging to another checkout — a reader sent looking
# for a workspace, where the answer is a human's.
wreck_runner "an introduced clause reported as another repository's is caught" \
  introducedaway 's#has_record "$2" pin "$3"#true#'

# The isolation itself. A worktree shares `.git` with the checkout it came from, so a worker could
# move the source's refs — and it leaves a `.git` file where a clone leaves a directory, which is
# what the check sees.
wreck_runner "a workspace sharing objects with the checkout it came from is caught" \
  sharedobjects 's#git clone --quiet --no-hardlinks#git clone --quiet --shared#'

# A workspace is where mutation happens. Without this, a run nobody authorised gets a mutable
# checkout of a target nobody allowed it.
wreck_runner "a workspace opened for a run nobody authorised is caught" \
  freeworkspace 's#^    authorise$##'

# `slug` truncates at 40 characters, so two long identities name one directory — and here that is two
# targets in one checkout rather than an untidy name. `foldedslot` below covers the same property
# through the digest, which is the thing that actually prevents it.
wreck_runner "a target directory named by a truncating slug is caught" \
  slugslot 's#"$(readable_name "$1")" "$(identity_digest "$1")"#"$(slug "$1")" ""#'

# Idempotent, or `open` is not attach and a second session destroys the first one's work.
# Attaching is what makes `open` idempotent. Never attach and a published workspace is refused as
# something occupying its own slot.
wreck_runner "a workspace cloned over on every open is caught" \
  reclone 's#^attached() {#attached() { return 1;#'

# The origin is where a branch pushed from here goes. Left as the path it was cloned from, delivery
# would land on this machine and nowhere else.
wreck_runner "a workspace keeping the path it was cloned from is caught" \
  localorigin 's#    git -C "$1" remote set-url origin "$2" 2>/dev/null \&\& return 0#    return 0#'

# A slot with no checkout is a clone that failed or one another session is filling. Cloning over it
# destroys whichever it is, and `git clone` into a directory holding files fails with a message about
# the wrong thing.
wreck_runner "a half-made checkout cloned over is caught" \
  halfclone 's#{ \[ -e "$1" \] || \[ -L "$1" \]; } || return 0#return 0#'

# `[ -e ]` follows the link. Without `-L` a dangling slot reads as nothing there, so the build runs
# and `publish_workspace` refuses the rename onto it — "could not publish", for a thing that needs
# removing.
wreck_runner "a dangling slot reported as a session in flight is caught" \
  danglingslot 's#\[ -e "$1" \] || \[ -L "$1" \]#[ -e "$1" ]#'

# A slot can hold a valid checkout of another repository. Attaching on HEAD alone hands the run a
# workspace belonging to someone else, and every gate after it grades that.
wreck_runner "a workspace belonging to another repository is caught" \
  anyorigin 's#    \[ "$(git -C "$1" remote get-url origin 2>/dev/null)" = "$2" \] || return 1##'

wreck_runner "a workspace opened for another ref is caught" \
  anybaseref 's#    \[ "$(git -C "$1" config --get foundry.ref 2>/dev/null)" = "$3" \]#    :#'

# The identity, not the decoration. Fold punctuation and four repositories share one checkout.
wreck_runner "a slot named by folding punctuation alone is caught" \
  foldedslot 's#printf .%s-%s. "$(readable_name "$1")" "$(identity_digest "$1")"#readable_name "$1"#'

# Built beside the slot and published into it, or a reader sees a half-made checkout as the finished
# one — and is told to remove what another session is still filling.
wreck_runner "a workspace assembled in the slot rather than published into it is caught" \
  assembled 's#    clone_into "$building" "$(repo_root)" "$2" "$3"#    clone_into "$1" "$(repo_root)" "$2" "$3"; return 0#'

# Invariant 4 describes a stamp. A run whose selection nobody recorded is a run the work source
# cannot ask, because there is no one it may ask.
wreck_runner "a run that records nobody selecting it is caught" \
  noauthority 's#    stamp_selection "$dir" "$(selector)" "$id"##'

# §2.5 keeps the two apart by shape, and the shape only holds if they are kept apart by store. Three
# fields in the pool completion reads existentially would be a record with no ref, satisfying nothing
# and looking like it could.
wreck_runner "a selection written into the evidence ledger is caught" \
  authorityinledger 's#>> "$(authority_file "$1")"#>> "$(evidence_file "$1")"#'

# Attribution records who, never whether they may — so a name nobody gave is worse than no name.
wreck_runner "a selector invented when nobody is named is caught" \
  inventedwho 's#${FOUNDRY_WHO:-$(git config user.email 2>/dev/null)}#${FOUNDRY_WHO:-nobody}#'

wreck_runner "a gate that eats the gates after it is caught" \
  eatstdin 's#why=$("$@" </dev/null 2>&1)#why=$("$@" 2>\&1)#'

#
# The work source. **Two verbs take no argument for what a human is supposed to supply**, and these
# are the breaks that put those arguments back — `read` saying what an item holds, `receive` saying
# what a human answered. Everything else in this stage rests on them.
#
# `%` as the delimiter: the line being matched holds `$#`, and sed reads that `#` as the end of the
# pattern.
wreck_runner "a read that lets the caller say what the item holds is caught" \
  srcwords 's%\[ "$#" -le 2 \]%[ "$#" -le 3 ]%'

wreck_runner "a receive that takes an answer is caught" \
  srcanswer 's#-le 3 \] || { note "receive#-le 9 ] || { note "receive#'

# An answer satisfying by merely existing. `receive` carries whatever a human wrote, "no" included,
# so the clause's own id is what separates a decision from a presence.
wreck_runner "an answer that satisfies without naming the clause is caught" \
  anyanswer 's#        \*"$id"\*) ;;#        *) ;;#'

#
# A question is `run + stage + clause`. Each term keeps one wrong answer away from a reader, so each
# gets its own break — dropping the run lets a later run derive an earlier one's question, and the
# other two let a question be asked that no stage will ever look for.
#
wreck_runner "a question that does not name its run is caught" \
  srcrun 's@"${1##\*/}" "$2" "$(clause_id "$3")"@"$2" "$(clause_id "$3")" ""@'

wreck_runner "a stage nothing reads is caught" \
  srcstage 's#authorisation | completion) return 0 ;;#*) return 0 ;;#'

wreck_runner "a question about a clause the charter does not hold is caught" \
  srcclause 's#\[ -n "$(clause_kind "$(charter_file "$1")" "$(clause_id "$2")")" \] && return 0#return 0#'

# A run reads one item, because a delivery and a question are both addressed to it.
wreck_runner "a run that reads a second item is caught" \
  srcitem 's#\[ "$held" = "$2" \] && return 0#return 0#'

wreck_runner "a question with nothing to address it to is caught" \
  srcaddr 's#\[ -n "$(item_id "$1")" \] && return 0#return 0#'

# Grants reserved a name; a run that authorised nothing gave its back, and the next run derived the
# deleted run's question byte for byte.
wreck_runner "a run name that can be minted twice is caught" \
  srcslot 's#reserve_name() { mkdir -p "$GRANTS/$1" 2>/dev/null; }#reserve_name() { :; }#'

# A source that is not there answers "no item", and no item is what an unread run looks like.
wreck_runner "a work source that is not there passing for one is caught" \
  nosource 's#\[ -f "$(source_resolver)" \] ||#true ||#'

#
# The adapter's own rules, and the file is the point: an adapter is a program of its own and floor
# is not its only caller. Floor now records what it sent and refuses from that first, so the checks
# these break reach the adapter only once the record is off.
wreck_runner "a delivery that absorbs a second branch is caught" \
  dirbranch 's#delivered "$file" "$3" || return 4#:#' lib/source-dir.sh

#
# The rules that keep an absence observed.
#
# Three places answer *nothing there*, and each has a way to be wrong about it: the adapter's probe,
# floor's mapping of what the adapter said, and the resolver naming the half of level 1 that is
# missing. A break on any one of them puts a false fact back.
#
wreck_runner "a bad credential passing for a missing item is caught" \
  ghprobe 's#repository_answers || return 3#:#' lib/source-github.sh

wreck_runner "an answer that could not be read passing for silence is caught" \
  ghanswer '/could not read the comments/{n;s/return 3/return 0/}' lib/source-github.sh

wreck_runner "a source that could not be asked reported as empty is caught" \
  unasked 's#exit 20#exit 1#'


# Whether `chmod 000` means anything here. Windows records no read bit and root ignores the one it
# finds, so the break below would report a rule held for a reason that is not the rule.
records_unreadable() {
  probe="$tmp/read-probe"
  : > "$probe"
  chmod 000 "$probe" 2>/dev/null
  unreadable=1; [ -r "$probe" ] && unreadable=0
  chmod 644 "$probe" 2>/dev/null

  [ "$unreadable" -eq 1 ]
}

# A declaration and a guess are different ranks. `awk` exits non-zero for a file naming no gate and


# The run pointer is §4's join test, and `open` discarded the status that says it landed. The inner

# The ladder is read downward and the first rung that holds wins. Dropping the top one makes a
# delivered run read as a graded one — work that is finished, offered as work to resume.
wreck_runner "a delivered run reported as still graded is caught" \
  ladder 's#\[ -s "$(delivery_file "$1")" \] && { printf .delivered.; return; }#:#'
# guard matters for its own reason: with several slots only the last one's status survives a loop,
# so the first failure has to stick.
audit_the_unjoinable_slot() {
  records_unreadable || {
    printf '  skip  a slot nobody can join — this filesystem records no mode bits\n'
    return
  }

  wreck_runner "a workspace whose pointer never landed is caught" \
    nopointer 's@point_slots_at_run "$root" "${dir##\*/}" || {@point_slots_at_run "$root" "${dir##*/}"; : || {@'
}
audit_the_unjoinable_slot
# A file that is there and cannot be read is not a file nobody wrote. #200 taught the other adapter
# this; the contract is unproven until two satisfy it — RFC-001 §8.
audit_the_unreadable_item() {
  records_unreadable || {
    printf '  skip  an unreadable item read as an absent one — this filesystem records no read bit\n'
    return
  }

  wreck_runner "an unreadable item read as one nobody filed is caught" \
    diritem 's#\[ -r "$root/items/$1" \] || return 3##' lib/source-dir.sh
}
audit_the_unreadable_item
# for one it could not open, and dropping the read guard puts both back on the same footing — so a
# repository's bar becomes whatever detection finds.
audit_the_unreadable_declaration() {
  records_unreadable || {
    printf '  skip  a declaration read as a guess — this filesystem records no read bit\n'
    return
  }

  wreck_runner "a declaration it could not read becoming a guess is caught" \
    unreadable 's#\[ -r "$dir/.foundry/gates" \] || return 22##' lib/detect-gates.sh
}
audit_the_unreadable_declaration
# The check this breaks is the one skipped where `gh` is installed, so this is skipped there too. Both
# run under `sh bin/gates.sh linux`, whose image has no `gh` — which is the whole point of the rule.
audit_the_missing_half() {
  command -v gh >/dev/null 2>&1 && {
    printf '  skip  a directory answering silently for a GitHub remote — this machine has gh\n'
    return
  }

  wreck_runner "a directory answering silently for a GitHub remote is caught" \
    quietfall '/remote_is_github && echo/d' lib/source.sh
}
audit_the_missing_half

wreck_runner "a question rewritten under a human is caught" \
  dirwords 's#same_question "$file" "$3" || return 4#:#' lib/source-dir.sh

wreck_runner "silence answered as an answer is caught" \
  dirsilence 's#\[ -f "$root/answers/$1/$2" \] || return 1#\[ -f "$root/answers/$1/$2" \] || return 0#' lib/source-dir.sh


# Which adapter answers, decided by whatever the machine has installed. The suite's own checks
# changed answer on a machine with `gh`, and nothing said so — #176.
wreck_runner "a work source that cannot be named is caught" \
  namedsource 's#"${FOUNDRY_SOURCE:-$SELF_DIR/../lib/source.sh}"#"$SELF_DIR/../lib/source.sh"#'
# The question names the clause it asks about, so a reader that starts at the marker hands the question
# back as its answer — and a human who has not replied yet reads as having agreed.
wreck_runner "a question answering itself is caught" \
  ghself 's#mine = index($0, mark) > 0; open = 0#mine = 1; open = 1#' lib/source-github.sh
# The author is the only thing telling the run's own words from a person's. A reader that ignores it
# hands back a note the run wrote — which is exactly what #373 was, and it stamped a
# human answer nobody gave.
wreck_runner "a run answering its own question is caught" \
  ghauthor 's#if (who == self) { skipped(#if (0) { skipped(#' lib/source-github.sh

# A lookup that could not answer, read as a delivery that is not there — whose remedy is to open one.
# The run lives in the body so that one run cannot open a second delivery, and this is the check that
# enforces it failing open.
wreck_runner "a failed lookup passing for an absence is caught" \
  ghlookup 's#had=$(delivery_of "$2") || return 3#had=$(delivery_of "$2")#' lib/source-github.sh

# The same read one function over. Empty is what `put_question` reads as *not asked yet*, and it
# answers by asking — so a resumed run whose lookup failed put the question to the human twice.
wreck_runner "a question lookup that failed asking again is caught" \
  ghasked 's#asked=$(after_marker "$1" "floor-question: $2 ") || return 3#asked=$(after_marker "$1" "floor-question: $2 ")#' lib/source-github.sh

#
# The record is read before the source is asked, and written when the source answers.
#
# Neither half alone is the rule. Read-only leaves nothing to read; write-only asks GitHub anyway, and
# GitHub's body index is eventually consistent — a lookup seconds after a delivery says nothing, which
# is what opens a second delivery.


# Two ways a run reaches the ask, and only one of them may. Inverting the guard asks about a clause


#
# The boundary between two comments is the adapter's, not `gh`'s.
#
# Without it `said_after` cannot tell where the question's own body ends, and reads either nothing or
# the words that asked. The layout it used to recognise — `author:` and a rule — is what GitHub
# stopped serving to an older client at all.
#
wreck_runner "a comment boundary read out of a rendering is caught" \
  noboundary 's#"floor-comment: " + .author.login, .body#.body#' lib/source-github.sh
#
# A question a human can act on, and one only its own run can read.
#
# Condition 3 asking is not broken separately: `alwaysask` above makes every authorise ask, and the
# check that counts questions after a condition-3 refusal goes red with it.
#
wreck_runner "a question carrying nothing a human can act on is caught" \
  blankask 's#"May this clause exist?.*to authorise it."#"Please answer."#'

wreck_runner "a question any run can answer is caught" \
  sharedask 's@printf .%s.%s.%s. "${1##\*/}"@printf "%s.%s.%s" "shared"@'

# The last field of a tab-separated row is a gate's own output. Unflattened, a gate writes rows — and
# for a clause no gate grades, nothing would ever stand beside the one it wrote.
wreck_runner "a gate whose output becomes a record is caught" \
  forgedrow 's#"$(one_line "$6")"#"$6"#'

# A gate that could not run, stamped as one that failed. The ledger is append-only and read
# conjunctively, so the row it writes is the run's ref for good — every gate green afterwards and
# still nothing to deliver from.
wreck_runner "a gate that could not run recorded as one that failed is caught" \
  ranfail 's#never_ran "$result" *&& #false \&\& #'
# nobody introduced, which is #66's test failing — and the check that used to hold this ground read
# `charter check`, a verb with no question in it.
wreck_runner "a run asking when nothing blocks is caught" \
  alwaysask 's#\[ -z "$introduced" \] ||#false ||#'

# The exit code was checked and the sentence was not, so the one command that grants a target could
# be dropped from the refusal and every check stayed green. The whole message goes, because the
# remedy is written with backticks and GNU sed reads a backslashed one as the start of the buffer.
wreck_runner "a refusal that names no remedy is caught" \
  noremedy 's#note "not authorised for this run.*#note "not authorised"#'
# Invariant 4 already refuses this run at `complete`. The break is the silence, not the refusal: a
# second machine that hears it only after the work has done the work.
wreck_runner "a run nobody selected made in silence is caught" \
  quietwho 's#^    say_if_nobody_selected$#    :#'

# A search narrows and a marker decides. Dropping the marker lets another run's pull request come
# back on shared date tokens, and `publish` then refuses a run that never delivered.
wreck_runner "a delivery matched on tokens rather than its marker is caught" \
  bodymark 's#select(.body | contains(\\"floor-run: $1\\")) | ##' lib/source-github.sh

wreck_runner "a delivery record the run never reads is caught" \
  noread 's#delivered_already "$dir" && return#:#'

wreck_runner "a delivery the run never records is caught" \
  nowrite 's#> "$(delivery_file "$1")"#> /dev/null#'

# A delivery that publishes without pushing. The pull request is opened, points at a branch no remote
# has, and the run reads as delivered — the one outcome `deliver` exists to make true.
wreck_runner "a delivery that never pushed is caught" \
  nopush 's#    push_workspace "$1" "$2" "$branch"#    :#'

# Git says why a clone failed and floor is the only thing that hears it. A refusal that keeps the exit
# code and drops the words leaves a worker with a workspace that will not build and no way to know why.
wreck_runner "a clone that swallows git's words is caught" \
  clonesilent 's#    note "could not clone \[$3\]: $why"#    note "could not clone [$3]"#'

# A question nobody could deliver, and a run that says a human was asked anyway. The human answers
# where nothing was written, and waits for one that has nowhere to arrive.
wreck_runner "a stage that reports asking without asking is caught" \
  silentask 's#        ask_about_each "$run_dir" "$introduced" || exit 1#        ask_about_each "$run_dir" "$introduced"#'

#
# The authorisation join, and its three claims are three breaks: the stage asks, an answer that does
# not name the clause authorises nothing, and an unanswered clause still blocks.
#
# `anyword` is the one that matters. `receive` carries whatever a human wrote, "no" included, so a
# run that took any answer as approval would read a refusal as a yes.
#
wreck_runner "a stage that blocks without asking is caught" \
  silentblock 's#        ask_to_authorise "$1" "$text" || return 1#        :#'

wreck_runner "an answer that authorises without naming the clause is caught" \
  anyword 's#        \*"$(clause_id "$2")"\*) return 0 ;;#        *) return 0 ;;#'

wreck_runner "an unanswered clause that authorises anyway is caught" \
  nowordneeded 's#    said=$(source_says receive "$(item_id "$1")" "$(question_id "$1" authorisation "$2")" 2>/dev/null) || return 1#    return 0#'

# The item proposes and the allowlist decides. A run that took an advised target as authorised would
# let anyone who can file an item choose what the run may touch.
wreck_runner "an advised target that skips the allowlist is caught" \
  advised 's#        add_target "$1" "$2" "$repo" "$(bootstrap_ref "$1")"#        printf "%s %s\n" "$repo" "$(bootstrap_ref "$1")" >> "$2"#'

#
# Standing authority, and the break is the surface it opens. Practice lives in the target, a worker
# owns the checkout, and a run reading the working tree would let a worker grant itself anything.
#
wreck_runner "a practice read from the worker's tree is caught" \
  livepractice 's#    base=$(bootstrap_base "$2") || return 1#    base=HEAD#'

# A practice nobody could read, reported as one granting nothing. The human grants what they already
# granted, it works, and the base stays broken.
wreck_runner "a practice that could not be read passing for an empty one is caught" \
  mutepractice 's#        note "could not read the practice at \[$1\]: $why"#        :#'

# One repository twice. `ungradable_targets` counts selected targets, so a duplicate is one
# repository reported twice and every clause graded against it twice.
wreck_runner "a repository selected twice is caught" \
  twiceover 's#    refuse_selected_twice "$file" "$identity"#    :#'

# Silence read as success. Derive found nothing, said nothing, and the refusal arrived two stages
# later about a file the reader thought was fine.
wreck_runner "a derive that says nothing is caught" \
  mutederive 's#    say_what_derived "$file"#    :#'

# One yes outranking a no. While every record was an exit code this was invisible: one tree gives one
# answer. A human answering makes a second, contradicting record possible.
wreck_runner "a yes that outranks a no is caught" \
  onlyyes 's#END { exit !(yes && !no) }#END { exit !yes }#'

# A shell standing in a run that cannot name it. Joining needed no new noun, only this lookup, and
# without it a workspace handed to a second person answers nothing.
wreck_runner "a run that cannot be found from inside it is caught" \
  nofeet 's#^    enclosing_run$#    return 1#'

# Both halves of `send_delivery` answer 19 now. Sharing 1 with `ask` put a rejected delivery and a
# run that was never made behind one code.
wreck_runner "a delivery refusal wearing another verb's code is caught" \
  onecode 's#    exit "$3"#    exit 1#'


# A run that never ran its gate handed over a pass for it and reached complete = 0.
wreck_runner "a pass handed over for a pinned gate is caught" \
  handedover 's#^    refuse_a_pinned_name.*#    :#'

# A run that rewrote the script its gate names recorded a pass and reached deliverable.
wreck_runner "a gate the run rewrote itself is caught" \
  basegate 's#^    enter_base_gates.*#    :#'

# A run whose delivery moved after it was graded landed a tree nothing answered for.
wreck_runner "a merge that lands a moved head is caught" \
  movedhead 's#^    refuse_a_moved_head.*#    :#'

# A gate a signal killed was stamped as one that failed, and append-only made that permanent.
wreck_runner "a gate killed by a signal recorded as failed is caught" \
  killedgate 's#^was_killed() .*#was_killed() { false; }#'

# A bare word recorded as an observation could only be read by its position, and every event would
# then owe the same positions.
wreck_runner "an observation field with no name is caught" \
  unnamedfield 's#^        case $pair in .*#        continue#'

# A host replaced while a run held a workspace lost work nobody recorded.
wreck_runner "a host called settled while a run holds a workspace is caught" \
  notsettled 's#\$1 == "open" || \$1 == "graded"#0#'

# A run rewrote a file its gate runs and no command names. Nothing covered it.
wreck_runner "a gate reaching a second file is caught" \
  reaches 's#^        \[ "$grown".*#        break#'

# Provenance is the whole of what tells a commit the run made
# from one it did not. Each removes one half of it.
wreck_runner "a foreign commit waved through is caught" \
  mutestranger 's#^refuse_foreign_ancestry() {#refuse_foreign_ancestry() { return 0;#'

wreck_runner "a base nobody recorded is caught" \
  nobase 's#^record_base() {#record_base() { return 0;#'

wreck_runner "a commit the operation did not record is caught" \
  nomade 's#^record_produced() {#record_produced() { git -C "$2" rev-parse HEAD; return 0;#'

wreck_runner "an override matching any commit is caught" \
  anyaccept 's#grep -q "\^\$sha " "\$said" 2>/dev/null \&\& continue#[ -s "$said" ] \&\& continue#'

#
# Three parts of one claim, and any one missing leaves the gap #332 named.
#
# Without the reader nothing derives. Without the judge nothing says who to ask. Without the kind a
# gate could answer a judgement.
wreck_runner "a declared judgement nothing derives is caught" \
  nojudged 's#^    detect_judged | while_reading_judged#    false | while_reading_judged#'

wreck_runner "a judged clause naming no judge is caught" \
  nojudge 's#^        print_judges "\$id" "\$judge" >> "\$draft" || return 1$#        : >> "$draft" || return 1#'

wreck_runner "a judgement derived as a gate is caught" \
  judgedasgate 's#print_clause "\$id" Judged "\$text"#print_clause "$id" Gate "$text"#'

#
# A panel is several minds, and unanimous. Each break takes one half of that.
#
# `onejudge` keeps the list whole, so a panel of two becomes one member nobody is called. `anyjudge`
# lets one approval stand for all of them, which is a majority of one.
wreck_runner "a panel kept whole instead of split is caught" \
  onejudge 's#^print_judges() {#print_judges() { printf "judge %s %s\n" "$1" "$2"; return 0;#'

wreck_runner "one approval standing for the whole panel is caught" \
  anyjudge 's#satisfied "\$1" "\$2" "\$3" judged "\$who" || exit 1#satisfied "$1" "$2" "$3" judged "$who" \&\& exit 0#'

#
# A verdict answers for one commit and one bar. Each break unbinds it from one of them.
#
# `staleref` lets an answer about an older commit be credited to whatever the workspace is on now.
# `nohandoff` takes a verdict from a judge nothing records being handed anything.
wreck_runner "a verdict credited to a commit nobody read is caught" \
  staleref 's#^    refuse_a_revision_nobody_reviewed "\$reviewed"$#    :#'

wreck_runner "a verdict from a judge nobody handed the bar is caught" \
  nohandoff 's#^    refuse_a_judge_never_handed_the_bar "\$dir" "\$text" "\$judge" "\$reviewed" "\$version"$#    :#'

# The reader half. The writer half cannot be observed today: the only comment
# floor writes is a question, and `floor-question:` already bounds one.
wreck_runner "a reader blind to the stamp is caught" \
  blindstamp 's#held\[i\] ~ /\^floor-\[a-z\]+: /#held[i] ~ /^never-matches-this: /#' lib/source-github.sh

# The seam adds the reference. Stop dropping the one a brief wrote and the
# pull request names its item twice.
wreck_runner "a brief's own reference kept alongside the seam's is caught" \
  twicenamed 's#\$0 ~ "\^(Closes\|Refs) #\$0 ~ "^(NeverCloses|NeverRefs) #' lib/source-github.sh

# A range is only about this run's work while the base is still behind the head. Ask the
# question about the base twice and it answers yes for a branch built from anywhere.
wreck_runner "a base that is not behind the head is caught" \
  noancestor 's#merge-base --is-ancestor "\$base" "\$head"#merge-base --is-ancestor "$base" "$base"#'

# The fault this refusal exists for, put back: a workspace already here, and its head named
# as the place it started.
wreck_runner "a head adopted as the base it never was is caught" \
  adoptbase 's#^refuse_unrecorded_base() {#refuse_unrecorded_base() { record_base "$1" "$2" "$1/$(target_slot "$2")"; return 0;#'

# The producer signing off its own bar.
wreck_runner "a worker accounting for its own ancestry is caught" \
  selfaccept 's#^refuse_self_accounting() {#refuse_self_accounting() { return 0;#'

report_breaks

# --- break the install ---

echo
echo "audit — break the install, the install suite must notice"

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "${tmp:?}/$1" && cp -R "$root" "$tmp/$1"; }

# Determine if the install suite fails against the broken copy.
caught() { suite_caught "$tmp/$1" "$root/tests/install.sh"; }

# Break one thing about the install and require the suite to notice.
wreck() {
  local name="$1" tag="$2" break_it="$3"

  copy "$tag"             || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }

  # Three answers, read as three. `caught` returns 2 for a mutant that never answered, and
  # `||` read that as *the suite passed against a broken install* — the right red for the
  # wrong reason, which is a quieter lie than the false green it replaced.
  caught "$tag"; local answer=$?
  [ "$answer" -eq 2 ] && { moot "$name — killed at ${deadline}s, and a clean pass took ${clean}s"; return; }
  [ "$answer" -eq 0 ] || { bad "$name — the suite passed against a broken install"; return; }

  kept "$name"
}

# Determine if this filesystem records an executable bit. Windows does not, and removing a bit that
# was never there mutates nothing.
records_exec() {
  probe="$tmp/exec-probe"
  : > "$probe"
  chmod +x "$probe" 2>/dev/null
  [ -x "$probe" ] || return 1
  chmod -x "$probe" 2>/dev/null
  [ ! -x "$probe" ]
}

# Read a file and write it back, so a break can filter a file through itself.
rewrite() { cat > "$1.new" && mv "$1.new" "$1"; }

# The breaks. Every one is a failure kernel or signal actually shipped.
crlf()    { awk '{ printf "%s\r\n", $0 }' "$1/hooks/announce.sh" | rewrite "$1/hooks/announce.sh"; }
unquote() { sed 's/\\"//g' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bare()    { sed 's|"command": "sh |"command": "|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unshell() { grep -v '"shell"' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
rewire()  { sed 's|hooks/announce.sh|hooks/gone.sh|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unwire()  { grep -v 'preflight.sh' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unhook()  { chmod -x "$1/hooks/announce.sh"; }
mute()    { printf 'exit 0\n' > "$1/hooks/announce.sh"; }
misfire() { sed 's|"SessionStart"|"Stop"|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }

wreck "a hook checked out with CRLF is caught"         crlf   crlf
wreck "an unquoted plugin root is caught"              noquot unquote
wreck "a bare path with no interpreter is caught"      barep  bare
wreck "a hook that declares no shell is caught"        noshel unshell
wreck "hooks.json pointing at nothing is caught"       nofile rewire
wreck "a hook that ships but is never wired is caught" nowire unwire
wreck "an announce hook that says nothing is caught"   quiet  mute
wreck "a hook moved to an event that cannot inject is caught" event misfire

audit_the_executable_bit() {
  records_exec || {
    printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
    return
  }
  wreck "a hook that lost its executable bit is caught" nox unhook
}
audit_the_executable_bit

# Nothing is left queued. This file grows at its end, so a break added below the drain above would
# run with nobody waiting for it and nobody reading what it said — and a verdict nobody reads is the
# one thing this audit may never produce.
report_breaks


# The tally every check reports through. A break that empties a
# suite used to turn it green, and no audit could see it,
# because the audit reads the same exit code.
( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
  && bad "a suite that ran nothing passed" \
  || printf '  ok    a suite that ran nothing does not pass\n'

# A skip used to be amber. Two tests reused a fixture name, inherited the other's repository, and
# skipped on what they found — into a 700-line log, under a green tally, past a gate that said PASS.
( . "$root/tests/lib.sh"; ok x; skip y; summary 'a suite that skipped' ) >/dev/null 2>&1 \
  && bad "a suite that skipped a check passed" \
  || printf '  ok    a suite that skipped a check does not pass\n'

# And the other half of that split: NTFS records no executable bit, so one check here is
# unanswerable and answerable in the container. Failing on it would make the suite unrunnable on the
# machine it is written on.
( . "$root/tests/lib.sh"; ok x; cannot y; summary 'a suite that could not answer' ) >/dev/null 2>&1 \
  && printf '  ok    a check this platform cannot answer does not fail it\n' \
  || bad "a check this platform cannot answer failed the suite"
echo

# --- break the join, the host suite must notice ---

echo
echo "audit — break the join, the host suite must notice"

# The same shape as the install audit above, reading the other suite.
hosted() { suite_caught "$tmp/$1" "$root/tests/host.sh"; }

wreck_join() {
  local name="$1" tag="$2" mutation="$3"

  copy "$tag" || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  sed "$mutation" "$root/bin/join.sh" | rewrite "$tmp/$tag/bin/join.sh"
  cmp -s "$tmp/$tag/bin/join.sh" "$root/bin/join.sh" \
    && { moot "$name — the break did not apply, so this proves nothing"; return; }
  hosted "$tag"; local answer=$?
  [ "$answer" -eq 2 ] && { moot "$name — killed at ${deadline}s, and a clean pass took ${clean}s"; return; }
  [ "$answer" -eq 0 ] || { bad "$name — the suite passed against a broken join"; return; }

  kept "$name"
}

# Each of the three that used to be silent, made silent again one at a time.
wreck_join "a host with no git author waved through is caught" \
  noauthor 's#^    refuse_without_an_author$#    :#'

wreck_join "a host with no authority waved through is caught" \
  noauthority 's#^    refuse_without_an_authority$#    :#'

wreck_join "a repository that is not there waved through is caught" \
  norepo 's#^    refuse_without_a_repository$#    :#'

# The silent one this command exists for. Saying nothing about the source is what it replaced.
wreck_join "a source that is chosen without a word is caught" \
  mutesource 's#^    report_work_source$#    say "who     $FOUNDRY_WHO"#'

# A count that reads comments and blank lines reports a repository authorising more than a human
# wrote — the shape of the number matters as much as its presence.
wreck_join "a grant count that counts comments is caught" \
  loudcount 's#grep -cv#grep -c#'

# The whole point of the section: a rule naming a skill nobody can invoke used to say nothing.
wreck_join "a skill the rules name that nobody reports is caught" \
  muteskills 's#^    report_skills_the_rules_name$#    :#'

wreck_join "a plugin that is off reported as reachable is caught" \
  allreachable 's#^    grep -q "\\"\$1@" "\$settings" \&\& return$#    return#'

# Unknown is not absence. Reporting a missing settings file as a missing plugin sends the reader to
# install something they already have.
wreck_join "a settings file it cannot read called a missing plugin is caught" \
  blindsettings 's#^    \[ -r "\$settings" \] || { printf .  — cannot tell, no %s. "\$settings"; return; }$#    [ -r "$settings" ] || return#'

[ "$failed" -eq 0 ] && echo "ALL GREEN"
[ "$failed" -eq 1 ] && echo "FAILURES ABOVE"
[ "$failed" -eq 3 ] && printf 'PROVED NOTHING — %s experiments never ran\n' "$never_ran"
exit $failed
