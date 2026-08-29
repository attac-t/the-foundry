#!/bin/bash
# The brief a judge is handed: what reaches it, and what it refuses to pretend.
#
# Run through `sh`, never `bash` — that is what ships.
#
# Set RUNNER to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

runner="${RUNNER:-$here/bin/brief.sh}"
tmp="${TMPDIR:-/tmp}/panel-brief-$$"
mkdir -p "$tmp"

# A real directory holding no rounds. `next` refuses a path nobody made, so this must exist.
mkdir -p "$tmp/empty"
trap 'rm -rf "$tmp"' EXIT

brief() { sh "$runner" "$@" 2>/dev/null; }
brief_says() { sh "$runner" "$@" 2>&1; }
code_of() { "$@" >/dev/null 2>&1; printf '%s' "$?"; }

printf 'a\nbar\n' > "$tmp/charter"
printf 'the work\n' > "$tmp/work"

#
# A named file that cannot be read is not a file nobody named.
#
# `flag_value` ran inside `$(...)`, so its `exit 4` ended the subshell and the script carried on. An
# unreadable charter became an absent one, the brief said NOT SUPPLIED, and a handoff was recorded
# as though the bar had gone over.
a_named_file_that_cannot_be_read_stops_it() {
  is "an unreadable charter is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/nothing-here")" "4"
  has "and it says which file"  "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/nothing-here")" "is not a file"

  is "an unreadable work file is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/nothing-here")" "4"

  # A directory is readable. `cat` then failed, `main` carried on, and the brief printed an empty
  # charter block and returned 0.
  mkdir -p "$tmp/adir"
  is "a directory named as the charter is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/adir")" "4"
  has "and it says a directory is not one" \
      "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/adir")" "is not a file"

  #
  # The only case `-f` does not already catch: a real file the caller may not read.
  #
  # Skipped where the shell can read it anyway. Git Bash under an administrator ignores the mode,
  # and an assertion that passes for that reason is not an oracle.
  printf 'a bar\n' > "$tmp/shut"
  chmod 000 "$tmp/shut" 2>/dev/null
  if [ -r "$tmp/shut" ]; then
    skip "a file the caller may not read — this shell reads it anyway"
  else
    is "a file that cannot be read is refused" \
       "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/shut")" "4"
    has "and it says it cannot read it" \
        "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter "$tmp/shut")" "cannot read the charter"
  fi

  is "a flag with no value is refused"  "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --charter)" "2"
  is "an argument nobody defined is refused"  "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --wat x)" "2"
}
a_named_file_that_cannot_be_read_stops_it

#
# What the judge is actually given. A path it was told to open is not a thing it was given.
#
what_reaches_the_judge() {
  said=$(brief adversary 'a stranger can read it' --verdicts "$tmp/empty" --review R1 --charter "$tmp/charter" --work "$tmp/work")

  has "the role's own words"        "$said" "You are the **Adversary**"
  has "the clause it answers"       "$said" "a stranger can read it"
  has "the charter, read and printed" "$said" "bar"
  has "the work it answers"         "$said" "the work"
  has "a skill the role declares"   "$said" "Craft Verdict"
  has "which outcome words bind"    "$said" "VERDICT: revise"

  # Absent is legal. Silent is not.
  bare=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)
  has "a missing charter is said out loud" "$bare" "NOT SUPPLIED"
  is  "and that is not an error"           "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)" "0"

  is "no role is refused"  "$(code_of brief nobody 'a clause' --verdicts "$tmp/empty" --review R1)" "3"
  is "no clause is refused" "$(code_of brief adversary --verdicts "$tmp/empty" --review R1)" "2"
}
what_reaches_the_judge

#
# The round before this one. The Adversary refuses to judge a history it was told, and a file on the
# command line is a telling — any prose naming the review would pass.
#
the_round_before_comes_from_the_chain() {
  chain="$tmp/chain"
  mkdir -p "$chain/verdicts"
  printf 'round one of this review said revise\n' \
    | sh "$here/bin/verdicts.sh" record "$chain" adversary R1 >/dev/null 2>&1

  said=$(brief adversary 'a clause' --verdicts "$chain" --review R1)
  has "the prior round arrives in full"  "$said" "round one of this review said revise"
  has "and it names the record that was read"  "$said" "verdicts.sh prior"
  has "and it says who owns the chain"        "$said" "whoever convened it owns that"

  first=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)
  has "an empty chain says so, and names itself" "$first" "holds no round"
  is  "and that is not an error" \
      "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)" "0"

  # The reset anybody could take by leaving a flag out. The chain answers which round this is.
  is "a brief naming no chain is refused, never called round one" \
     "$(code_of brief adversary 'a clause')" "2"
  is "a round whose predecessor names another review is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$chain" --review R9)" "5"

  #
  # `next` pads to three digits. `$(( ))` reads a leading zero as octal, so round 010 arrived as 8
  # and rounds 008 and 009 were arithmetic errors.
  #
  deep="$tmp/deep"
  mkdir -p "$deep"
  i=1
  while [ "$i" -le 9 ]; do
    printf 'round %s of review R1\n' "$i" | sh "$here/bin/verdicts.sh" record "$deep" adversary R1 >/dev/null 2>&1
    i=$((i + 1))
  done

  is "the chain is nine rounds deep" "$(sh "$here/bin/verdicts.sh" next "$deep" 2>/dev/null)" "010"
  has "and the brief calls this round ten" \
      "$(brief adversary 'a clause' --verdicts "$deep" --review R1)" "round [10]"
}
the_round_before_comes_from_the_chain

summary "brief"