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

wreck_runner "a runner that stops checking for a free path is caught" \
  collide 's|\[ -e "$RUNS/$candidate" \] |\[ 1 -eq 0 \] |'

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
