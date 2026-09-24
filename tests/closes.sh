#!/bin/bash
# What `.claude/hooks/closes.sh` refuses before a merge, and what it lets through.
#
# A merge and a completion are two transitions. Only the second is a judgement, and until this hook
# nothing read the first. `ticks.sh` speaks after the merge, which is after the issue is already
# closed and its boxes are already blank.
#
# **The case that shipped this is prose.** On 15 September 2026 a request body ended `Refs #711` and
# closed #711 anyway, because a sentence under *The limits* read *this closes #711's last box*. The
# forge matches the keyword anywhere, in any case, so the suite drives that shape first.
#
# Every call is a file on disk. One typed on this suite's command line would be read by the live
# hooks running it.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "closes"

tmp="${TMPDIR:-/tmp}/closes-suite-$$"
mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT

call() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$tmp/call.json"; }

#
# A stand-in for the forge, so this suite never asks the real one. It answers two questions and
# tells them apart by the noun: a request carries what it closes, an issue body carries boxes.
#
# A request's title and commits come back only when `--json` names them, in the lines the hook's
# `--jq` makes. **So a hook that stops asking goes red.** The `--jq` itself is measured live.
stub_gh() {
  printf "%s" "$1" > "$tmp/pr.body"
  printf "%s" "$2" > "$tmp/issue.body"
  printf "%s" "${3:-}" > "$tmp/pr.commits"
  printf "%s" "${4:-}" > "$tmp/pr.title"
  {
    printf '#!/bin/sh\n'
    printf 'fields=; prior=\n'
    printf 'for arg in "$@"; do [ "$prior" = --json ] && fields=$arg; prior=$arg; done\n'
    printf 'case "$1 $2" in\n'
    printf '  "pr view")    cat %s; echo\n' "$tmp/pr.body"
    printf '    case ",$fields," in *,title,*) cat %s; echo ;; esac\n' "$tmp/pr.title"
    printf '    case ",$fields," in *,commits,*) cat %s; echo ;; esac ;;\n' "$tmp/pr.commits"
    printf '  "issue view") [ "$3" = 711 ] && cat %s ;;\n' "$tmp/issue.body"
    printf 'esac\nexit 0\n'
  } > "$tmp/bin/gh"
  chmod +x "$tmp/bin/gh"
}

asked() { PATH="$tmp/bin:$PATH" sh "$root/.claude/hooks/closes.sh" < "$tmp/call.json" 2>&1; }

# Spelled apart so this file does not trip a live hook reading its own command line.
verb() { printf 'gh %s %s' "$1" "$2"; }

# --- the case that happened: the keyword is prose, mid-sentence ---

stub_gh 'This closes #711 last box and nothing else. Refs #711' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a keyword in prose is read the way the forge reads it" ;;
  *)                               bad "a keyword in prose is read the way the forge reads it — it was not" ;;
esac

case $(asked) in
  *'#711 with 1 box'*) ok "it names the issue and how many are open" ;;
  *)                   bad "it names the issue and how many are open — it did not" ;;
esac

case $(asked) in
  *'This closes #711 last box'*) ok "it quotes the line that closes it" ;;
  *)                             bad "it quotes the line that closes it — it did not" ;;
esac

# --- the forge takes nine words, not one ---
#
# `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`. A check
# that knows one of them lets the other eight through, and the fault is identical every time.

for word in close closes closed fix fixes fixed resolve resolves resolved; do
  stub_gh "$word #711" '- [ ] one thing'

  call "$(verb pr merge) 740 --merge"
  case $(asked) in
    *'"permissionDecision":"deny"'*) ok "$word #N is closure" ;;
    *)                               bad "$word #N is closure — it was let through" ;;
  esac
done

# --- a word that merely contains one is not closure ---

stub_gh 'Refs #711. Disclosure is not closure, and unfixable is not fixed.' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *deny*) bad "a word containing a keyword is not closure — it was denied" ;;
  *)      ok "a word containing a keyword is not closure" ;;
esac

# --- the capital the author actually typed ---
#
# Every keyword above is lowercase, so nothing drove the lowering until this. The body that caused
# this hook read `This closes`, and a request template writes `Closes #N` at the start of a line.

