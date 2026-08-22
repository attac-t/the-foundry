#!/bin/bash
# Proves each count fires on its own, and that the dodges are shut.
#
# Isolation is asserted by behaviour, not by numbers. Every block fixture is scored twice: once
# normally, and once with the count under test moved out of reach. The second run must pass. That
# says "nothing else fired" without pinning the fixture's word counts to magic numbers.
#
# SCORER can point elsewhere. run.sh uses that to aim the suite at a broken scorer and check the
# suite goes red. A suite that cannot fail is not a suite.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tests/lib.sh"

scorer="${SCORER:-$root/lib/score.awk}"

# Score some text and get the exit code.
verdict() {
  printf '%s' "$1" | awk -f "$scorer" >/dev/null 2>&1
  echo $?
}

# Score some text and get one field from the report.
field() {
  printf '%s' "$1" | awk -f "$scorer" 2>/dev/null \
    | awk -F= -v k="$2" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

# Score some text with one count moved out of reach, and get the exit code.
without() {
  case "$1" in
    long)  printf '%s' "$2" | awk -f "$scorer" -v long_warn=100  -v long_block=100  >/dev/null 2>&1 ;;
    sent)  printf '%s' "$2" | awk -f "$scorer" -v sent_warn=999  -v sent_block=999  >/dev/null 2>&1 ;;
    words) printf '%s' "$2" | awk -f "$scorer" -v words_warn=1e9 -v words_block=1e9 >/dev/null 2>&1 ;;
  esac
  echo $?
}

# Get a sentence repeated the given number of times.
repeat() {
  local out="" i=0
  while [ $i -lt "$1" ]; do out="$out $2"; i=$((i + 1)); done
  printf '%s' "$out"
}

echo "scorer"

clean='Agents write too much. We cut it by ten.
The hook reads what the agent said. It counts the words.'
is "clean text passes" "$(verdict "$clean")" 0

# --- each count blocks on its own ---

longwords='The elephant ate a banana. My family had a holiday. The computer rang the telephone.'
sentence='I went to the shop and I got some milk and some bread and some jam and then I went home and put it all away and made a cake for my mum and dad, and then we sat down at the table and ate it all up before the sun went down.'
budget=$(repeat 110 'The cat sat on a mat.')

is "long words block"           "$(verdict "$longwords")"     2
is "and nothing else fired"     "$(without long "$longwords")" 0
is "a long sentence blocks"     "$(verdict "$sentence")"      2
is "and nothing else fired"     "$(without sent "$sentence")"  0
is "the word count blocks"      "$(verdict "$budget")"        2
is "and nothing else fired"     "$(without words "$budget")"  0

# --- each count warns on its own ---
# Only the long-word band had a fixture before. Blanking either of the others stayed green.

longwarn='The elephant sat on a mat. My family went to the shop and got some milk today.'
sentwarn='I went to the shop and I got some milk and then I went home and had a cake for tea.'
budgetwarn=$(repeat 25 'The cat sat on a mat.')

is "long words warn"        "$(verdict "$longwarn")"        1
is "and nothing else fired" "$(without long "$longwarn")"    0
is "a long sentence warns"  "$(verdict "$sentwarn")"        1
is "and nothing else fired" "$(without sent "$sentwarn")"    0
is "the word count warns"   "$(verdict "$budgetwarn")"      1
is "and nothing else fired" "$(without words "$budgetwarn")" 0


#
# A percentage over eleven words is arithmetic, not measurement.
#
# This reply was blocked at 27% long words. Three long words in eleven, and one word moves that nine
# points. It was blocked for being short and dense, which is what the standard asks
# for — `plain-english` says answer in one line and cut the words.
#
short='Nine PRs, main unmoved, and every open issue needs your decision — idling.'

is "a short reply warns but does not block"    "$(verdict "$short")" 1
is "and the ratio is still reported"           "$(field "$short" long_pct)" 27.3

# The floor lifts nothing else. A short reply with one long sentence is still a long sentence.
onesentence=$(for i in $(seq 1 46); do printf 'one '; done)
is "a long sentence still blocks under the floor" "$(verdict "$onesentence")" 2

# Above the floor the ratio decides as it always did.
long=$(for i in $(seq 1 12); do printf 'Independent verification demonstrates considerable architectural sophistication throughout. '; done)
is "a long reply still blocks on the ratio" "$(verdict "$long")" 2
# --- the dodges ---

fragmented='The elephant.
The banana.
The computer.
The telephone.
A cat.'
is "line breaks do not hide long words" "$(verdict "$fragmented")" 2

# The sentence count used to end at every line break, so hard-wrapping a long sentence measured its
# widest line. Same sentence, wrapped and not, must measure the same.
wrapped='I went to the shop and I got some milk and some bread
and some jam and then I went home and put it all away
and made a cake for my mum and dad, and then we sat down
at the table and ate it all up before the sun went down.'
is "wrapping does not shorten a sentence" "$(field "$wrapped" longest)" "$(field "$sentence" longest)"

