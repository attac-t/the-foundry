#!/bin/bash
# What `.claude/hooks/ticks.sh` says after a merge, and how it says it.
#
# `Closes #N` flips an issue closed and never touches its body. Eighteen boxes went blank on 4
# September and fourteen more on 9 September, and both were found only because somebody went looking.
#
# **The hook shipped printing plainly, and nothing ever saw it speak.** Only SessionStart,
# UserPromptSubmit and Setup inject what a hook prints; on a tool event it reaches the transcript and
# nobody reads it back. Floor's own suite carries that reasoning and caught the same mistake in a
# plugin hook a day later. A repository-level hook had no suite until this one.
#
# Every call is a file on disk. One typed on this suite's command line would be read by the live
# hooks running it.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "ticks"

tmp="${TMPDIR:-/tmp}/ticks-suite-$$"
mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT

call() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$tmp/call.json"; }

#
# A stand-in for the forge, so this suite never asks the real one. It answers two questions and
# tells them apart by the noun: a request body carries what it closes, an issue body carries boxes.
#
# `$1` is the noun and `$2` the verb, because `gh <noun> <verb>` is the shape the hook calls.
stub_gh() {
  {
    printf '#!/bin/sh\n'
    printf 'case "$1 $2" in\n'
    printf '  "pr view")    printf "%%s\\\\n" "%s" ;;\n' "$1"
    printf '  "issue view") printf "%%s\\\\n" "%s" ;;\n' "$2"
    printf 'esac\n'
  } > "$tmp/bin/gh"
  chmod +x "$tmp/bin/gh"
}

asked() { PATH="$tmp/bin:$PATH" sh "$root/.claude/hooks/ticks.sh" < "$tmp/call.json" 2>&1; }

# Spelled apart so this file does not trip a live hook reading its own command line.
verb() { printf 'gh %s %s' "$1" "$2"; }

# --- a merge that left a box open ---

stub_gh 'Closes #517' '- [ ] one thing'

call "$(verb pr merge) 530 --merge"
case $(asked) in
  *'"additionalContext"'*) ok "it speaks through additionalContext" ;;
  *)                       bad "it speaks through additionalContext — it did not" ;;
esac

case $(asked) in
  *'#517'*) ok "and names the issue the merge closed" ;;
  *)        bad "and names the issue the merge closed — it did not" ;;
esac

case $(asked) in
  *'1 open'*) ok "and how many boxes are still open" ;;
  *)          bad "and how many boxes are still open — it did not" ;;
esac

# **Never stdout on a tool event.** That is the fault this file exists for, and it is the one thing
# a passing hook and a silent one look alike on.
case $(asked) in
  ticks:*) bad "and never prints plainly — it did" ;;
  *)       ok  "and never prints plainly" ;;
esac

# --- silence, and it is the ordinary case ---

stub_gh 'Closes #517' '- [x] one thing'
call "$(verb pr merge) 530 --merge"
[ -z "$(asked)" ] && ok "a merge whose issue is fully ticked says nothing" \
                  || bad "a merge whose issue is fully ticked says nothing — it spoke"

stub_gh 'Refs #517' '- [ ] one thing'
call "$(verb pr merge) 530 --merge"
[ -z "$(asked)" ] && ok "a merge that only refs an issue says nothing" \
                  || bad "a merge that only refs an issue says nothing — it spoke"

stub_gh 'Closes #517' '- [ ] one thing'
call "$(verb pr merge) --merge"
[ -z "$(asked)" ] && ok "a merge naming no number says nothing" \
                  || bad "a merge naming no number says nothing — it spoke"

call "git status --short"
[ -z "$(asked)" ] && ok "and a command that is not a merge says nothing" \
                  || bad "and a command that is not a merge says nothing — it spoke"

printf '\nticks — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
