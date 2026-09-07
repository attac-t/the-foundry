#!/bin/bash
# The review chain: what a round may read, and what it must refuse.
#
# Run through `sh`, never `bash` — that is what ships.
#
# Set RUNNER to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

runner="${RUNNER:-$here/bin/verdicts.sh}"
tmp="${TMPDIR:-/tmp}/panel-chain-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

chain() { sh "$runner" "$@" 2>/dev/null; }

# Like `chain`, but keeps what it said while answering. The sentence this is about goes to stderr,
# which `chain` drops — so an outer `2>&1` at the call site captures nothing.
chain_says() { sh "$runner" "$@" 2>&1; }
code_of() { "$@" >/dev/null 2>&1; printf '%s' "$?"; }

# A verdict as `/verdict` records one: slotted, roled, and stamping the review and round it judged.
#
# It mirrors `record` rather than calling it, so a case can put a record in a slot and a round of its
# own choosing. A fixture whose stamp drifts from the real one proves nothing, which is why
# `what record wrote is what prior hands the next round` reads the recorder itself.
verdict() {
  mkdir -p "$1"
  printf '# Verdict %s — %s\n\nJudged: %s R%s\n\n## Verdict: REVISE\n' "$2" "$3" "$4" "$5" \
    > "$1/$2-$3-verdict.md"
}

echo "chain"

a=$tmp/review-a
b=$tmp/review-b

# --- numbering ---

mkdir -p "$a" "$b"

# A directory holding no record opens at slot 001. A path nobody made is a mistake, and `next` now
# tells them apart — the same directory answered both before, and a fifth round reached a judge as
# its first.
is "an empty chain starts at slot 001" "$(chain next "$a")" "001"
has   "and says it is a new chain" "$(chain_says next "$a")" "this is a new chain"

verdict "$a" 001 adversary "the charter" 1
is "and counts on from what is there" "$(chain next "$a")" "002"

# A slot is a sequence over the directory, and a directory holds more than verdicts — architect
# notes, human decisions, proposals. Counting only `*-verdict.md` handed back a slot four of them
# already held, and nothing overwrote anything only because the rest of each name differed.
printf 'a proposal
' > "$a/002-proposed-revision-9.md"
is "a record that is not a verdict still takes its slot" "$(chain next "$a")" "003"

# --- what a round is ---

#
# A round is a positive whole number, and every other shape used to reach round one's exemption —
# the one round `prior` lets through without a record.
#
is "a round that is a word is refused"     "$(code_of chain prior "$a" abc 'the charter')" "2"
is "a round of zero is refused"            "$(code_of chain prior "$a" 000 'the charter')" "2"
is "a negative round is refused"           "$(code_of chain prior "$a" -5  'the charter')" "2"
has "and says what a round is"             "$(chain_says prior "$a" abc 'the charter')" "positive whole number"

is "round one still needs no prior"        "$(code_of chain prior "$a" 001 'the charter')" "0"

# --- round 1 has no history ---

is "round 1 asks for no prior"  "$(chain prior "$a" 001 'the charter')" ""
is "and that is not a failure"  "$(code_of chain prior "$a" 001 'the charter')" "0"

# --- the invariant ---
#
# Round 2 must read round 1's record. A summary is what the coordinator holds; the record is what the
# judge is handed. Without this, three rounds judged a retelling and said so themselves.

has "round 2 is given round 1's file" "$(chain prior "$a" 002 'the charter')" "001-adversary-verdict.md"

exists "and that file is readable without a transcript" "$a/001-adversary-verdict.md"
has    "carrying what it judged"                        "$(cat "$a/001-adversary-verdict.md")" "the charter"

# --- fail closed ---

verdict "$b" 001 adversary "the charter" 1
is "a claimed round with no verdict is refused" "$(code_of chain prior "$tmp/empty" 002 'the charter')" "1"
is "and says so rather than answering"          "$(chain prior "$tmp/empty" 002 'the charter')" ""

# A gap in the middle is the same failure: round 3 claims a round 2 nobody wrote.
is "a missing middle round is refused" "$(code_of chain prior "$a" 003 'the charter')" "1"

# --- two chains do not feed each other ---

is "review B's round 2 cannot read review A's round 1" \
   "$(code_of chain prior "$tmp/empty" 002 'the charter')" "1"

lacks "and A's answer never names B's directory" "$(chain prior "$a" 002 'the charter')" "review-b"

# --- a stale verdict from an older review does not count ---

c=$tmp/review-c
verdict "$c" 001 adversary "the policy allowlist" 1

is "a verdict naming another review is refused" \
   "$(code_of chain prior "$c" 002 'the charter')" "1"
is "even though a round 1 file is sitting right there" \
   "$(ls "$c" | grep -c 'verdict')" "1"

