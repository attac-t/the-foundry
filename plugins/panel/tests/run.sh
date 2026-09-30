#!/bin/bash
#
# Run the suite, then check the suite can fail.
#
# A green suite proves nothing until you have watched it go red, so each rule is broken on purpose
# and every break must take the suite down with it.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/panel-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

#
# A mutant that never answers is not a mutant the suite caught. Copied from floor's audit rather
# than shared, because a plugin ships alone and a suite needing a
# sibling breaks the thing it tests.
#
# Timeout exits 124 when it kills one. Inverting that gives zero, which is this file's word for the
# suite noticing, so a mutant that hung would be filed as caught.
#
moot() { [ "$failed" -eq 0 ] && failed=3; printf '  MOOT  %s\n' "$1"; }

# Eight times the slowest mutant measured here, which was about fifteen seconds. A deadline reached
# too early is a verdict nobody earned.
deadline=${FOUNDRY_AUDIT_DEADLINE:-120}

bounded() {
  local seconds="$1"
  shift

  command -v timeout >/dev/null 2>&1 && { timed "$seconds" "$@"; return; }

  polled "$seconds" "$@"
}

# A real 2 from the command reads as a deadline. These suites answer 0 or 1, so the collision is a
# shape they do not have.
timed() {
  local seconds="$1" said
  shift

  timeout "$seconds" "$@" >/dev/null 2>&1
  said=$?

  [ "$said" -eq 124 ] && return 2
  return "$said"
}

# macOS ships no timeout unless someone installed the GNU tools, so without
# this there is no bound at all there. Wait with a deadline is bash
# 4.3 and macOS ships 3.2, which is the same platform twice.
polled() {
  local seconds="$1" job waited=0
  shift

  "$@" >/dev/null 2>&1 &
  job=$!

  while kill -0 "$job" 2>/dev/null; do
    [ "$waited" -ge "$seconds" ] && { kill -9 "$job" 2>/dev/null; wait "$job" 2>/dev/null; return 2; }
    sleep 1
    waited=$((waited + 1))
  done

  wait "$job"
}

# One shape for every noticer here. The suite must go red against the mutant, and 2 says it never
# answered at all — which is not the suite answering badly.
red_against() {
  local suite="$1" said
  shift

  bounded "$deadline" env "$@" bash "$root/tests/$suite"
  said=$?

  [ "$said" -eq 2 ] && return 2
  [ "$said" -eq 0 ] && return 1
  return 0
}

bash "$root/tests/brief.sh" || failed=1
echo

echo "audit — break the brief, the suite must notice"

caught_brief() { red_against brief.sh RUNNER="$tmp/$1/bin/brief.sh"; }

# The role, its skills and every file beside it travel with the mutant. `brief.sh` reads all three
# from its own parent, so a copy missing one fails for want of it, never for the rule under test.
stage_brief() {
  rm -rf "${tmp:?}/$1" && mkdir -p "$tmp/$1" \
    && cp -r "$root/agents" "$root/skills" "$root/bin" "$tmp/$1/"
}

#
# The control, run once before any break. An unbroken copy staged as each break is must pass.
# It once failed nineteen checks for want of `verdicts.sh`, so every break read as caught. #1057.
#
refuse_a_staging_that_breaks_the_brief() {
  stage_brief control || { bad "the brief could not be staged, so no break below proves anything"; return; }
  caught_brief control
  [ "$?" -eq 1 ] && { printf '  ok    an unbroken copy, staged as each break is, passes\n'; return; }

  bad "an unbroken copy fails the suite, so no break below proves anything"
}
refuse_a_staging_that_breaks_the_brief

