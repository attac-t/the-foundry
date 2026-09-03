#!/bin/bash
#
# One case, one mutant, one assertion. Sourced by `tests/model.sh`, never run.
#
# The audit above this reads whether a suite went red. That answers *something noticed*, and a break
# tripping an unrelated check reads exactly like the break that was caught. These read the check.
#
# Each case names three things: the state it starts from, the body it runs, and the one assertion its
# mutant must flip. The state is built by the clean runner and restored to one pathname, so a case
# starts immediately before the operation its mutant changes and never after it.
#
# A body holds the declared assertion and nothing else the mutant can move. That is the whole
# discipline: a second assertion the mutant also flips makes *caught* unreadable again.
#

# Every case this file holds. `--case-smoke` names a subset of these.
case_ids() {
    cat <<'EOF'
second-ref-elsewhere
live-selection
moved-gate-selection
base-gate
no-handoff
blind-stamp
no-ancestor
adopt-base
EOF
}

#
# The one assertion a case's mutant must flip.
#
# Read by the audit, which credits a kill to this name and to no other. `is` and its kin decorate a
# failing name with what they wanted and what they got, so the audit matches this as a prefix.
#
declared_assertion() {
    case "$1" in
        second-ref-elsewhere) printf 'a second ref for the bootstrap target is refused' ;;
        live-selection)       printf 'a selection that moved after the freeze stops delivery' ;;
        moved-gate-selection) printf 'gates refuses a moved selection rather than recording' ;;
        base-gate)            printf "and the work satisfies it through the base's own script" ;;
        no-handoff)           printf 'a verdict from a judge nobody handed the bar is refused' ;;
        blind-stamp)          printf 'a stamped comment is dropped whatever the account said' ;;
        no-ancestor)          printf 'a base that is not behind the head refuses' ;;
        adopt-base)           printf 'opening a workspace with no recorded base refuses' ;;
    esac
}

# --- what a name may run ---

# A case id is a name this file holds, never whatever the caller typed.
named_case() {
    case_ids | grep -Fxq -- "${1:-}" && return 0

    printf 'no case named [%s]. This file holds:\n%s\n' "${1:-}" "$(case_ids)" >&2
    return 1
}

# An id reads with hyphens and a function name cannot hold one.
as_function() { printf '%s' "$1" | tr '-' '_'; }

# The state a case starts from, built here by the clean runner and copied away by the audit.
build_checkpoint() {
    named_case "${1:-}" || return 2

    "checkpoint_$(as_function "$1")" && return 0

    printf 'the checkpoint for [%s] could not be built\n' "$1" >&2
    return 1
}

# One case, on state already restored. Its assertions are the answer; the tally is for a reader.
run_one_case() {
    named_case "${1:-}" || return 2

    "case_$(as_function "$1")"
    summary "case $1"
}

# --- the state several cases share ---

#
# A run with a bar, a selection, a workspace and a graded gate.
#
# Named once because four cases start here and none of them is about getting here. Every step is the
# shipped runner: a checkpoint assembled by hand would be a state floor cannot reach.
#
a_graded_run() {
    a_repository_with_a_gate "$1" || return 1

    floor_new_as "$tmp/$1" ada@example.com 'Ready' >/dev/null || return 1
    floor "$tmp/$1" charter derive >/dev/null 2>&1 || return 1
    floor "$tmp/$1" policy authorize "https://github.com/acme/$1.git" >/dev/null 2>&1 || return 1
    floor "$tmp/$1" targets add "https://github.com/acme/$1.git" main >/dev/null 2>&1 || return 1
    floor "$tmp/$1" open >/dev/null 2>&1 || return 1
    floor "$tmp/$1" gates >/dev/null 2>&1 || return 1
}

# The same, granted somewhere to deliver. `refuse_ungranted_delivery` stands before the ancestry
# check, so a run without this answers 18 and never reaches what these two cases are about.
a_run_that_may_deliver() {
    a_repository_with_a_gate "$1" || return 1

    floor_new_as "$tmp/$1" ada@example.com 'Provenance' >/dev/null || return 1
    floor "$tmp/$1" charter derive >/dev/null 2>&1 || return 1
    floor "$tmp/$1" policy authorize  "https://github.com/acme/$1.git" >/dev/null 2>&1 || return 1
    floor "$tmp/$1" policy deliver-to "https://github.com/acme/$1.git" >/dev/null 2>&1 || return 1
    floor "$tmp/$1" targets add       "https://github.com/acme/$1.git" main >/dev/null 2>&1 || return 1
    floor "$tmp/$1" open >/dev/null 2>&1 || return 1
    floor "$tmp/$1" gates >/dev/null 2>&1 || return 1
}

a_repository_with_a_gate() {
    make_repo "$tmp/$1" main || return 1
    set_origin "$tmp/$1" "https://github.com/acme/$1.git" || return 1
    mkdir -p "$tmp/$1/.foundry" || return 1
    commit_file "$tmp/$1" .foundry/gates 'tests  true
'
}

