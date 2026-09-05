#!/bin/sh
#
# The judge this repository reaches. `.foundry/judged` pins it, and `run.sh judged` runs it.
#
# **Floor knows nothing about this file.** It writes a brief, points at a receipt it has already half
# filled, and runs whatever the charter says. Everything below is this repository's answer to *how is
# our judge reached*, and another repository's answer is its own.
#
# What floor already wrote into the receipt is what floor knows: the run, the clause, the candidate,
# the role, the brief digest, the round and whatever came before it. **This may not restate any of
# them** — a key said twice is two answers, and floor refuses the file rather than choosing.
#
# So what this appends is only what it saw happen:
#
#     adapter  requested_model  requested_effort  context  fresh  report  time  verdict
#
# **There is no fallback, and there never may be.** A receipt naming one harness and carrying another
# one's reading is the single thing a judgement receipt exists to make impossible. Codex missing is
# recorded `unavailable`, which is not a verdict and satisfies nothing.
#
# **`--skip-git-repo-check` is not passed, and that is measured.** It only lets Codex run outside a
# git repository; floor grades in a workspace, and a workspace is a checkout of the target. A call
# without it returned exit 0 here on 5 September 2026.
#
# `--sandbox read-only` because a judge writes no code. The receipt and the report are written by
# this script, outside the tree being read.
#
# Usage: floor sets FOUNDRY_BRIEF and FOUNDRY_RECEIPT, and runs it. Nothing else calls it.
#
# Exit: 0 a judgement came back, 1 none did, 2 nothing was handed over

set -u

readonly MODEL=gpt-5.6-sol
readonly EFFORT=max
readonly ADAPTER=codex-exec

main() {
    ensure_floor_handed_both

    report="${FOUNDRY_RECEIPT%.receipt}.report"
    trail="${FOUNDRY_RECEIPT%.receipt}.jsonl"

    reachable || { record_unreachable "$report"; return 1; }

    forget_the_last_round "$report" "$trail"
    ask "$report" "$trail" || note "the harness exited $? — reading what it left"
    record_what_came_back "$report" "$trail"
}

# --- what floor handed over ---

ensure_floor_handed_both() {
    [ -n "${FOUNDRY_BRIEF:-}" ] && [ -r "${FOUNDRY_BRIEF:-}" ] || fail "no brief to read"
    [ -n "${FOUNDRY_RECEIPT:-}" ] && [ -f "${FOUNDRY_RECEIPT:-}" ] || fail "no receipt to write to"
}

# --- the harness ---

# Whether it is on this host at all. **There is no second answer**, and adding one would make every
# receipt this ever wrote worth less than the name it carries.
reachable() { command -v codex >/dev/null 2>&1; }

#
# Every round writes to the same two names, so every round empties them first.
#
# **A harness killed before it answered leaves the round before it standing** — a report that is
# there, not empty, and carrying a verdict about another commit. `record_what_came_back` asks only
# whether the file holds anything, so that stale approval would be attached to this candidate and
# this brief. Emptying first is what makes *holds anything* mean *this round wrote it*.
#
# Found by the adversary reading its own round-two receipt, which is the state that proves it: the
# brief and the stream were round two's while the report was still round one's.
forget_the_last_round() {
    : > "$1" && : > "$2" || fail "cannot write beside [$FOUNDRY_RECEIPT]"
}

#
# Ask, and keep both halves of the answer.
#
# `--output-last-message` writes the reply straight to a file, so nothing here parses JSON for the
# part that matters. The stream is kept only for the thread handle, which is one quoted field on its
# first line and the one thing a receipt may say it watched.
#
# The prompt goes over stdin. Argv has a length nobody agrees on, and a bar is as long as it is.
ask() {
    prompt_from "$FOUNDRY_BRIEF" |
        codex exec --json --model "$MODEL" -c model_reasoning_effort="$EFFORT" \
            --sandbox read-only --output-last-message "$1" - > "$2" 2>&1
}

#
# The bar, and what an answer has to look like.
#
# The brief is quoted whole and nothing is summarised out of it: floor digested that file, and the
# receipt says the judge answered that digest. A framing that dropped half of it would make the two
# agree about a bar only one of them saw.
prompt_from() {
    cat <<'EOF'
You are an adversary judging work you did not write. Read the repository you are standing in
against the bar below, and report what is wrong with it.

The checkout is a clone at the candidate commit, with its own history. The work under judgement is
`git diff <base>..<candidate>`, both named below. When those are the same commit there is no range,
and what you are judging is the tree at that commit. Do not repair anything, and write to no file.

EOF
    cat "$1"
    cat <<'EOF'

Report, in this order:

  - each finding, with a severity of Critical, Warning or Nitpick
  - the residual risks you would have recorded
  - a last line, and nothing after it, reading exactly one of:

        VERDICT: approve
        VERDICT: reject
        VERDICT: revise

Approve only when nothing Critical stands — a Warning or a Nitpick does not block. Reject when the
work is wrong. Revise when it is close and something must change. Only the last line is read, so
anything written after it means no verdict was given at all.
EOF
}

