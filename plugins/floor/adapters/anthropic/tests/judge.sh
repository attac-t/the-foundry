#!/bin/bash
# What this adapter makes of what a harness hands back.
#
# Driven through a `claude` this suite writes, so every check is the real script reading a real
# answer. Mocking its readers would prove the parts and leave the join.
#
# **No network, ever.** A gate that needs one goes red on a train.
#
# **This harness hands its reply back on stdout**, where the other one writes it to a file it was
# given. So the stub differs from codex's, and so does what is checked: the adapter chooses the
# session, so the stub keeps its arguments and the receipt's handle is read against them.

set -u
adapter="$(cd "$(dirname "$0")/.." && pwd)/run.sh"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s' "$1"; printf '\n'; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s' "$1"; printf '\n'; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "anthropic"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/noclaude"

# It reads the prompt and prints what it was told to say, and keeps the arguments it was handed.
# `$TMP/stderr` is what a case wants on stderr — a line shaped like a command, for one of them.
cat > "$tmp/bin/claude" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$TMP/argv"
cat > /dev/null
[ -f "$TMP/stderr" ] && cat "$TMP/stderr" >&2
cat "$TMP/reply"
STUB
chmod +x "$tmp/bin/claude"

# The session the adapter handed the harness, read from the harness's own arguments.
session_handed() { awk 'prev == "--session-id" { print; exit } { prev = $0 }' "$tmp/argv" 2>/dev/null; }

# **Silence is an empty file, not an empty line.** A reply of one newline is a harness that spoke
# and named nothing, which the adapter treats differently and should.
a_claude_that_says() {
  : > "$tmp/reply"
  [ -n "$1" ] || return 0
  printf '%s\n' "$1" > "$tmp/reply"
}

# A run floor would have handed over: a brief to read, and a receipt already half filled.
handed() {
  mkdir -p "$tmp/$1"
  printf 'judge this' > "$tmp/$1/brief"; printf '\n' >> "$tmp/$1/brief"
  printf 'run  x' > "$tmp/$1/r.receipt"; printf '\n' >> "$tmp/$1/r.receipt"
  printf '%s' "$tmp/$1"
}

judged() {
  ( cd "$1" && PATH="$tmp/bin:$PATH" TMP="$tmp" FOUNDRY_BRIEF="$1/brief"     FOUNDRY_RECEIPT="$1/r.receipt" sh "$adapter" >/dev/null 2>&1 )
}

# --- what floor must have handed over ---
#
# **Absent is said, never left unsaid.** Omitting one of these let the subshell inherit it, and a
# judge running the gate suite exports both. So this case ran the real harness against a fixture
# brief and appended a verdict to a live receipt — one that had already been answered.
#
# It cost a panel on 12 September: one receipt carried two verdicts, the second from nobody.

d=$(handed nobrief)
is "a run with no brief is refused"    "$( ( cd "$d" && FOUNDRY_BRIEF= FOUNDRY_RECEIPT="$d/r.receipt" sh "$adapter" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

is "and a run with no receipt is refused"    "$( ( cd "$d" && FOUNDRY_BRIEF="$d/brief" FOUNDRY_RECEIPT= sh "$adapter" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

# --- the same two, with a live receipt in the environment ---
#
# **This is the case that would have caught it.** The overrides above are green on any machine that
# sets neither variable, so removing one would go red nowhere. Here the bait is exported first, which
# is what floor does when it runs a judge.
#
# A guard that is gone lets the adapter inherit the bait, find a real harness on PATH, and write.

bait=$tmp/bait.receipt
printf 'run bait
role nobody
' > "$bait"
was=$(cksum < "$bait")

d=$(handed baited)
(
  # **The stub, never the live PATH.** This file's header says it reaches no network, and a guard
  # that regressed here would call the real harness to prove it. The stub writes the same receipt,
  # so the bait still moves and the check still goes red.
  cd "$d" && export PATH="$tmp/bin:$PATH" TMP="$tmp"
  export FOUNDRY_RECEIPT="$bait" FOUNDRY_BRIEF="$d/brief"
  FOUNDRY_BRIEF= sh "$adapter" >/dev/null 2>&1
  FOUNDRY_BRIEF="$d/brief" FOUNDRY_RECEIPT= sh "$adapter" >/dev/null 2>&1
)