wreck_brief() {
  local name="$1" tag="$2" mutation="$3"

  stage_brief "$tag" || { bad "$name — could not stage"; return; }
  sed "$mutation" "$root/bin/brief.sh" > "$tmp/$tag/bin/brief.sh" \
    || { bad "$name — sed failed, so this proves nothing"; return; }
  [ -s "$tmp/$tag/bin/brief.sh" ] || { bad "$name — the mutant is empty"; return; }
  cmp -s "$tmp/$tag/bin/brief.sh" "$root/bin/brief.sh" \
    && { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught_brief "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken brief"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac

  printf '  ok    %s\n' "$name"
}

#
# The finding that put this suite here. A named file nobody can read became a file nobody named, and
# the handoff was recorded as though the bar had gone over.
#
# `-r` alone has no mutant. `-f` catches every case a test can build, and the one case left — a real
# file the caller may not read — is skipped wherever the shell reads it anyway. A break nothing can
# kill is not a proof, so it is not listed.
wreck_brief "a directory passing for a charter is caught" \
  dirbar 's#^    \[ -f "\$2" \] || fail 4 "the \$1 at \[\$2\] is not a file"$#    :#'

#
# A chain that cannot say which round this is, carrying on anyway: the fail-closed rule inverted.
# `and says the chain could not say which round` kills it. The exit-code check beside it cannot.
#
# By pattern, not by line number. It named lines 169 and 172, and 172 had long since stopped being a
# refusal — a mutant aimed at the wrong line proves whatever that line happens to do.
#
# The two refusals after this one have no mutant. `round` and `prior` read the same stamps, so a
# chain that answered the first cannot fail the second, and nothing a test can build reaches them.
wreck_brief "a chain that records nothing answered as a prior round is caught" \
  noprior 's#^        || fail 5 "the chain at .*$#        || true#'

wreck_brief "a role's declared skills quietly dropped is caught" \
  noskills 's#^    declared_skills "\$file" | while IFS= read -r skill; do#    false | while IFS= read -r skill; do#'

#
# Words asked for after the verdict line. Every word is still in the brief, in the wrong order, so
# only the check on its last line can see it. #1056.
wreck_brief "a paragraph asked for after the verdict line is caught" \
  paraafter '/^    VERDICT: revise$/a\
Then one paragraph saying why.'

#
# The commit dropped from the block that names the tree. A path is what the brief always gave, and
# a path is the fault: the judge reads whatever is there while it reads.
wreck_brief "a brief naming a worktree and no commit is caught" \
  nocommit 's|^    printf .    commit %s.*$|    :|'

#
# The grade typed rather than read. The line a convener wrote was *the 25 gates at `<head>` — ALL
# GREEN*, and a judge could weigh that only as a claim. With the refusal gone the claim goes over.
wreck_brief "a grade typed into the work file is caught" \
  typedgrade 's#^    said=$(grade_word_in "$work")$#    said=#'

# Fail closed, the other half. A log recording no gate is no grade, and passing one would have
# printed an empty block over the top of the claim it was meant to answer.
wreck_brief "a log recording no gate accepted as a grade is caught" \
  nogaterows 's#^    \[ -n "$graded" \] || fail 7 #    [ -n "$graded" ] || : #'

#
# The exit code dropped from a gate's row. Every gate name is still there, so only the check reading
# the code can see it — and the code is the half a convener's summary always lost.
wreck_brief "a grade carrying names and no exit codes is caught" \
  nocodes 's#— exit %s, at %s#— at %s#'

#
# A failing gate's own output left where the log put it. `kept in <dir>` is a path, and this file's
# header says a path is not a handoff: the judge is handed nothing and cannot tell.
wreck_brief "a failing gate's kept log pointed at instead of carried is caught" \
  pointedat 's#^    kept_dirs "$evidence" | while IFS= read -r where; do#    false | while IFS= read -r where; do#'

# A verdict and a handoff live in the same ledger and neither ran anything. Read as gates, they
# arrive as rows a judge would weigh as a grade.
wreck_brief "a ledger read whole instead of its gates is caught" \
  everyrow 's#\$2 != "machine" { next }#$2 == "" { next }#'

#
# The grade of another tree. `locate_the_commit` holds the head and every gate row names what it
# graded, and nothing compared them — so a sibling run's green ledger printed under this head.
wreck_brief "a grade of a commit the tree is not on is caught" \
  othertree 's#^    at=$(a_ref_that_is_not "$evidence" "$commit")$#    at=#'

# The other half of that check. An exact match refuses an honest abbreviated ref, which is the
# check failing rather than the grade.
wreck_brief "a commit compared without allowing an abbreviation is caught" \
  exactref 's#index(head, $6) == 1 || index($6, head) == 1 { next }#$6 == head { next }#'

#
# The ledger appends, so a gate regraded holds two rows. Reporting the first hands the judge the
# answer that was replaced, and nothing on the page says so.
wreck_brief "a regraded gate reported at its first row is caught" \
  firstrow 's#{ times\[$4\]++; code\[$4\] = $5; at\[$4\] = $6; why\[$4\] = $7 }#{ times[$4]++; if (times[$4] == 1) { code[$4] = $5; at[$4] = $6; why[$4] = $7 } }#'

# Collapsing to the last row is right. Doing it in silence is not — a gate that went red before it
# went green is the thing a judge most wants to know.
wreck_brief "a gate graded twice in silence is caught" \
  quietregrade 's#graded %s times — this is the last of them#this is the last of them#'

#
# The word inside a word. PASS matched BYPASS and FAIL matched FAILING, so a work file writing
# ordinary prose about a gate was refused as a grade claim.
wreck_brief "a grade word matched inside a longer word is caught" \
  insideword 's#padded ~ /\[^A-Za-z\]PASS\[^A-Za-z\]/#$0 ~ /PASS/#'

#
# The provenance no mechanism here can give. A row is a line of text, and swearing it was not
# retyped told the judge not to doubt the one thing it should.
wreck_brief "a brief vouching for a log it never checked is caught" \
  vouched 's#^.*Nothing here proves it is one.*$#    :#'

# `kept in` first rather than last. A gate printing the phrase itself took the path, and the judge
# was told the logs were gone.
wreck_brief "the first kept-in path taken instead of the last is caught" \
  firstkept 's#^            while (match(rest, /kept in /)) {#            if (match(rest, /kept in /)) {#'

bash "$root/tests/chain.sh" || failed=1
echo

echo "audit — break the chain, the suite must notice"

caught() { red_against chain.sh RUNNER="$tmp/$1/bin/verdicts.sh"; }

#
# Break one rule and require the suite to notice.
#
# Three ways a mutant proves nothing: sed fails, the output comes out empty, or the pattern never
# matched. `cmp` alone catches only the third — an empty file differs from the original too.
#
wreck() {
  local name="$1" tag="$2" mutation="$3"

  rm -rf "${tmp:?}/$tag" && mkdir -p "$tmp/$tag/bin" || { bad "$name — could not stage"; return; }
  sed "$mutation" "$root/bin/verdicts.sh" > "$tmp/$tag/bin/verdicts.sh" \
    || { bad "$name — sed failed, so this proves nothing"; return; }
  [ -s "$tmp/$tag/bin/verdicts.sh" ] || { bad "$name — the mutant is empty"; return; }
  cmp -s "$tmp/$tag/bin/verdicts.sh" "$root/bin/verdicts.sh" \
    && { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken chain"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac

  printf '  ok    %s\n' "$name"
}

# The whole point. A claimed prior round with no record must refuse, not answer.
wreck "a chain that answers without a prior verdict is caught" \
  openchain 's|^        note "round $round of .*$|        return 0|'

# A verdict from another review is another chain's history. Accepting it lets a stale record from an
# older charter, or the review sharing the directory, satisfy a round it never saw.
wreck "a chain that accepts any review's verdict is caught" \
  anyreview 's,\[ "${stamp#\* }" = "$2" \] || continue,true,'

# The other half, and it fails the other way. Counting another review's rounds as this review's puts
# a chain ahead of itself, so its next round asks for a predecessor nobody wrote.
wreck "a chain that counts any review's rounds is caught" \
  countsany 's,\[ "${stamp#\* }" = "$2" \] \&\& printf,true \&\& printf,'

# A record is the prior of exactly one round. Any record of this review satisfying any round is a
# chain with no order in it — round 9 handed round 1, and a gap in the middle handed anything.
wreck "a chain that accepts a record from any round is caught" \
  anyprior 's,\[ "${stamp%% \*}" = "$3" \] || continue,true,'

# A round that is not a round reached the exemption round 1 has. Exit 2 is *asked for something this
# does not do*; 1 is *a prior was claimed and nothing records it*. Different remedies.
wreck "a round that is not a round answered as round one is caught" \
  anyround 's|^    refuse_unless_a_round "$round"$|    :|'

# Round 1 has no prior and must not be made to invent one; every later round must look.
wreck "a chain where no round ever looks back is caught" \
  neverlook 's#^    \[ "$want" -ge 1 \] .*$#    return 0#'

# The slot is how two records keep out of each other's filename. Stuck, every record is the first.
wreck "a chain that always reports slot 001 is caught" \
  stuckone 's|^    printf .%03d\\n. "$(( .*$|    printf "001\\n"|'

# A new chain and a mistyped path are the same directory to `next`, and an empty chain is the one
# case `prior` exempts. It cannot tell them apart; staying quiet about which it chose is what let it
# matter.
wreck "a new chain that says nothing is caught" \
  quietstart 's|note "no records at |: "|'

# The same silence, one level down. A review nobody has judged and a review whose name was mistyped
# both answer round one, and only the sentence tells a convener which they have.
wreck "a review starting a chain in silence is caught" \
  quietround 's|note "no round for |: "|'

# The stamp is the whole reason `prior` can tell one chain from another. A recorder that omits it
# writes verdicts that fail the next honest round.
wreck "a recorder that does not stamp the review is caught" \
  nostamp 's|^        printf .Judged: %s R%s.*$|        :|'

# The other half of the stamp. Without the round, a record says which review it judged and nothing
# about where it sits, so the next round finds no predecessor.
wreck "a recorder that stamps no round is caught" \
  noround 's|^        printf .Judged: %s R%s.*$|        printf "Judged: %s\\n\\n" "$review"|'

# Two records writing the same file is one record overwritten.
wreck "a recorder that always writes slot 001 is caught" \
  sameslot 's|^    slot=$(next_slot "$dir").*$|    slot=001|'

#
# The defect this file was rewritten for, put back. The slot counts every review in the directory
# and the round counts one, so a review opening in a shared directory is stamped at the slot — and
# its round one, which nothing wrote, is what its round two then asks for.
wreck "a recorder taking the round from the slot is caught" \
  slotisround 's|^    round=$(next_round "$dir" "$review").*$|    round=$(next_slot "$dir")|'

# A caller appending its own round makes the review `<review> R1`, so the name changes every round
# and every round is round one — the reset, back through the door left open to patch around it.
wreck "a recorder taking a review that carries a round is caught" \
  anyname 's,^    is_a_round "${word#R}" || return 0$,    return 0,'

# The guard's reach. It watched `record` alone, and `round` and `prior` answered for a name it would
# have refused. A name is read far more often than it is written.
wreck "a guard that watches the recorder only is caught" \
  readpaths '/^prior_round() {/,/^}/ s|^    refuse_unless_a_review "$review"$|    :|
             /^next_round() {/,/^}/ s|^    refuse_unless_a_review "$2"$|    :|'

# The two characters the stamp owns, not the name. A comma opens the recorder's note, and a line
# break ends the stamp — putting the round on line four, where the judge's body starts.
wreck "a review holding the stamp's own punctuation is caught" \
  anypunct 's|^        \*,\*)|        ZZCOMMA)|
            s|^        \*"$newline"\*)|        ZZBREAK)|'