# --- the receipt ---

#
# Nothing was asked, and the receipt says so rather than staying quiet.
#
# `unavailable` is not a verdict. Floor records it, the clause stays unmet, and the delivery stops —
# which is a different fact from a judge that read the work and refused it, and takes a different
# remedy: install the harness, rather than change the work.
record_unreachable() {
    printf 'codex is not on this host, and this adapter reaches nothing else.\n' > "$1"

    say_the_report "$1" ''
    printf 'verdict unavailable\n' >> "$FOUNDRY_RECEIPT"
    note "codex is not on this host — recorded unavailable, and nothing else was asked"
}

#
# What the harness returned, or the honest absence of it.
#
# A reply naming no verdict leaves the key out. Floor refuses a receipt with no `verdict` at all, and
# **that refusal is the right one**: choosing a word for a judge that named none is exactly the
# invention the whole contract exists to stop.
record_what_came_back() {
    [ -s "$1" ] || { record_silence "$1" "$2"; return 1; }

    said=$(verdict_in "$1")
    say_the_report "$1" "$(thread_in "$2")"

    [ -n "$said" ] || { note "the judge named no verdict, so this receipt claims none"; return 1; }

    printf 'verdict %s\n' "$said" >> "$FOUNDRY_RECEIPT"
}

# The harness ran and said nothing. Its own output is the report, because that is what came back.
record_silence() {
    cp "$2" "$1" 2>/dev/null || printf 'the harness returned nothing at all.\n' > "$1"

    say_the_report "$1" "$(thread_in "$2")"
    printf 'verdict unavailable\n' >> "$FOUNDRY_RECEIPT"
    note "the harness returned no message — recorded unavailable"
}

#
# Everything but the verdict, and only what this watched.
#
# No `model`, no `provider`, no `effort`. The stream names none of the three, and asked outright this
# harness gave a name other than the one requested — so what is written is what was asked for, said
# as such. Floor refuses the bare keys by name.
say_the_report() {
    printf 'adapter %s\nrequested_model %s\nrequested_effort %s\n' "$ADAPTER" "$MODEL" "$EFFORT" \
        >> "$FOUNDRY_RECEIPT"
    printf 'report %s\ntime %s\n' "$(cksum < "$1" | awk '{ print $1 }')" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$FOUNDRY_RECEIPT"

    say_the_thread "$2"
}

# A handle, and that it was new. This adapter never resumes, so every thread it opens is fresh — and
# a run with no handle to name says neither, because `fresh` about nothing is a claim about nothing.
say_the_thread() {
    [ -n "$1" ] || return 0

    printf 'context %s\nfresh yes\n' "$1" >> "$FOUNDRY_RECEIPT"
}

# --- reading what came back ---

#
# The verdict, and only when it is the reply's last word.
#
# **The last line that carries anything, never a matching line anywhere.** A reply quoting the
# instruction, weighing two answers, or contradicting itself after saying one, would otherwise be
# read as having chosen — and the one it chose would be whichever came last by accident.
#
# Nothing when the last line is not a verdict. Floor refuses a receipt carrying none, which is the
# right refusal: picking a word for a judge that named none is the invention this all exists to stop.
verdict_in() {
    awk 'NF { last = $0 }
         END { if (last !~ /^[ \t]*VERDICT:[ \t]*(approve|reject|revise)[ \t]*$/) exit
               sub(/^[ \t]*VERDICT:[ \t]*/, "", last); sub(/[ \t]*$/, "", last); print last }' "$1"
}

# The thread the harness opened, off its own stream. Cut to the value rather than counted to it: a
# split on `"` puts the JSON colon after the key, so counting one field along printed `:` into every
# receipt this wrote. Found by an adversary reading the receipt it had just been handed.
thread_in() {
    awk '/"thread.started"/ && /"thread_id"[ \t]*:[ \t]*"/ {
             sub(/^.*"thread_id"[ \t]*:[ \t]*"/, ""); sub(/".*$/, ""); print; exit }' "$1" 2>/dev/null
}

# --- one voice ---

note() { printf 'judge: %s\n' "$1" >&2; }

fail() { note "$1"; exit 2; }

main "$@"
