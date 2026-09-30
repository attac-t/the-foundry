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

  # Floor's adapters read the last line that carries anything. A brief asking for words after the
  # verdict asks the judge to leave none. #1056.
  is  "the verdict line is the last thing it asks for" \
      "$(printf '%s\n' "$said" | awk 'NF { last = $0 } END { sub(/^[ \t]+/, "", last); print last }')" "VERDICT: revise"
  has "and it says nothing may follow it" "$said" "nothing after it"

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

  # A chain nobody made cannot say which round this is, and a brief that cannot ask stops. The
  # sentence is checked as well as the code: the two refusals after it also answer 5, so an exit code
  # alone cannot say which of the three fired.
  is "a chain nobody made stops the brief" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/no-such-chain" --review R1)" "5"
  has "and says the chain could not say which round" \
      "$(brief_says adversary 'a clause' --verdicts "$tmp/no-such-chain" --review R1)" "could not say which round"

  # The chain's own reason, not this file's guess at it. `2>/dev/null` on the `round` call hid
  # `drop the [R2]` and printed `could not say which round` over the top of it.
  is "a review carrying a round stops the brief" \
     "$(code_of brief adversary 'a clause' --verdicts "$chain" --review 'R9 R2')" "5"
  has "and the chain's own reason reaches the caller" \
      "$(brief_says adversary 'a clause' --verdicts "$chain" --review 'R9 R2')" "the round is written here"

  #
  # A review with no record in a directory is on round one, whatever else the directory holds. That
  # is what two reviews in one directory means, and R9 has never been judged here.
  #
  # It is not a way to escape a prior. The escape was always the `--verdicts` flag, and `say_the_prior`
  # says so out loud: nothing here can know this is the chain for your review.
  is "a review new to a chain is round one, not a refusal" \
     "$(code_of brief adversary 'a clause' --verdicts "$chain" --review R9)" "0"
  has "and the brief says which review holds no round" \
      "$(brief adversary 'a clause' --verdicts "$chain" --review R9)" "holds no round for [R9]"

  #
  # Nine rounds deep, where `next` would have padded to `010` and `$(( ))` read the leading zero as
  # octal — round 010 arrived as 8, and 008 and 009 were arithmetic errors. `round` answers plainly.
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

#
# The commit, never the worktree alone. A judge reads files there for as long as it works, and a
# commit landing meanwhile changes what it reads — one verdict named three heads over seventeen
# minutes, and the judge only knew from the reflog.
#
a_brief_names_the_commit_it_was_built_from() {
  tree=$tmp/tree
  mkdir -p "$tree"
  git -C "$tree" init -q >/dev/null 2>&1
  printf 'one\n' > "$tree/file"
  git -C "$tree" add -A >/dev/null 2>&1
  git -C "$tree" -c user.email=a@b.c -c user.name=a commit -qm one >/dev/null 2>&1
  head=$(git -C "$tree" rev-parse HEAD 2>/dev/null)

  said=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --worktree "$tree")
  has "the brief names the commit it was built from" "$said" "$head"
  has "and the worktree that commit is in"           "$said" "$tree"
  has "and says the recorder is told the same"       "$said" "refuses your verdict"

  # Absent is legal here as it is for the bar. Silent is not: a brief naming no tree leaves nobody
  # able to say afterwards whether one moved.
  bare=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)
  has "a brief naming no tree says so" "$bare" "NOT SUPPLIED"

  # A directory with no commit in it is not a worktree, and a brief that printed an empty commit
  # would hand the recorder nothing to check.
  mkdir -p "$tmp/norepo"
  is "a worktree that is no checkout is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --worktree "$tmp/norepo")" "6"
  is "a worktree that is not there is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --worktree "$tmp/nowhere")" "6"
  is "a worktree flag with no value is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --worktree)" "2"
}
a_brief_names_the_commit_it_was_built_from