# The one checkout a run holds, from the run rather than from a path a test remembered.
case_work_tree() { only_slot "$(floor "$tmp/$1" path)/units/01/workspace"; }

# Where `open` writes what a target started from.
case_base_file() { printf '%s/units/01/base' "$(floor "$tmp/$1" path)"; }

# --- second-ref-elsewhere ---
#
# The bar is derived at the bootstrap's ref, so a second ref would be graded against a tree the
# charter never read. The checkpoint stops at the run, immediately before the `targets add`.

checkpoint_second_ref_elsewhere() {
    make_repo "$tmp/sr" main || return 1
    set_origin "$tmp/sr" 'https://github.com/acme/sr.git' || return 1
    commit_file "$tmp/sr" README.md 'a repository
' || return 1
    git -C "$tmp/sr" branch other >/dev/null 2>&1 || return 1

    floor_new_as "$tmp/sr" ada@example.com 'Second ref' >/dev/null || return 1
}

case_second_ref_elsewhere() {
    is "the checkpoint selected nothing" "$(floor "$tmp/sr" targets | grep -c .)" "0"

    is "a second ref for the bootstrap target is refused" \
       "$(code_of floor "$tmp/sr" targets add 'https://github.com/acme/sr.git' other)" "4"
}

# --- live-selection ---
#
# The freeze is what the run was authorised over, and §4 makes a changed selection a new attempt.
# The checkpoint holds the second target already added, immediately before the `complete`.

checkpoint_live_selection() {
    a_graded_run lv || return 1

    floor "$tmp/lv" policy authorize 'https://github.com/acme/other.git' >/dev/null 2>&1 || return 1
    floor "$tmp/lv" targets add 'https://github.com/acme/other.git' main >/dev/null 2>&1 || return 1
}

case_live_selection() {
    exists "the selection was frozen before it moved" \
           "$(floor "$tmp/lv" path)/units/01/selection"

    is "a selection that moved after the freeze stops delivery" \
       "$(code_of floor "$tmp/lv" complete)" "10"
}

# --- moved-gate-selection ---
#
# The same fact, read by the recorder rather than the grader. A grader answers wrongly once; the
# ledger a recorder writes takes nothing back.

checkpoint_moved_gate_selection() {
    a_graded_run mg || return 1

    floor "$tmp/mg" policy authorize 'https://github.com/acme/other.git' >/dev/null 2>&1 || return 1
    floor "$tmp/mg" targets add 'https://github.com/acme/other.git' main >/dev/null 2>&1 || return 1
}

case_moved_gate_selection() {
    exists "the selection was frozen before it moved" \
           "$(floor "$tmp/mg" path)/units/01/selection"

    is "gates refuses a moved selection rather than recording" \
       "$(code_of floor "$tmp/mg" gates)" "10"
}

# --- base-gate ---
#
# A run that rewrote the script its own gate names. The base's `check.sh` asks for a file only the
# run adds, so it passes for one reason: the base's script ran, and it ran against the work.

checkpoint_base_gate() {
    make_repo "$tmp/bg" main || return 1
    set_origin "$tmp/bg" 'https://github.com/acme/bg.git' || return 1
    commit_file "$tmp/bg" check.sh 'test -f added
' || return 1
    mkdir -p "$tmp/bg/.foundry" || return 1
    commit_file "$tmp/bg" .foundry/gates 'tests  sh check.sh
' || return 1

    floor_new_as "$tmp/bg" ada@example.com 'Base gates' >/dev/null || return 1
    floor "$tmp/bg" charter derive >/dev/null 2>&1 || return 1
    floor "$tmp/bg" policy authorize 'https://github.com/acme/bg.git' >/dev/null 2>&1 || return 1
    floor "$tmp/bg" targets add 'https://github.com/acme/bg.git' main >/dev/null 2>&1 || return 1
    floor "$tmp/bg" open >/dev/null 2>&1 || return 1

    work=$(case_work_tree bg)
    [ -n "$work" ] || return 1

    printf 'ok\n' > "$work/added" || return 1
    printf 'exit 1\n' > "$work/check.sh" || return 1
    git -C "$work" add added >/dev/null 2>&1 || return 1
    git -C "$work" -c user.email=a@b.c -c user.name=a \
        commit -aqm 'the work, and a gate that refuses it' >/dev/null 2>&1
}

case_base_gate() {
    is "the run rewrote the gate its charter pins" \
       "$(cat "$(case_work_tree bg)/check.sh")" "exit 1"

    is "and the work satisfies it through the base's own script" \
       "$(code_of floor "$tmp/bg" gates)" "0"
}

# --- no-handoff ---
#
# A verdict answers for one commit and one bar. The checkpoint records neither handoff nor verdict,
# immediately before the verdict nothing gave the judge.

