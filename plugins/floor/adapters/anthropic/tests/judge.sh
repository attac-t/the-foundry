#!/bin/bash
# What this adapter makes of what a harness hands back.
#
# Driven through a `claude` this suite writes, so every check is the real script reading a real
# answer. Mocking its readers would prove the parts and leave the join.
#
# **No network, ever.** A gate that needs one goes red on a train.
#
# **This harness hands its reply back on stdout**, where the other one writes it to a file it was
# given. So the stub differs from codex's, and so does what is checked: there is no handle here, and
# two receipt keys are absent because nothing opened a thread.

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

# It reads the prompt and prints what it was told to say. Nothing else: a reply on stdout is the
# whole of this harness's contract, and a stub doing more would prove a reader nothing calls.
cat > "$tmp/bin/claude" <<'STUB'
#!/bin/sh
cat > /dev/null
cat "$TMP/reply"
STUB
chmod +x "$tmp/bin/claude"

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

d=$(handed nobrief)
is "a run with no brief is refused"    "$( ( cd "$d" && FOUNDRY_RECEIPT="$d/r.receipt" sh "$adapter" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

is "and a run with no receipt is refused"    "$( ( cd "$d" && FOUNDRY_BRIEF="$d/brief" sh "$adapter" >/dev/null 2>&1 ); printf '%s' "$?")" "2"

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

# **Two keys the other adapter carries and this one cannot.** Nothing opened a thread, so a receipt
# claiming one would be a claim about nothing.
hasnt "and no handle is claimed"            "$(cat "$d/r.receipt")" "context "
hasnt "and freshness is not claimed either" "$(cat "$d/r.receipt")" "fresh "

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

printf '
anthropic — %d passed, %d failed
' "$passed" "$failed"
[ "$failed" -eq 0 ]
