#!/bin/bash
#
# Run every suite, then check the suites can fail.
#
# The second half is the part that matters. A green suite proves nothing until you have watched it
# go red, so we break the plugin one rule at a time and each break must take a suite down with it.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/floor-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0

# Record a failing audit.
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

for suite in model install; do
  bash "$root/tests/$suite.sh" || failed=1
  echo
done

# --- break the runner ---

echo "audit — break the runner, the model suite must notice"

# Determine if the model suite fails against a broken runner.
#
# Bounded where `timeout` exists. A break can hang rather than answer wrongly — one removes the only
# refusal from a counting loop — and an unbounded audit stops on those instead of reporting them. A
# stopped audit reads as a slow one.
model_caught() {
  local broken="$tmp/$1/bin/run.sh"

  command -v timeout >/dev/null 2>&1 \
    && { ! RUNNER="$broken" timeout 300 bash "$root/tests/model.sh" >/dev/null 2>&1; return; }

  ! RUNNER="$broken" bash "$root/tests/model.sh" >/dev/null 2>&1
}

#
# Break one rule in the runner and require the model suite to notice.
#
# Three ways a mutant proves nothing, all seen for real in this repo: sed fails, the output comes
# out empty, or the pattern never matched. `cmp` alone catches only the third — an empty file
# differs from the original too.
#
wreck_runner() {
  local name="$1" tag="$2" mutation="$3"

  rm -rf "${tmp:?}/$tag" && cp -R "$root" "$tmp/$tag" || { bad "$name — could not copy the plugin"; return; }
  sed "$mutation" "$root/bin/run.sh" > "$tmp/$tag/bin/run.sh" || { bad "$name — sed failed, so this proves nothing"; return; }
  [ -s "$tmp/$tag/bin/run.sh" ] || { bad "$name — the mutant is empty, so the suite failed for the wrong reason"; return; }
  cmp -s "$tmp/$tag/bin/run.sh" "$root/bin/run.sh" && { bad "$name — the break did not apply, so this proves nothing"; return; }
  model_caught "$tag" || { bad "$name — the suite passed against a broken runner"; return; }

  printf '  ok    %s\n' "$name"
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
  blind 's# *|| die_unwritable "$dir/item.md"$##; s# *|| die_unwritable "$dir"$##; s# *|| die_unwritable "$RUNS"$##; s# *|| die_unwritable "$1/id"##; s# *|| die_unwritable "$(authority_file "$1")"$##; s# *|| die_unwritable "$1/bootstrap"$##'

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
# The freeze. Three breaks, because it makes three separate promises: the set is written down, a
# moved set is refused, and the record holds the lines.
#
# `unfrozen` is aimed at the write. Blinding the comparison alone leaves a suite that would still
# pass if nothing were ever recorded — the comparison has nothing to disagree with.
#
wreck_runner "a selected set that is never written down is caught" \
  unfrozen 's|    freeze_selection "$run_dir" "$selection_path"|    :|'

wreck_runner "a selection that moved and authorises anyway is caught" \
  drifted 's|\[ "$(normalised_selection "$2")" = "$(cat "$frozen")" \] && return 0|return 0|'

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
  ownbar 's|    introduced=$(introduced_clauses "$charter_path")|    introduced=|'

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
  global 's|printf .%s/%s/targets. "$GRANTS" "$(basename "$1")"|printf "%s/targets" "$GRANTS"|'

# A newline turns `grep -Fxq` into a pattern list, so one grant matches a second repo and the append
# writes both. The whole exploit is one unguarded argument.
wreck_runner "an identity that may hold a newline is caught" \
  smuggle 's|\*\[!-A-Za-z0-9_.:/@~+%\]\* \| \*/../\* \| \*/..)|no-such-shape)|'

# Grants outlive the run directory, so a slot chooser that reads only `runs/` inherits an allowlist.
# The half `collide` cannot tell you about.
wreck_runner "a slot reclaimed with grants behind it is caught" \
  inherit 's#slot_is_reserved() { \[ -e "$GRANTS/$1" \]; }#slot_is_reserved() { false; }#'

# The bootstrap is an effective grant. Copied, it becomes a second place the truth lives.
wreck_runner "a bootstrap copied into the grants is caught" \
  copyboot 's|is_authorised "$dir" "$identity" && return 0|is_authorised "$dir" "$identity" \&\& [ 1 -eq 0 ] \&\& return 0|'

# A bootstrap file naming nothing must read as no bootstrap, or `policy` lists a nameless entry.
wreck_runner "a bootstrap that names nothing is caught" \
  blankboot 's|NR == 1 && $1 != "" { printf "%s", $1; found = 1 } END { exit !found }|NR == 1 { printf "%s", $1; exit }|'

# Policy state is read by eye and outlives the run. A password stored here is a password on disk.
wreck_runner "a grant that stores credentials is caught" \
  grantcreds 's|printf .%s\\n. "$identity" >> "$grants"|printf "%s\\n" "$repo" >> "$grants"|'

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

# The other half of that line. Without the guard the ref is empty rather than refused, so a repo with
# no commit records a gate against nothing — and `noref` cannot catch it, because it blanks the ref
# where a commit exists and this one only differs where none does.
wreck_runner "a record written before the first commit is caught" \
  unbornref 's#ref=$(delivered_ref) || { note "no commit to record evidence against"; exit 1; }#ref=$(delivered_ref)#'

# Grants are keyed by the run's id, so a renamed directory looks up a key nothing holds and `policy`
# answered exit 0 with the bootstrap alone. Authority a human gave, gone, without a word.
#
# Three call sites, and deliberately so: `policy`, `targets` and `authorise` each read the grants for
# authority, and the rule is that no reader softens it. It does not prove any one of the three alone
# is caught — `model.sh` asserts each separately for that.
wreck_runner "a renamed run that loses its grants in silence is caught" \
  renamed 's#    refuse_renamed_run "$dir"##; s#    refuse_renamed_run "$run_dir"##'

# The other direction. Failing open on a missing `id` is what lets a run made before this rule keep
# working, and closing it breaks every one of them at once — silently, because nothing asked.
wreck_runner "a guard that refuses a run made before it is caught" \
  nogrand 's#named=$(recorded_id "$1") || return 0#named=$(recorded_id "$1") || exit 13#'

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
  gatecwd 's#    cd "$(repo_root)" || { note "no checkout to run gates in"; exit 1; }##'

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
  staleref 's# \&\& $6 "" == ref ""##'

# `satisfying` evidence is a record whose answer is yes. A record that a gate failed is a record.
wreck_runner "a failing gate counted as satisfying its clause is caught" \
  anyresult 's#\&\& $5 == "0" \&\& $6 "" == ref ""#\&\& $6 "" == ref ""#'

# Quantified over clauses and over targets, so each empty set satisfies it for free. These two are
# the fail-opens, and neither is an edge case: every fresh run has an empty selection.
wreck_runner "an empty charter delivering vacuously is caught" \
  vacuousbar 's#        empty_bar "$dir"##'

wreck_runner "an empty selection delivering vacuously is caught" \
  vacuousselection 's#        empty_selection "$dir"##'

wreck_runner "a run nobody selected delivering anyway is caught" \
  unclaimed 's#        unauthorised_run "$dir"##'

# Quantified over every selected target, and one checkout answers for one. Without this the second
# is graded by nothing and the run delivers on evidence that never mentioned it.
wreck_runner "a second selected target graded by nothing is caught" \
  onetarget 's#        ungradable_targets "$dir"##'

# `targets` and `authorise` refuse a hand-edited selection. The grader read it, and every clause is
# graded against every selected target.
wreck_runner "a grader reading a selection nobody authorised is caught" \
  ungrated 's#    refuse_unselectable "$dir" "$(unit_targets_file "$dir")" || exit 5##'

# Three ways a clause is not met, and they take different remedies. Collapse the first into the
# second and an introduced clause reads as one belonging to another checkout — a reader sent looking
# for a workspace, where the answer is a human's.
wreck_runner "an introduced clause reported as another repository's is caught" \
  introducedaway 's#has_record "$file" pin "$id"#true#'

# The isolation itself. A worktree shares `.git` with the checkout it came from, so a worker could
# move the source's refs — and it leaves a `.git` file where a clone leaves a directory, which is
# what the check sees.
wreck_runner "a workspace sharing its git directory is caught" \
  sharedgit 's#git clone --quiet --no-hardlinks --branch "$4" "$2" "$1"#git -C "$2" worktree add --quiet -f "$1" "$4"#'

# A workspace is where mutation happens. Without this, a run nobody authorised gets a mutable
# checkout of a target nobody allowed it.
wreck_runner "a workspace opened for a run nobody authorised is caught" \
  freeworkspace 's#^    authorise$##'

# `slug` truncates at 40 characters, so two long identities name one directory — and here that is two
# targets in one checkout rather than an untidy name.
wreck_runner "a target directory named by a truncating slug is caught" \
  slugslot 's#target_slot "$2"#slug "$2"#'

# Idempotent, or `open` is not attach and a second session destroys the first one's work.
wreck_runner "a workspace cloned over on every open is caught" \
  reclone 's#    \[ -d "$slot/.git" \] && return 0##'

# The origin is where a branch pushed from here goes. Left as the path it was cloned from, delivery
# would land on this machine and nowhere else.
wreck_runner "a workspace keeping the path it was cloned from is caught" \
  localorigin 's#    git -C "$1" remote set-url origin "$3" 2>/dev/null##'

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

# --- break the install ---

echo
echo "audit — break the install, the install suite must notice"

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "${tmp:?}/$1" && cp -R "$root" "$tmp/$1"; }

# Determine if the install suite fails against the broken copy.
caught() { ! PLUGIN_ROOT="$tmp/$1" bash "$root/tests/install.sh" >/dev/null 2>&1; }

# Break one thing about the install and require the suite to notice.
wreck() {
  local name="$1" tag="$2" break_it="$3"

  copy "$tag"             || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught "$tag"           || { bad "$name — the suite passed against a broken install"; return; }

  printf '  ok    %s\n' "$name"
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

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