checkpoint_no_handoff() {
    make_repo "$tmp/nh" main || return 1
    set_origin "$tmp/nh" 'https://gitlab.com/acme/nh.git' || return 1
    mkdir -p "$tmp/nh/.foundry" || return 1
    commit_file "$tmp/nh" .foundry/gates 'tests  true
' || return 1
    commit_file "$tmp/nh" .foundry/judged 'a-reviewer  a stranger can read it
' || return 1

    floor_new_as "$tmp/nh" ada@example.com 'Handed nothing' >/dev/null || return 1
    floor "$tmp/nh" charter derive >/dev/null 2>&1 || return 1
    floor "$tmp/nh" policy authorize 'https://gitlab.com/acme/nh.git' >/dev/null 2>&1 || return 1
    floor "$tmp/nh" targets add 'https://gitlab.com/acme/nh.git' main >/dev/null 2>&1 || return 1
    floor "$tmp/nh" open >/dev/null 2>&1 || return 1
    floor "$tmp/nh" gates >/dev/null 2>&1 || return 1
}

case_no_handoff() {
    is "the checkpoint records no handoff" \
       "$(floor "$tmp/nh" evidence | grep -c handed)" "0"

    is "a verdict from a judge nobody handed the bar is refused" \
       "$(code_of floor "$tmp/nh" evidence verdict 'a stranger can read it' 'a-reviewer' \
                 approve 'fine' "$(reviewed_at "$tmp/nh")")" "36"
}

# --- blind-stamp ---
#
# The account is not provenance. Two people share one and a run posts under another, so floor stamps
# what it writes and the stamp is read before the account is. The checkpoint holds a person's answer
# and a stamped comment beneath it, immediately before the read.

checkpoint_blind_stamp() {
    make_repo "$tmp/bs" main || return 1
    set_origin "$tmp/bs" 'https://github.com/acme/bs.git' || return 1
    commit_file "$tmp/bs" Makefile 'test:
	echo ok
' || return 1

    fake_gh "$tmp/ghbin" || return 1
    the_store_this_case_reads || return 1

    gh_floor new 'Other adapter' >/dev/null || return 1
    gh_floor source read 12 >/dev/null 2>&1 || return 1
    gh_floor charter derive >/dev/null 2>&1 || return 1
    gh_floor source ask authorisation tests 'May this clause exist?' >/dev/null 2>&1 || return 1

    gh_says 'yes, go ahead'
    said_by a-person 'floor-run: whatever-run

The answer is 9876543210.'
}

case_blind_stamp() {
    the_store_this_case_reads

    has "a person's answer comes back" \
        "$(gh_floor source receive authorisation tests)" "yes, go ahead"

    lacks "a stamped comment is dropped whatever the account said" \
          "$(gh_floor source receive authorisation tests)" "9876543210"
}

# What the stub answers from. Set in both halves, because a checkpoint keeps files and never a
# variable the process that wrote it held.
the_store_this_case_reads() {
    GH_STORE="$tmp/ghstore"
    export GH_STORE

    mkdir -p "$GH_STORE" || return 1
    printf 'Make the other thing\n\nAnd make it well.\n' > "$GH_STORE/item" || return 1
    printf 'foundry:defect\nbug\n' > "$GH_STORE/labels" || return 1
    printf 'foundry-run\n' > "$GH_STORE/me"
}

# The GitHub adapter, named rather than detected — `floor` above names the directory one, and this
# case is about the other. The stub goes on the path; core chooses the adapter from the origin.
gh_floor() {
    ( cd "$tmp/bs" 2>/dev/null || exit 9
      PATH="$tmp/ghbin:$PATH" FOUNDRY_HOME="$home" FOUNDRY_RUN="" FOUNDRY_WHO="" \
        sh "$runner" "$@" 2>/dev/null )
}

# --- no-ancestor ---
#
# `base..head` answers for a head the base is not behind, and the answer is about a history that
# never held it. The checkpoint leaves a rebuilt branch, immediately before the delivery.

checkpoint_no_ancestor() {
    a_run_that_may_deliver na || return 1

    work=$(case_work_tree na)
    [ -n "$work" ] || return 1

    other=$(git -C "$work" -c user.email=a@b.c -c user.name=a \
              commit-tree "$(git -C "$work" rev-parse 'HEAD^{tree}')" \
              -m 'chore: another history' 2>/dev/null) || return 1
    git -C "$work" reset -q --hard "$other" >/dev/null 2>&1
}

case_no_ancestor() {
    is "the checkpoint left a head the recorded base is not behind" \
       "$(code_of git -C "$(case_work_tree na)" merge-base --is-ancestor \
                  "$(cut -d' ' -f2 "$(case_base_file na)")" HEAD)" "1"

    is "a base that is not behind the head refuses" \
       "$(code_of floor "$tmp/na" deliver 'Rebuilt')" "33"
}

# --- adopt-base ---
#
# A workspace that was here before any base was recorded. Its head is where the work got to, so
# adopting it names every commit already carried as one this run made.

checkpoint_adopt_base() {
    a_run_that_may_deliver ab || return 1

    rm -f "$(case_base_file ab)"
}

case_adopt_base() {
    absent "the checkpoint left no recorded base" "$(case_base_file ab)"

    is "opening a workspace with no recorded base refuses" \
       "$(code_of floor "$tmp/ab" open)" "33"
}
