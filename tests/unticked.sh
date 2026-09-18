#!/bin/bash
# What `bin/unticked.sh` counts as an unticked box, and what it refuses to.
#
# **The sweep is not a gate** — it reaches the network, and a gate that needs one goes red on a
# train. So nothing graded it, and it shipped counting `- [ ]` anywhere in a body. An issue that
# discussed its own boxes inflated its own debt: #494 read as ten and holds seven, #746 as one and
# holds none.
#
# Driven through a `gh` this suite writes, so every check is the real script reading a real body.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()  { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }

# **Added because two checks of mine called it and nothing did.** The shell said `command not
# found`, the tally said 17 passed, and both assertions had simply gone.
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "unticked"

tmp="${TMPDIR:-/tmp}/unticked-suite-$$"
mkdir -p "$tmp/bin" "$tmp/bodies"
trap 'rm -rf "$tmp"' EXIT

# **A body is a file, never an argument.** A box is markdown with newlines and backticks in it, and
# one folded onto a command line stops being the thing under test.
#
# **The index is composed here, from the same two fixtures.** The script asks REST for numbers and
# reasons together now, and a fixture per fact keeps each case saying one thing.
#
# **`state_reason` comes first, and the order is the whole stub.** Both paginated calls carry
# `--paginate`, so matching that first answered the index with the total and turned fourteen cases
# red. What tells them apart is the field each one asks for.
cat > "$tmp/bin/gh" <<'STUB'
#!/bin/sh
case "$*" in
  *state_reason*) while read -r number; do
                      printf '%s\t%s\n' "$number" "$(cat "$BODIES/$number.reason" 2>/dev/null)"
                  done < "$BODIES/numbers" ;;

  *--paginate*) n=$(cat "$BODIES/total" 2>/dev/null) || n=0
                case $n in ""|*[!0-9]*) exit 0 ;; esac
                i=0; while [ "$i" -lt "$n" ]; do echo "$i"; i=$((i + 1)); done ;;

  *"/issues/"*) for a in "$@"; do case $a in *"/issues/"*) n=${a##*/issues/} ;; esac; done
                cat "$BODIES/$n" 2>/dev/null ;;
esac
STUB
chmod +x "$tmp/bin/gh"

swept() { ( cd "$root" && PATH="$tmp/bin:$PATH" BODIES="$tmp/bodies" sh bin/unticked.sh "$1" 2>&1 ); }
code_of() { ( cd "$root" && PATH="$tmp/bin:$PATH" BODIES="$tmp/bodies" sh bin/unticked.sh "$1" >/dev/null 2>&1 ); printf '%s' "$?"; }

# --- a box that is open ---

printf '1\n' > "$tmp/bodies/numbers"
printf -- '## Done when\n\n- [x] one held\n- [ ] one did not\n' > "$tmp/bodies/1"

is  "an open box is found"     "$(code_of 1)" "1"
has "and it is counted once"   "$(swept 1)"   "#1     1 unticked"

# --- a box quoted in prose is not a box ---
#
# **The fault this suite was written for.** An issue explaining why a box was struck quotes it, and
# the quote sat inside backticks mid-sentence. Unanchored, the count read the discussion as debt.

printf -- '## Done when\n\n- [x] one held\n\nThe line `- [ ] a box nobody can tick` was the older shape,\nand counting `- [ ]` anywhere is how this went wrong.\n' > "$tmp/bodies/1"

is  "a body whose boxes all hold is clean" "$(code_of 1)" "0"
has "and it says none"                     "$(swept 1)"   "none in the last"

# --- a struck box is answered ---
#
# `closing.md` strikes a requirement that was wrong when written and leaves the `- [ ]`. Counting it
# makes a decision read as debt for ever.

printf -- '## Done when\n\n- [x] one held\n- [ ] ~~this was wrong when written~~ — struck, and here is why\n' > "$tmp/bodies/1"

is "a struck box is not debt" "$(code_of 1)" "0"

# --- both shapes at once ---
#
# The count is the open ones, and neither the quoted nor the struck.

printf -- '## Done when\n\n- [ ] first open\n- [ ] ~~struck~~\n- [ ] second open\n\nprose holding `- [ ] a quote`\n' > "$tmp/bodies/1"

has "an open box beside a struck one counts only itself" "$(swept 1)" "#1     2 unticked"

# --- a plain bullet is unrecordable, and not this script's question ---

printf -- '## Done when\n\n- a claim nobody can tick\n' > "$tmp/bodies/1"

is "a plain bullet is not an unticked box" "$(code_of 1)" "0"

# --- the tally across issues ---

printf '1\n2\n3\n' > "$tmp/bodies/numbers"
printf -- '- [ ] open\n'                   > "$tmp/bodies/1"
printf -- '- [x] held\n'                   > "$tmp/bodies/2"
printf -- '- [ ] ~~struck~~ — and why\n'   > "$tmp/bodies/3"

has "only the issues with an open box are tallied" "$(swept 3)" "1 of the last 3"

# --- an issue the repository turned down ---
#
# **A declined issue's open box is the record, never a lie.** #431 asked for a whole capability and
# closed `NOT_PLANNED`; its ten boxes describe work nobody was going to do. Counted as debt, they
# send the next reader to build what the repository already refused.
#
# Five of thirty-six read that way on 18 September, and four were the next four I would have taken.

printf '1\n2\n' > "$tmp/bodies/numbers"
printf -- '- [ ] open\n' > "$tmp/bodies/1"
printf -- '- [ ] open\n' > "$tmp/bodies/2"
printf 'NOT_PLANNED\n'  > "$tmp/bodies/2.reason"

said=$(swept 2)
has "a declined issue is counted apart"      "$said" "1 of the last 2"
has "and the line says what it was"          "$said" "1 more closed as not planned"
lacks "and it is not in the tally above"     "$said" "#2 "

# Nothing declined, nothing said. A line that always prints is a line nobody reads.
rm -f "$tmp/bodies/2.reason"
lacks "no declined issue says nothing about them" "$(swept 2)" "not planned"

# Every one declined is still a sweep that found nothing owing.
printf 'NOT_PLANNED\n' > "$tmp/bodies/1.reason"
printf 'NOT_PLANNED\n' > "$tmp/bodies/2.reason"
is  "a sweep of only declined issues is clean" "$(code_of 2)" "0"
has "and it still names them"                  "$(swept 2)" "2 more closed as not planned"

rm -f "$tmp/bodies/1.reason" "$tmp/bodies/2.reason"

# --- the edge of the window ---
#
# **A window is honest about its edge, or it is not honest.** The default reads the last sixty,
# and this tree holds a hundred and sixty-six closed. Seven and forty-four are both true, and the
# line that says seven has to say which it is.

printf '1\n2\n3\n' > "$tmp/bodies/numbers"
printf '20\n'      > "$tmp/bodies/total"
printf -- '- [ ] open\n' > "$tmp/bodies/1"

has "a window that read three of twenty says so" "$(swept 3)" "17 more are closed and were not read"

# The same line, and the same silence, when nothing was left out.
printf '3\n' > "$tmp/bodies/total"

is "a window that read all of them adds nothing" \
   "$(swept 3 | grep -c "more are closed")" "0"

# A total nobody could read is not a reason to say a wrong one.
printf 'not a number\n' > "$tmp/bodies/total"

is "a total that is not a number is left unsaid" \
   "$(swept 3 | grep -c "more are closed")" "0"
has "and the sweep still reports"  "$(swept 3)" "of the last 3"

rm -f "$tmp/bodies/total"

# --- GitHub not answering is not a clean sweep ---

printf '' > "$tmp/bodies/numbers"
is "a sweep that got no numbers back refuses" "$(code_of 3)" "3"

# A suite that ran nothing passes everything.
[ $((passed + failed)) -gt 0 ] || { printf '  FAIL  no check ran\n'; failed=1; }

printf '\nunticked — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