stub_gh 'Closes #711' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a capitalised keyword is closure" ;;
  *)                               bad "a capitalised keyword is closure — it was let through" ;;
esac

# --- a keyword inside a longer word refuses, and that is on purpose ---
#
# The forge wants a word boundary and this does not. **It refuses more than the forge closes**, which
# costs a reword and never a wrongly closed issue. The message quotes the line so the author can see
# what matched.

stub_gh 'This discloses #711 in full.' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a keyword inside a word still refuses, by choice" ;;
  *)                               bad "a keyword inside a word still refuses, by choice — it did not" ;;
esac

# --- two issues in one body, and the right line is quoted ---
#
# Driven live on 15 September, the message named the wrong sentence: the first keyword anywhere in
# the body, not the one for the issue it refused. **The author reads a line they did not write.**

stub_gh 'A quote: this closes #999 and nothing else.
Closes #711' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'Closes #711'*) ok "it quotes the line for the issue it refuses" ;;
  *)               bad "it quotes the line for the issue it refuses — it quoted another" ;;
esac

case $(asked) in
  *'closes #999'*) bad "it does not quote another issue's line — it did" ;;
  *)               ok "it does not quote another issue's line" ;;
esac

# --- a commit closes an issue too, and so does the title ---
#
# On 24 September #1021 closed from commit `04cf28b`, whose message ended `Closes #1021`, under a
# body saying `Refs`. **GitHub closes from a commit when it reaches `main`.** The title rides in the
# merge commit, so it closes the same way.

stub_gh 'Refs #711' '- [ ] one thing' 'commit 04cf28b: one still fails. Closes #711.'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a commit message is read the way the forge reads it" ;;
  *)                               bad "a commit message is read the way the forge reads it — it was not" ;;
esac

case $(asked) in
  *'[commit 04cf28b: one still fails. Closes #711.]'*) ok "it names the commit whose line closes it" ;;
  *)                                                   bad "it names the commit whose line closes it — it did not" ;;
esac

stub_gh 'Refs #711' '- [x] one thing' 'commit 04cf28b: Closes #711.'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *deny*) bad "a commit closing a fully ticked issue merges — it was denied" ;;
  *)      ok "a commit closing a fully ticked issue merges" ;;
esac

stub_gh 'Refs #711' '- [ ] one thing' '' 'merge commit: fix #711 in one line'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a title is read, because the merge commit carries it" ;;
  *)                               bad "a title is read, because the merge commit carries it — it was not" ;;
esac

# --- the line it quotes never breaks the refusal ---
#
# A commit quotes freely, and a refusal that does not parse refuses nothing. A request edited on
# the web comes back with carriage returns.

stub_gh 'Refs #711' '- [ ] one thing' 'commit 04cf28b: the "last" box, in a\b. Closes #711.'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'[commit 04cf28b: the last box, in ab. Closes #711.]'*) ok "a quote and a backslash never reach the JSON" ;;
  *)                                                      bad "a quote and a backslash never reach the JSON — one did" ;;
esac

stub_gh $'Closes #711\t\r' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'[Closes #711]'*) ok "a tab and a carriage return never reach the JSON" ;;
  *)                 bad "a tab and a carriage return never reach the JSON — one did" ;;
esac

# --- every box ticked, so the merge may close it ---

stub_gh 'Closes #711' '- [x] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *deny*) bad "a fully ticked issue merges — it was denied" ;;
  *)      ok "a fully ticked issue merges" ;;
esac

# --- Refs is not closure ---

stub_gh 'Refs #711, #738' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *deny*) bad "Refs alone is not closure — it was denied" ;;
  *)      ok "Refs alone is not closure" ;;
esac

# --- anything that is not a merge is none of its business ---

stub_gh 'Closes #711' '- [ ] one thing'

call "$(verb pr view) 740"
case $(asked) in
  *deny*) bad "a command that is not a merge passes — it was denied" ;;
  *)      ok "a command that is not a merge passes" ;;
esac

# --- a merge naming no number cannot guess, and says nothing ---

stub_gh 'Closes #711' '- [ ] one thing'

call "$(verb pr merge) --merge"
case $(asked) in
  *deny*) bad "a merge naming no request says nothing — it denied on a guess" ;;
  *)      ok "a merge naming no request says nothing" ;;
esac

printf '\ncloses — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
