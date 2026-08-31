#!/bin/bash
# What `bin/say.sh` renders, and the nine ways it refuses.
#
# The defect this exists for: guidance forbade publishing run output in three separate documents,
# and a worker published twelve kilobytes of session ids, token counts and a duplicated transcript
# to a public pull request anyway. Every check below is one of those kilobytes.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

say="${RUNNER:-$here/bin/run.sh}"
say="$(dirname "$say")/say.sh"

echo "say"

# Every check calls it the same way, so a check reads as its own name and nothing else.
said()    { sh "$say" "$@" </dev/null 2>/dev/null; }
refused() { sh "$say" "$@" </dev/null >/dev/null 2>&1; printf '%s' "$?"; }

# --- what it renders ---

a_finding_renders_every_field_it_was_given() {
  body=$(said --kind finding --subject '#416' --was proposed --now approved \
              --because 'two readers agreed' --next 'merge it' --evidence 507a735)

  has "the kind names itself"  "$body" "**Finding**"
  has "and the subject"        "$body" "#416"
  has "the delta, as an arrow" "$body" "proposed → approved"
  has "what follows"           "$body" "two readers agreed"
  has "what happens next"      "$body" "merge it"
  has "and what can be checked" "$body" "Evidence: 507a735"
  matches "with a key derived, never given" "$body" "seam:[0-9]+"
}
a_finding_renders_every_field_it_was_given

#
# A decision and a closure are irreversible on their own. Neither carries a delta, and demanding one
# would make the two kinds that always matter the two kinds that cannot be said.
the_two_kinds_that_need_no_delta() {
  is "a decision renders"  "$(refused --kind decision --subject '#416' --because 'the owner said yes' \
                                      --next 'merge' --evidence 507a735)" "0"
  is "and a closure does"  "$(refused --kind closure --subject '#418' --because 'every box holds' \
                                      --next 'closed' --evidence 8507df0)" "0"
}
the_two_kinds_that_need_no_delta

# --- the nine refusals ---

nothing_but_the_three_kinds() {
  is "a fourth kind refuses"   "$(refused --kind update --subject x --because y --next z --evidence w)" "2"
  is "and so does no kind"     "$(refused --subject x --because y --next z --evidence w)" "2"
}
nothing_but_the_three_kinds

#
# A flag with no value leaves `shift 2` short, so the loop never ends and the next flag is read as a
# value. Floor's own runner shipped that bug once.
a_flag_with_no_value_refuses() {
  is "a trailing flag refuses" "$(refused --kind finding --subject)" "2"
}
a_flag_with_no_value_refuses

every_field_is_required() {
  is "no subject"     "$(refused --kind decision --because y --next z --evidence w)" "2"
  is "no consequence" "$(refused --kind decision --subject x --next z --evidence w)" "2"
  is "no next"        "$(refused --kind decision --subject x --because y --evidence w)" "2"
  is "no evidence"    "$(refused --kind decision --subject x --because y --next z)" "2"
}
every_field_is_required

#
# The regression's exact shape. A finding with no delta is a status line, and status lines are what
# filled the thread.
a_finding_with_no_delta_refuses() {
  is "neither side given"  "$(refused --kind finding --subject x --because y --next z --evidence w)" "50"
  is "only one side given" "$(refused --kind finding --subject x --was a --because y --next z --evidence w)" "50"
  is "and both the same"   "$(refused --kind finding --subject x --was a --now a --because y --next z --evidence w)" "50"
}
a_finding_with_no_delta_refuses