# Blank lines and list items must still end a sentence, or these would join into one long one and
# block on length. Neither fixture closes with punctuation, so the boundary is all that saves them.
bullets='Here are things.

- the first thing
- the second thing
- the third thing'
paragraphs='the cat sat on a mat and the dog ran to the shop and got a bun for tea

the cat sat on a mat and the dog ran to the shop and got a bun for tea'
is "a list item ends a sentence" "$(verdict "$bullets")"    0
is "a blank line ends a sentence" "$(verdict "$paragraphs")" 0

brackets='The (elephant) ate a banana. My (family) had a holiday. The (computer) rang the (telephone).'
is "brackets do not hide long words" "$(field "$brackets" long_pct)" "$(field "$longwords" long_pct)"

table='Here it is.

| Word | Meaning |
|---|---|
| elephant | big |
| banana | food |
| telephone | ring |
| computer | box |'
is "a table does not hide long words"   "$(verdict "$table")"     2
is "table cells stay out of the budget" "$(field "$table" words)" 3

# A fence that never closes fenced nothing off. Otherwise opening one and never closing it hides the
# whole rest of the reply.
unclosed='Here it is.

```bash
The elephant ate a banana. My family had a holiday. The computer rang the telephone.'
is "an unclosed fence still counts" "$(verdict "$unclosed")" 2

# A wall of product names must not water the share down. Names leave both sides of the fraction, so
# the four long words here still carry it past the line. Left in the denominator alone, the same
# text reads under 25% and never blocks.
dilution='We use PostgreSQL, TypeScript, MySQL and GraphQL comprehensively, additionally, extensively and consistently.'
is "names cannot dilute the share" "$(verdict "$dilution")" 2

# --- what gets stripped ---

incode='Run it.

```bash
utilise the comprehensive functionality
```'
is "words inside code are not counted" "$(field "$incode" long_pct)" 0.0
is "code-only text passes"             "$(verdict "$incode")"        0
is "inline code is not counted" "$(field 'Do not write `comprehensive` in a reply.' long_pct)" 0.0
is "names are not long words"   "$(field 'We use PostgreSQL and TypeScript here.' long_pct)" 0.0

# Punctuation must not turn a word into a name. The anchor used to let a leading quote stand in for
# the first letter, so a quoted long word was skipped.
not "quoted long words are still words" \
    "$(field 'He said "Comprehensive" and "Additionally" and "Functionality" today.' long_pct)" 0.0

is "empty input passes" "$(verdict "")" 0

# --- the syllable count ---
# This was wrong on the commonest shape in technical English: every -tion word gained a beat it does
# not have, so the gate ran stricter than documented.

tion='The nation took action at the station in this section by option.'
is "-tion words are two beats, not three" "$(field "$tion" long_pct)" 0.0
is "a sentence of them passes"            "$(verdict "$tion")"        0

# `patio` and `ratio` end at the vowel pair, where it really is two beats, so the -tion carve-out
# must not reach them. `studio` would mask this: its `dio` has no t/c/s/x and scores 3 either way.
not "-tio endings are three beats" "$(field 'The patio and the ratio.' long_pct)" 0.0
not "split vowels are three beats" "$(field 'The manual usual video media.' long_pct)" 0.0

# --- policy ---
# The failure message names something a user has. It used to cite a document that shipped nowhere.

[ -f "$root/lib/banned.txt" ] \
  && bad "a word list is back — read 'Word choice is judged, not listed' in plugins/signal/README.md first" \
  || ok "no word list ships"

padded='Additionally, it is worth noting that we should leverage this comprehensive functionality in order to facilitate a robust implementation.'
is "padded prose still blocks on shape alone" "$(verdict "$padded")" 2

# The gap we accepted, made executable. Adding a word list later means deleting a passing test.
is "short unusual words pass the counts" "$(verdict 'We shall hence deem it thus, whilst the crux is moot.')" 0

# A block must always say why, even when the dials are set so no warn line fires.
report=$(printf '%s' "$longwords" | awk -f "$scorer" -v long_warn=99 -v long_block=1 2>/dev/null)
is  "inverted dials still block" "$(printf '%s\n' "$report" | awk -F= '$1 == "verdict" { print $2 }')" block
not "and still say why"          "$(printf '%s\n' "$report" | awk -F= '$1 == "reason" { sub(/^[^=]*=/, ""); print }')" ""

# --- the plugin holds itself to this ---
# Capture the code before anything else runs, or a command substitution in the label overwrites it.

for doc in "$root/README.md" "$root/skills/plain-english/SKILL.md"; do
  awk -f "$scorer" -v words_warn=99999 -v words_block=99999 < "$doc" >/dev/null 2>&1
  rc=$?
  is "$(basename "$doc") clears its own gate" "$rc" 0
done

summary "scorer"
