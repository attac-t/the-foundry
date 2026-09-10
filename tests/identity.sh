#!/bin/bash
# What `.claude/hooks/identity.sh` denies, and what it must not.
#
# The active forge account changed four times in one session, none announced. Three writes were
# refused by the other account's own permissions and one landed — a finding on a public thread
# under a name that did not write it.
#
# **The account is asked at the write, never remembered from session start.** Each of those four
# switches followed a clean check by under an hour, so anything cached is a check that already
# passed and no longer holds.
#
# Every case is a file on disk, for the same reason the seam's suite works that way: a tool call
# typed on this suite's command line would be read by the live hooks running it.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "identity"

tmp="${TMPDIR:-/tmp}/identity-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# One tool call, as the harness sends it. Written, never typed.
call() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$tmp/call.json"; }

# A stand-in for the forge, so this suite never asks the real one who is signed in. A test whose
# answer depends on the machine it runs on grades the machine.
stub_gh() {
  mkdir -p "$tmp/bin"
  printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "$1" > "$tmp/bin/gh"
  chmod +x "$tmp/bin/gh"
}

asked() { PATH="$tmp/bin:$PATH" sh "$root/.claude/hooks/identity.sh" < "$tmp/call.json" 2>&1; }

denies() { case $(asked) in *'"deny"'*) ok "$1" ;; *) bad "$1 — it was allowed" ;; esac; }
allows() { case $(asked) in *'"deny"'*) bad "$1 — it was denied" ;; *) ok "$1" ;; esac; }

# Spelled apart so this file does not trip a live hook reading its own command line.
verb() { printf 'gh %s %s' "$1" "$2"; }

# --- the account matches ---

stub_gh someone
export FOUNDRY_FORGE=someone

call "$(verb pr merge) 1 --merge"
allows "a merge under the expected account"

call "$(verb issue edit) 1 --add-label x"
allows "and an edit under it"

call "git push origin HEAD"
allows "and a push under it"

# --- the account does not ---

stub_gh somebody-else

call "$(verb pr merge) 1 --merge"
denies "a merge under another account"

call "$(verb issue edit) 1 --add-label x"
denies "and an edit under it"

call "git push origin HEAD"
denies "and a push under it"

# The remedy travels with the refusal. A guard naming no way out is worse than the silence it
# replaced, and `join.sh` learned that first.
case $(asked) in
  *'gh auth switch'*) ok "and the refusal names the way out" ;;
  *)                  bad "and the refusal names the way out — it did not" ;;
esac

case $(asked) in
  *somebody-else*) ok "and says which account is signed in" ;;
  *)               bad "and says which account is signed in — it did not" ;;
esac

# --- what it must not touch ---

# A guard that stops reading is one people turn off. Nothing here changes anything on the forge.
call "$(verb pr view) 1"
allows "a read is left alone"

call "$(verb issue list) --state open"
allows "and a listing"

call "git status --short"
allows "and a command that is not a write"

# --- where it cannot answer ---

# Unset and no remote is a repository this cannot have an opinion about. Denying there would stop
# every write in every checkout that is not this one.
unset FOUNDRY_FORGE
mkdir -p "$tmp/nowhere"
call "$(verb pr merge) 1 --merge"
case $( cd "$tmp/nowhere" && PATH="$tmp/bin:$PATH" sh "$root/.claude/hooks/identity.sh" < "$tmp/call.json" 2>&1 ) in
  *'"deny"'*) bad "outside a repository it says nothing — it denied" ;;
  *)          ok  "outside a repository it says nothing" ;;
esac

# A forge that cannot answer is not a forge answering wrongly. The guard stands down rather than
# guessing, because guessing here refuses work that was fine.
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/gh"
chmod +x "$tmp/bin/gh"
export FOUNDRY_FORGE=someone
call "$(verb pr merge) 1 --merge"
allows "a forge that cannot say who is signed in stands down"

printf '\nidentity — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
