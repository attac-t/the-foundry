#!/bin/bash
# Plants each fault `bin/rulefiles.sh` exists for in a copy, and reads its exit code and its words.
#
# A copy holds the gate, its reader, and floor's shipped `bin`, `lib`, `hooks` and `adapters`. Each
# case changes one of them, so a pass proves the gate saw that change and nothing else. #1184.

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/rulefiles-$$"
trap 'rm -rf "$tmp"' EXIT
passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

# A fresh copy: the gate, the reader, and floor's four shipped directories, tests and all.
a_lab() {
  local part
  rm -rf "$tmp/lab" && mkdir -p "$tmp/lab/bin" "$tmp/lab/plugins/floor" || return 1
  cp "$root/bin/rulefiles.sh" "$root/bin/rulefiles.awk" "$tmp/lab/bin/" || return 1
  for part in bin lib hooks adapters; do
    cp -R "$root/plugins/floor/$part" "$tmp/lab/plugins/floor/" || return 1
  done
}

# Run the copy's gate, and say its exit code and what it printed.
gate() { said=$(sh "$tmp/lab/bin/rulefiles.sh" 2>&1); code=$?; }

expect() { # <name> <exit> [<words the gate must say>]
  [ "$code" -eq "$2" ] || { bad "$1 — exited $code, not $2"; return; }
  [ -z "${3:-}" ] || printf '%s\n' "$said" | grep -qF -- "$3" || { bad "$1 — never said [$3]"; return; }
  ok "$1"
}

# One plant, into a fresh copy, then the gate.
planted() { a_lab || { bad "no lab could be made"; return 1; }; ( cd "$tmp/lab" && eval "$1" ); gate; }

lib=plugins/floor/lib/source.sh
runner=plugins/floor/bin/run.sh
reads_bench='bench_in() { cat "$1/.foundry/bench"; }'

# --- the shipped tree ---

planted ':'
expect "floor as shipped passes" 0 "PASS"

# --- a fourth file, named where floor reads it ---

planted "printf '%s\n' '$reads_bench' >> $lib"
expect "a read in lib names a file deliver does not refuse" 1 "\`.foundry/bench\`, which deliver does not refuse"

planted "printf '%s\n' 'cat \"\$root/.foundry/bench\"' >> plugins/floor/hooks/drift.sh"
expect "and one in hooks" 1 "plugins/floor/hooks/drift.sh"

planted "printf '%s\n' '$reads_bench' >> plugins/floor/adapters/codex/run.sh"
expect "and one in an adapter" 1 "plugins/floor/adapters/codex/run.sh"

planted "printf '%s\n' '{ print \".foundry/bench\" }' >> plugins/floor/lib/contribution.awk"
expect "and one in an awk file, whatever the extension" 1 "plugins/floor/lib/contribution.awk"

planted "mkdir -p plugins/floor/adapters/codex/tests && printf '%s\n' '$reads_bench' >> plugins/floor/adapters/codex/tests/probe.sh"
expect "but never one under tests" 0 "PASS"

# --- the refusal ---

planted "sed -i 's| \.foundry/judged 2>| 2>|' $runner"
expect "a refusal that lost a file floor still names" 1 "\`.foundry/judged\`, which deliver does not refuse"

planted "sed -i 's| \.foundry/judged 2>| .foundry/judged .foundry/extra 2>|' $runner"
expect "a file only the refusal names fails safe" 0 "that floor names: extra gates judged practice"

# --- what a comment is ---

planted "printf '%s\n' '# .foundry/bench is read nowhere' >> $lib"
expect "a line opening on a hash names nothing" 0 "PASS"

planted "printf '%s\n' 'true  # .foundry/bench is read nowhere' >> $lib"
expect "a comment after code sits on a code line, and names" 1 "\`.foundry/bench\`, which deliver does not refuse"

planted "sed -i '/^rules_changed_between() {/a # .foundry/bench is refused where it is read' $runner && printf '%s\n' '$reads_bench' >> $lib"
expect "a comment inside the refusal refuses nothing" 1 "\`.foundry/bench\`, which deliver does not refuse"

# --- a name, whole ---

planted "printf '%s\n' 'cat \"\$1/.foundry/gates2\"' >> $lib"
expect "a name is taken whole" 1 "\`.foundry/gates2\`, which deliver does not refuse"

planted "printf '%s\n' 'for kind in bench; do cat \"\$1/.foundry/\$kind\"; done' >> $lib"
expect "a path whose name is not spelled out" 1 "a \`.foundry/\` path whose name is not spelled out"

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
