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
model_caught() { ! RUNNER="$tmp/$1/bin/run.sh" bash "$root/tests/model.sh" >/dev/null 2>&1; }

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
# Two breaks on one line, and they are not the same break: this one blinds the slot chooser
# completely, `inherit` below blinds it only to grants. Same line, different halves of its meaning.
#
wreck_runner "a runner that stops checking for a free path is caught" \
  collide 's|\[ ! -e "$RUNS/$1" \] && \[ ! -e "$GRANTS/$1" \]|true|'

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
wreck_runner "a runner that ignores a home it cannot write to is caught" \
  blind 's# *|| die_unwritable "$dir/item.md"$##; s# *|| die_unwritable "$dir"$##'

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
  inherit 's|\[ ! -e "$RUNS/$1" \] && \[ ! -e "$GRANTS/$1" \]|[ ! -e "$RUNS/$1" ]|'

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

if records_exec; then
  wreck "a hook that lost its executable bit is caught" nox unhook
else
  printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
fi

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