# The refusal itself, gone. A verdict then records against a tree the branch left, which is the
# fault this pair was built for.
wreck "a chain that records a verdict after the branch moved is caught" \
  movedon 's|^    \[ -n "$commit" \] && refuse_unless_the_branch_holds.*$|    :|'

# Hashes where trees belong. An amend, a rebase or a merge changing no file renames the commit and
# moves nothing the judge read, so comparing hashes refuses work that is sound.
wreck "a chain comparing commits instead of trees is caught" \
  hashnottree 's|"$2^{tree}"|"$2"|'


# The tally every check reports through. A break that empties a suite used to turn it green, and no
# audit could see it, because the audit reads the same exit code.
( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
  && bad "a suite that ran nothing passed" \
  || printf '  ok    a suite that ran nothing does not pass\n'
echo
# End to end, and not just the bound. A runner that never returns must reach the verdict rather
# than the answer the suite would have given without it.
mkdir -p "$tmp/hang/bin" && printf '#!/bin/sh\nsleep 30\n' > "$tmp/hang/bin/verdicts.sh"
( deadline=1; caught hang )
[ "$?" -eq 2 ] && printf '  ok    a hanging mutant reaches the verdict, not a pass\n' \
               || bad "a hanging mutant did not reach the verdict"

# The bound itself, because no mutant has ever hung and an unused guard is the one that rots.
( deadline=1; bounded "$deadline" sleep 5 )
[ "$?" -eq 2 ] && printf '  ok    a mutant that never answers is bounded\n' \
               || bad "a mutant that never answers was not bounded"

[ "$failed" -eq 0 ] && echo "ALL GREEN"
[ "$failed" -eq 1 ] && echo "FAILURES ABOVE"
[ "$failed" -eq 3 ] && echo "PROVED NOTHING — the experiments above never ran"
exit $failed