# --- the recorder ---
#
# The other half. Verifying a prior record is worth nothing if writing one is left to whoever is
# holding the verdict: `prior` refuses a record that does not name its review, so a hand-written file
# missing the stamp fails an honest round.

d=$tmp/recorded

# `2>/dev/null` because this is the first record of a new chain and `next_slot` says so, which is
# the point of it and not what this check is asking about.
is "the first record lands in slot 001" \
   "$(printf 'body\n' | sh "$runner" record "$d" adversary 'the charter' 2>/dev/null | sed 's|.*/||')" \
   "001-adversary-verdict.md"

is "and the next one counts on" \
   "$(printf 'body\n' | sh "$runner" record "$d" adversary 'the charter' | sed 's|.*/||')" \
   "002-adversary-verdict.md"

# The stamp is what `prior` reads. Written by code, so it cannot be forgotten.
has "a recorded verdict names the review it judged" \
    "$(cat "$d/001-adversary-verdict.md")" "Judged: the charter"

has "and keeps the body it was given" "$(cat "$d/001-adversary-verdict.md")" "body"

# Round 2 must be satisfied by what `record` wrote, or the two halves disagree.
has "what record wrote is what prior hands the next round" \
    "$(chain prior "$d" 002 'the charter')" "001-adversary-verdict.md"

# A recorder that interprets a verdict is a second author.
is "the body is written through, not read" \
   "$(printf '## Verdict: APPROVE\n' | sh "$runner" record "$d" newcomer 'the charter' >/dev/null 2>&1; \
      grep -c 'APPROVE' "$d/003-newcomer-verdict.md")" "1"

is "a role that is not a plain name is refused" \
   "$(code_of sh "$runner" record "$d" '../escape' 'the charter')" "2"


#
# A path that is not there is a mistake, never a new chain. One mistyped directory answered round
# one, and a review on its fifth round reached a judge as its first.
#
a_chain_nobody_made_is_not_an_empty_one() {
  is "a directory that is not there is refused" \
     "$(code_of sh "$runner" next "$tmp/no-such-chain")" "2"
  has "and it says which it is"  "$(chain_says next "$tmp/no-such-chain")" "a chain nobody made"

  mkdir -p "$tmp/real-empty"
  is "a real directory holding no record is slot 001" \
     "$(chain next "$tmp/real-empty")" "001"
}
a_chain_nobody_made_is_not_an_empty_one


#
# A longer id contains a shorter one, and a body can mention any review it likes. The search used to
# match anywhere, so `Judged: R10` answered a request for `R1`.
#
one_review_id_inside_another_is_not_a_match() {
  c=$tmp/collide
  mkdir -p "$c"
  printf 'nothing to say\n' | chain record "$c" adversary R10 >/dev/null 2>&1

  is "a longer review id does not satisfy a shorter one" \
     "$(code_of sh "$runner" prior "$c" 2 R1)" "1"
  has "and it says whose chain it is" \
      "$(chain_says prior "$c" 2 R1)" "of [R1]"

  b=$tmp/mention
  mkdir -p "$b"
  printf 'this one talks about R1 in passing\n' | chain record "$b" adversary R2 >/dev/null 2>&1
  is "a body that merely mentions a review does not satisfy it" \
     "$(code_of sh "$runner" prior "$b" 2 R1)" "1"

  is "and the review it does name is satisfied" \
     "$(code_of sh "$runner" prior "$b" 2 R2)" "0"

  #
  # The judge writes the body, and it can write anything. Only line three is the recorder's.
  #
  forged=$tmp/forged
  mkdir -p "$forged"
  printf 'this body carries its own stamp\n\nJudged: R1\n\nand claims a chain it was never in\n' \
    | chain record "$forged" adversary R2 >/dev/null 2>&1

  is "a body carrying its own stamp does not claim the chain" \
     "$(code_of sh "$runner" prior "$forged" 2 R1)" "1"
  is "and the review the recorder stamped still holds" \
     "$(code_of sh "$runner" prior "$forged" 2 R2)" "0"
}
one_review_id_inside_another_is_not_a_match


