#!/bin/bash
# What `bin/unnamed.sh` calls a disagreement between the page and the code.
#
# **Every check writes its own page and its own script.** The real page carries a hundred and
# eighty-two rows, and a suite that reads it would pass for as long as nobody edited either.
#
# The three words sit in a table at the top of the page, fenced exactly like a head. Reading those as
# decisions made the page disagree with itself three times, and the fix is that a decision row
# carries a number.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "unnamed"

tmp="${TMPDIR:-/tmp}/unnamed-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/code.sh" <<'FIX'
refuse_a_thing() {
    note "it was not there"
    exit 7
}

refuse_another() {
    note "nor was that"
    exit 8
}
FIX

page() { cat > "$tmp/page.md"; }
said() { ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/code.sh" \
           sh bin/unnamed.sh 2>&1 ); }
code_of() { ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/code.sh" \
              sh bin/unnamed.sh >/dev/null 2>&1 ); printf '%s' "$?"; }

# --- the page and the code agree ---

page <<'P'
| Word | Means |
|---|---|
| `invariant` | it may never soften |
| `answer` | it refuses nothing |
| `default` | somebody chose it once |

| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `refuse_a_thing` | 7 | default | it was not there | nobody has asked |
| `refuse_another` | 8 | default | nor was that | nobody has asked |
P

is  "a page naming every decision passes" "$(code_of)" "0"
has "and says how many it read"           "$(said)"    "2 decisions"

# The word table is fenced exactly like a head. Without the number it read as three stale rows.
lacks "the word table is not three decisions" "$(said)" "invariant"

# --- a decision the page never named ---

page <<'P'
| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `refuse_a_thing` | 7 | default | it was not there | nobody has asked |
P

is  "a refusal the page lacks is caught"  "$(code_of)" "1"
has "and it is named"                     "$(said)"    "refuse_another"
has "and said to be the code's, not the page's" "$(said)" "the page does not say so"

# --- a row the code stopped making ---
#
# Told apart from the one above, because the remedies are opposite: one wants a judgement written
# and the other wants a line deleted.

page <<'P'
| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `refuse_a_thing` | 7 | default | it was not there | nobody has asked |
| `refuse_another` | 8 | default | nor was that | nobody has asked |
| `refuse_a_ghost` | 9 | default | nobody refuses this | nobody has asked |
P

is  "a row the code no longer makes is caught" "$(code_of)" "1"
has "and it is named"                          "$(said)"    "refuse_a_ghost"
has "and said to be the page's"                "$(said)"    "the code no longer refuses"

# --- a row nobody judged ---

page <<'P'
| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `refuse_a_thing` | 7 | default | it was not there | nobody has asked |
| `refuse_another` | 8 |  | nor was that |  |
P

is  "a row with no word is caught"    "$(code_of)" "1"
has "and counted"                    "$(said)"    "1 rows carry no word"
has "and called unjudged, not wrong" "$(said)"    "nobody has judged them"


# --- a refusal added on a code the page already carries ---
#
# **One function, one code, two reasons.** A new code is the easy half, and so are two functions —
# the head already parts those. This is the hard one: the same head refusing the same way twice for
# different reasons, which only the message can separate.
#
# **The first version of this check passed against a weaker key.** Its two refusals sat in different
# functions, so head and code alone told them apart and the message proved nothing.

cat > "$tmp/twocode.sh" <<'FIX'
refuse_a_thing() {
    note "it was not there"
    exit 7

    note "and this is a different reason"
    exit 7
}
FIX

page <<'P'
| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `refuse_a_thing` | 7 | default | it was not there | nobody has asked |
P

is  "a second refusal on a listed code is caught" \
    "$( ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/twocode.sh" \
          sh bin/unnamed.sh >/dev/null 2>&1 ); printf '%s' "$?")" "1"
has "and it is named by what it says" \
    "$( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/twocode.sh" \
        sh bin/unnamed.sh 2>&1 )" "a different reason"
# --- what it refuses ---

is "a page it cannot read refuses" \
   "$( ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/nope.md" FOUNDRY_REFUSALS_READS="$tmp/code.sh" \
         sh bin/unnamed.sh >/dev/null 2>&1 ); printf '%s' "$?")" "3"

is "a script it cannot read refuses" \
   "$( ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/nope.sh" \
         sh bin/unnamed.sh >/dev/null 2>&1 ); printf '%s' "$?")" "3"

# A script holding no refusal at all. Zero found is a reader that could not read, never a clean tree.
printf 'f() {\n    printf hello\n}\n' > "$tmp/quiet.sh"
is "a script that refuses nothing refuses" \
   "$( ( cd "$root" && FOUNDRY_REFUSALS_PAGE="$tmp/page.md" FOUNDRY_REFUSALS_READS="$tmp/quiet.sh" \
         sh bin/unnamed.sh >/dev/null 2>&1 ); printf '%s' "$?")" "3"

printf '\nunnamed — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
