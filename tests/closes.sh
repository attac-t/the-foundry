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
# A stand-in for the forge, so this suite never asks the real one. It answers three questions: a
# request's address, body and title, its commits, and an issue's boxes.
#
# **It answers only the two `--jq` strings measured live on #1027.** No jq runs here, so a hook
# whose expression drifts gets nothing back and goes red. Measure again before changing a copy.
#
# The commits answer only at the repository the request's address names, and only paged, because
# `{owner}` follows the directory and an unpaged read stops at thirty.
THE_REQUEST='.url, .body, ("merge commit: " + .title)'
EACH_COMMIT_LINE='.[] | .sha[0:7] as $c | .commit.message | split("\n")[] | "commit \($c): \(.)"'

stub_gh() {
  printf "%s" "$1" > "$tmp/pr.body"
  printf "%s" "$2" > "$tmp/issue.body"
  printf "%s" "${3:-}" > "$tmp/pr.commits"
  printf "%s" "${4:-}" > "$tmp/pr.title"
  printf "%s" "$THE_REQUEST" > "$tmp/jq.view"
  printf "%s" "$EACH_COMMIT_LINE" > "$tmp/jq.api"
  printf '0' > "$tmp/api.exit"
  {
    printf '#!/bin/sh\n'
    printf 'fields=; jq=; paged=; prior=\n'
    printf 'for arg in "$@"; do\n'
    printf '  [ "$prior" = --json ] && fields=$arg\n'
    printf '  [ "$prior" = --jq ] && jq=$arg\n'
    printf '  [ "$arg" = --paginate ] && paged=yes\n'
    printf '  prior=$arg\n'
    printf 'done\n'
    printf 'case "$1 $2" in\n'
    printf '  "pr view")    [ "$jq" = "$(cat %s)" ] || exit 1\n' "$tmp/jq.view"
    printf '                case ",$fields," in *,url,*) echo https://github.com/acme/closes/pull/740 ;; esac\n'
    printf '                cat %s; echo\n' "$tmp/pr.body"
    printf '                case ",$fields," in *,title,*) cat %s; echo ;; esac ;;\n' "$tmp/pr.title"
    printf '  "issue view") [ "$3" = 711 ] && cat %s ;;\n' "$tmp/issue.body"
    printf '  "api repos/acme/closes/pulls/740/commits")\n'
    printf '                [ "$jq" = "$(cat %s)" ] && [ -n "$paged" ] || exit 1\n' "$tmp/jq.api"
    printf '                cat %s; echo; exit "$(cat %s)" ;;\n' "$tmp/pr.commits" "$tmp/api.exit"
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

# --- a commit closes an issue too, and the title is read by choice ---
#
# On 24 September #1021 closed from commit `04cf28b`, whose message ended `Closes #1021`, under a
# body saying `Refs`. **GitHub closes from a commit when it reaches `main`.** The title rides in the
# merge commit. Whether that closes is unmeasured, so reading it is a choice that only refuses more.

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

# JSON forbids every control character below a space, not only the two a web edit brings.
stub_gh $'Closes #711\001\033' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'[Closes #711]'*) ok "no control character reaches the JSON" ;;
  *)                 bad "no control character reaches the JSON — one did" ;;
esac

# --- a commit read that fails leaves the body's check standing ---

stub_gh 'Closes #711' '- [ ] one thing' 'commit 04cf28b: nothing here'
printf '1' > "$tmp/api.exit"

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a commit read that fails still refuses on the body" ;;
  *)                               bad "a commit read that fails still refuses on the body — it let the merge through" ;;
esac

# --- a hook copied without its sibling blocks nothing ---
#
# Under dash a failed `.` exits 2, and a PreToolUse hook that exits 2 blocks every command. So a
# hook that cannot read `forge-reads.sh` exits 0 before it tries.

mkdir -p "$tmp/lonely" && cp "$root/.claude/hooks/closes.sh" "$tmp/lonely/closes.sh"
stub_gh 'Closes #711' '- [ ] one thing'
call "$(verb pr merge) 740 --merge"
lonely=$(PATH="$tmp/bin:$PATH" sh "$tmp/lonely/closes.sh" < "$tmp/call.json" 2>&1); code=$?
[ "$code" -eq 0 ] && [ -z "$lonely" ] && ok "a hook missing its sibling exits 0 and blocks nothing" \
  || bad "a hook missing its sibling exits 0 and blocks nothing — it exited $code"

# --- only the first line names the repository ---
#
# The address is the first line the request read prints. A body line shaped like another address
# must not add a second repository, or the commit read builds a path that answers nothing.

stub_gh 'Refs #711
https://github.com/elsewhere/other/pull/740' '- [ ] one thing' 'commit 04cf28b: Closes #711.'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a body line shaped like an address leaves the commits read" ;;
  *)                               bad "a body line shaped like an address leaves the commits read — they went unread" ;;
esac

# --- a colon, and two issues on one line ---
#
# GitHub closes on `Closes: #10`, and on each issue in `Resolves #10, resolves #123`. A pattern
# keeping the last match on a line read only the second, and a colon hid the first.

stub_gh 'Closes: #711' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'"permissionDecision":"deny"'*) ok "a colon after the word is closure" ;;
  *)                               bad "a colon after the word is closure — it was let through" ;;
esac

# In the middle, so reading only the first match or only the last one both miss it.
stub_gh 'Resolves #999, resolves #711, resolves #998' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'#711 with 1 box'*) ok "every issue on a line is read, not only the last" ;;
  *)                   bad "every issue on a line is read, not only the last — #711 was missed" ;;
esac

# A longer number is not this issue's line. With no boundary, the pattern quoted `#7110` for `#711`.
stub_gh 'Closes #7110
Closes #711' '- [ ] one thing'

call "$(verb pr merge) 740 --merge"
case $(asked) in
  *'[Closes #711]'*) ok "it quotes the line for this number, not a longer one" ;;
  *)                 bad "it quotes the line for this number, not a longer one — it quoted #7110" ;;
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
