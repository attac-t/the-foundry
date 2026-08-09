#!/bin/bash
# Proves each count fires on its own, and that the dodges are shut.
#
# Every block test moves ONE count past its line and asserts the other two stay inside theirs. A
# suite where all three fire at once would pass even if two of them were dead code.
#
# SCORER can point elsewhere. run.sh uses that to aim the suite at a broken scorer and check the
# suite goes red. A suite that cannot fail is not a suite.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tests/lib.sh"

scorer="${SCORER:-$root/lib/score.awk}"

#
# Score some text and get the exit code.
#
verdict() {
  printf '%s' "$1" | awk -f "$scorer" >/dev/null 2>&1
  echo $?
}

#
# Score some text and get one field from the report.
#
field() {
  printf '%s' "$1" | awk -f "$scorer" 2>/dev/null \
    | awk -F= -v k="$2" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

#
# Get a sentence repeated the given number of times.
#
repeat() {
  local out="" i=0
  while [ $i -lt "$1" ]; do out="$out $2"; i=$((i + 1)); done
  printf '%s' "$out"
}

echo "scorer"

# First, prove the suite can read an exit code at all. An earlier self-gate loop wrote
# `is "$(basename ...)" "$?" 0`, which is always green: bash runs the substitution while building
# the argument list, and that overwrites $? before $? is read.
awk 'BEGIN { exit 1 }' >/dev/null 2>&1
rc=$?
is "the suite reads exit codes truthfully" "$rc" 1

clean='Claude writes too much. We cut it by ten.
The hook reads what Claude said. It counts the words.'
is "clean text passes" "$(verdict "$clean")" 0

# --- one count past its line, two inside ---

longwords='The elephant ate a banana. My family had a holiday. The computer rang the telephone.'
sentence='I went to the shop and I got some milk and some bread and some jam and then I went home and put it all away and made a cake for my mum and dad.'
budget=$(repeat 52 'The cat sat on a mat.')

is "long words alone block"     "$(verdict "$longwords")" 2
is "long sentence alone blocks" "$(verdict "$sentence")"  2
is "word count alone blocks"    "$(verdict "$budget")"    2

is "the long-word case keeps its sentences short" "$(field "$longwords" longest)"  5
is "the long-word case stays under budget"        "$(field "$longwords" words)"    15
is "the long-sentence case has no long words"    "$(field "$sentence" long_pct)"  0.0
is "the long-sentence case stays under budget"    "$(field "$sentence" words)"     35
is "the word-count case has no long words"        "$(field "$budget" long_pct)"    0.0
is "the word-count case keeps sentences short"    "$(field "$budget" longest)"     6

# --- the warn bands ---
# Only the long-word band had a fixture before. Blanking either of the others stayed green.

longwarn='The elephant sat on a mat. My family went to the shop and got some milk today.'
sentwarn='I went to the shop and I got some milk and then I went home and had a cake for tea.'
budgetwarn=$(repeat 25 'The cat sat on a mat.')

is "the long-word warn band fires"  "$(verdict "$longwarn")"   1
is "the sentence warn band fires"   "$(verdict "$sentwarn")"   1
is "the word-count warn band fires" "$(verdict "$budgetwarn")" 1

is "the sentence warn case has no long words"  "$(field "$sentwarn" long_pct)"   0.0
is "the sentence warn case sits in the band"   "$(field "$sentwarn" longest)"    21
is "the word warn case has no long words"      "$(field "$budgetwarn" long_pct)" 0.0
is "the word warn case sits in the band"       "$(field "$budgetwarn" words)"    150

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
and made a cake for my mum and dad.'
is "wrapping does not shorten a sentence" "$(field "$wrapped" longest)" "$(field "$sentence" longest)"
is "a wrapped long sentence still blocks" "$(verdict "$wrapped")"       2

# Blank lines, headings and list items still end a sentence, or a bullet list would read as one
# enormous sentence and block on length alone.
bullets='Here are things.

- the first thing
- the second thing
- the third thing'
is "bullets are separate sentences" "$(field "$bullets" sentences)" 4
is "a bullet list passes"           "$(verdict "$bullets")"         0

# Neither paragraph closes with punctuation, so the blank line is the only boundary. Joined they run
# to 38 words and block; split they pass. The bullet case does not cover this: list items carry
# their own boundary.
paragraphs='the cat sat on a mat and the dog ran to the shop and got a bun for tea

the cat sat on a mat and the dog ran to the shop and got a bun for tea'
is "a blank line ends a sentence" "$(field "$paragraphs" sentences)" 2
is "two loose paragraphs pass"    "$(verdict "$paragraphs")"         0

brackets='The (elephant) ate a banana. My (family) had a holiday. The (computer) rang the (telephone).'
is "brackets do not hide words"      "$(field "$brackets" words)"    "$(field "$longwords" words)"
is "brackets do not hide long words" "$(field "$brackets" long_pct)" "$(field "$longwords" long_pct)"

table='Here it is.

| Word | Meaning |
|---|---|
| elephant | big |
| banana | food |
| telephone | ring |
| computer | box |'
is "a table does not hide long words"   "$(verdict "$table")"      2
is "table cells stay out of the budget" "$(field "$table" words)"  3

# A fence that never closes fenced nothing off. Otherwise opening one and never closing it hides
# the whole rest of the reply.
unclosed='Here it is.

```bash
The elephant ate a banana. My family had a holiday. The computer rang the telephone.'
is  "an unclosed fence still counts"  "$(verdict "$unclosed")"      2
not "an unclosed fence hides nothing" "$(field "$unclosed" long_pct)" 0.0

# --- what gets stripped ---

incode='Run it.

```bash
utilise the comprehensive functionality
```'
is "words inside code are not counted" "$(field "$incode" long_pct)" 0.0
is "code-only text passes"             "$(verdict "$incode")"        0
is "inline code is not counted" "$(field 'Do not write `comprehensive` in a reply.' long_pct)" 0.0

# Names leave both sides of the share. In the denominator only, a wall of product names would
# water the percentage down.
names='We use PostgreSQL and TypeScript here.'
is "names are not long words"          "$(field "$names" long_pct)" 0.0
is "names still spend budget"          "$(field "$names" words)"    6
is "names leave the share denominator" "$(field "$names" measured)" 4

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

is "-cial words are two beats too" "$(field 'It was special and partial and social.' long_pct)" 0.0
is "but official is three"         "$(field 'It was official.' long_pct)" 33.3

# `patio` and `ratio` end at the vowel pair, where it really is two beats, so the -tion carve-out
# must not reach them. `studio` would mask this: its `dio` has no t/c/s/x and scores 3 either way.
not "-tio endings are three beats" "$(field 'The patio and the ratio.' long_pct)" 0.0
not "split-vowel words are three beats" \
    "$(field 'The manual usual video media serious various previous.' long_pct)" 0.0

# --- policy ---
# The failure message names something a user has. It used to cite a document that shipped nowhere.

[ -f "$root/lib/banned.txt" ] \
  && bad "a word list is back — read 'Word choice is judged, not listed' in plugins/signal/README.md first" \
  || ok "no word list ships"

padded='Additionally, it is worth noting that we should leverage this comprehensive functionality in order to facilitate a robust implementation.'
is "padded prose still blocks on shape alone" "$(verdict "$padded")" 2

# The gap we accepted, made executable. Adding a word list later means deleting a passing test.
shortodd='We shall hence deem it thus, whilst the crux is moot.'
is "short unusual words pass the counts" "$(verdict "$shortodd")"        0
is "and they really are short"           "$(field "$shortodd" long_pct)" 0.0

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