#
# The grade, and the one line a convener used to type in its place.
#
# **The judge was handed *the 25 gates at `<head>` — ALL GREEN*** and could weigh it only as a claim.
# A grade keeps a log; the log names each gate, the code it answered with and what it printed. That
# is what goes over now.
#
a_grade_comes_from_the_log_it_kept() {
  kept="$tmp/kept"
  mkdir -p "$kept"
  printf 'the floor suite ran nine mutants\nPROVED NOTHING — the experiments above never ran\n' \
    > "$kept/floor.log"

  # The ledger's own shape: seven tab-separated fields, `machine` for a gate that ran. A red row ends
  # `kept in <dir>`, which is where that gate's own output went.
  printf '2026-09-30T00:00:00Z\tmachine\t01\tgates\t1\t89775ab5c31ea1266b3be04be15420edac0120a8\t  PASS  shell   FAIL  floor  1 RED kept in %s\n' "$kept" > "$tmp/ledger"
  printf '2026-09-30T00:00:01Z\tmachine\t01\tagree\t0\t89775ab5c31ea1266b3be04be15420edac0120a8\t  PASS  CONTRIBUTING AGREED 25 gates\n' >> "$tmp/ledger"
  printf '2026-09-30T00:00:02Z\tjudged\t01\ta clause\t0\t89775ab\tadversary said approve\tadversary\n' >> "$tmp/ledger"

  printf 'the 25 gates at 89775ab — ALL GREEN\n' > "$tmp/typed"

  said=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence "$tmp/ledger")

  has "every gate the log holds is named"    "$said" "gates —"
  has "and the one beside it"                "$said" "agree —"
  has "the exit code the gate answered with" "$said" "exit 1"
  has "and a passing gate's own code"        "$said" "exit 0"
  has "the commit the grade read"            "$said" "89775ab"
  has "what the log kept of the output"      "$said" "PASS  CONTRIBUTING"

  # `kept in <dir>` is a path, and this file's own header says a path is not a handoff.
  has "the failing gate's own last lines travel" "$said" "PROVED NOTHING"
  has "and the gate they belong to is named"     "$said" "floor — the last"

  # A verdict sits in the same file and ran nothing.
  lacks "a verdict row is not read as a gate" "$said" "adversary said approve"

  #
  # The refusal. A grade typed into the work file, with no log it was read from.
  #
  is "a work file claiming a grade with no log is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/typed")" "7"
  has "and it says which word it read" \
      "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/typed")" "ALL GREEN"
  has "and names the flag that settles it" \
      "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/typed")" "--evidence"

  is "the same work file with the log is not refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/typed" --evidence "$tmp/ledger")" "0"

  # The other shout a grade's record makes. One word is not the rule — the grade's vocabulary is.
  printf 'the suite went 1 RED at 89775ab\n' > "$tmp/typedred"
  is "a red grade typed with no log is refused too" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/typedred")" "7"

  # Prose claiming no grade is not a grade. A refusal firing here would block an honest brief.
  is "a work file claiming no grade needs no log" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --work "$tmp/work")" "0"

  #
  # A log holding no gate is no grade. Passing one claims a grade a second way, and the brief would
  # have printed an empty block over the top of the claim.
  #
  printf '2026-09-30T00:00:02Z\tjudged\t01\ta clause\t0\t89775ab\tadversary said approve\tadversary\n' \
    > "$tmp/nogates"
  is "a log that records no gate is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence "$tmp/nogates")" "7"
  has "and it says the log records no gate" \
      "$(brief_says adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence "$tmp/nogates")" "records no gate"

  is "a log nobody can read is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence "$tmp/nothing-here")" "4"
  is "an evidence flag with no value is refused" \
     "$(code_of brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence)" "2"

  # Absent is legal here as it is for the bar and the tree. Silent is not.
  bare=$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1)
  has "a brief naming no grade says so" "$bare" "No gate ran for you"

  # The path the record names, gone. A brief pointing at it and reading nothing must say which.
  printf '2026-09-30T00:00:00Z\tmachine\t01\tgates\t1\t89775ab\t1 RED kept in %s\n' "$tmp/nowhere" \
    > "$tmp/lostlogs"
  has "a kept log that is no longer there is said out loud" \
      "$(brief adversary 'a clause' --verdicts "$tmp/empty" --review R1 --evidence "$tmp/lostlogs")" \
      "It is not there now"
}
a_grade_comes_from_the_log_it_kept

summary "brief"