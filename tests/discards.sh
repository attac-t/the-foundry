#!/bin/bash
# What `.claude/hooks/discards.sh` refuses before a restore, and what it lets through.
#
# **`git checkout --` restores to `HEAD`, never to the edit before yours.** A worker plants a break
# to prove a check goes red, restores, and the repair it was testing goes too.
#
# It happened twice on 20 September 2026, hours apart, in one session. The second time a widened
# guard and four new cases went with the break, and the function name grepped back as `0`.
#
# Every call is a file on disk. One typed on this suite's command line would be read by the live
# hooks running it.
#
# The repository is real and made here, because the hook asks `git diff HEAD` and `git stash list`.
# Nothing below touches the tree this suite lives in.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "discards"

tmp="${TMPDIR:-/tmp}/discards-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

hook="$root/.claude/hooks/discards.sh"

call() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$tmp/call.json"; }

# The hook asks git about the directory it runs in, so every case runs inside the fixture.
said() { ( cd "$repo" && sh "$hook" < "$tmp/call.json" 2>&1 ); }

#
# A repository with one committed file and one identity, because `git` refuses a commit without an
# author and a fixture has no checkout behind it. `identity.md` names this as its only exception.
repo="$tmp/r"
mkdir -p "$repo"
git -C "$repo" init -q 2>/dev/null || { echo "  n/a   git could not make a repository here"; exit 0; }
git -C "$repo" config user.name  'A Fixture'
git -C "$repo" config user.email 'fixture@example.invalid'

printf 'one\n' > "$repo/kept.md"
printf 'one\n' > "$repo/other.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m 'first'

# --- work nothing holds ---

printf 'two\n' > "$repo/kept.md"
call 'git checkout -- kept.md'

out=$(said)

has "a restore over uncommitted work is denied" "$out" '"permissionDecision":"deny"'
has "and the file is named"                     "$out" 'kept.md'
has "and it says what checkout does"            "$out" 'restores to HEAD'
has "and it names the way out"                  "$out" 'Commit or stash first'

# --- the new spelling ---
#
# **Git ships two verbs for one act.** A worker reaching for either means the same thing, and a
# hook reading only the older one is a hook the newer spelling walks past.

call 'git restore kept.md'
has "git restore is read the same way" "$(said)" '"permissionDecision":"deny"'

# --- a clean path ---

call 'git checkout -- other.md'
is "a file with no changes is allowed" "$(said)" ""

# --- staged is not safe, and is still refused ---
#
# **A staged change is lost by `git checkout --` too.** Counting the index as safety would wave
# through the case a worker is most sure of.

git -C "$repo" add kept.md
call 'git checkout -- kept.md'
has "a staged change is still work to lose" "$(said)" '"permissionDecision":"deny"'
git -C "$repo" reset -q

# --- the index is a different verb ---
#
# `--staged` moves the index and leaves the working tree, so it is not this accident.

call 'git restore --staged kept.md'
is "restoring the index is left alone" "$(said)" ""

# --- a stash holds a copy ---

git -C "$repo" stash push -q -m 'a copy' kept.md 2>/dev/null
printf 'three\n' > "$repo/kept.md"
call 'git checkout -- kept.md'

is "a path a stash carries is allowed" "$(said)" ""

git -C "$repo" checkout -q -- kept.md 2>/dev/null
git -C "$repo" stash drop -q 2>/dev/null

# --- everything else git does ---

for safe in 'git checkout main' 'git status --short' 'git checkout -b a-branch' 'git commit -m x'; do
  call "$safe"
  is "[$safe] is not a restore" "$(said)" ""
done

# --- a chained command ---
#
# **A path list ends at the next command.** Reading past `&&` asks git about a word, and a word is
# not a path — so the answer would be empty and the refusal would never fire.

printf 'four\n' > "$repo/kept.md"
call 'git checkout -- kept.md && echo done'
has "a chained restore is still denied" "$(said)" '"permissionDecision":"deny"'
lacks "and the echo is not read as a path" "$(said)" 'echo'

# --- it is not another tool's business ---

printf '{"tool_name":"Read","tool_input":{"file_path":"kept.md"}}' > "$tmp/call.json"
is "a call with no command says nothing" "$(said)" ""

printf '\ndiscards — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
