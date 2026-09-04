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
# Timeout exits 124 when it kills one. Inverting that gives zero,
# which is this file's word for the suite noticing, so
# a mutant that hung would be filed as caught.
#
moot() { [ "$failed" -eq 0 ] && failed=3; printf '  MOOT  %s\n' "$1"; }

# Eight times the slowest mutant measured here, which
# was about fifteen seconds. A deadline reached
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

# The role and its skills travel with the mutant. `brief.sh` reads them from its own parent, so a
# copy alone would fail for want of a role rather than for the rule under test.
wreck_brief() {
  local name="$1" tag="$2" mutation="$3"

  rm -rf "${tmp:?}/$tag" && mkdir -p "$tmp/$tag/bin" || { bad "$name — could not stage"; return; }
  cp -r "$root/agents" "$root/skills" "$tmp/$tag/" || { bad "$name — could not stage the role"; return; }
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
# A chain that cannot say which round this is, carrying on anyway. That is the fail-closed rule
# inverted, and `a chain nobody made stops the brief` is what kills it.
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


# The tally every check reports through. A break that empties a
# suite used to turn it green, and no audit could see it,
# because the audit reads the same exit code.
( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
  && bad "a suite that ran nothing passed" \
  || printf '  ok    a suite that ran nothing does not pass\n'
echo
# End to end, and not just the bound. A runner that never returns
# must reach the verdict rather than the answer
# the suite would have given without it.
mkdir -p "$tmp/hang/bin" && printf '#!/bin/sh\nsleep 30\n' > "$tmp/hang/bin/verdicts.sh"
( deadline=1; caught hang )
[ "$?" -eq 2 ] && printf '  ok    a hanging mutant reaches the verdict, not a pass\n' \
               || bad "a hanging mutant did not reach the verdict"

# The bound itself, because no mutant has ever hung
# and an unused guard is the one
# that rots.
( deadline=1; bounded "$deadline" sleep 5 )
[ "$?" -eq 2 ] && printf '  ok    a mutant that never answers is bounded\n' \
               || bad "a mutant that never answers was not bounded"

[ "$failed" -eq 0 ] && echo "ALL GREEN"
[ "$failed" -eq 1 ] && echo "FAILURES ABOVE"
[ "$failed" -eq 3 ] && echo "PROVED NOTHING — the experiments above never ran"
exit $failed
