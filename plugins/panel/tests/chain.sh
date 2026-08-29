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

# A verdict as `/verdict` records one: numbered, roled, and naming what it judged.
verdict() {
  mkdir -p "$1"
  printf '# Verdict %s — %s\n\nJudged: %s\n\n## Verdict: REVISE\n' "$2" "$3" "$4" \
    > "$1/$2-$3-verdict.md"
}

echo "chain"

a=$tmp/review-a
b=$tmp/review-b

# --- numbering ---

mkdir -p "$a" "$b"

# A chain with no rounds is round one. A path nobody made is a mistake, and `next` now tells them
# apart — the same directory answered both before, and a fifth round reached a judge as its first.
is "an empty chain starts at round 1" "$(chain next "$a")" "001"
has   "and says it is a new chain" "$(chain_says next "$a")" "this is a new chain"

verdict "$a" 001 adversary "the charter"
is "and counts on from what is there" "$(chain next "$a")" "002"

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

verdict "$b" 001 adversary "the charter"
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
verdict "$c" 001 adversary "the policy allowlist"

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

# `2>/dev/null` because this is the first record of a new chain and `next_round` says so, which is
# the point of it and not what this check is asking about.
is "the first record lands at round 1" \
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
  is "a real directory holding no rounds is round one" \
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
      "$(chain_says prior "$c" 2 R1)" "another review's chain"

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

summary "chain"