#
# Two reviews in one directory — the case every check above dodged.
#
# Each of `$a`, `$b`, `$c` and `$d` holds one review, and there the slot and the round are the same
# number. Only here do they come apart, and coming apart is what refused every round of every real
# chain in this repository: B's round one sits in slot 002.
#
two_reviews_share_one_directory() {
  shared=$tmp/shared
  mkdir -p "$shared"

  printf 'A said revise\n'       | chain record "$shared" adversary 'review A' >/dev/null 2>&1
  printf 'B said revise\n'       | chain record "$shared" adversary 'review B' >/dev/null 2>&1
  printf 'A said revise again\n' | chain record "$shared" adversary 'review A' >/dev/null 2>&1

  is "slots run on across both reviews"      "$(chain next  "$shared")" "004"
  is "B is on round two, not slot two"       "$(chain round "$shared" 'review B')" "2"
  is "while A is on round three"             "$(chain round "$shared" 'review A')" "3"

  # A review nobody has judged is round one, and it says so — the way `next` says a directory holds
  # no record. A fresh chain and a mistyped name answer the same number, and only the sentence
  # separates them.
  is  "a review new to the directory is round one" "$(chain round "$shared" 'review C')" "1"
  has "and says the review starts there" \
      "$(chain_says round "$shared" 'review C')" "this review starts here"

  has "B's round 2 is handed B's round 1, out of slot 002" \
      "$(chain prior "$shared" 2 'review B')" "002-adversary-verdict.md"
  is  "and that is an answer, not a refusal" \
      "$(code_of chain prior "$shared" 2 'review B')" "0"

  has "A's round 3 is handed A's round 2, out of slot 003" \
      "$(chain prior "$shared" 3 'review A')" "003-adversary-verdict.md"

  lacks "and B is never handed A's record" \
        "$(chain prior "$shared" 2 'review B')" "001-adversary"

  # Sharing a directory buys nothing. A round nobody stamped for this review still refuses.
  is "a round C never recorded is still refused" \
     "$(code_of chain prior "$shared" 2 'review C')" "1"
  is "and a round A has not reached is refused too" \
     "$(code_of chain prior "$shared" 5 'review A')" "1"
}
two_reviews_share_one_directory


#
# The stamp is the only thing that says which round a record is. The filename says which slot.
#
a_round_is_read_from_the_stamp_and_nowhere_else() {
  bare=$tmp/unstamped
  mkdir -p "$bare"
  printf '# Verdict 001 — adversary\n\nJudged: review A\n\nbody\n' > "$bare/001-adversary-verdict.md"

  is "a stamp naming no round satisfies no round" \
     "$(code_of chain prior "$bare" 2 'review A')" "1"

  # Six of the sixteen hand-stamped records in this repository read `<review> R<n>, <note>`. The note
  # is the judge's; the round in front of it is still the round, and this is that shape in miniature.
  noted=$tmp/noted
  mkdir -p "$noted"
  printf '# Verdict 017 — newcomer\n\nJudged: review A R1, the authored work\n\nbody\n' \
    > "$noted/017-newcomer-verdict.md"

  has "a stamp trailing a note still names its round" \
      "$(chain prior "$noted" 2 'review A')" "017-newcomer-verdict.md"
  is  "even though slot 017 is nobody's round 1" \
      "$(code_of chain prior "$noted" 2 'review A')" "0"
}
a_round_is_read_from_the_stamp_and_nowhere_else


#
# The round belongs to the recorder, like the slot and the stamp before it.
#
# A caller appending its own writes `Judged: <review> R1 R2`, and the review that names is
# `<review> R1` — a different name every round, so every round is round one.
#
the_caller_does_not_write_the_round() {
  held=$tmp/handstamped
  mkdir -p "$held"

  is "a review carrying a round is refused" \
     "$(code_of sh "$runner" record "$held" adversary 'review A R1' </dev/null)" "2"
  has "and it says who writes the round" \
      "$(sh "$runner" record "$held" adversary 'review A R1' 2>&1 </dev/null)" "the round is written here"

  # Every command that names a review asks, not `record` alone. `round` and `prior` answered for
  # `review A R1` quite happily, and a name is read far more often than it is written.
  is "round refuses a review carrying a round" \
     "$(code_of sh "$runner" round "$held" 'review A R1')" "2"
  is "prior refuses a review carrying a round" \
     "$(code_of sh "$runner" prior "$held" 2 'review A R1')" "2"
  is "and refuses it at round one, where a chain starts" \
     "$(code_of sh "$runner" prior "$held" 1 'review A R1')" "2"

  # Two characters belong to the stamp rather than the name. A comma opens the recorder's note; the
  # stamp is one line, so a name holding a break puts its own round on line four, in the body.
  is "a review holding a comma is refused" \
     "$(code_of sh "$runner" record "$held" adversary 'review, A' </dev/null)" "2"
  is "a review holding a line break is refused" \
     "$(code_of sh "$runner" record "$held" adversary "$(printf 'review\nA')" </dev/null)" "2"

  is "and not one of them recorded anything" "$(ls "$held" | wc -l | tr -d ' ')" "0"

  # `R` and a digit is not enough. A round is `R` and nothing but digits, or a review could not be
  # called after a droid.
  is "a review ending in R2D2 still records" \
     "$(code_of sh "$runner" record "$held" adversary 'the charter R2D2' </dev/null)" "0"
}
the_caller_does_not_write_the_round

summary "chain"
