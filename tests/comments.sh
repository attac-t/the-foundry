#!/bin/bash
# What `bin/comments.sh` finds when it reads a public thread back.
#
# Driven through a `gh` this suite writes, so every check is the real script reading a real answer.
# Mocking its insides would prove the parts and leave the join — which is where the bug was.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is() { [ "$2" = "$3" ] && { ok "$1"; return; }; bad "$1 — want [$3], got [$2]"; }
has() { case $2 in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing" ;; esac; }

echo "comments"

tmp="${TMPDIR:-/tmp}/comments-suite-$$"
mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT

# The thread, as `gh` would answer it: one comment per line, id and body, tab separated.
thread() { printf '%s\n' "$@" > "$tmp/thread"; }

# A `gh` that answers from the file above and nothing else. On PATH ahead of the real one, so the
# script under test cannot reach the network even by accident.
cat > "$tmp/bin/gh" <<'FAKE'
#!/bin/sh
[ "${1:-}" = api ] || exit 1
cat "$THREAD"
FAKE
chmod +x "$tmp/bin/gh" 2>/dev/null

read_back() {
  PATH="$tmp/bin:$PATH" THREAD="$tmp/thread" sh "$root/bin/comments.sh" 416 2>&1
  return $?
}
code_of() { read_back >/dev/null 2>&1; printf '%s' "$?"; }

# --- what passes ---

a_thread_of_rendered_comments_passes() {
  thread "$(printf '1\t**Finding** — #416 proposed → approved <!-- seam:123 -->')" \
         "$(printf '2\t**Closed** — #418 every box holds <!-- seam:456 -->')"

  is  "every rendered comment obeys the seam" "$(code_of)" "0"
  has "and it says so"                        "$(read_back)" "still obeys the seam"
}
a_thread_of_rendered_comments_passes

an_empty_thread_passes() {
  : > "$tmp/thread"
  is "a thread with nothing on it is not a failure" "$(code_of)" "0"
}
an_empty_thread_passes

# --- what fails ---

#
# The whole point. A comment carrying the marker has claimed to come through the seam, so every rule
# the seam applies must still hold on GitHub's copy. A marker is not a laundering device.
a_rendered_comment_over_the_limit_fails() {
  long=$(head -c 1400 /dev/zero | tr '\0' 'x')
  thread "$(printf '9\t**Finding** — %s <!-- seam:123 -->' "$long")"

  is  "it goes red"      "$(code_of)" "1"
  has "and names the id" "$(read_back)" "9"
}
a_rendered_comment_over_the_limit_fails

a_rendered_comment_carrying_a_log_fails() {
  thread "$(printf '8\t**Finding** — session 01a0532a-34d0-7ac0-972d-12b19dd0740c <!-- seam:123 -->')"

  is  "a session id goes red" "$(code_of)" "1"
  has "and says what it is"   "$(read_back)" "log field"
}
a_rendered_comment_carrying_a_log_fails

a_second_bad_comment_is_still_reported() {
  long=$(head -c 1400 /dev/zero | tr '\0' 'x')
  thread "$(printf '6\t**Finding** — %s <!-- seam:1 -->' "$long")" \
         "$(printf '7\t**Finding** — %s <!-- seam:2 -->' "$long")"

  said=$(read_back)
  is "one bad comment does not hide the next" \
     "$(printf '%s' "$said" | grep -c FAIL)" "2"
}
a_second_bad_comment_is_still_reported

#
# The regression's shape, and the honest limit.
#
# A long comment with no marker did not come through the seam. This cannot say who wrote it — a
# person and the worker sign in as the same account — so it reports and does not fail. #421 owns the
# credential that would tell them apart.
an_unrendered_comment_is_named_and_not_failed() {
  long=$(head -c 1400 /dev/zero | tr '\0' 'x')
  thread "$(printf '5\t%s' "$long")"

  is  "it does not go red"      "$(code_of)" "0"
  has "and it is named anyway"  "$(read_back)" "did not come through the seam"
}
an_unrendered_comment_is_named_and_not_failed

# --- what it does when it cannot read ---

#
# A gate that could not run is not a gate that passed. Exit 3 is this repo's word for it.
no_gh_reads_nothing() {
  # Coreutils, and no `gh`. An empty PATH answers 127 for `dirname`, which is a different
  # finding wearing the same number.
  no_gh=$(PATH=/usr/bin:/bin sh "$root/bin/comments.sh" 416 >/dev/null 2>&1; printf %s "$?")
  is "no gh answers 3" "$no_gh" "3"
  is "and no number answers 3" \
     "$(PATH="$tmp/bin:$PATH" THREAD="$tmp/thread" sh "$root/bin/comments.sh" >/dev/null 2>&1; printf '%s' "$?")" "3"
}
no_gh_reads_nothing

printf 'comments — %d passed, %d failed\n' "$passed" "$failed"
[ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — comments ran nothing.\n'; exit 1; }
[ "$failed" -eq 0 ]
