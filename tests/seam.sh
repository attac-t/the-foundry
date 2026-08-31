#!/bin/bash
# What `.claude/hooks/seam.sh` denies, and what it must not.
#
# Forty-three checks shipped before this file and not one drove the hook. The line that reads a
# `--body-file` path is the most fragile thing in it, and it broke twice — silently, both times,
# because a tool rewrote a backslash on the way through.
#
# Every case is a file on disk. A tool call written on this suite's own command line would be read
# by the hook that is running it.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "seam"

tmp="${TMPDIR:-/tmp}/seam-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# One tool call, as the harness sends it. Written, never typed.
call() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$tmp/call.json"; }

asked() { sh "$root/.claude/hooks/seam.sh" < "$tmp/call.json" 2>&1; }

denies() { case $(asked) in *'"deny"'*) ok "$1" ;; *) bad "$1 — it was allowed" ;; esac; }
allows() { case $(asked) in *'"deny"'*) bad "$1 — it was denied" ;; *) ok "$1" ;; esac; }

# The three verbs and the two API routes, spelled apart so this file does not trip the live hook.
verb() { printf 'gh %s %s' "$1" "$2"; }

# --- a rendered body passes ---

a_rendered_file_is_allowed() {
  sh "$root/plugins/floor/bin/say.sh" --kind closure --subject '#1' \
     --because a --next b --evidence c </dev/null > "$tmp/body.md" 2>/dev/null

  call "$(verb issue comment) 1 --body-file $tmp/body.md"
  allows "a body the seam rendered"

  call "$(verb pr comment) 1 --body-file=$tmp/body.md"
  allows "and the same path given with an equals"
}
a_rendered_file_is_allowed

# --- what is denied ---

an_unrendered_body_is_denied() {
  call "$(verb issue comment) 1 --body hello"
  denies "a body typed on the command line"

  printf 'no marker here\n' > "$tmp/plain.md"
  call "$(verb issue comment) 1 --body-file $tmp/plain.md"
  denies "a file with no marker"

  call "$(verb issue comment) 1 --body-file $tmp/missing.md"
  denies "a file that is not there"
}
an_unrendered_body_is_denied

#
# `seam:` alone used to be enough. A log that merely mentions the word walked through, which is the
# exact shape this exists to stop.
the_word_alone_is_not_the_marker() {
  call "$(verb issue comment) 1 --body 'a log mentioning seam: and 12KB besides'"
  denies "the word without the marker"

  printf 'seam: is mentioned here\n' > "$tmp/mentions.md"
  call "$(verb issue comment) 1 --body-file $tmp/mentions.md"
  denies "and the same inside a file"
}
the_word_alone_is_not_the_marker

# --- what it must not touch ---

#
# `gh pr review --approve` carries no body at all. Denying it stopped a legitimate action for
# lacking a marker it could never have had.
a_call_with_no_body_is_not_a_comment() {
  call "$(verb pr review) 416 --approve"
  allows "a review with no body"

  call "git status"
  allows "a command that is not gh"

  call "gh pr view 416 --json headRefOid"
  allows "reading a pull request"
}
a_call_with_no_body_is_not_a_comment

printf 'seam — %d passed, %d failed\n' "$passed" "$failed"
[ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — seam ran nothing.\n'; exit 1; }
[ "$failed" -eq 0 ]