is "a receipt the environment names is not written to" "$(cksum < "$bait")" "$was"
is "and nothing is written beside it" "$(ls "$tmp" | grep -c '^bait\.')" "1"

# --- the harness is not here ---
#
# **Look before calling.** That PATH keeps a shell, and a `claude` under `/usr` is still on it.

bare="$tmp/noclaude:/usr/bin:/bin"

if PATH="$bare" command -v claude >/dev/null 2>&1; then
  bad "the absence check cannot run — claude is on the bare PATH"
else
  d=$(handed gone)
  ( cd "$d" && PATH="$bare" FOUNDRY_BRIEF="$d/brief" FOUNDRY_RECEIPT="$d/r.receipt"     sh "$adapter" >/dev/null 2>&1 )

  has "a harness that is not here is unavailable" "$(cat "$d/r.receipt")" "verdict unavailable"
  hasnt "and no verdict is invented for it"       "$(cat "$d/r.receipt")" "verdict approve"
  hasnt "and no command count either"             "$(cat "$d/r.receipt")" "commands "
  hasnt "and no session, because none was asked"  "$(cat "$d/r.receipt")" "context "
fi

# --- what came back ---

a_claude_that_says 'looks fine
VERDICT: approve'
d=$(handed clean); judged "$d"

has "a verdict on the last line is read"    "$(cat "$d/r.receipt")" "verdict approve"
has "and the adapter names itself"          "$(cat "$d/r.receipt")" "adapter anthropic"
has "and what was asked for, as asked for"  "$(cat "$d/r.receipt")" "requested_model opus"

# **This harness has no effort control.** Writing `max` would be a claim about a thing that does not
# exist, so the receipt says what is true instead.
has "and the effort it has none of"         "$(cat "$d/r.receipt")" "requested_effort unset"

# Floor refuses the bare keys by name. What this watched is what it may write.
hasnt "and no bare model is claimed"        "$(cat "$d/r.receipt")" "
model "
hasnt "and no provider is claimed"          "$(cat "$d/r.receipt")" "provider "

# **The session is the adapter's to choose, so the receipt names it** — the one the harness was
# handed, read from its own arguments rather than from anything the adapter says about itself. #993.
has "a round names the session it opened"   "$(cat "$d/r.receipt")" "context $(session_handed)"
has "and says it was a new one"             "$(cat "$d/r.receipt")" "fresh yes"

case $(session_handed) in
  ????????-????-4???-[89ab]???-????????????) ok  "and the session is a version-4 uuid" ;;
  *)                                          bad "and the session is a version-4 uuid — got [$(session_handed)]" ;;
esac

# **No command count, ever.** Text mode keeps no stream, and a line shaped like a command on stderr
# once read as one: every receipt said `commands 0`, a round refused two shells included. #993.
printf '{"type":"tool_use","input":{"command":"ls"}}\n' > "$tmp/stderr"
d=$(handed counted); judged "$d"
rm -f "$tmp/stderr"

hasnt "a command on stderr is never counted"   "$(cat "$d/r.receipt")" "commands "

# --- a verdict that is not the last word ---
#
# A reply quoting the instruction, or changing its mind, has not chosen. Reading a match anywhere
# would take whichever came last by accident.

a_claude_that_says 'VERDICT: approve
and on reflection I am not sure'
d=$(handed late); judged "$d"

hasnt "a verdict that is not last is not read" "$(cat "$d/r.receipt")" "verdict approve"

a_claude_that_says 'nothing to say here'
d=$(handed none); judged "$d"

hasnt "and a reply naming none claims none"    "$(cat "$d/r.receipt")" "verdict "

# --- silence ---

a_claude_that_says ''
d=$(handed quiet); judged "$d"

has "a harness that said nothing is unavailable" "$(cat "$d/r.receipt")" "verdict unavailable"
hasnt "and it names no session it cannot vouch for" "$(cat "$d/r.receipt")" "context "

printf '
anthropic — %d passed, %d failed
' "$passed" "$failed"
[ "$failed" -eq 0 ]