#
# The thread is the ledger, and it arrives on stdin. A file beside the run would be one the same
# worker writes — which neither architecture consultation would call evidence.
a_key_already_on_the_thread_refuses() {
  first=$(said --kind decision --subject '#416' --because 'yes' --next 'merge' --evidence 507a735)
  again=$(printf '%s' "$first" | sh "$say" --kind decision --subject '#416' \
                                           --because 'yes' --next 'merge' --evidence 507a735 >/dev/null 2>&1; printf '%s' "$?")

  is "the same thing twice refuses" "$again" "51"

  other=$(printf '%s' "$first" | sh "$say" --kind decision --subject '#418' \
                                           --because 'yes' --next 'merge' --evidence 507a735 >/dev/null 2>&1; printf '%s' "$?")
  is "and a different subject does not" "$other" "0"

  # Keys are variable-length decimals. Matched as a bare substring, seam:123 hit seam:1234 and
  # refused a key nobody had published. The whole marker is matched now.
  near=$(printf '<!-- seam:9999999999 -->' | sh "$say" --kind decision --subject '#900' --because y --next z --evidence w >/dev/null 2>&1; printf '%s' "$?")
  is "a longer key that starts the same does not block" "$near" "0"
}
a_key_already_on_the_thread_refuses

#
# Named field shapes, never a regex over prose. Both architecture consultations refused a noise
# filter, separately: a caller learns to phrase around one, and the phrasing is the tell.
what_leaked_is_what_is_refused() {
  is "a session id"   "$(refused --kind decision --subject x --because 'session 01a0532a-34d0-7ac0-972d-12b19dd0740c' --next z --evidence w)" "52"
  is "a token count"  "$(refused --kind decision --subject x --because 'tokens used 40311' --next z --evidence w)" "52"
  is "a transcript"   "$(refused --kind decision --subject x --because 'exec  git rev-parse HEAD' --next z --evidence w)" "52"

  # A careless caller capitalises. The filter read case-sensitively, so `Session ID` walked through.
  is "and case does not matter"      "$(refused --kind decision --subject x --because 'Session ID 01A0532A-34D0-7AC0-972D-12B19DD0740C' --next z --evidence w)" "52"

  # Two of six fields were never screened, so 52 could not be reached through either of them.
  is "the delta is screened"    "$(refused --kind finding --subject x --was 'tokens used 40311' --now b --because y --next z --evidence w)" "52"
  is "and so is its other half" "$(refused --kind finding --subject x --was a --now 'tokens used 40311' --because y --next z --evidence w)" "52"

  # A marker inside a field lands on the thread and blocks that key for whoever earned it.
  is "a seam marker in a field" "$(refused --kind decision --subject x --because 'see seam:123' --next z --evidence w)" "52"
}
what_leaked_is_what_is_refused

evidence_naming_nothing_refuses() {
  for word in none n/a - pending; do
    is "evidence [$word]" "$(refused --kind decision --subject x --because y --next z --evidence "$word")" "53"
  done
}
evidence_naming_nothing_refuses

#
# The count is the last refusal and never the first. A caller who compressed noise to fit still
# fails the allowlist above — that is the whole reason the allowlist comes first.
a_body_too_long_refuses() {
  long=$(head -c 2000 /dev/zero | tr '\0' 'x')
  is "over 1200 characters" "$(refused --kind decision --subject x --because "$long" --next z --evidence w)" "54"

  wordy=$(awk 'BEGIN { while (i++ < 200) printf "word " }')
  is "and over 180 words"   "$(refused --kind decision --subject x --because "$wordy" --next z --evidence w)" "54"
}
a_body_too_long_refuses

#
# The render is fixed on purpose. `bin/comments.sh` re-derives it from what GitHub returns, so a
# comment that did not come through here reads as one that did not — and a stamp nobody can forge is
# a stamp nobody has to hold a key for.
the_render_does_not_drift() {
  # Pinned, not compared to itself. Two empty renders are equal, so the old check passed with the
  # function's body deleted — it proved determinism and nothing about the shape.
  want='**Closed** — #418

a

b

Evidence: c

<!-- seam:'
  has "the body is the shape the audit expects"       "$(said --kind closure --subject '#418' --because a --next b --evidence c)" "$want"
}
the_render_does_not_drift

summary "say"
