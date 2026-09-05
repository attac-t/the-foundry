#!/bin/bash
# What `bin/judge.sh` makes of what a harness hands back.
#
# Driven through a `codex` this suite writes, so every check is the real script reading a real
# answer. Mocking its readers would prove the parts and leave the join — and the join is where an
# adversary found four faults that no check had.
#
# **No network, ever.** A gate that needs one goes red on a train.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/nocodex"

# The harness honours `--output-last-message`, because the real one does. `ask` hands `codex` a path
# and reads the reply out of that file, never out of the JSON. A stub that skipped it would prove a
# reader nothing calls.
cat > "$tmp/bin/codex" <<'STUB'
#!/bin/sh
msg=
while [ $# -gt 0 ]; do
  if [ "$1" = "--output-last-message" ]; then msg=$2; shift 2; continue; fi
  shift
done
[ -n "$msg" ] && cat "$TMP/reply" > "$msg"
cat "$TMP/stream"
STUB
chmod +x "$tmp/bin/codex"

# `$1` is the JSON stream. `$2` is the reply the harness leaves in the message file.
a_codex_that_says() { printf '%s\n' "$1" > "$tmp/stream"; printf '%s\n' "$2" > "$tmp/reply"; }

# A run floor would have handed over: a brief to read, and a receipt already half filled.
handed() {
  mkdir -p "$tmp/$1"
  printf 'judge this\n'        > "$tmp/$1/brief"
  printf 'run  x\nclause  y\n' > "$tmp/$1/r.receipt"
  printf '%s' "$tmp/$1"
}

judged() {
  ( cd "$1" && PATH="$tmp/bin:$PATH" TMP="$tmp" FOUNDRY_BRIEF="$1/brief" \
    FOUNDRY_RECEIPT="$1/r.receipt" sh "$root/bin/judge.sh" >/dev/null 2>&1 )
}

# --- what floor must have handed over ---

d=$(handed nobrief)
is "a run with no brief is refused" \
   "$( ( cd "$d" && FOUNDRY_RECEIPT="$d/r.receipt" sh "$root/bin/judge.sh" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

d=$(handed noreceipt)
is "a run with no receipt is refused" \
   "$( ( cd "$d" && FOUNDRY_BRIEF="$d/brief" sh "$root/bin/judge.sh" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

# --- the harness is not here ---
#
# The one the owner asked for by name. **No fallback, and nothing else asked.**
#
# A PATH holding a shell and no `codex`. `/nonexistent` alone takes `sh` with it, and the check would
# then prove the suite broke rather than the script refusing.

d=$(handed gone)
bare="$tmp/nocodex:/usr/bin:/bin"

# **Look before calling.** That PATH keeps a shell, and a `codex` installed under `/usr` is still
# on it — `npm i -g` with a `/usr` prefix puts one there. `reachable` would find it and the gate
# would call a vendor, which is the one thing this file says it never does.
if PATH="$bare" command -v codex >/dev/null 2>&1; then
  bad "the absence check cannot run — codex is on the bare PATH"
  out=""
else
  out=$( ( cd "$d" && PATH="$bare" FOUNDRY_BRIEF="$d/brief" FOUNDRY_RECEIPT="$d/r.receipt" sh "$root/bin/judge.sh" 2>&1 ) )
fi
has "a harness that is not here says so" "$out" "not on this host"
has "and records it unavailable"         "$(cat "$d/r.receipt")" "unavailable"
hasnt "and asks nothing else"            "$(cat "$d/r.receipt")" "context"

# --- what it makes of what came back ---

a_codex_that_says '{"type":"thread.started","thread_id":"01a0-beef"}' 'looks fine
VERDICT: approve'
d=$(handed yes); judged "$d"
has   "a verdict on the last line is taken"    "$(cat "$d/r.receipt")" "approve"
has   "and the thread it opened is recorded"   "$(cat "$d/r.receipt")" "01a0-beef"
is    "the thread is the handle and nothing else" "$(awk '$1 == "context" { print $2 }' "$d/r.receipt")" "01a0-beef"

# A verdict that is not the last word is not the answer. It was taken from anywhere before.
a_codex_that_says '{"type":"thread.started","thread_id":"01a0-cafe"}' 'VERDICT: approve
actually, no'
d=$(handed buried); judged "$d"
hasnt "a verdict that is not the last word is not taken" "$(cat "$d/r.receipt")" "approve"

# A stream that opened no thread claims none. `fresh` about nothing is a claim about nothing.
a_codex_that_says '{"type":"turn.started"}' 'VERDICT: reject'
d=$(handed nothread); judged "$d"
has   "a verdict still lands with no thread"           "$(cat "$d/r.receipt")" "reject"
hasnt "and a stream that opened none claims no context" "$(cat "$d/r.receipt")" "context"

# A suite that ran nothing passes everything. The checks above are top-level, so this is unreachable
# today - and it is what makes that a fact rather than an assumption.
[ $((passed + failed)) -gt 0 ] || { printf '  FAIL  no check ran
'; failed=1; }

printf '\njudge — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
