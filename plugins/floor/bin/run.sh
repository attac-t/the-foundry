#!/bin/sh
#
# floor — make a run, and find the one you are in. See README.md.
#
# Making a run changes nothing in any repository. Keep it that way.
#
# `set -e` is off: `path` exits 1 when no run is active, which is an answer.
#
# Exit codes — every command but one. `evidence record` returns what the gate returned, so read its
# refusals off stderr and the ledger, never off the code.
#
#   0  answered
#   1  nothing to answer with — no run is active, no bootstrap target, no charter yet, or the work
#      source holds no item, no clause by that name, and no answer
#   2  asked for something this does not do
#   3  nowhere to put a run, or the home cannot be written to
#   4  a target was refused: no portable identity, or a ref that is not one
#   5  a target was refused: nobody authorised it for this run
#   6  a clause was refused: it would weaken the charter, its pin could not be captured, or the run
#      would derive from an artifact it changed — including a run that recorded no base
#   7  the charter cannot be run against as it stands — something drifted, went missing, holds
#      together with nothing, or is pinned to a repository this is not
#   8  the charter gives this stage nothing to run — it holds no clause, none that pins a gate, or
#      none that names a judge
#   9  a clause grades no selected target, so it is no bar
#  10  the selection moved after it was authorised — that is a new run, not this one
#  11  a clause is introduced and nothing can ask a human to authorise it
#  12  the detector yields a gate the charter holds no clause for — re-derive
#  13  the run directory was renamed, so the grants a human gave it are not there
#  14  a gate the charter pins did not pass — an answer, not a refusal
#  15  this run may not deliver yet — an answer too, and it names what is missing
#  16  no workspace could be opened. The target was authorised and the home is writable, so 5 and 3
#      would each send the reader to a remedy that changes nothing
#  17  this run already sent the work source something else — another item, another branch, or the
#      same question in other words. One remedy: a new run
#  18  nobody said this run may deliver to that target. `policy authorize` grants grading, and
#      writing to a repository is a second act a human takes
#  19  the delivery could not be sent — the push was refused, or the source was. The grant was there
#      and the work was done, so 18 and 15 would each send the reader to a remedy that changes
#      nothing
#  20  the work source could not be asked — a tool that is not there, a credential it refused, a
#      network. Not 1: that is the source answering, and answering that nothing is there
#  21  a gate or a judge never answered — its command is not on this host, or a signal killed it
#      before it could. Nothing was graded and nothing is recorded. Not 14:
#      that is a gate answering, and its answer stands at that ref for good
#  23  nobody said this run may merge into that repository. `policy deliver-to` grants proposing,
#      and landing work in the trunk is a third act a human takes
#  24  the delivery is not the thing that was graded, or the source will not take it. An answer
#      about one delivery, never a fault in this run
#  25  the source could not be asked about the delivery, or could not land it. Not 24: that is the
#      source answering, and this is nobody answering
#  26  an open delivery elsewhere cannot be brought together with this one. An answer about
#      two deliveries, and a fault in neither
#  27  the work source has no way to do that at all — it can only be read. Not 20: that is a
#      source that could not be reached, and this is one that was
#  28  the item advised the repository it was filed in. A source is not a target, and advice is
#      the one path no human typed
#  29  a run here holds a workspace, so this host is not settled. An answer about the host, and
#      never a fault in any run
#  30  another host holds that item, or this one does not. A claim is not authority, so this is
#      never a refusal about what a run may touch
#  31  the source says one item is more than one kind. The inventory is short so a reader never
#      has to choose, and two answers is that choice arriving anyway
#  32  the delivery carries a commit this run has no record of making, and nobody accounted for it
#  33  the ancestry cannot be trusted — no base was recorded, it cannot be read, or it is not
#      behind the head. One remedy for all three: a new run, from where the work actually is
#  35  a verdict names a revision this run is not on. A review of one commit is not a review of
#      another, and the size of the change between them is not the point
#  36  nothing records this judge being handed the bar. A verdict given without the charter is
#      worth what it was given, and `evidence handed` is what says it was given
#  37  the receipt cannot be read as evidence — it is not there, it is there and holds nothing, it
#      carries a line this has no reading for, or it claims a thing it did not check. One remedy for
#      all four: a receipt saying what the contract names, and nothing beyond it
#  38  the receipt is about other work. It answers for another run, or for a bar that has changed
#      since it went over. The judgement is real and it is not about this
#  34  the worker may not account for ancestry. It named itself, so a record it writes about its
#      own commits is the producer signing off its own bar
#  22  the repository declares a bar in a file that is there and cannot be read. Not 8: that is a
#      charter holding no clause, and this is one nobody could derive. The remedy is the file
#  39  a judged clause the runner asked about is not met — the judge refused, asked for another
#      round, or could not answer at all. An answer about the work, never a fault in the run. Not
#      14: that is a command answering, and no command answers this
#
# Eight through twelve are one stage and five remedies: write a requirement down, select a target it
# governs, or start again. Collapsing them would make the exit code say *authorisation refused* and
# leave the caller to read prose for what to do about it.

set -u

# Where this script lives, read once. `dirname` is a process, and three resolvers wanted it
# on every call. A bare `$0` has no slash to cut, so that case is named rather than assumed.
case $0 in
    */*) SELF_DIR=${0%/*} ;;
    *)   SELF_DIR=. ;;
esac

main() {
    action=${1:-}
    [ "$#" -gt 0 ] && shift

    HOME_DIR=$(foundry_home) || die_homeless
    RUNS="$HOME_DIR/runs"
    GRANTS="$HOME_DIR/policy/runs"

    case "$action" in
        new)       make_run "${1:-}" ;;
        path)      print_active_run ;;
        home)      print_home ;;
        runs)      list_runs "$@" ;;
        settled)   settled "$@" ;;
        bootstrap) print_bootstrap ;;
        targets)   targets "$@" ;;
        policy)    policy "$@" ;;
        charter)   charter "$@" ;;
        evidence)  evidence "$@" ;;
        gates)     gates "$@" ;;
        judged)    judged "$@" ;;
        open)      open_workspace "$@" ;;
        commit)    commit_work "$@" ;;
        complete)  complete "$@" ;;
        deliver)   deliver "$@" ;;
        aside)     aside "$@" ;;
        claim)     claim "$@" ;;
        release)   release "$@" ;;
        observe)   observe "$@" ;;
        observed)  observed "$@" ;;
        merge)     merge_delivery "$@" ;;
        reconcile) reconcile "$@" ;;
        authorise) authorise ;;
        source)    work_source "$@" ;;
        *)         usage; exit 2 ;;
    esac
}

usage() {
    usage_run
    usage_evidence
    usage_source
}

usage_run() {
    cat <<'EOF'
floor — where work happens.

  run.sh new <title>              make a run, and point this checkout at it
  run.sh path                     print the active run's directory, or exit 1
  run.sh home                     print the Foundry home
  run.sh runs                     every run this home holds, and how far each one got
  run.sh settled                  whether this host holds work, and what it is waiting for
  run.sh bootstrap                print the run's bootstrap target, or exit 1
  run.sh targets                  list unit 01's targets
  run.sh targets add <repo> <ref> add one
  run.sh policy                   list what this run may change
  run.sh policy authorize <repo>  let this run change one more
  run.sh policy deliver-to <repo> let this run write to one — a second act, and grading is not it
  run.sh policy merge-to <repo>   let this run land what it delivered — a third act, absent by default
  run.sh policy closes            say a person read the item's list and it is met
  run.sh charter                  print what must be true for this run to be good
  run.sh charter derive           derive clauses from this repository, pinned at its base
  run.sh charter check            report clauses that drifted from their pins, or went missing
  run.sh charter introduce <kind> <text>
                                  add a clause nothing derived — it stays introduced
  run.sh gates                    run every pinned gate and record each — exit 14 if one did not pass
  run.sh judged                   ask every judge the charter names — exit 39 if one did not approve
  run.sh open                     check out every selected target in isolation, and print where
  run.sh commit <message>         commit what is staged, and record that this run made it
  run.sh complete                 may this run deliver? exit 15 names what is missing
  run.sh deliver <title> [brief]  push the work, with a file the source carries as the body
  run.sh aside [text]             record what this run cannot act on, or print what it has
  run.sh claim <item>             take it for this host, or say who has it
  run.sh release <item>           let it go, if this host took it
  run.sh observe [event] [k=v...] record that something happened, or print what did
  run.sh observed [event]         every run's observations, with the run named
  run.sh merge                    land what was graded, or say why it may not be
  run.sh reconcile [accept <sha> <reason>]
                                  what else is open, or a person accounting for a stray commit
  run.sh authorise                refuse a run describing no work, or whose selection moved —
                                  exit 1, 5, 8, 9, 10, 11 or 12
EOF
}

# Its own list, because `usage` was one line over the cap the shell gate holds. Split by what a verb
# reaches rather than by length, or the next verb moves the seam again.
# The ledger's own list. Split from `usage_run` the same way `usage_source` was — by what a verb
# reaches, so the next verb added does not move the seam again.
usage_evidence() {
    cat <<'EOF'
  run.sh evidence                 print what this run has proved
  run.sh evidence record <name> <command...>   run it, and stamp what happened
  run.sh evidence handed <clause> <judge> <how> [brief]
                                  say this judge was given the bar, how it ran, and which brief
  run.sh evidence verdict <clause> <judge> <approve|reject|revise> <text> <sha>
  run.sh evidence receipt <file>  read a judgement receipt, and stamp what it attests
EOF
}

usage_source() {
    cat <<'EOF'
  run.sh source read <item>       pull the item's words into this run
  run.sh source kind              what the source says this work is, or exit 1
  run.sh source publish <branch> <title>
                                  report this run's delivery, and print its identity
  run.sh source ask <stage> <clause> <question>
                                  ask a human about one clause, and print the question's identity
  run.sh source receive <stage> <clause>
                                  print the answer to that question, or exit 1
EOF
}

note() { printf 'floor: %s\n' "$1" >&2; }

die_homeless() {
    note "no FOUNDRY_HOME and no HOME — nowhere to put a run"
    exit 3
}

die_unwritable() {
    note "could not write $1"
    exit 3
}

# Git Bash sets `$HOME` on Windows too, so this needs no branch for it. It must not grow one.
foundry_home() {
    [ -n "${FOUNDRY_HOME:-}" ] && { printf '%s' "$FOUNDRY_HOME"; return 0; }
    [ -n "${HOME:-}" ]         && { printf '%s/.foundry' "$HOME"; return 0; }
    return 1
}

print_home() { printf '%s\n' "$HOME_DIR"; }

# Every run this home holds, and how far each got. The only verb not scoped
# to the active run, because selection lived in whoever was driving it.
list_runs() {
    [ "$#" -eq 0 ] || { usage; exit 2; }
    [ -d "$RUNS" ] || return 0

    for dir in "$RUNS"/*/; do
        [ -d "$dir" ] || continue

        # The glob ends every path with a slash. `basename` strips one and `${x##*/}` does not,
        # so reading the id without stripping it first returned nothing at all.
        held=${dir%/}
        printf '%s\t%s\n' "$(how_far "$held")" "${held##*/}"
    done
}

#
# Whether this host can be replaced. A run holding a workspace has a
# checkout somebody may be writing to, and swapping the
# host under it loses work nobody recorded.
#
# Three of the four conditions a safe boundary wants fall out of that one test. An attached
# session and a gate mid-run both hold a workspace, and the fourth
# is a transition floor has no word for.
#
settled() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    inflight=$(runs_in_flight)
    [ -n "$inflight" ] || { note "nothing is in flight"; return 0; }

    note "these runs hold a workspace, so this host is not settled:"
    printf '%s
' "$inflight" | while read -r underway; do note "  $underway"; done

    return 29
}

# A workspace is the part a worker writes to. A run that only charted holds
# none, so replacing the host under it loses nothing, and a delivered run is done.
runs_in_flight() {
    list_runs | awk '$1 == "open" || $1 == "graded" { print $2 }'
}

# The furthest thing a run's own files say about it, read downward so the
# first that holds wins. A position, never a verdict: waiting needs the source.
how_far() {
    [ -s "$(delivery_file "$1")" ] && { printf 'delivered'; return; }
    [ -s "$(evidence_file "$1")" ] && { printf 'graded';    return; }

    [ -n "$(ls "$(unit_workspace "$1")" 2>/dev/null)" ]      && { printf 'open';     return; }
    [ -n "$(selected_targets "$(unit_targets_file "$1")")" ] && { printf 'selected'; return; }
    [ -s "$(charter_file "$1")" ]                            && { printf 'charted';  return; }

    printf 'new'
}

make_run() {
    title=$1
    [ -n "$title" ] || { note "new needs a title"; exit 2; }

    day=$(date +%Y-%m-%d)
    [ -n "$day" ] || { note "the clock did not answer, so this run would have no date"; exit 2; }

    id=$(mint_id "$day" "$title") || die_unwritable "$RUNS"
    dir="$RUNS/$id"

    reserve_name "$id"         || die_unwritable "$GRANTS/$id"
    build_layout "$dir"        || die_unwritable "$dir"
    write_id "$dir" "$id"
    write_item "$dir" "$title" || die_unwritable "$dir/item.md"
    write_bootstrap "$dir"
    stamp_selection "$dir" "$(selector)" "$id"
    say_if_nobody_selected
    point_this_checkout_at "$id"
    emit "$dir" run.began "$(began_with)"

    printf '%s\n' "$dir"
}

# `<date>-<slug>-<first free slot>`. The day arrives read, because a name cannot check itself.
#
# Eight concurrent runs minted four ids beginning with `-`: under fork pressure `date` answered
# nothing, and the substitution was silently empty. Seven slots served eight runs, and two runs
# sharing one slot share its targets — so a grant a person gave to one authorises the other.
mint_id() { claim_free_slot "$1-$(slug "$2")"; }

authority_file() { printf '%s/authority' "$1"; }

#
# Who selected the work item, and which run it authorised — RFC-001 invariant 4.
#
# **Not evidence, and not in that ledger.** It names no clause, so it can satisfy none. §2.5 keeps
# the two apart by giving this a different shape rather than the evidence record a field to sort by:
# three columns, and neither `unit` nor `ref` is one of them. A record with no `ref` cannot satisfy
# the completion invariant, which is the separation stated in the shape instead of in a sentence.
#
# It happens before the run does, so it lands with the layout and names the run it authorised.
#
stamp_selection() {
    printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(one_line "$2")" "$3" \
        >> "$(authority_file "$1")" 2>/dev/null || die_unwritable "$(authority_file "$1")"
}

#
# The human this run answers to. `FOUNDRY_WHO` first: a harness knows who it is acting for, and git
# knows only whose checkout this is.
#
# Nobody is a real answer and is written as one. `new` changes nothing in any repository, so it is
# the wrong place to demand a name — completion is, where a run nobody selected is a run nobody may
# deliver.
#
selector() { printf '%s' "${FOUNDRY_WHO:-$(git config user.email 2>/dev/null)}"; }

# Nobody is a real answer and the run is still made — `selector` says why `new` is the wrong place to
# demand a name. What it may not do is stay quiet: a second machine that learns this at `complete` has
# already done the work.
say_if_nobody_selected() {
    [ -n "$(selector)" ] && return 0

    note "nobody is recorded as having selected this run — set FOUNDRY_WHO, or it may not deliver"
}

#
# `<base>-NNNN`, counting up from zero until nothing holds that name.
#
# Counting, not seeding from `$$`. Every `new` is a fresh process, so pid-seeded ids differed without
# the loop ever running once — and the test that claimed to prove uniqueness passed without
# exercising it. A hash would not help: `md5` is BSD's, `shasum` is not everywhere, and it would
# still need the loop.
#
# Grants outlive the run directory by design, so a slot reclaimed after `rm -rf` would hand the next
# run the deleted run's allowlist — authority no human gave it.
slot_is_reserved() { [ -e "$GRANTS/$1" ]; }

#
# A run's name, held for good.
#
# Reserving it on the first grant left a run that authorised nothing free to give its name back when
# its directory went, and the same base then minted the same id and the same clause id — so a later
# run derives an earlier one's question byte for byte, and an answer left where it outlives a run
# matches the wrong one. RFC-001 §2.1 asks for a run unique over all time; this is what makes it one.
#
# Reserved after the slot is claimed, never inside the loop that claims it. A reservation that can
# fail while the run directory already exists leaves the loop counting past a failure counting cannot
# fix, which is the hang `claim_free_slot` refuses by name.
#
reserve_name() { mkdir -p "$GRANTS/$1" 2>/dev/null; }

slot_is_taken() { slot_is_reserved "$1" || [ -e "$RUNS/$1" ]; }

# `mkdir` without `-p`: it creates the directory or fails because someone else already did, in one
# step nothing can interleave with. `-p` succeeds on a directory that already exists, which reports
# the collision as success — testing a name and creating it later is the same mistake spelled longer.
claim_slot() {
    slot_is_reserved "$1" && return 1
    mkdir "$RUNS/$1" 2>/dev/null
}

# `<base>-NNNN`, counting up from zero until a claim lands.
#
# Counting, not seeding from `$$`. Every `new` is a fresh process, so pid-seeded ids differed without
# the loop ever running once — and the test that claimed to prove uniqueness passed without
# exercising it. A hash would not help: `md5` is BSD's, `shasum` is not everywhere, and it would
# still need the loop.
claim_free_slot() {
    # Refuse here, not in the loop. The loop reaches the same answer only by counting, so a mutant
    # that removes its guard leaves an unwritable home spinning instead of failing.
    mkdir -p "$RUNS" 2>/dev/null || return 1

    n=0

    while :; do
        candidate="$1-$(printf '%04x' "$n")"

        claim_slot "$candidate" && { printf '%s' "$candidate"; return 0; }

        # Taken is the only failure worth counting past. `mkdir -p` above succeeds on a `runs/` that
        # exists and cannot be written, so without this the loop spins for ever on a directory it
        # will never create.
        slot_is_taken "$candidate" || return 1

        n=$((n + 1))
    done
}

# `sed`, not `tr -c`: the complement form needs its replacement set padded, and implementations
# disagree about who pads it. The trim runs twice because `cut` can slice mid-word and leave a dash.
slug() {
    text=$(printf '%s' "$1" \
        | tr 'A-Z' 'a-z' \
        | sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-*//; s/-*$//' \
        | cut -c1-40 \
        | sed 's/-*$//')

    [ -n "$text" ] || text=run
    printf '%s' "$text"
}

# One unit today. The level ships anyway, because adding it later moves every path in every adapter.
build_layout() {
    mkdir -p "$1/memory" "$1/planning" "$1/units/01/memory"
}

#
# The run's own name for itself, written once.
#
# Grants are keyed by it and kept beside the runs, never inside one — a slot reclaimed after `rm -rf`
# would otherwise hand the next run a dead run's allowlist. That is why renaming the directory used
# to lose every grant at exit 0: the key moved and nothing held the old one.
#
write_id() { printf '%s\n' "$2" > "$1/id" 2>/dev/null || die_unwritable "$1/id"; }

# Fails open on a missing file, which is how a run made before this rule keeps working. It also
# fails open on an empty or unreadable one, and that is a hole rather than a grandfather clause: the
# guard it feeds cannot tell "no id was ever written" from "the id will not read".
recorded_id() { [ -f "$1/id" ] && read -r named < "$1/id" && printf "%s" "$named"; }

#
# Authority is bound to the id, so a directory that no longer answers to it has none.
#
# Refuses rather than following the recorded id, which would let a rename carry a grant set to a name
# a human never authorised.
#
# **Renames only.** Grants key on the directory's name, so a copy that keeps its name under another
# parent still reads the same grants and passes here. Closing that needs an identity the filesystem
# cannot supply, and it belongs to the workspace boundary.
#
# Every command that reads the grants for authority calls this. `policy` refusing alone let a rename
# onto a deleted run's id add a target through `targets add` at exit 0.
#
refuse_renamed_run() {
    named=$(recorded_id "$1") || return 0
    [ "$named" = "${1##*/}" ] && return 0

    note "this run is at [${1##*/}] and calls itself [$named], so its grants are not here"
    note "move it back, or start a new run — authority a human gave is not renamed with a directory"
    exit 13
}

# The title, until a work source is asked for the item's own words. `source read` replaces this.
write_item() {
    cat > "$1/item.md" <<EOF
---
source: cli
---

$2
EOF
}

# Inside the git directory, so it is never committed and needs no gitignore entry. A worktree has
# its own git directory, so it gets its own pointer.
pointer() {
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1
    [ -n "$git_dir" ] || return 1
    printf '%s/foundry-run' "$git_dir"
}

point_this_checkout_at() {
    mark=$(pointer) || return 0
    printf '%s\n' "$1" > "$mark" 2>/dev/null || note "could not write $mark"
}

active_run() {
    named_run     && return 0
    pointed_run   && return 0
    enclosing_run
}

#
# The run this shell is standing in. A workspace lives inside its run, so a person handed
# only that path can act on it — RFC-001 §4 calls that the test of whether the
# decomposition was right, and it answered nothing before this.
#
# Last, never first. A named run and a pointed checkout are both something a human chose; this is
# only where the shell happens to be, and it must not outrank either.
#
enclosing_run() {
    dir=$(pwd -P 2>/dev/null) || return 1

    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        is_a_run "$dir" && { printf '%s' "$dir"; return 0; }
        dir=${dir%/*}
    done

    return 1
}

# The run's own name for itself, matching the directory holding it. A copy under another parent keeps
# its name and passes here, which is the same hole `refuse_renamed_run` records — closing it
# needs an identity the filesystem cannot supply.
is_a_run() {
    [ -f "$1/id" ] || return 1
    [ "$(recorded_id "$1")" = "${1##*/}" ]
}

# `-d` matches the check kernel makes before it moves memory. Drop it and floor calls a run active
# that kernel has already fallen back from, while announce stays quiet because the variable is set.
# A caller may write the path with a trailing slash. Twelve places read the last segment with
# `${x##*/}`, which returns nothing when the path ends in one — `basename` strips it first and
# this does not. Stripped here, where the path enters, rather than at each of the twelve.
#
# A run at `/` keeps its own name, because stripping that would leave nothing at all.
named_run() {
    [ -n "${FOUNDRY_RUN:-}" ] && [ -d "$FOUNDRY_RUN" ] || return 1

    said=${FOUNDRY_RUN%/}
    [ -n "$said" ] || said=$FOUNDRY_RUN
    printf '%s' "$said"
}

# The run this checkout was pointed at, when it is still there.
pointed_run() {
    mark=$(pointer) || return 1
    [ -f "$mark" ] || return 1

    # `read` takes the first line without a process. `head -1` cost two.
    IFS= read -r id < "$mark" 2>/dev/null || id=''
    [ -n "$id" ] || return 1

    dir="$RUNS/$id"
    [ -d "$dir" ] || return 1

    printf '%s' "$dir"
}

print_active_run() {
    dir=$(active_run) || exit 1
    printf '%s\n' "$dir"
}

#
# A repository identity that still means the same thing on another machine.
#
# Anything that resolves to a path is refused rather than written down: a path is precisely what a
# target may not hold. What each branch strips, and why, sits on the helper that strips it.
#
#
# What may be written down, quite apart from where it points.
#
# `grep -Fxq` reads a pattern holding a newline as a list of patterns and matches when any one line
# does, so a single grant would authorise a second repo — and the append writes both. `is_usable_ref`
# has guarded the other half of the line since #70; this is that guard on this half.
#
# `..` is rejected for the eye, not the parser: git resolves dot segments, so `acme/../evil/x.git`
# clones `evil` and reads as `acme` in a file whose whole job is being read.
#
is_storable() {
    case "$1" in
        *[!-A-Za-z0-9_.:/@~+%]* | */../* | */..) return 1 ;;
    esac
    return 0
}

# Guards the argument, not each result: stripping only removes characters, so nothing here can put
# one back.
repo_identity() {
    url=$1

    [ -n "$url" ]      || return 1
    is_storable "$url" || return 1
    is_file_url "$url" && return 1

    case "$url" in
        ssh://*) strip_ssh_password "$url"; return 0 ;;
        *://*)   strip_userinfo "$url";     return 0 ;;
    esac

    # scp-style goes through whole: `git@` is an ssh login, not a credential.
    is_scp_style "$url" || return 1
    printf '%s' "$url"
}

# A scheme is case-insensitive, so `FILE://` names the same path `file://` does.
is_file_url() {
    case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
        file://*) return 0 ;;
    esac
    return 1
}

# `ssh://git@host` carries a login, and dropping it breaks the clone. Take the password, leave the
# user.
strip_ssh_password() { printf '%s' "$1" | sed 's|://\([^/@]*\):[^/]*@|://\1@|'; }

# Everywhere else the whole userinfo is a credential. Greedy to the last `@` before the path,
# because a password may contain one — `[^/@]*@` stopped at the first and left the tail on disk.
strip_userinfo() { printf '%s' "$1" | sed 's|://[^/]*@|://|'; }

#
# `user@host:path`, and not a path that happens to hold a colon.
#
# A `/` before the colon means a path — git's own rule, without which `/srv/git/v1.2:mirror` reads as
# scp-style. A host with no dot in it is a Windows drive letter.
#
is_scp_style() {
    case "$1" in *:*) ;; *) return 1 ;; esac

    host=${1%%:*}
    case "$host" in */*) return 1 ;; esac
    case "${host##*@}" in *.*) return 0 ;; esac

    return 1
}

# The ref work starts from — not the branch it will deliver on. A branch when there is one, the
# commit when the head is detached.
base_ref() {
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && { printf '%s' "$branch"; return 0; }
    git rev-parse HEAD 2>/dev/null
}

# The commit the run starts from. `base_ref` names where work happens and moves as the run commits;
# this does not, and provenance is read here — RFC-001 invariant 2, the artifact captured at the
# base ref. A branch name is not a base. Derive through one and a worker commits its own bar.
#
# `--verify`, because a repository with no commits answers `HEAD` on stdout and fails only on stderr.
# Recording that string would pin every clause to a ref git cannot resolve.
base_commit() { git rev-parse --verify --quiet HEAD 2>/dev/null; }

# The repository this shell sits in, as a target. Nothing when there is no git, no origin, or no
# portable identity.
bootstrap_here() {
    git rev-parse --git-dir >/dev/null 2>&1 || return 1
    url=$(git remote get-url origin 2>/dev/null) || return 1
    identity=$(repo_identity "$url") || return 1

    # Both halves or nothing. `add_target` refuses a missing ref, and two writers of one contract
    # cannot disagree about what a complete line is.
    ref=$(base_ref)
    [ -n "$ref" ] || return 1

    # The base is optional here and required by `derive`. A repository with no commits still has an
    # identity `policy` must answer for; what it has no answer for is where a requirement came from.
    line="$identity $ref"
    commit=$(base_commit) && line="$line $commit"

    printf '%s' "$line"
}

#
# Zero or one per run. Two different things, and only the first is an answer:
#
#   no portable bootstrap can be derived    → valid absence, record none
#   one was derived but cannot be written   → failure, and the run does not exist
#
# It used to note the second and carry on, which turned a lost target into a run that looked like it
# never had one. Nothing downstream could tell them apart.
#
# The failure cannot be forced portably — `build_layout` creates the directory and nothing runs
# between that and this write — so the guard ships untested rather than pretended.
#
write_bootstrap() {
    line=$(bootstrap_here) || return 0
    printf '%s\n' "$line" > "$1/bootstrap" 2>/dev/null || die_unwritable "$1/bootstrap"
}

print_bootstrap() {
    dir=$(active_run) || exit 1
    [ -f "$dir/bootstrap" ] || exit 1
    cat "$dir/bootstrap"
}

# Under the unit, not the run root: a workspace belongs to a unit, and targets belong to a workspace.
unit_targets_file() { printf '%s/units/01/targets' "$1"; }

#
# The workspace — one isolated checkout per selected target, under the unit that owns it.
#
# **One adapter is not a proven seam.** §2.6 leaves this contract deliberately unwritten, and §3
# holds a seam unproven until two adapters satisfy it. This is one: a clone, on this machine, of a
# target this checkout already is. It exists because nothing downstream can run without isolation,
# and it claims nothing about container, VM or sandbox adapters.
#
# **A clone, never a worktree.** A worktree shares `.git` with the checkout it came from, so a worker
# could move the source's refs — the isolation this exists for, absent.
#
# Under the run, which already lives outside every repository it changes, so a session that dies
# leaves the workspace as it was and the next `open` attaches to it.
#
open_workspace() {
    dir=$(active_run) || exit 1
    [ "$#" -eq 0 ] || { usage; exit 2; }

    # Read before `authorise` runs: its callee `refuse_unselectable` assigns `dir` too, and every
    # variable here is global.
    root=$(unit_workspace "$dir")
    selection=$(unit_targets_file "$dir")

    # A workspace is where mutation happens, so it may not exist for a run nobody authorised. One
    # rule, two callers — idempotent once the selection is frozen, so `open` refuses without
    # restating any of its twelve reasons.
    authorise
    here=$(this_repository)

    # A here-doc, not a pipe: `exit` inside a pipe leaves the subshell, so a target that could not be
    # checked out would be followed by one that could and the run would believe it had a workspace.
    while read -r identity ref; do
        [ -n "$identity" ] || continue
        check_out_target "$root" "$identity" "$ref" "$here"
    done <<EOF
$(selected_targets "$selection")
EOF

    point_slots_at_run "$root" "${dir##*/}" || {
        note "[$root] holds a checkout nobody can join — its run pointer could not be written"
        exit 16
    }
    printf '%s\n' "$root"
}

#
# §4's test of whether the decomposition was right: *a person can join by opening a shell in the
# workspace and reading the run.* They could not — the pointer landed only in the checkout Foundry
# was invoked from, so joining meant carrying `FOUNDRY_RUN` by hand, which is the new machinery §4
# says would mean the nouns were wrong.
#
# On every open, attach included, so a pointer that went missing comes back. Writing the same id
# twice is writing it once.
#
point_slots_at_run() {
    for slot in "$1"/*/; do
        [ -d "$slot/.git" ] || continue
        printf '%s\n' "$2" > "$slot/.git/foundry-run" || return 1
    done
}

# What the unit selected, as `identity ref`. Comments and blank lines are not selections.
selected_targets() { awk '!/^[ \t]*#/ && NF { print $1, $2 }' "$1" 2>/dev/null; }

unit_workspace() { printf '%s/units/01/workspace' "$1"; }

#
# The directory one target takes: a name to read, and a digest to be right.
#
# **The digest is the identity; the name is decoration.** Folding punctuation to `-` made
# `acme/a-b`, `acme/a/b`, `acme/a.b` and `acme/a_b` one directory — four repositories, one checkout.
# A longer fold would only move the collision.
#
# **Twelve characters do not make a collision impossible, and nothing here claims they do.** What
# they buy is rarity; what makes a collision safe is `attached`, which compares the origin and finds
# another repository's checkout. Two targets on one slot is refused, never shared — so the guarantee
# holds at any prefix length, and the length is only how often a reader meets that refusal.
#
target_slot() { printf '%s-%s' "$(readable_name "$1")" "$(identity_digest "$1")"; }

readable_name() { printf '%s' "$1" | sed 's#.*/##; s#\.git$##; s#[^A-Za-z0-9][^A-Za-z0-9]*#-#g'; }

# `git hash-object`, because git is already declared and a checksum is not collision-resistant —
# `clause_id` uses `cksum` to name a clause, which is a different job with a different bar.
identity_digest() {
    sha=$(printf '%s' "$1" | git hash-object --stdin) || return 1

    printf '%s' "$sha" | awk '{ print substr($0, 1, 12) }'
}

#
# A target is an identity, never a path — §2.3 — so the only one this can clone is the one this
# checkout already is. Any other is named and refused rather than guessed at: a URL rebuilt from an
# identity carries no credential, and a private repository would fail at the network with a message
# about the wrong thing.
#
check_out_target() {
    slot="$1/$(target_slot "$2")"

    attached "$slot" "$2" "$3" && { refuse_unrecorded_base "$1" "$2"; return 0; }
    refuse_occupied_slot "$slot" "$2"
    [ "$2" = "$4" ] || { note "no checkout here to clone [$2] from — one target, for now"; exit 16; }

    build_and_publish "$slot" "$2" "$3"
    record_base "$1" "$2" "$slot"
}

#
# A workspace that was here before any base was recorded.
#
# Its head is where the work got to, never where it started, so adopting it
# would name every commit already carried as one this run made.
#
# A run that opened before provenance did cannot deliver. Nothing here can be
# reconstructed, and a guess is the fault this exists to catch.
refuse_unrecorded_base() {
    [ -n "$(recorded_base "$1" "$(target_slot "$2")")" ] && return 0

    note "[$2] has a workspace and no recorded base — saw nothing, wanted a sha from \`open\`"
    note "  this run opened before its base was recorded. Open a new one from where the work is"
    exit 33
}

# Where this target started. Written once and never again: a
# second write would move the floor under every later answer.
#
# One line per target, because a run may hold several.
record_base() {
    file=$(base_file "$1")
    slot=$(target_slot "$2")

    grep -q "^$slot " "$file" 2>/dev/null && return 0

    sha=$(git -C "$3" rev-parse --verify --quiet HEAD 2>/dev/null) || sha=
    [ -n "$sha" ] || { note "[$2] has no head to record as its base"; exit 16; }

    mkdir -p "${file%/*}" || die_unwritable "$file"
    printf '%s %s\n' "$slot" "$sha" >> "$file" || die_unwritable "$file"
}

#
# The only operation that makes a commit and the only one
# that records provenance. A commit made any other way is
# unrecorded, and `deliver` refuses it.
#
# Provenance, never acceptance. A commit this made needs no
# human. A commit nobody can account for does.
commit_work() {
    said=${1:-}
    [ "$#" -le 1 ] || { usage; exit 2; }
    [ -n "$said" ] || { note "commit names the change"; exit 2; }

    dir=$(active_run) || exit 1
    refuse_unreadable_run "$dir"

    tree=$(unit_work_tree "$dir" "$(this_repository)") || exit 16
    git -C "$tree" diff --cached --quiet 2>/dev/null \
        && { note "nothing is staged in [$tree]"; exit 2; }

    why=$(git -C "$tree" commit -qm "$said" 2>&1) || {
        note "could not commit in [$tree]: $why"
        exit 16
    }

    record_produced "$dir" "$tree"
}

# Append-only, written after the commit exists. A sha
# recorded for a commit that failed proves nothing.
record_produced() {
    sha=$(git -C "$2" rev-parse --verify --quiet HEAD 2>/dev/null) || sha=
    [ -n "$sha" ] || { note "committed in [$2] and could not read the sha back"; exit 16; }

    file=$(produced_file "$(unit_workspace "$1")")
    mkdir -p "${file%/*}" || die_unwritable "$file"
    printf '%s\n' "$sha" >> "$file" || die_unwritable "$file"
    printf '%s\n' "$sha"
}

#
# Every commit this delivery carries that the run cannot
# account for.
#
# Provenance comes from the record, never from an author, a
# message, another ref or a patch id. Those are observations.
#
# Fails closed. An unreadable base, head or range refuses,
# and each says what it saw and what it wanted.
refuse_foreign_ancestry() {
    work=$(unit_workspace "$1")
    tree=$(unit_work_tree "$1" "$2") || exit 16

    base=$(recorded_base "$work" "$(target_slot "$2")")
    [ -n "$base" ] || {
        note "no base was recorded for [$2] — saw nothing, wanted a sha from \`open\`"
        exit 33
    }

    head=$(git -C "$tree" rev-parse --verify --quiet HEAD 2>/dev/null) || head=
    [ -n "$head" ] || { note "[$tree] has no head to inspect — saw nothing, wanted a sha"; exit 33; }

    # `base..head` answers for a head the base is not behind, and the answer is
    # about a history that never held it. A rebuilt branch reads as a grown one.
    git -C "$tree" merge-base --is-ancestor "$base" "$head" 2>/dev/null || {
        note "[$base] is not behind [$head] in [$tree] — saw a rebuilt branch, wanted a grown one"
        exit 33
    }

    carried=$(git -C "$tree" rev-list "$base..$head" 2>/dev/null) || {
        note "could not walk [$base..$head] in [$tree] — saw a failed rev-list, wanted a range"
        exit 33
    }

    strangers=$(unaccounted_in "$work" "$carried")
    [ -n "$strangers" ] || return 0

    note "this delivery carries commits the run did not make:"
    printf '%s\n' "$strangers" >&2
    note "  a person runs \`reconcile accept <sha> <reason>\`, in a shell with no FOUNDRY_WORKER"
    exit 32
}

# A sha the production record does not hold, and no human has
# accepted. Both files are append-only; absence is the answer.
unaccounted_in() {
    made=$(produced_file "$1")
    said=$(accepted_file "$1")

    printf '%s\n' "$2" | while IFS= read -r sha; do
        [ -n "$sha" ] || continue
        grep -qx "$sha" "$made" 2>/dev/null && continue
        grep -q "^$sha " "$said" 2>/dev/null && continue
        printf '  %s\n' "$sha"
    done
}

#
# A person accounting for one commit the run did not make.
#
# One sha per call, with a reason, appended and never edited.
# A record that can be rewritten is not an account.
accept_ancestry() {
    sha=${1:-}; shift 2>/dev/null
    why=$*

    [ -n "$sha" ] || { note "accept names a commit"; exit 2; }
    [ -n "$why" ] || { note "accept names why [$sha] belongs here"; exit 2; }

    refuse_self_accounting
    dir=$(active_run) || exit 1
    refuse_unreadable_run "$dir"

    tree=$(unit_work_tree "$dir" "$(this_repository)") || exit 16
    full=$(git -C "$tree" rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null) || full=
    [ -n "$full" ] || { note "[$sha] is not a commit in [$tree]"; exit 2; }

    file=$(accepted_file "$(unit_workspace "$dir")")
    mkdir -p "${file%/*}" || die_unwritable "$file"
    printf '%s %s %s %s\n' "$full" "$(selector)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$why" >> "$file" \
        || die_unwritable "$file"

    note "recorded: [$full] accepted"
}

#
# Who may write one of those accounts, and who may not.
#
# The worker produced the work. A record it writes about its own commits is
# the producer signing off its own bar, which never happens here.
#
# So the agent is refused and a person is named. Both are records and neither
# is proof — #156 owns making the actor real, and nothing here may imply it is.
refuse_self_accounting() {
    said=$(worker)
    [ -z "$said" ] || {
        note "[$said] produced this work, so it may not account for what it did not record"
        note "  a person runs this in a shell with no FOUNDRY_WORKER set"
        exit 34
    }

    [ -n "$(selector)" ] || {
        note "nobody is named to account for this — saw nothing, wanted FOUNDRY_WHO"
        exit 34
    }
}

base_file()     { printf '%s/../base' "$1"; }
produced_file() { printf '%s/../produced' "$1"; }
accepted_file() { printf '%s/../accepted' "$1"; }

# The base this target started from, or nothing.
recorded_base() {
    awk -v want="$2" '$1 == want { print $2; exit }' "$(base_file "$1")" 2>/dev/null
}

#
# Ours, whole, and this target's. Three questions, because a slot can be a valid checkout of the
# wrong repository: `open` answered 0 for one holding another repository entirely, and the gates
# would then have graded it.
#
# `-d "$1/.git"` before anything else: `git -C` searches upward, so an empty slot would otherwise be
# answered for by an ancestor repository. A clone, never a worktree, so the directory is exact.
#
# A killed clone is no longer among the cases — it dies inside the build path and never reaches a
# slot. What is left is a slot damaged by hand, or by a worker.
#
attached() {
    [ -d "$1/.git" ] || return 1
    git -C "$1" rev-parse --verify --quiet HEAD >/dev/null 2>&1 || return 1
    [ "$(git -C "$1" remote get-url origin 2>/dev/null)" = "$2" ] || return 1
    [ "$(git -C "$1" config --get foundry.ref 2>/dev/null)" = "$3" ]
}

#
# Anything else at that path is neither ours to use nor ours to delete. `-L` as well as `-e`, because
# `[ -e ]` follows the link and a dangling one would read as nothing there.
#
refuse_occupied_slot() {
    { [ -e "$1" ] || [ -L "$1" ]; } || return 0
    note "[$1] is not a checkout of [$2] — remove it and open again"
    exit 16
}

#
# Built beside the slot, published into it. **A reader never sees a half-built workspace**, because
# the slot does not exist until the checkout is whole.
#
# `mkdir` on the build path is what serialises this, not the rename: measured, `mv` onto an existing
# directory moves the source *inside* it and exits 0, so a rename cannot be the thing that refuses.
# A creator that dies leaves `<slot>.building` — recoverable garbage, and never a slot.
#
build_and_publish() {
    building="$1.building"

    mkdir -p "${1%/*}" 2>/dev/null || die_unwritable "${1%/*}"
    mkdir "$building" 2>/dev/null \
        || { note "[$2] is being checked out — remove [$building] if no session is"; exit 16; }

    clone_into "$building" "$(repo_root)" "$2" "$3" || { rm -rf "$building"; exit 16; }
    publish_workspace "$building" "$1"
}

publish_workspace() {
    [ -e "$2" ] && { rm -rf "$1"; note "[$2] appeared while it was being built"; exit 16; }

    mv "$1" "$2" 2>/dev/null && return 0
    rm -rf "$1"
    note "could not publish [$2]"
    exit 16
}

#
# Local objects, remote identity. Cloning from the checkout is what makes this need no network; the
# origin is then the identity the target names, so a branch pushed from here goes where the target
# says rather than where this machine happened to be.
#
# `--no-hardlinks`, because a local clone shares object files by default and a workspace that shares
# anything with the checkout it isolates from is worth the disk.
#
#
# Every step returns rather than exits, so `build_and_publish` can clear the build path before it
# refuses. Left behind, `<slot>.building` makes every later `open` answer *being checked out* — a
# typo in a ref would be diagnosed once and misdiagnosed for ever after.
#
clone_into() {
    fetch_objects   "$1" "$2" "$3" || return 1
    check_out_ref   "$1" "$3" "$4" || return 1
    point_at_origin "$1" "$3"      || return 1
    record_base_ref "$1" "$4"
}

#
# What it was opened for, in git's own config rather than a file of ours — a second store is a second
# thing to drift.
#
# **Compared against the run's frozen selection, never against itself.** The value lives in a
# repository the worker owns, so a worker can write it; what it is checked against does not. That
# makes it the same kind of guard as the charter — it catches a workspace built for another ref, and
# it does not resist someone editing both sides. Containment is the runtime boundary's, and there
# isn't one.
#
record_base_ref() {
    git -C "$1" config foundry.ref "$2" 2>/dev/null && return 0
    note "could not record the base ref in [$1]"
    return 1
}

fetch_objects() {
    why=$(git clone --quiet --no-hardlinks "$2" "$1" 2>&1) && return 0
    note "could not clone [$3]: $why"
    return 1
}

#
# After cloning, never by `--branch`, which takes a branch or a tag and refuses a sha. §2.3 permits
# all three, and `base_ref` records a sha whenever the checkout is detached — so `--branch` made a
# legal target unopenable and said so in a message about the wrong thing.
#
check_out_ref() {
    git -C "$1" checkout --quiet "$3" 2>/dev/null && return 0
    note "[$2] has no ref [$3] to check out"
    return 1
}

point_at_origin() {
    git -C "$1" remote set-url origin "$2" 2>/dev/null && return 0
    note "could not point [$1] at [$2]"
    return 1
}

targets() {
    dir=$(active_run) || exit 1
    refuse_renamed_run "$dir"

    file=$(unit_targets_file "$dir")

    case "${1:-}" in
        '')  refuse_unselectable "$dir" "$file" || exit 5
             list_targets "$file" ;;
        add) shift
             refuse_unselectable "$dir" "$file" || exit 5
             [ "$#" -eq 0 ] && { add_advised "$dir" "$file"; return; }
             add_target "$dir" "$file" "${1:-}" "${2:-}" ;;
        *)   usage; exit 2 ;;
    esac
}

#
# Policy — what this run may change.
#
# **This is not a security boundary.** It records what was permitted and refuses what was not. A
# worker holding a shell as the same user can edit the grants directly, and nothing here stops that.
# Resisting a hostile worker needs a runtime that puts these files out of its reach, and that is a
# later stage. Saying otherwise would be the kind of claim this repo exists to refuse.
#
# What it does buy: an accident cannot widen authority. No ordinary command grants anything, so a
# work item naming a repository, or a planner reaching for one, is refused rather than obeyed.
#
policy() {
    dir=$(active_run) || exit 1
    refuse_renamed_run "$dir"

    case "${1:-}" in
        '')         list_policy "$dir" ;;
        authorize)  shift; authorize  "$dir" "${1:-}" ;;
        deliver-to) shift; deliver_to "$dir" "${1:-}" ;;
        merge-to)   shift; merge_to   "$dir" "${1:-}" ;;
        closes)     shift; closes     "$dir" ;;
        *)          usage; exit 2 ;;
    esac
}

#
# One run, one set of grants — kept beside the runs, never inside one.
#
# Scoped to the run because authorising a repository for today's work must not quietly authorise
# every work item this machine ever runs. Project-wide grants can come later, if asking twice turns
# out to be real friction rather than imagined friction.
#
grants_file() { printf '%s/%s/targets' "$GRANTS" "${1##*/}"; }

#
# The bootstrap target's identity, without its ref.
#
# A file with a blank first field is no identity. Saying so here keeps the two readers of this file
# agreeing: `policy` would otherwise list a nameless entry that authorises nothing.
#
bootstrap_identity() {
    [ -f "$1/bootstrap" ] || return 1
    awk 'NR == 1 && $1 != "" { printf "%s", $1; found = 1 } END { exit !found }' "$1/bootstrap"
}

# The commit this run was made from. Recorded once, never rewritten — a run that could re-read it
# from the checkout would read whatever the worker last committed.
bootstrap_base() {
    [ -f "$1/bootstrap" ] || return 1
    awk 'NR == 1 && $3 != "" { printf "%s", $3; found = 1 } END { exit !found }' "$1/bootstrap"
}

# The ref the invoker stood on, and so where the bar came from — whatever the selection later names.
bootstrap_ref() {
    [ -f "$1/bootstrap" ] || return 1
    awk 'NR == 1 && $2 != "" { printf "%s", $2; found = 1 } END { exit !found }' "$1/bootstrap"
}

#
#
# One target, one ref. The charter pins at the bootstrap's commit and `open` checks out the ref the
# selection names, so a second ref derives the bar from a tree nothing grades — and invariant 2 reads
# as satisfied throughout, because a pin was captured, just not from there.
#
refuse_second_ref() {
    from=$(bootstrap_ref "$1") || return 0

    [ "$(bootstrap_identity "$1")" = "$2" ] || return 0
    [ "$from" != "$3" ] || return 0

    note "the bar was derived at [$from], so [$3] would be graded against a tree it never read"
    note "start a run there, or select [$from]"
    exit 4
}

#
# Authorised because someone invoked Foundry there, or because someone said so since.
#
# The bootstrap target is never copied into the grants file. A copy is a second place the truth
# lives, and the two drift the first time a run is edited by hand.
#
is_authorised() {
    [ "$(bootstrap_identity "$1")" = "$2" ] && return 0
    standing grade "$1" "$2" && return 0

    grants=$(grants_file "$1")
    [ -f "$grants" ] || return 1
    grep -Fxq -- "$2" "$grants"
}

#
# What a human said Foundry may do here without asking again — §2.3's allowlist, declared once
# instead of granted per run.
#
# **Read at the base commit, never the working tree.** A worker can edit this file, and a worker
# editing it must grant itself nothing: invariant 1's rule, that a run's own work may invalidate
# authority and never create it. A human commits it; a later run reads it.
#
standing() {
    base=$(bootstrap_base "$2") || return 1

    practice_at_base "$base" | awk -v verb="$1" -v id="$3" '$1 == verb && $2 "" == id ""' | grep -q .
}

practice_at_base() {
    scratch="${TMPDIR:-/tmp}/floor-practice-$$"

    why=$(git worktree add --detach --quiet "$scratch" "$1" 2>&1) || {
        note "could not read the practice at [$1]: $why"
        return 1
    }

    [ -f "$scratch/.foundry/practice" ] && awk '!/^[ \t]*#/ && NF' "$scratch/.foundry/practice"
    git worktree remove --force "$scratch" >/dev/null 2>&1
}

list_policy() {
    boot=$(bootstrap_identity "$1") && printf '%s\tbootstrap\n' "$boot"

    list_grants "$(grants_file "$1")"     granted
    list_grants "$(deliveries_file "$1")" deliver
    list_grants "$(closes_file "$1")"     closes
}

list_grants() {
    [ -f "$1" ] || return 0
    awk -v held="$2" '!/^[ \t]*#/ && NF { print $0 "\t" held }' "$1"
}

#
# Beside the allowlist, never merged into it. One file holding both would make `policy authorize`
# grant the second power as well.
#
deliveries_file() { printf '%s/%s/deliveries' "$GRANTS" "${1##*/}"; }

#
# **No bootstrap exemption, and that asymmetry is the separation.** `is_authorised` passes the
# repository Foundry was invoked in; standing somewhere is not permission to write there, and every
# run is bootstrapped somewhere.
#
may_deliver_to() {
    standing deliver "$1" "$2" && return 0

    file=$(deliveries_file "$1")
    [ -f "$file" ] || return 1
    grep -Fxq -- "$2" "$file"
}

#
# Both grants are one act on two files, and the predicate is the whole difference.
#
grant() {
    dir=$1; file=$2; holds=$3; repo=${4:-}

    [ -n "$repo" ] || { note "a grant names a repo"; exit 2; }

    identity=$(repo_identity "$repo") || {
        note "no portable identity for [$repo] — needs a remote url, no local path, no space, no .."
        exit 4
    }

    "$holds" "$dir" "$identity" && return 0
    record_grant "$file" "$identity"
}

record_grant() {
    mkdir -p "${1%/*}" || die_unwritable "$1"
    printf '%s\n' "$2" >> "$1" || die_unwritable "$1"
}

authorize()  { grant "$1" "$(grants_file "$1")"     is_authorised  "${2:-}"; }
deliver_to() { grant "$1" "$(deliveries_file "$1")" may_deliver_to "${2:-}"; }
merge_to()   { grant "$1" "$(merges_file "$1")"     may_merge_to   "${2:-}"; }

# The one grant that names no repository. A run reads one item, so there is
# nothing to point at. It records that a person read the list and found it met.
closes() {
    item=$(item_id "$1")
    [ -n "$item" ] || { note "this run reads no item, so there is nothing to close"; exit 2; }

    may_close_item "$1" && return 0
    record_grant "$(closes_file "$1")" "$item"
}

closes_file() { printf '%s/%s/closes' "$GRANTS" "${1##*/}"; }

# Keyed by the item, so a grant cannot outlive the item it was given for.
may_close_item() {
    file=$(closes_file "$1")
    [ -f "$file" ] || return 1

    grep -Fxq -- "$(item_id "$1")" "$file"
}

list_targets() {
    [ -f "$1" ] || return 0
    awk '!/^[ \t]*#/ && NF' "$1"
}

#
# The selection, re-checked every time it is read.
#
# `add_target` guarded the write and nothing guarded the read, so a line appended by hand was
# selected all the same. RFC-001 grades every charter clause against every selected target, which
# made this file a way to change what the run answers for without touching the charter — and
# re-deriving the charter cannot catch it, because the charter did not move.
#
# Refuses rather than filters. Dropping the line silently would leave the run working against a
# selection nobody chose, which is the failure this exists to make loud.
#
# `$1` in awk is whitespace-delimited, so it can never hold a space and the split below is safe.
#
refuse_unselectable() {
    dir=$1
    file=$2
    status=0

    [ -f "$file" ] || return 0

    for line in $(awk '!/^[ \t]*#/ && NF && NF != 2 { print NR }' "$file"); do
        note "line $line of the selection is not a repo and a ref"
        status=1
    done

    for identity in $(awk '!/^[ \t]*#/ && NF { print $1 }' "$file"); do
        is_authorised "$dir" "$identity" || {
            note "selected but not authorised: [$identity] — \`policy authorize\` it, or drop the line"
            status=1
        }
    done

    return "$status"
}

#
# What the item advised, selected — the one step a human took that Foundry claimed to own.
#
# **Advisory means anyone who can file an item wrote them**, so every one goes through the guards a
# typed target does. The item proposes; the allowlist decides, and exit 5 is where it says so.
#
# The bootstrap's ref, because a target read from an item names no ref and `refuse_second_ref` holds
# the bar and the graded tree to one anyway.
#
add_advised() {
    advised=$(advised_targets "$1")
    [ -n "$advised" ] || { note "the item advises no target, so name one"; exit 2; }

    for repo in $advised; do
        refuse_the_source_as_advice "$1" "$repo"
        add_target "$1" "$2" "$repo" "$(bootstrap_ref "$1")"
    done
}

#
# Advice may not make the source a target. An item filed in a repository
# can name that repository, and the bootstrap already authorises
# it wherever you stand, so advice alone would select it.
#
# A source that cannot say leaves this open. Nothing here can
# refuse what nothing can name, and a directory
# source has no repository to be.
#
refuse_the_source_as_advice() {
    from=$(source_says where "$(item_id "$1")" 2>/dev/null) || return 0
    [ "$from" = "$2" ] || return 0

    note "[$2] is where this item was filed, so advice may not select it"
    note "a human naming it with \`targets add\` still can"
    exit 28
}

# The `targets:` lines in the item's own words. Floor reads a repository and nothing else — what the
# source meant by the rest is the source's.
advised_targets() { awk '$1 == "targets:" { print $2 }' "$1/item.md" 2>/dev/null; }

# Selecting one repository twice. `ungradable_targets` counts selected targets, so a duplicate is one
# repository reported twice and every clause graded against it twice — invisible until something
# counted.
refuse_selected_twice() {
    list_targets "$1" | awk -v id="$2" '$1 "" == id ""' | grep -q . || return 0

    note "already selected: [$2]"
    exit 4
}

add_target() {
    dir=$1
    file=$2
    repo=$3
    ref=$4

    [ -n "$repo" ] && [ -n "$ref" ] || { note "targets add needs a repo and a ref"; exit 2; }

    identity=$(repo_identity "$repo") || {
        note "no portable identity for [$repo] — needs a remote url, no local path, no space, no .."
        exit 4
    }

    is_usable_ref "$ref" || { note "not a usable ref: [$ref]"; exit 4; }
    refuse_second_ref "$dir" "$identity" "$ref"
    refuse_selected_twice "$file" "$identity"

    # Every guard runs before the append, so a refusal leaves the file byte-identical. This is where
    # selection happens until planning exists, so this is where policy has to bite.
    is_authorised "$dir" "$identity" || {
        note "not authorised for this run: [$identity] — run \`policy authorize\` first"
        exit 5
    }

    printf '%s %s\n' "$identity" "$ref" >> "$file" || die_unwritable "$file"
}

# The other half of the line. A leading `/` is a path, and whitespace either splits the two fields or
# writes a second target from one call.
is_usable_ref() {
    case "$1" in
        /* | *[!-A-Za-z0-9_./]*) return 1 ;;
    esac
    return 0
}

# --- charter ---
#
# What must be true for this run to be good.
#
# Four records, sharing an id:
#
#     clause  <id>  Gate|Judged|Decided  <text>
#     pin     <id>  <target>  <ref>  <source>  <sha>
#     gate    <id>  <command...>
#     judge   <id>  <who>  <command...>
#
# `print_clause`, `print_pin`, `print_gate` and `print_judges` write them, and each is the only
# writer of its kind. This header said two for long enough that a reader built a design question on
# the missing pair.
#
# A command is the last field on purpose. `pinned_command` strips two and prints the rest, so spaces,
# quotes and `&&` need no parser and get none. `judge_command` strips three and does the same, which
# is the whole of how a judged clause grew a way to be reached.
#
# **A judge's command may be absent, and a gate's may not.** A gate with no command grades nothing,
# so `gate_held` refuses one. A judge with no command is a clause only a person can answer, which is
# every judged clause floor had before the runner could ask one — so it derives, and `judged`
# refuses it rather than the charter doing so.
#
# One clause, many pins — a clause whose meaning comes from two repositories names both. They are
# separate records because inline pins make dropping a target and deleting a clause the same edit,
# and monotonicity has to tell those apart.
#
# The charter lives inside the run. Grants do not, which is why a reclaimed slot could inherit them
# — see `slot_is_free`. Nothing can inherit a charter, because deleting a run deletes it.
#
# Not a security boundary. The worker can write this file as the same user. What it buys is that no
# accident moves the bar, and that a moved one is visible to `check`.

charter() {
    dir=$(active_run) || exit 1

    case "${1:-}" in
        '')        cat "$(charter_file "$dir")" 2>/dev/null; return 0 ;;
        derive)    derive_charter "$dir" ;;
        check)     check_charter "$dir" ;;
        introduce) shift; introduce_clause "$dir" "${1:-}" "${2:-}" ;;
        *)         usage; exit 2 ;;
    esac
}

charter_file() { printf '%s/charter' "$1"; }

evidence_file() { printf '%s/evidence' "$1"; }

#
# What was proved, and by whom — RFC-001 §2.5.
#
#     record  <name> <command...>   run it, stamp what happened
#     (none)                        print the ledger
#
# `machine` only. `judged` needs a judge and `human` needs the work source, and the completion
# invariant needs the gates stage to say which clause a name belongs to — §9 orders all three after
# this. What ships is the record and the rule that a caller cannot write one.
#
# No rename guard: the ledger lives inside the run and moves with it, where grants are keyed by the
# run's name and do not. Nothing here reads a grant.
evidence() {
    dir=$(active_run) || exit 1

    case "${1:-}" in
        '')     cat "$(evidence_file "$dir")" 2>/dev/null; return 0 ;;
        record) shift; refuse_wrong_repository "$dir"; record_gate "$dir" "$@" ;;
        verdict) shift; refuse_wrong_repository "$dir"; verdict "$dir" "$@" ;;
        handed) shift; refuse_wrong_repository "$dir"; handed "$dir" "$@" ;;
        receipt) shift; refuse_wrong_repository "$dir"; receipt "$dir" "${1:-}" ;;
        *)      usage; exit 2 ;;
    esac
}

#
# **There is no parameter for a result.** The recorder takes a command, runs it, and stamps what
# happened — so a worker can claim a gate passed only by making it pass.
#
# It cannot stop a model appending to the file by hand, and §2.5 says so. Removing the capability is
# what Panel does with `tools: Read, Glob, Grep`, and it is what this does.
#
record_gate() {
    dir=$1; name=${2:-}; [ "$#" -gt 0 ] && shift; [ "$#" -gt 0 ] && shift

    refuse_unrecordable "$name" "$@"
    refuse_a_pinned_name "$dir" "$name"
    enter_work_tree "$dir"
    stamp_command "$dir" "$(delivered_ref)" "$name" "$@"
}

#
# A clause the charter pins to a command is that command's to answer.
#
# `evidence record gates true` ran `true`, stamped a machine pass under the gate's name, and
# `satisfied` took it — the clause was met by a run that never ran its gate. The row
# was honest about the command it ran and silent about which one it stood for.
#
# Only a pinned name is refused. A check no gate expresses still has nowhere else to go, and that is
# what this verb is for.
#
refuse_a_pinned_name() {
    pinned_by_name "$1" "$2" || return 0

    note "[$2] is pinned to a command, so only \`gates\` may answer it"
    note "record a name the charter does not pin, or run \`gates\`"
    exit 2
}

# Every name the charter pins a gate to. `Gate` clauses only — a `Judged:` or `Decided:` clause has
# no command, so nothing about it is this verb's to refuse.
pinned_by_name() {
    awk -v want="$2" '$1 == "clause" && $3 == "Gate" && $4 == want { found = 1 }
                      END { exit !found }' "$(charter_file "$1")" 2>/dev/null
}

# A newline in a name writes a second record whose result the caller chose. `why` is flattened; a
# name is refused, because a gate named across two lines is a mistake, not something to tidy up.
refuse_unrecordable() {
    name=$1; shift

    [ -n "$name" ] || { note "record needs a name and a command"; exit 2; }
    [ "$#" -gt 0 ] || { note "record needs a command to run — a result is not something you pass"; exit 2; }
    is_one_line "$name" || { note "a gate's name is one line: [$name]"; exit 2; }
}

# The directory is not restored: nothing may run after this, and both callers end with it.
enter_work_tree() {
    here=$(this_repository)

    tree=$(unit_work_tree "$1" "$here") || exit 16
    cd "$tree" || { note "cannot enter [$tree]"; exit 16; }
}

#
# A command this host could not run, told from one that ran and lost.
#
# **Stamping the first as the second poisons the ref for good.** `satisfied` reads the ledger
# conjunctively — one pass and no failure at that ref — and the ledger is append-only, so a row
# saying a gate failed can never be taken back. Install the missing tool, watch every gate pass,
# and the run still refuses to deliver at the commit the work was done on.
#
# POSIX gives the shell 127 for a command it could not find and 126 for one it could not execute.
# **A gate choosing either as its own failure code is misread here**, and that costs a run which
# says *unmet* where it should say *failed* — blocked either way, and recoverable rather than not.
#
never_ran() { [ "$1" -eq 126 ] || [ "$1" -eq 127 ]; }

#
# A signal is 128 plus its number, so a killed gate arrives as 130, 137 or 143. None of those is a
# gate answering badly, and every one of them poisoned the ref
# until it was read here.
#
# Hit for real. A run stalled inside a copy, was killed, and stamped 143.
# The next run passed all eight gates at the same commit and completion
# still refused, because a failure at a ref can never be taken back.
#
# A gate wanting to fail has 1. Nothing here kills itself to say so,
# and a gate that did would be choosing a code this
# reads as never having answered.
#
was_killed() { [ "$1" -gt 128 ] && [ "$1" -lt 160 ]; }

#
# Run it, and stamp what happened. The only path to a `machine` record, and it takes the ref rather
# than reading one — `gates` grades every gate against the tree it asked about, not against whatever
# an earlier gate left behind.
#
stamp_command() {
    dir=$1; ref=$2; name=$3
    shift 3

    # `</dev/null`, because `gates` feeds its pin list to the loop on stdin and the command inherits
    # it. A gate that reads stdin ate the gates after it: they never ran, were never recorded, and
    # the run answered 0. Closing it here rather than at the loop covers `evidence record` too — a
    # recorded command that reads the caller's terminal is evidence of something nobody can repeat.
    why=$("$@" </dev/null 2>&1); result=$?

    never_ran "$result"  && { note "[$name] could not run on this host: $why"; exit 21; }
    was_killed "$result" && { note "[$name] was killed by signal $((result - 128)), so nothing was graded"; exit 21; }

    stamp "$dir" machine "$name" "$result" "$ref" "$why"
    return "$result"
}

# Append-only. One line, tab-separated, in the order §2.5 names.
stamp() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" 01 "$3" "$4" "$5" "$(one_line "$6")" \
        >> "$(evidence_file "$1")" 2>/dev/null || die_unwritable "$(evidence_file "$1")"
}

#
# A verdict, and the judge as its own field.
#
# Eight fields, not seven. The judge was folded into `why` as a prefix, so comparing it meant
# reading prose. Nothing counts the fields, so a trailing one costs no reader anything.
stamp_verdict() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" judged 01 "$2" "$3" "$4" "$(one_line "$5")" "$(one_line "$6")" \
        >> "$(evidence_file "$1")" 2>/dev/null || die_unwritable "$(evidence_file "$1")"
}

#
# A receipt's row. `stamp_verdict`'s eight and one more, holding what the receipt vouched for.
#
# Its own stamper rather than an optional field on that one. A verdict typed by hand attests nothing
# beyond its five arguments, and an empty ninth column on it would say it attested nothing — when
# nobody ever asked it to.
stamp_receipt() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" judged 01 "$2" "$3" "$4" "$(one_line "$5")" "$(one_line "$6")" "$(one_line "$7")" \
        >> "$(evidence_file "$1")" 2>/dev/null || die_unwritable "$(evidence_file "$1")"
}

# The handoff's own row. Same eight columns, so one reader serves both, and a kind of its own so
# `satisfied` never mistakes a handoff for an answer.
#
# Ten now. The last is the digest of the brief that went over, and a receipt answering a different
# one is answering a bar this run did not set. A handoff that recorded none leaves it empty, and an
# empty baseline satisfies nothing — `refuse_a_brief_nothing_recorded` says so.
stamp_handoff() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" handed 01 "$2" 0 "$3" "$4" "$(one_line "$5")" "$(one_line "$6")" "$(one_line "$7")" \
        >> "$(evidence_file "$1")" 2>/dev/null || die_unwritable "$(evidence_file "$1")"
}

# A gate that printed nothing on failure still records the ref it applies to, so `why` is last and
# may be empty. `\r` as well as `\n`: Git Bash is a platform this ships on, and `is_one_line` counts
# all three.
# Flatten a field to one line. The common case holds nothing to flatten and costs one `case`.
#
# The `tr` this replaced spawned two processes every time, on every field of every record,
# to change nothing at all in almost all of them.
one_line() {
    said=$1

    while :; do
        case $said in
            *"$NEWLINE"*)         said="${said%%"$NEWLINE"*} ${said#*"$NEWLINE"}" ;;
            *"$CARRIAGE_RETURN"*) said="${said%%"$CARRIAGE_RETURN"*} ${said#*"$CARRIAGE_RETURN"}" ;;
            *"$TAB"*)             said="${said%%"$TAB"*} ${said#*"$TAB"}" ;;
            *)                    break ;;
        esac
    done

    printf '%s' "$said"
}

# The sha the evidence applies to. `check` compares against the base; this is what the run delivers,
# which is where the work is. It answers for the repository the caller stands in — `evidence` refuses
# a wrong one before asking.
delivered_ref() { git rev-parse --verify --quiet HEAD 2>/dev/null; }

#
# Run every gate the charter pins, and record each — RFC-001 §2.4.
#
# **The command comes from the charter, never from the caller.** `evidence record` will run anything
# you hand it under any name, so `evidence record tests true` writes a `machine` pass for a gate that
# never ran. This takes no command, which is the whole of the difference between a record and a claim.
#
# `check_charter` first, and it exits 7 on drift: a moved pin is a command nobody authorised, and
# evidence for it would look exactly like evidence for the one they did. It also carries the
# `refuse_wrong_repository` guard, so there is no second call to it here.
#
gates() {
    dir=$(active_run) || exit 1
    [ "$#" -eq 0 ] || { usage; exit 2; }

    # The ledger is append-only, so the recorder needs the guards the graders have and one reason
    # more: a grader that reads a run it should have refused answers wrongly once, and a recorder
    # writes a row nothing takes back. Both of these refused everywhere but here.
    refuse_renamed_run "$dir"
    refuse_moved_selection "$dir" "$(unit_targets_file "$dir")" || exit 10

    check_charter "$dir"
    run_pinned_gates "$dir"
}

#
# Where a gate runs — §2.4's *that target's checkout*, which since the workspace landed means the
# workspace's and nothing else.
#
# **No fallback to the checkout Foundry was invoked from.** That is also a checkout of the target,
# which is why grading it looked defensible; it is not the one the unit owns, so a gate would record
# a `machine` result for a tree the worker never wrote to. `open` is a precondition, not a
# convenience.
#
# `attached` and not a directory test: the same predicate that decides what `open` may attach to
# decides what a gate may grade, so a workspace built for another target or another ref is refused
# here for the reason it was refused there.
#
# Asked, never computed. Naming the directory here made core reach for `git hash-object`, so a
# container or a sandbox would have to be git to put its workspace where core looks. `attached` is
# already the question; the name is the adapter's business.
work_tree() {
    for slot in "$(unit_workspace "$1")"/*/; do
        attached "${slot%/}" "$2" "$3" && { printf '%s' "${slot%/}"; return 0; }
    done

    note "no workspace holds [$2] at [$3] — \`open\` one, and the gates grade what the work is in"
    return 1
}

# The workspace this unit owns. The ref comes from the selection rather than the caller, so no two
# stages can answer about different trees — three asked the same three-part question before this.
unit_work_tree() {
    work_tree "$1" "$2" "$(selected_ref "$(unit_targets_file "$1")" "$2")"
}

# The ref this run selected for one target. `"" ==` on both sides: an `-v` assignment is a numeric
# string, and an identity that looked like a number would otherwise match a different one.
selected_ref() {
    awk -v want="$2" '!/^[ \t]*#/ && NF && $1 "" == want "" { print $2; exit }' "$1" 2>/dev/null
}

#
# A gate runs where its pin says it came from. One checkout exists, so a gate pinned elsewhere has
# nowhere to run — and running it here would grade this repository against another one's bar.
#
# `moved_sources` reports a foreign pin `uncheckable:` and never counts it, deliberately: a
# multi-target charter cannot be verified from one checkout. That is right for asking whether the
# charter is sound, and wrong for asking whether this gate can run, so the question lives here.
#
refuse_gates_from_elsewhere() {
    file=$(charter_file "$1")
    here=$(this_repository)

    elsewhere=$(printf '%s\n' "$2" | while read -r id _; do
        [ -n "$id" ] || continue
        has_local_pin "$file" "$id" "$here" || printf '%s ' "$id"
    done)

    [ -z "$elsewhere" ] && return 0
    note "these gates are pinned to another repository, so this checkout cannot run them: $elsewhere"
    return 1
}

# Every gate the charter pins, as `id command...`. `print_gate` wrote them.
pinned_gates() {
    awk '$1 == "gate" { $1 = ""; sub(/^ /, ""); print }' "$(charter_file "$1")" 2>/dev/null
}

#
# The commit a clause was pinned at. Every clause carries its own: a charter may pin two gates at two
# bases, and reading one for the other grades against a tree nobody agreed to.
#
pinned_base() {
    awk -v want="$2" '$1 == "pin" && $2 == want { print $4; exit }' "$(charter_file "$1")" 2>/dev/null
}

#
# Every file a pinned command runs, and every file those run — to a fixed point.
#
# **What a script runs, never what it mentions.** A gate naming `README.md` in a message would have
# the run's own README graded as the base wrote it, which is the opposite failure: work nobody could
# ever pass.
#
# Only a literal path. A path built from a variable is not followed, and that boundary is where this
# stops — so a run can weaken its own plugin's suite and be
# graded by the weakened copy.
#
# The README carries the cost of closing it: thirty-three of sixty commits touch a plugin suite, and
# twenty-eight change the code that suite grades. #341 holds
# the trade, and either side of it is a person's act.
#
closure_of() {
    base=$1
    shift
    held=$(printf '%s\n' "$@" | sort -u)

    while :; do
        grown=$(printf '%s\n' "$held" | while read -r path; do
                    [ -n "$path" ] || continue
                    printf '%s\n' "$path"
                    files_run_by "$base" "$path"
                done | sort -u)

        [ "$grown" = "$held" ] && break
        held=$grown
    done

    printf '%s\n' "$held"
}

# Read from the base and from the work, both. A run that adds a call to a helper is invisible in the
# base's copy, and one that removes a call is invisible in its own.
#
# Only what the base holds is yielded. A helper the run added has nothing to restore, and the script
# that would call it is restored to a version that does not.
files_run_by() {
    named=$(both_versions "$1" "$2" | runs_these)

    # A here-doc, and not a pipe. A path this yields is one the base holds, and a pipeline would
    # answer for the loop rather than for the reads behind it.
    while read -r path; do
        [ -n "$path" ] || continue
        git cat-file -e "$1:$path" 2>/dev/null && printf '%s
' "$path"
    done <<EOF
$named
EOF
}

# Both copies, as text. Either may be missing — a file the run added, or one it deleted — and a
# missing copy is nothing to read rather than a failure to report.
both_versions() {
    base=$(git show "$1:$2" 2>/dev/null)
    work=$(cat "$2" 2>/dev/null)

    printf '%s
%s
' "$base" "$work"
}

# `sh x`, `bash x`, `. x`, `source x`, `awk -f x`. A word in one of those positions and nowhere else.
runs_these() {
    awk '{
        for (i = 1; i < NF; i++) {
            word = ""
            if ($i == "sh" || $i == "bash" || $i == "." || $i == "source") word = $(i + 1)
            if ($i == "-f" && i > 1 && $(i - 1) ~ /awk$/)                  word = $(i + 1)

            gsub(/^[\047\042]|[\047\042]$/, "", word)
            if (word ~ /^[A-Za-z0-9_.\/-]+$/) print word
        }
    }'
}

# The files a command names outright. A word that is no file here is an option, or the interpreter.
named_files() {
    for word in "$@"; do
        [ -f "$word" ] && printf '%s\n' "$word"
    done
}

#
# Every file a pinned command reaches that this run has since changed, as `base<TAB>path`.
#
moved_gate_scripts() {
    printf '%s\n' "$2" | while read -r id command; do
        [ -n "$id" ] || continue
        base=$(pinned_base "$1" "$id")
        [ -n "$base" ] || continue

        for path in $(closure_of "$base" $(named_files $command)); do
            git cat-file -e "$base:$path" 2>/dev/null || continue
            git diff --quiet "$base" -- "$path" 2>/dev/null && continue
            printf '%s\t%s\n' "$base" "$path"
        done
    done | sort -u
}

#
# A worktree holding this run's work, with each named file as the base wrote it.
#
# **The work is what is graded.** Only the gate's own file comes from the base, so a run improving a
# gate is still graded by the gate it agreed to, and every other change it made stands.
#
# The base blob is planted in a tree holding the work rather than the base tree being checked out.
# That is the whole of why no gate changes: `dirname $0/..` still lands on the work, because the
# script sits inside it.
#
tree_with_base_gates() {
    where=$(base_gates_tree "$1")
    forget_base_gates "$where"

    index=$(base_gates_index "$1")
    rm -f "$index"
    export GIT_INDEX_FILE="$index"
    git read-tree HEAD >/dev/null 2>&1 || return 1

    plant_base_blobs "$2" || return 1

    tree=$(git write-tree) || return 1
    commit=$(printf 'the gates as the base wrote them\n' | git commit-tree "$tree" -p HEAD) || return 1
    unset GIT_INDEX_FILE
    rm -f "$index"

    git worktree add --detach "$where" "$commit" >/dev/null 2>&1 || return 1
    printf '%s' "$where"
}

# The mode travels with the blob. A gate restored without its executable bit exits 126, which this
# reads as a host that could not run it — a refusal where the answer is a substitution that went wrong.
plant_base_blobs() {
    printf '%s\n' "$1" | while IFS="$(printf '\t')" read -r base path; do
        [ -n "$path" ] || continue
        entry=$(git ls-tree "$base" -- "$path") || return 1
        git update-index --cacheinfo \
            "$(printf '%s' "$entry" | awk '{ print $1 "," $3 }'),$path" || return 1
    done
}

# Beside the charter, not in a temp directory. A substitution that graded wrong is worth reading, and
# a fixed path is one a person can be told to open.
base_gates_tree() { printf '%s/gates-tree' "$1"; }

# `mktemp` stood here and is not POSIX, while floor declares `sh`, `awk` and `git`. It also made a
# file only to delete it and keep the name, which is a race this repository refuses everywhere else.
base_gates_index() { printf '%s/gates-index' "$1"; }

# git's worktree, so git forgets it. Left registered, the next `add` refuses a path that is gone.
forget_base_gates() {
    git worktree remove --force "$1" >/dev/null 2>&1
    rm -rf "$1"
}

#
# Where the gates run. The workspace, unless this run changed a gate that grades it.
#
# A run could rewrite `bin/gates.sh` to `exit 0`, record eight passes and deliver. The pin does not
# catch it: `.foundry/gates` is a clause's source and never moved, while the script it names is what
# executes.
#
# Nearly every run touches no gate and takes the first line out.
#
enter_base_gates() {
    moved=$(moved_gate_scripts "$1" "$2")
    record_the_substitution "$1" "$moved"
    [ -n "$moved" ] || return 0

    tree=$(tree_with_base_gates "$1" "$moved") || {
        note "the gates this run changed could not be restored from the base"
        exit 16
    }

    note "grading with the base's own gates: $(printf '%s\n' "$moved" | cut -f2 | tr '\n' ' ')"
    substituted=$moved
    cd "$tree" || { note "cannot enter [$tree]"; exit 16; }
}

# Said once on stderr, it died with the run. A reader re-running a gate at the delivered ref then ran
# a file this run rewrote, got another exit code, and read an
# honest record as a forged one.
#
# The claim is checkable, which is why writing it is safe: `git diff <base> <ref> -- <path>` is empty
# for a path that never moved, so a substitution invented to
# explain a mismatch does not survive a reading.
#
# Written on every grading, because a run that puts a gate back would otherwise leave the last
# grading's file standing — and a record that lies about what
# it substituted is worse than one that says nothing.
record_the_substitution() {
    [ -n "$2" ] || { rm -f "$(substitutions_file "$1")"; return 0; }

    printf '%s\n' "$2" > "$(substitutions_file "$1")" 2>/dev/null ||
        die_unwritable "$(substitutions_file "$1")"
}

run_pinned_gates() {
    dir=$1
    substituted=
    failed=0

    pins=$(pinned_gates "$dir")
    [ -n "$pins" ] || { note "this charter pins no gate, so it grades nothing mechanically"; exit 8; }
    refuse_gates_from_elsewhere "$dir" "$pins" || exit 7

    enter_work_tree "$dir"

    # One ref for the whole set — taken after the move, so a gate that commits cannot shift the tree
    # the gates behind it are recorded against. Taken before the substitution too: what a run
    # delivers is its own work, never the tree the gates were run in.
    ref=$(delivered_ref)

    enter_base_gates "$dir" "$pins"

    # A here-doc, not a pipe. A tally raised inside a pipe's subshell dies with it, and the tally is
    # the only thing this loop produces that the caller needs.
    while read -r id command; do
        [ -n "$id" ] || continue
        gate_held "$dir" "$ref" "$id" "$command" || failed=$((failed + 1))
    done <<EOF
$pins
EOF

    [ "$failed" -eq 0 ] && return 0
    note "gates that did not pass: $failed"
    say_the_substitution "$substituted"
    return 14
}

# Why a gate failed here and passes by hand. The run changed a
# file the gate runs, so it was graded against a tree
# that is neither the base nor what ships.
#
# Said only when a gate actually failed. Nearly every run that substitutes
# something passes anyway, and a note on all of those is a note people skip.
say_the_substitution() {
    [ -n "$1" ] || return 0

    note "this run changed a file its own gates run:"
    printf '%s\n' "$1" | cut -f2 | sed 's/^/floor:   /' >&2
    note "each was graded as the base wrote it, so a gate reading one saw neither tree whole"
    note "a change to the bar itself is landed by a person — no run can prove it"
}

#
# The ledger reads in the charter's words. `clause_text` is the name a human agreed to; the id is
# this file's bookkeeping and means nothing to the person reading the record back.
#
gate_held() {
    dir=$1; ref=$2; id=$3; command=$4

    name=$(clause_text "$(charter_file "$dir")" "$id")

    # Reachable only by editing the charter, which is what `check` calls unattended drift. Refused
    # rather than stamped: a record naming no clause cannot be matched to the bar it was meant to
    # grade, and it would sit in the ledger looking like one that can.
    [ -n "$name" ] || { note "the charter pins a command under [$id] and names no clause for it"; exit 7; }

    # `sh -c ""` exits 0. A `.foundry/gates` line holding a name and nothing else derives to a clause
    # with an empty command, and that is a typo away — so the green it would record is the one kind
    # that is never earned. `derive` should refuse it at the source too; it does not yet.
    [ -n "$command" ] || { note "the charter pins no command for [$name]"; exit 7; }

    stamp_command "$dir" "$ref" "$name" sh -c "$command"
    answered=$?; emit "$dir" gate.finished name="$name" result="$answered" runtime="$(runtime)"; return "$answered"
}

#
# Ask every judge the charter names, and record what came back — #332.
#
# **The command comes from the charter, never from the caller.** That is the whole difference between
# this and `evidence receipt`: that verb reads a file somebody else made, and this one runs what the
# repository declared and reads the file that came out. A caller passing anything is refused.
#
# The same guards `gates` carries, for the reason `gates` carries them: the ledger is append-only, so
# a recorder reading a run it should have refused writes a row nothing takes back.
#
# **It does not loop.** A refused judgement is answered by new work, and new work is a new commit —
# so round two is a second invocation at a second candidate, never a second pass here. The round is
# counted from the ledger. Nothing bounds how many, and #332 still owns that.
#
judged() {
    dir=$(active_run) || exit 1
    [ "$#" -eq 0 ] || { usage; exit 2; }

    refuse_renamed_run "$dir"
    refuse_moved_selection "$dir" "$(unit_targets_file "$dir")" || exit 10

    check_charter "$dir"
    ask_pinned_judges "$dir"
}

#
# Every judge, and how many of them left their clause unmet.
#
ask_pinned_judges() {
    dir=$1
    unmet=0

    # `bench`, never `panel`: `refuse_a_judge_nobody_asked` takes the members into a variable of that
    # name, sh has no locals, and the loop below runs through it. `.foundry/judged` already calls the
    # place a member stands a bench, so the second name was there to be used.
    bench=$(every_judge_record "$(charter_file "$dir")")
    [ -n "$bench" ] || { note "this charter names no judge, so there is nothing here to judge"; exit 8; }

    enter_work_tree "$dir"
    refuse_a_judge_this_run_rewrote "$dir" "$bench"
    ref=$(delivered_ref)

    # A here-doc, not a pipe. A tally raised inside a pipe's subshell dies with it, and the tally is
    # the only thing this loop produces that the caller needs.
    while read -r id who command; do
        [ -n "$who" ] || continue
        judge_answered "$dir" "$ref" "$id" "$who" "$command" || unmet=$((unmet + 1))
    done <<EOF
$bench
EOF

    [ "$unmet" -eq 0 ] && return 0
    note "judged clauses no judge approved: $unmet"
    return 39
}

#
# One judge, on one clause: hand the bar over, ask, and read the answer.
#
# The receipt goes through `receipt`, which is the verb a person types. Same keys, same refusals, and
# **a run cannot reach a satisfaction a hand-written receipt could not.**
#
# `satisfied` decides the answer rather than `receipt`'s exit code. A receipt saying `reject` or
# `unavailable` is a receipt floor took and recorded, so recording it succeeded and the clause is
# still unmet — two different questions, and only the second is this one.
#
judge_answered() {
    dir=$1; ref=$2; id=$3; who=$4; command=$5

    text=$(clause_text "$(charter_file "$dir")" "$id")
    [ -n "$text" ] || { note "the charter names a judge under [$id] and no clause for it"; exit 7; }
    [ -n "$command" ] || { note "the charter says nothing about how [$who] is reached for [$text]"; exit 7; }

    mkdir -p "$dir/judged" 2>/dev/null || die_unwritable "$dir/judged"
    bar=$(brief_for "$dir" "$id")
    answer=$(receipt_for "$dir" "$id")

    # `bar` and `digest`, never `brief`: `handed` takes the digest into a variable of that name, sh
    # has no locals, and reading it back after the call digested a checksum. That is `craft-sh` rule
    # 10 — one name, one meaning — and it cost a debugging pass here before the rule was applied.
    write_brief "$dir" "$text" "$ref" "$who" > "$bar" || die_unwritable "$bar"
    digest=$(digest_of "$bar")

    handed "$dir" "$text" "$who" "$command" "$digest"
    write_receipt_context "$dir" "$text" "$ref" "$who" "$digest" > "$answer" \
        || die_unwritable "$answer"

    ask_the_judge "$bar" "$answer" "$command"
    receipt "$dir" "$answer"

    satisfied "$dir" "$text" "$ref" judged "$who"
    met=$?; emit "$dir" judge.finished judge="$who" result="$met" runtime="$(runtime)"; return "$met"
}

# Where the bar goes over, and where the answer comes back. Beside the charter and named for the
# clause, so a person told a run's path can open either and read what was asked and what was said.
brief_for()   { printf '%s/judged/%s.brief' "$1" "$2"; }
receipt_for() { printf '%s/judged/%s.receipt' "$1" "$2"; }

#
# Run the judge, and tell a host that could not from a judge that answered badly.
#
# `stamp_command`'s two refusals without its stamp. A `machine` row under a judged clause's name is a
# command answering the question no command can answer, so nothing here writes one — what the judge
# says is in the receipt, and the receipt is what gets recorded.
#
# `</dev/null` for `stamp_command`'s reason: a judge that reads the caller's terminal is evidence of
# something nobody can repeat. Its own words go to stderr, because a judge that failed and wrote no
# receipt refuses two lines later with a sentence about a file, and this is the sentence about why.
#
ask_the_judge() {
    said=$(FOUNDRY_BRIEF="$1" FOUNDRY_RECEIPT="$2" sh -c "$3" </dev/null 2>&1); answered=$?

    never_ran "$answered"  && { note "the judge could not run on this host: $said"; exit 21; }
    was_killed "$answered" && { note "the judge was killed by signal $((answered - 128))"; exit 21; }
    [ "$answered" -eq 0 ] || note "the judge exited $answered: $(one_line "$said")"

    return 0
}

#
# What went over, written by the runner and digested before the judge is asked.
#
# **Floor writes this one and reads no other.** `handed` takes a digest from whoever handed the bar
# over, and everywhere else that is a caller's word. Here the runner is the caller, so the file it
# digested is the file the judge was pointed at, and the two cannot differ.
#
# The charter travels with it because the charter is the bar. The ledger does not: a judge handed
# this run's own answers has been handed its reply, which is the rule the README states about a
# receipt and is no less true of a brief.
#
write_brief() {
    printf 'run %s\nclause %s\ncandidate %s\njudge %s\nround %s\n\n' \
        "$(recorded_id "$1")" "$2" "$3" "$4" "$(next_round "$1" "$2" "$4")"
    printf -- '--- the charter this work is graded against ---\n'
    cat "$(charter_file "$1")"
}

#
# The half of the receipt only the runner knows, written before the judge is asked.
#
# **Every key here is one the judge may not restate.** `refuse_a_line_that_is_not_a_receipt_line`
# calls a key said twice two answers and refuses the file, so an adapter writing its own candidate is
# refused rather than believed. That refusal is what makes these fields the runner's.
#
# What the judge appends is what only it saw: `adapter`, `verdict`, `report`, `time`, and whatever
# else it can vouch for. Nothing here writes one of those, because floor did not watch it happen.
#
write_receipt_context() {
    printf '# written by the runner, before the judge was asked. The judge appends what it saw.\n'
    printf 'run %s\nclause %s\ncandidate %s\nrole %s\nbrief %s\nround %s\n' \
        "$(recorded_id "$1")" "$2" "$3" "$4" "$5" "$(next_round "$1" "$2" "$4")"
    print_prior "$1" "$2" "$4"
}

# The verdict before this one, and nothing when this is the first. A `prior` naming nothing is what
# `refuse_a_round_with_no_prior` refuses, so an absent one has to stay absent rather than be filled.
print_prior() {
    said=$(prior_verdict "$1" "$2" "$3")
    [ -n "$said" ] || return 0

    printf 'prior %s\n' "$said"
}

#
# Which round this is: every verdict this judge already gave on this clause, plus one.
#
# Counted from the ledger and never from the receipt, because the ledger is the run's and the receipt
# is the producer's. A round the producer names is a record; this is the count floor can make.
next_round() {
    awk -F'\t' -v name="$2" -v judge="$3" '
        $2 != "judged"    { next }
        $4 "" != name ""  { next }
        $8 "" != judge "" { next }
        { rounds++ }
        END { print rounds + 1 }' "$(evidence_file "$1")" 2>/dev/null
}

# What that judge last said about that clause, as the ledger kept it.
prior_verdict() {
    awk -F'\t' -v name="$2" -v judge="$3" '
        $2 != "judged"    { next }
        $4 "" != name ""  { next }
        $8 "" != judge "" { next }
        { said = $7 }
        END { print said }' "$(evidence_file "$1")" 2>/dev/null
}

#
# A run that rewrote the file its own judge runs is grading itself.
#
# `gates` plants the base's copy and grades against that. This refuses instead, and the difference is
# what the two produce: a gate answers with an exit code, so a substituted one still answers, while a
# judge writes a receipt and a substitution would leave nobody able to say which copy wrote it.
#
# **A file the base does not hold is not a rewrite**, so the judge a run adds is not caught here —
# `moved_gate_scripts` yields only what the base can restore. Landing a bar change is a person's act,
# and #341 owns the rest of that seam.
#
refuse_a_judge_this_run_rewrote() {
    rewrote=$(moved_gate_scripts "$1" "$(judge_commands "$2")")
    [ -z "$rewrote" ] || {
        note "this run changed a file its own judge runs:"
        printf '%s\n' "$rewrote" | cut -f2 | sed 's/^/floor:   /' >&2
        note "a judge the work can rewrite grades the work that rewrote it"
        exit 7
    }
}

# The panel's records as `id command...`, which is the shape `moved_gate_scripts` reads. A member
# nobody said how to reach has no command and no file, so it is dropped rather than read as one.
judge_commands() {
    printf '%s\n' "$1" | awk 'NF > 2 { id = $1; $1 = ""; $2 = ""; sub(/^ +/, ""); print id, $0 }'
}

#
# May this run deliver? — RFC-001 §2.5's completion invariant.
#
# Every conjunct answers from state something else already wrote: `new` stamped the selection, the
# charter holds the clauses, unit 01 holds the selection, the ledger holds what ran. Nothing here
# keeps a record of its own, because a second copy of any of them is a second thing to drift.
#
# The first two conjuncts close fail-opens, not edge cases: the invariant quantifies over clauses and
# over targets, so an empty charter and an empty selection each satisfy it vacuously. Every fresh run
# has the second, and any repository the detector reads no gate from produces the first.
#
complete() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    dir=$(active_run) || exit 1
    refuse_unreadable_run "$dir"

    findings=$(unmet_for_delivery "$dir")

    [ -n "$findings" ] || return 0
    printf '%s\n' "$findings"
    exit 15
}

#
# The guards both readers of the invariant open with.
#
# The same guard `targets` and `authorise` use. Every clause is graded against every selected target,
# so a line put into the file by hand decides what the run answers for — and the grader read it where
# the other two refuse it.
#
# `refuse_unselectable` cannot see an absence, and the frozen record is the only thing that still
# remembers a deleted line was selected. Authorisation read it; the stage that grades did not.
#
refuse_unreadable_run() {
    refuse_renamed_run "$1"
    refuse_unselectable "$1" "$(unit_targets_file "$1")" || exit 5
    refuse_moved_selection "$1" "$(unit_targets_file "$1")" || exit 10
}

# §2.5's three conjuncts, and invariant 4's. One definition, because `complete` answers whether a run
# may deliver and `deliver` acts on that answer — two copies would let them disagree.
unmet_for_delivery() {
    unauthorised_run "$1"
    empty_bar "$1"
    empty_selection "$1"
    ungradable_targets "$1"
    underived_clauses "$1"
    unmet_clauses "$1"
}
#
# A clause the charter no longer derives.
#
# `check_charter` reads this at `charter check` and inside `gates`. **Neither runs again on the way
# out.** So a `Judged` clause deleted from the charter after the gates passed reached `complete` and
# `deliver` with nothing looking, and completion answered that the charter was fully satisfied.
#
# `authorise` reads the gate half — `underived_gates`, filtered to `deleted:`. It never reaches the
# judged half, and the judged half is the one a person cannot re-run.
#
underived_clauses() {
    underived_judged "$(charter_file "$1")"
}

#
# Completed work, made reviewable.
#
# **Authority first, because it is answerable before the work is.** Telling someone their clauses are
# unmet when the real answer is that nobody granted delivery sends them to a remedy that changes
# nothing.
#
#
# Beside the other two, never merged into them. One file holding all three would make `policy
# authorize` grant the third power as well.
#
merges_file() { printf '%s/%s/merges' "$GRANTS" "${1##*/}"; }

#
# No bootstrap exemption, for the reason `may_deliver_to` has none. Standing somewhere is not
# permission to land work there, and every run is bootstrapped somewhere.
#
may_merge_to() {
    standing merge "$1" "$2" && return 0

    file=$(merges_file "$1")
    [ -f "$file" ] || return 1
    grep -Fxq -- "$2" "$file"
}

#
# Merge what this run delivered.
#
# **The thing merged must be the thing graded.** Every other refusal here is worth less than that
# one: a head that moved after grading is a tree nothing answered for, and landing it puts work in
# the trunk that no gate ever saw.
#
# Provider permission is not authority, and neither implies the other. Anything that can run `gh` can
# merge whatever the practice says — `.foundry/practice` opens by saying so. This records intent and
# withholds nothing; the identity Foundry runs under is what refuses.
#
merge_delivery() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    dir=$(active_run) || exit 1
    here=$(this_repository)

    refuse_unreadable_run "$dir"
    refuse_ungranted_merge "$dir" "$here"
    refuse_incomplete "$dir"
    refuse_missing_source

    land_what_was_graded "$dir" "$(graded_ref "$dir" "$here")"
}

refuse_ungranted_merge() {
    may_merge_to "$1" "$2" && return 0

    note "nobody said this run may merge into [$2] — \`policy merge-to\` is what says so"
    exit 23
}

# The commit the evidence names. `refuse_incomplete` has already passed, so every clause is met at
# this ref — which is the whole of what a merge may land.
graded_ref() {
    tree=$(unit_work_tree "$1" "$2") || exit 16
    git -C "$tree" rev-parse --verify --quiet HEAD
}

land_what_was_graded() {
    said=$(source_says state "${1##*/}")
    asked=$?

    # A source that answered *nothing delivered* is not one that could not be asked.
    [ "$asked" -eq 1 ] && { note "this run has delivered nothing, so there is nothing to merge"; exit 24; }
    [ "$asked" -eq 0 ] || exit 25

    read -r head state mergeable target <<EOF
$said
EOF

    # A retry after a merge that landed. Silence here would read as a second merge that worked, and
    # a refusal would read as one that never happened.
    [ "$state" = MERGED ] && { note "this delivery is already merged"; return 0; }

    refuse_a_delivery_not_open   "$state"
    refuse_a_moved_head          "$head" "$2"
    refuse_a_source_that_will_not "$mergeable"
    refuse_a_required_check_that_did_not_pass "$target" "$(what_the_target_requires "$said")"

    source_says land "${1##*/}" || {
        note "the source would not land it — a bar floor cannot read may be what refused"
        exit 25
    }
    note "merged."
}

refuse_a_moved_head() {
    [ "$1" = "$2" ] && return 0

    note "the delivery is at [$1] and the evidence names [$2]"
    note "the thing merged must be the thing graded — grade again, or deliver what was graded"
    exit 24
}

refuse_a_delivery_not_open() {
    [ "$1" = OPEN ] && return 0

    note "the delivery is [$1], so there is nothing here to merge"
    exit 24
}

# `UNKNOWN` is the source still working it out, and it is refused with the rest. A lookup that has
# not finished is not a lookup that said yes.
refuse_a_source_that_will_not() {
    [ "$1" = MERGEABLE ] && return 0

    note "the source says this delivery is [$1], so it will not take it"
    exit 24
}

#
# **Only what the target requires, and every one of those.** The rollup holds checks nobody made a
# condition of landing, and refusing on those was floor holding a bar the source never set. A target
# requiring nothing could not be merged into at all.
#
# A check that has not answered is still refused. **A check that did not answer is not a check that
# passed**, and a required check still pending reads as an empty failure list to anybody who looks
# only for a `FAILURE`.
#
# **Only `SUCCESS` passes, which is stricter than the source may be.** GitHub may hold `SKIPPED` and
# `NEUTRAL` to have met a required check. Nothing here has measured that, and no branch this runs
# against requires a check to measure it against — so both refuse, which is the safe side of a
# question nobody has answered. It is the one place this is tighter than the bar, not looser.
#
# **The cost, said plainly: the bar is now the source's bar.** A target requiring nothing is a
# target checking nothing, and deferring to it inherits exactly that — weaker than refusing on
# everything, and true. What a repository must pass is not floor's to decide.
#
refuse_a_required_check_that_did_not_pass() {
    failed=$(printf '%s\n' "$2" | awk 'NF && $1 != "SUCCESS"')
    [ -n "$failed" ] || return 0

    printf '%s\n' "$failed" | while read -r conclusion check; do
        note "[$check] is required to land on [$1], and $(what_became_of "$conclusion")"
    done
    exit 24
}

# A check that never ran is not a check that failed. The source lands neither, and only one of the
# two is a failure somebody can go and read.
what_became_of() {
    [ "$1" = MISSING ] && { printf 'it never ran'; return 0; }
    printf 'it answered [%s]' "$1"
}

# The check lines of what the source said, which is everything after the header.
what_the_target_requires() { printf '%s\n' "$1" | sed 1d; }


#
# Two deliveries against one target, and whether they can be brought
# together. Nothing coordinates them: the source is asked what
# else is open, and a branch name is all that crosses.
#
# **Nothing reads another run's workspace.** The merge is tried in a tree of this run's own, and a
# branch name is the whole of what came from anywhere else.
#
# Reported, never refused. A clash is a fact about two deliveries and a fault in neither, so this
# answers 26 and the delivery stays exactly where it was.
#
reconcile() {
    [ "${1:-}" = accept ] && { shift; accept_ancestry "$@"; return $?; }
    [ "$#" -eq 0 ] || { usage; exit 2; }

    dir=$(active_run) || exit 1
    here=$(this_repository)

    refuse_unreadable_run "$dir"
    refuse_missing_source

    others=$(source_says open "$(delivery_branch "$dir")") || exit 25
    [ -n "$others" ] || { note "nothing else is open against this target"; return 0; }

    report_clashes "$dir" "$here" "$others"
}

report_clashes() {
    tree=$(unit_work_tree "$1" "$2") || exit 16
    clashed=0

    while IFS="$(printf '\t')" read -r branch identity; do
        [ -n "$branch" ] || continue
        name_the_clash "$1" "$tree" "$branch" "$identity" || clashed=$((clashed + 1))
    done <<EOF
$3
EOF

    [ "$clashed" -eq 0 ] && { note "every other open delivery reconciles with this one"; return 0; }

    note "open deliveries this one cannot be brought together with: $clashed"
    return 26
}

# A branch nobody could fetch is not a branch that reconciles, and neither is a merge that could not
# be tried. Both are counted with the clashes: the question was whether these can be brought
# together, and this run still cannot say they can.
name_the_clash() {
    theirs=$(their_head "$2" "$3")

    [ -n "$theirs" ] || {
        note "[$4] could not be fetched, so nothing here can say whether it reconciles"
        return 1
    }

    named=$(clashing_files "$1" "$2" "$theirs")

    [ "$named" = "?" ] && { note "[$4] could not be merged here, so this says nothing either way"; return 1; }
    [ -n "$named" ] || return 0

    note "[$4] and this one both change: $named"
    return 1
}

# Fetched when the source answers, and the copy already here when it does not.
# A host that is down is no reason to stop, and a clone left the tracking ref.
their_head() {
    git -C "$1" fetch origin "$2" >/dev/null 2>&1
    fetched=$(git -C "$1" rev-parse --verify --quiet FETCH_HEAD 2>/dev/null)

    [ -n "$fetched" ] && { printf '%s' "$fetched"; return 0; }
    git -C "$1" rev-parse --verify --quiet "origin/$2" 2>/dev/null
}

#
# The merge, tried and thrown away. In the workspace it would leave
# this run's work in conflict over a question
# about someone else's.
#
# `FETCH_HEAD` is per worktree and this one was just made, so the sha travels rather than the name.
#
# **A merge that could not be tried says `?`.** Empty would mean nothing clashed, and a tree that
# never existed would read as two deliveries joining cleanly.
#
clashing_files() {
    where=$(reconcile_tree "$1")
    forget_tree "$2" "$where"

    git -C "$2" worktree add --detach "$where" HEAD >/dev/null 2>&1 || { printf '?'; return 0; }

    git -C "$where" merge --no-commit --no-ff "$3" >/dev/null 2>&1
    # Nothing conflicted is not one empty name. `printf` on an empty string still writes a line, and
    # a space is what a clash and a clean merge then look alike as.
    named=
    left=$(git -C "$where" diff --name-only --diff-filter=U 2>/dev/null)
    [ -n "$left" ] && named=$(printf '%s\n' "$left" | tr '\n' ' ')
    git -C "$where" merge --abort >/dev/null 2>&1
    forget_tree "$2" "$where"

    printf '%s' "$named"
}

# Beside the charter, like the gates tree. A merge that went wrong is worth
# reading, and a fixed path is one a person can be told to open.
reconcile_tree() { printf '%s/reconcile-tree' "$1"; }

# git's worktree, so git forgets it. Left registered, the next `add` refuses a path that is gone.
forget_tree() {
    git -C "$1" worktree remove --force "$2" >/dev/null 2>&1
    rm -rf "$2"
}

#
# Exactly one host may take an item. Two seeing the same one
# and both starting is the failure, and almost never
# is not a claim — it is money spent twice.
#
# A claim is not authority. It says a host started, never that it may — `policy` still decides what
# a run may touch, and this widens nothing.
#
claim() {
    [ "$#" -le 1 ] || { usage; exit 2; }
    refuse_missing_source

    item=${1:-}
    [ -n "$item" ] || { note "claim names an item"; exit 2; }

    source_says claim "$item" "$(recording_host)" && { note "claimed [$item]"; return 0; }
    break_a_dead_claim "$item" && return 0

    say_who_holds "$item"
    record_the_refusal "$item"
    exit 30
}

# An hour with no word. A wake is ten minutes, so a live host renews six
# times inside it, and a window this wide costs a slow host nothing.
CLAIM_TTL=${FOUNDRY_CLAIM_TTL:-3600}

# A host that died holding one would block that item for good, and nothing
# here may need a person to clear it. Age is the only signal a second machine has.
break_a_dead_claim() {
    held=$(source_says held "$1") || return 1
    age=$(claim_age "$held")      || return 1

    [ "$age" -gt "$CLAIM_TTL" ] || return 1

    source_says release "$1" "$(claim_holder "$held")" || return 1
    note "[$1] went $age seconds without a word from $(claim_holder "$held") — taking it"

    source_says claim "$1" "$(recording_host)"
}

# Seconds since the claim was stamped. A record written before floor kept an
# epoch cannot be aged at all, so it is never broken. Unknown is not stale.
claim_age() {
    stamped=$(printf '%s\n' "$1" | awk -F'\t' 'NF == 3 && $3 ~ /^[0-9]+$/ { print $3 }')
    [ -n "$stamped" ] || return 1

    printf '%s' "$(( $(date -u +%s) - stamped ))"
}

claim_holder() { printf '%s\n' "$1" | awk -F'\t' '{ print $2 }'; }

# What the loser keeps. A host claims before it opens a run as often as after,
# so there is not always a row to write. Inventing one to hold a line is worse.
record_the_refusal() {
    dir=$(active_run 2>/dev/null) || return 0
    record_observation "$dir" claim.refused "item=$1" || return 0
}

# Only the holder may let go. A host dropping another's claim is the race this exists to stop,
# arriving one step later.
release() {
    [ "$#" -le 1 ] || { usage; exit 2; }
    refuse_missing_source

    item=${1:-}
    [ -n "$item" ] || { note "release names an item"; exit 2; }

    source_says release "$item" "$(recording_host)" && { note "released [$item]"; return 0; }

    note "[$item] is not this host's to release"
    exit 30
}

say_who_holds() {
    held=$(source_says held "$1") || { note "[$1] is held, and the source could not say by whom"; return 0; }

    note "[$1] is held by $(claim_holder "$held"), since $(claim_when "$held")"
}

claim_when() { printf '%s\n' "$1" | awk -F'\t' '{ print $1 }'; }

#
# Something happened, recorded where it happened. Inside the run, because a run has already been
# carried between machines and its own history went with it, and a run
# somebody deletes took its own history too.
#
# An observation is not evidence. It says a thing occurred, and satisfying
# a clause needs a trusted producer, a ref and a clause to bind
# to — which is why completion never reads this file.
#
# A field nobody set is absent rather than empty. Composition follows
# the identities a record genuinely knows, so a missing one
# narrows what can be asked and breaks nothing.
#
observe() {
    dir=$(active_run) || exit 1
    refuse_unreadable_run "$dir"

    event=${1:-}
    [ -n "$event" ] || { list_observations "$dir"; return 0; }
    shift

    is_one_line "$event" || { note "an event name is one line: [$event]"; exit 2; }
    refuse_an_unnamed_field "$@"

    record_observation "$dir" "$event" "$@" || die_unwritable "$(observations_file "$dir")"
}

# Named pairs, so a reader knows what a value is without counting columns. A bare word could only be
# read by position, and every event would then owe the same positions.
refuse_an_unnamed_field() {
    for pair in "$@"; do
        case $pair in *=*) continue ;; esac

        note "an observation's fields are key=value, and [$pair] is not one"
        exit 2
    done
}

#
# The recording host names itself, because two machines do not
# agree on the time. Order inside one file is the order
# it was written, and across two there is none.
#
record_observation() {
    dir=$1; event=$2
    shift 2

    line=$(printf '%s\t%s\t%s\t%s' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "$(one_line "$(recording_host)")" "$(one_line "$event")" "$(one_line "$*")")

    refuse_a_torn_row "$line"

    printf '%s
' "$line" >> "$(observations_file "$dir")" 2>/dev/null
}

# `uname -n`, because `hostname` is not POSIX and a machine that answers neither is still a machine
# whose clock this row belongs to. Unknown is a name; empty is a column nobody can read.
recording_host() { uname -n 2>/dev/null || printf 'unknown'; }

#
# **One line, one write.** POSIX makes an append atomic only under `PIPE_BUF`, which is 4096 at
# worst, so a row that fits lands whole and two writers cannot tear each other's.
#
# That property picked this shape. Not a format because it is common, and not one because another
# file here already uses it.
#
# Characters, not bytes — a shell counts what it has. The margin is what covers the difference, and
# a row this long is a paragraph somebody put in the wrong file.
#
refuse_a_torn_row() {
    [ "${#1}" -lt 4000 ] && return 0

    note "an observation must fit one atomic write, and that one is ${#1} long"
    exit 2
}

#
# Every run this home holds, one row each, with the run named first. Two
# runs over one work item compose here without either
# ever having heard of the other.
#
# A run holding none contributes none. Nothing is counted here and nothing is summed — the rows go
# out as they were written, and the question is asked with `awk`.
#
observed() {
    [ "$#" -le 1 ] || { usage; exit 2; }

    want=${1:-}
    for held in "$RUNS"/*/; do
        [ -f "${held}observations" ] || continue
        say_the_rows "$(basename "${held%/}")" "${held}observations" "$want"
    done
}

say_the_rows() {
    awk -F'\t' -v run="$1" -v want="$3" \
        'want == "" || $3 == want { print run "\t" $0 }' "$2" 2>/dev/null
}

#
# What produced this row. A run graded under one implementation
# and completed under another was judged twice, and the two
# holes closed this week are why that is worth knowing.
#
# Read from the manifest beside this script, because a version compiled
# in is a second copy of the same fact and the
# one that goes stale.
#
# Recorded and not yet refused. Nothing here compares
# two runtimes, and the decision to refuse wants
# rows to argue from rather than a guess.
#
# Resolved once, before anything moves. `gates` enters the workspace, and a
# path relative to `$0` stops resolving from there — so
# every gate row said `floor/unknown`.
#
# `run.began` was right and the gate rows were wrong,
# which is the worst shape: the rows worth arguing
# from are those the version had fallen out of.
MANIFEST=$(cd "$SELF_DIR/../.claude-plugin" 2>/dev/null && pwd)/plugin.json

runtime() {
    stated=$(awk -F'"' '/"version"/ { print $4; exit }' "$MANIFEST" 2>/dev/null)

    [ -n "$stated" ] || stated=unknown

    printf 'floor/%s' "$stated"
}

# Which agent produced the work, in whatever word its harness uses. Core names the
# field and never the value, the same rule that keeps a
# label's prefix out of core.
#
# No fallback. `selector` falls back to a git address because a run with no
# human may not deliver. A run with no named worker is ordinary.
worker() { printf '%s' "${FOUNDRY_WORKER:-}"; }

# Three facts, and collapsing any two of them is what #156 is about.
#
# The host is where it ran. The selector permitted it. The worker produced it.
# A record naming one of the three has answered a different question.
began_with() {
    said=$(worker)
    [ -n "$said" ] && { printf 'runtime=%s worker=%s' "$(runtime)" "$(one_line "$said")"; return 0; }

    printf 'runtime=%s' "$(runtime)"
}

#
# Floor's own moments. An observation is not evidence, so a home that
# cannot take one must not stop the work somebody
# actually asked for.
#
# Silent when it fails, on purpose. A run whose home went read-only has a louder problem, and every
# verb that needs to write already says so.
#
emit() { record_observation "$@" || return 0; }

observations_file() { printf '%s/observations' "$1"; }

list_observations() { cat "$(observations_file "$1")" 2>/dev/null; }

#
# Something this run learned that its own bar does not cover. Recorded so it survives the
# run, and it blocks nothing — a run that widened itself to act on
# one would be doing work nobody selected.
#
# Never read by completion. An aside is not a clause, not evidence and not
# a grant, and the only thing that changes because of
# one is what a person does next.
#
aside() {
    [ "$#" -le 1 ] || { usage; exit 2; }

    text=${1:-}
    [ -n "$text" ] || { every_aside; return 0; }

    dir=$(active_run) || exit 1
    refuse_unreadable_run "$dir"

    printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(one_line "$text")" \
        >> "$(asides_file "$dir")" 2>/dev/null || die_unwritable "$(asides_file "$dir")"
}

# Every run's, and never only this one's. An aside is written
# for whoever comes next, so a reader who can see one
# run's has been shown the least useful half.
#
# Measured before this existed: one aside, across
# each run ever made here. A verb that records
# where nobody reads is a verb nobody uses.
every_aside() {
    for held in "$RUNS"/*/; do
        [ -f "${held}asides" ] || continue

        awk -F'\t' -v run="$(basename "${held%/}")" '{ print run "\t" $0 }' "${held}asides" 2>/dev/null
    done
}

asides_file() { printf '%s/asides' "$1"; }

list_asides() { cat "$(asides_file "$1")" 2>/dev/null; }

#
# Printed after the delivery, never before it. A reader who has just been
# told where the work went is the one who can act
# on what it left behind.
#
say_the_asides() {
    held=$(list_asides "$1")
    [ -n "$held" ] || return 0

    note "this run set aside:"
    printf %s "$held" | while IFS="$(printf '\t')" read -r _ said; do note "  $said"; done
}

deliver() {
    title=${1:-}
    [ "$#" -le 2 ] || { usage; exit 2; }
    [ -n "$title" ] || { note "deliver names the change"; exit 2; }

    dir=$(active_run) || exit 1
    here=$(this_repository)

    refuse_unreadable_run "$dir"
    refuse_ungranted_delivery "$dir" "$here"
    refuse_foreign_ancestry "$dir" "$here"
    refuse_incomplete "$dir"
    keep_the_brief "$dir" "${2:-}"

    send_delivery "$dir" "$here" "$title"
    say_the_asides "$dir"
    emit "$dir" run.delivered
}

# The brief travels with the run, never as an argument. A body is many lines and
# a positional one is a shape a shell mangles, so the caller names a
# file and the run keeps a copy that outlives whatever wrote it.
#
# Absent is legal. A source writes what it always wrote, and a delivery
# saying only which item it answers is a thin one rather than wrong.
# To pass a path that is not there is the mistake, so it refuses.
keep_the_brief() {
    [ -n "$2" ] || { say_what_a_brief_is; return 0; }

    [ -r "$2" ] || { note "no brief to read at [$2]"; exit 2; }
    cat "$2" > "$(brief_file "$1")" || die_unwritable "$(brief_file "$1")"
}

brief_file() { printf '%s/brief' "$1"; }

# Named where a body is missing, and nowhere else. A skill nobody meets
# at the moment that it applies is a skill that nobody ever invokes,
# and this is the very last moment that a delivery has to say so.
say_what_a_brief_is() {
    note "no brief, so this delivery says only which item it answers"
    note "  floor:brief names the five shapes a human surface takes"
}

# A path, or nothing at all. An adapter that is given a path it cannot
# read has been told a lie. One that was handed no path knows there
# is nothing at all, and so those are two very different things.
brief_if_kept() {
    [ -s "$(brief_file "$1")" ] && printf '%s' "$(brief_file "$1")"
}

refuse_ungranted_delivery() {
    may_deliver_to "$1" "$2" && return 0

    note "nobody said this run may deliver to [$2] — \`policy deliver-to\` is what says so"
    exit 18
}

refuse_incomplete() {
    findings=$(unmet_for_delivery "$1")

    [ -n "$findings" ] || return 0
    printf '%s\n' "$findings"
    exit 15
}

# Push, then say so. A source told about a delivery nobody can fetch is worse than silence, so the
# order is not a preference.
send_delivery() {
    branch=$(delivery_branch "$1")

    push_workspace "$1" "$2" "$branch"
    publish_delivery "$1" "$branch" "$3" "$(unit_head "$1" "$2")"
}

push_workspace() {
    tree=$(unit_work_tree "$1" "$2") || exit 16

    why=$(git -C "$tree" push origin "HEAD:refs/heads/$3" 2>&1) && return 0
    note "could not deliver [$3] to [$2]: $why"
    exit 19
}

# Read after the push and never before. `push_workspace` sends `HEAD`, so
# asking first names a commit the push might not have carried.
unit_head() { git -C "$(unit_work_tree "$1" "$2")" rev-parse HEAD 2>/dev/null; }

# Derived, never chosen. A branch a worker names is a branch a retry can rename, and then the source
# holds two deliveries for one run.
delivery_branch() { printf 'foundry/%s' "${1##*/}"; }

# Invariant 4. A run exists because a human selected the work item, and one that records nobody has
# no authority to deliver — the stamp lands at `new`, so its absence is a run made before the rule.
unauthorised_run() {
    # `~ /[^ ]/`, not `!= ""`. `one_line` folds every tab and newline in the selector to a space, so a
    # `FOUNDRY_WHO` holding one tab writes a field that is not empty and names nobody.
    who=$(awk -F'\t' 'NF == 3 && $2 ~ /[^ ]/ { print $2; exit }' "$(authority_file "$1")" 2>/dev/null)

    [ -n "$who" ] && return 0
    printf 'unauthorised: nobody is recorded as having selected this run\n'
}

empty_bar() {
    [ -n "$(awk '$1 == "clause" { print $2 }' "$(charter_file "$1")" 2>/dev/null)" ] && return 0
    printf 'nobar: the charter holds no clause, so it grades nothing\n'
}

#
# The invariant quantifies over **every** selected target, and one checkout answers for one of them.
# Without this, `unmet_clauses` grades what it can reach and a second selected target is never graded
# at all — so a run delivers on evidence that never mentioned the repository half its clauses govern.
#
# §8's two-target experiment is meant to fail today. This is the sentence that fails it, rather than
# the silence that used to pass it.
#
ungradable_targets() {
    here=$(this_repository)

    awk '!/^[ \t]*#/ && NF { print $1 }' "$(unit_targets_file "$1")" 2>/dev/null | while read -r identity; do
        [ "$identity" = "$here" ] && continue
        printf 'ungradable: [%s] has no checkout here, so nothing can be evidenced at its delivered ref\n' "$identity"
    done
}

empty_selection() {
    [ -n "$(awk '!/^[ \t]*#/ && NF { print $1 }' "$(unit_targets_file "$1")" 2>/dev/null)" ] && return 0
    printf 'nothing selected: no target, so every clause is satisfied over nothing\n'
}

#
# The invariant itself, per target — there is no run-level ref. A clause spanning two targets is
# satisfied against each one's delivered sha, and "the delivered ref" names neither.
#
# One checkout has a delivered ref. A clause pinned anywhere else is reported, never assumed
# satisfied: the alternative is a run that delivers because nobody could check it.
#
unmet_clauses() {
    file=$(charter_file "$1")
    here=$(this_repository)

    # The workspace's ref, found by the question the gates asked — so the two cannot answer about
    # different trees. A run with no workspace has delivered nothing, whatever its checkout holds.
    tree=$(unit_work_tree "$1" "$here" 2>/dev/null) \
        || { printf 'unopened: no workspace holds [%s], so nothing was delivered from one\n' "$here"; return; }

    ref=$(git -C "$tree" rev-parse --verify --quiet HEAD 2>/dev/null)
    [ -n "$ref" ] || { printf 'nothing delivered: the workspace holds no commit to be graded at\n'; return; }

    awk '$1 == "clause" { print $2 }' "$file" 2>/dev/null | while read -r id; do
        what_it_lacks "$1" "$file" "$id" "$here" "$ref"
    done
}

#
# What one clause is short of, or nothing at all.
#
# Three ways a clause is not met, and they take different remedies. A clause nothing pinned is
# invariant 1's *introduced*: no ref makes it true, and the answer that does is a human's, which the
# work source does not carry yet. Naming it `unverifiable` would send a reader looking for a checkout.
what_it_lacks() {
    text=$(clause_text "$2" "$3")

    has_record "$2" pin "$3" \
        || { printf 'introduced: [%s] rests on no pin, so no ref can satisfy it\n' "$text"; return; }

    has_local_pin "$2" "$3" "$4" \
        || { printf 'unverifiable: [%s] is pinned to a repository this checkout is not\n' "$text"; return; }

    panel=$(named_judges "$2" "$3")
    [ -n "$panel" ] && { what_the_panel_lacks "$1" "$text" "$4" "$5" "$panel"; return; }

    # A judged clause naming nobody is answered by nobody. Falling through let
    # any verdict satisfy it, which is a reader removing a requirement.
    [ "$(clause_kind "$2" "$3")" = Judged ] \
        && { printf 'unmet: [%s] at %s@%s — its panel names nobody, so nothing can answer it\n' "$text" "$4" "$5"; return; }

    satisfied "$1" "$text" "$5" "$(answers_for "$(clause_kind "$2" "$3")")" "" && return

    printf 'unmet: [%s] at %s@%s\n' "$text" "$4" "$5"
}

#
# A judge that answered, and said no.
#
# `satisfied` returns non-zero for a refusal and for silence alike, because both mean *not yes*. The
# two want opposite things next. A silent judge is asked again. **A refusal is answered by changing
# the work** — one dissent stops that ref for good, so asking the same judge again cannot help.
#
# Told apart by field 5, which the recorder already writes. Nothing new is stored.
#
#
# One and two, not merely non-zero. `reject` and `revise` are a judge answering; three and four are
# a judgement that never happened, and `stopped` holds those — reporting one as a refusal would send
# a reader to commit their way out of a harness that was never reached.
refused() {
    awk -F'\t' -v name="$2" -v ref="$3" -v judge="$4" '
        $4 "" != name "" || $6 "" != ref "" { next }
        $8 "" != judge ""                   { next }
        $5 == "1" || $5 == "2"              { found = 1 }
        END { exit !found }' "$(evidence_file "$1")" 2>/dev/null
}

#
# A judgement that never happened, recorded rather than left silent.
#
# An exhausted review budget or a harness nobody could reach. **Neither is a refusal and neither is
# silence.** A silent judge is asked again, a refusal is answered by new work, and this is answered
# by whoever owns the budget or the harness — three facts, three remedies.
#
# Told apart by the code the receipt's outcome mapped to, which the recorder already writes. Nothing
# new is stored.
stopped() {
    awk -F'\t' -v name="$2" -v ref="$3" -v judge="$4" '
        $4 "" != name "" || $6 "" != ref "" { next }
        $8 "" != judge ""                   { next }
        $5 == "3" || $5 == "4"              { found = 1 }
        END { exit !found }' "$(evidence_file "$1")" 2>/dev/null
}

# The members who answered no.
members_who_refused() {
    printf '%s
' "$4" | while IFS= read -r who; do
        [ -n "$who" ] || continue
        refused "$1" "$2" "$3" "$who" && printf '%s ' "$who"
    done
}

# The members a judgement was never reached for.
members_who_stopped() {
    printf '%s
' "$4" | while IFS= read -r who; do
        [ -n "$who" ] || continue
        stopped "$1" "$2" "$3" "$who" && printf '%s ' "$who"
    done
}

# The members who have not answered at all. Three ways one has spoken, and anything else is silence.
members_never_asked() {
    printf '%s
' "$4" | while IFS= read -r who; do
        [ -n "$who" ] || continue
        satisfied "$1" "$2" "$3" judged "$who" && continue
        refused    "$1" "$2" "$3" "$who"       && continue
        stopped    "$1" "$2" "$3" "$who"       && continue
        printf '%s ' "$who"
    done
}

# Every member said yes, or the ones who have not are named — and a refusal is named as one.
#
# It said `no approval from` for both, and the two want opposite things. A reader told that goes and
# asks. On a refusal that is a wasted trip: the dissent holds at this ref for good, and only a new
# commit moves it.
# A judgement that never happened gets its own line, for the same reason a refusal did. Which of the
# two it was — an exhausted budget or an unreachable harness — is in the record, in words.
what_the_panel_lacks() {
    judged_by_all "$1" "$2" "$4" "$5" && return

    said_no=$(spaced "$(members_who_refused "$1" "$2" "$4" "$5")")
    halted=$(spaced "$(members_who_stopped "$1" "$2" "$4" "$5")")
    silent=$(spaced "$(members_never_asked "$1" "$2" "$4" "$5")")

    [ -n "$silent" ] && printf 'unmet: [%s] at %s@%s — no approval from [%s]\n' \
        "$2" "$3" "$4" "$silent"

    [ -n "$said_no" ] && printf 'unmet: [%s] at %s@%s — [%s] refused here, and only a new ref moves it\n' \
        "$2" "$3" "$4" "$said_no"

    [ -n "$halted" ] && printf 'unmet: [%s] at %s@%s — [%s] never judged it. The record says why, and a new ref does not change it\n' \
        "$2" "$3" "$4" "$halted"

    return 0
}

#
# Every member of the panel said yes, at the ref delivered.
#
# **One dissent stops it.** A panel answering by majority would let the members who looked hardest
# be outvoted by the ones who did not.
#
# An empty panel is not agreement. A clause naming nobody is answered by nobody.
judged_by_all() {
    [ -n "$4" ] || return 1

    printf '%s
' "$4" | while IFS= read -r who; do
        [ -n "$who" ] || continue
        satisfied "$1" "$2" "$3" judged "$who" || exit 1
    done
}

# One line, one space between words, and none at either end. `one_line` leaves
# the separator the loop wrote, which read as an empty member.
spaced() { printf '%s' "$1" | awk '{ $1 = $1; print }' | tr '
' ' ' | sed 's/ *$//'; }

#
# A record answering *was this clause met* with yes, at the ref delivered.
#
# A yes and a no at one ref is a disagreement, not a satisfaction. §7 q10 held this open while every
# record was a command's exit code — one tree, one answer, and a second record could only repeat it.
# A human can answer now, and a second human can disagree, so the condition that made it harmless is
# gone. §2.2's rule for ambiguity is that it escalates: delivering on the yes would be choosing which
# of them was right.
#
# One tree still gives one answer, so a machine disagreement is a flaky gate saying so out loud.
#
# `""` on both sides of each comparison. An `-v` assignment is a numeric string, so a clause named
# `123` would match a record named `0123` — the identity defect §2.2 already paid for once.
#
# What may answer a clause, decided by the kind a human wrote. Trust was
# recorded and never read, so a gate could satisfy a
# clause whose whole point is that no command can.
#
# One row per kind, and no order over them. RFC-001 says the kinds are not a
# scale: a judgement raised to a gate wants a command that cannot exist.
#
# **`human` is only as true as the guard behind it.** `said_after` drops any comment written as the
# account this run posts under, and `posting_as` refuses to guess when it cannot read that account.
# Without both, a note the run wrote reads back as a person saying yes to it.
answers_for() {
    case "$1" in
        Gate)    printf 'machine' ;;
        Judged)  printf 'judged'  ;;
        Decided) printf 'human'   ;;
    esac
}

# A pass must come from the kind of authority the clause
# names. Any failure is a failure whoever read it, so
# a human's no still stops the gate that said yes.
#
# A record answering yes, at the ref delivered, from whoever may answer.
#
# `judge` is empty for every kind but `Judged`. Where it is set, a record from anybody else is
# skipped: they answered a question nobody put to them, which is neither a yes nor a no.
satisfied() {
    awk -F'\t' -v name="$2" -v ref="$3" -v trust="$4" -v judge="$5" '
        $4 "" != name "" || $6 "" != ref ""   { next }
        judge "" != "" && $8 "" != judge ""   { next }
        $5 != "0"                             { no = 1; next }
        trust == "" || $2 "" == trust ""      { yes = 1 }
        END { exit !(yes && !no) }' "$(evidence_file "$1")" 2>/dev/null
}

# A verdict from something that did not produce the work. That is the whole of
# what `judged` means, and a worker writing one about
# itself has answered nothing.
#
# Floor cannot prove who typed it, because the file is writable by the same
# user. Refusing the name it already knows is what an honest record can do.
verdict() {
    dir=$1; text=${2:-}; judge=${3:-}; outcome=${4:-}; said=${5:-}; reviewed=${6:-}

    [ -n "$text" ] && [ -n "$judge" ] && [ -n "$outcome" ] && [ -n "$said" ] && [ -n "$reviewed" ] \
        || { note "a verdict names the clause, the judge, the outcome, what they said, and the sha they read"; exit 2; }

    code=$(code_for_outcome "$outcome") || exit 2
    version=$(charter_version "$dir")

    refuse_a_kind_that_is_not_judged "$dir" "$text"
    refuse_a_judge_that_is_the_worker "$judge"
    refuse_a_judge_nobody_asked "$dir" "$text" "$judge"

    enter_work_tree "$dir"
    refuse_a_revision_nobody_reviewed "$reviewed"
    refuse_a_judge_never_handed_the_bar "$dir" "$text" "$judge" "$reviewed" "$version"

    stamp_verdict "$dir" "$text" "$code" "$reviewed" "$judge: $said" "$judge"
}

#
# Saying a judge was given the bar, before it answers.
#
# The recorder cannot read a transcript, so it can never know what reached anyone. What it can hold
# is this: whoever handed the bar over said so first, at a named charter and a named commit.
# `brief` is the digest of what was actually sent, and it is the caller's to supply — floor never
# reads a brief and has no idea where one lives. Absent, the handoff still records; what it costs is
# that a receipt has nothing to be checked against.
handed() {
    dir=$1; text=${2:-}; judge=${3:-}; how=${4:-}; brief=${5:-}

    [ -n "$text" ] && [ -n "$judge" ] && [ -n "$how" ] \
        || { note "a handoff names the clause, the judge, and how that judge was run"; exit 2; }

    version=$(charter_version "$dir")

    refuse_a_kind_that_is_not_judged "$dir" "$text"
    refuse_a_judge_nobody_asked "$dir" "$text" "$judge"

    enter_work_tree "$dir"
    stamp_handoff "$dir" "$text" "$(delivered_ref)" "$version" "$judge" "$how" "$brief"
}

# The charter's own sum. A bar rewritten after the handoff is a different bar, and a verdict
# answering the old one answers nothing here.
charter_version() { digest_of "$(charter_file "$1")"; }

#
# A file's sum, which is what a `brief` field holds.
#
# `cksum` because floor declares `sh`, `awk` and `git`, and nothing else. `sha1sum` is GNU, `shasum`
# is not everywhere, and a digest a host cannot compute is a field a producer has to invent.
#
# **Thirty-two bits, and it is a digest of what went over rather than a guard against a hand.** Two
# briefs can collide, and anyone who can edit a brief can edit the receipt naming it — §2.5 again.
digest_of() { cksum < "$1" 2>/dev/null | awk '{ print $1 }'; }

# The producer moved on and the review did not. Stamping it anyway credits an old
# answer to a commit that nobody ever read.
refuse_a_revision_nobody_reviewed() {
    [ "$1" = "$(delivered_ref)" ] && return 0

    note "[$1] is not where this run is — its work is at [$(delivered_ref)]"
    note "a review of one commit is not a review of another"
    exit 35
}

refuse_a_judge_never_handed_the_bar() {
    was_handed "$1" "$2" "$3" "$4" "$5" && return 0

    note "nothing records [$3] being handed the bar for [$2] at [$4]"
    note "  run.sh evidence handed <clause> <judge> is what says it was"
    exit 36
}

# One row is enough and every field must be that row's. A handoff at another commit, or under a
# charter since rewritten, is a different handoff.
was_handed() {
    awk -F'\t' -v name="$2" -v judge="$3" -v ref="$4" -v version="$5" '
        $2 != "handed"      { next }
        $4 "" != name ""    { next }
        $8 "" != judge ""   { next }
        $6 "" != ref ""     { next }
        $7 "" == version "" { found = 1 }
        END { exit !found }' "$(evidence_file "$1")" 2>/dev/null
}

#
# A verdict says which of three things happened, and the record carries it.
#
# It used to stamp 0 whatever the words said, so a judge writing `REJECT` satisfied the clause they
# had just refused. The prose was recorded and never read.
code_for_outcome() {
    case "$1" in
        approve) printf 0; return 0 ;;
        reject)  printf 1; return 0 ;;
        revise)  printf 2; return 0 ;;
    esac

    note "[$1] is not an outcome — approve, reject or revise"
    return 1
}

#
# The declared judge, and nobody else.
#
# **This compares a name. It proves nothing about who typed it**, because the record is writable by
# the same user — §2.5. A reviewer who was not asked has answered a question nobody put to them.
#
# A clause with no judge recorded takes no verdict at all. A reader that came back empty must never
# be the reason a requirement quietly went away.
refuse_a_judge_nobody_asked() {
    panel=$(named_judges "$(charter_file "$1")" "$(clause_id "$2")")

    printf '%s
' "$panel" | grep -qx "$3" && return 0

    [ -n "$panel" ] && {
        note "[$2] is answered by [$(spaced "$panel")], and this verdict is from [$3]"
        exit 2
    }

    # A clause naming nobody takes no verdict at all. Letting one in rested on a second
    # guard — no pin on an introduced clause — and a rule held up by another will not.
    note "[$2] names no panel, so nothing can answer it — declare one and re-derive"
    exit 2
}

refuse_a_kind_that_is_not_judged() {
    file=$(charter_file "$1")
    id=$(clause_id "$2")

    [ "$(clause_kind "$file" "$id")" = Judged ] && return 0

    note "[$2] is not a Judged clause, so a verdict answers nothing about it"
    note "a Gate clause is answered by \`gates\`, and a Decided one by a human where the item is"
    exit 2
}

refuse_a_judge_that_is_the_worker() {
    [ "$1" != "$(worker)" ] && return 0

    note "[$1] produced the work, so its verdict on that work says nothing"
    note "a verdict comes from something that did not write what it grades"
    exit 2
}

#
# Every key a receipt may carry. **Closed on purpose.** A key this has no reading for is a claim
# nobody checked wearing the look of one that was, so it is refused rather than kept.
#
# **`model`, `provider` and `effort` are not keys, and that is measured rather than careful.** One
# adapter was driven here in its json mode: its stream carries a thread handle, the reply and the
# usage, and names none of the three. Asked outright which model it was, it answered with a
# different name from the one requested.
#
# So the doubt sits in the key and never in a footnote beside it. `requested_` says what was asked
# for, which proves intent and nothing more — an alias, a routing rule or a fallback changes what
# ran. `self_reported_` says what the thing claimed about itself. **A bare `model` reads as fact to
# every reader and every script, and the caveat beside it is the part that gets skipped.**
#
# What a receipt proves outright is narrower and real: one thread returned review text, and whether
# that thread was new. Two runs gave two handles, so `context` and `fresh` are attestable.
#
# Core names the fields and never their values. What an adapter or a model is called is whatever
# wrote the receipt, exactly as `worker` takes a word and reads nothing into it.
#
# **So `adapter` is a label, and a substitution nobody records is invisible here.** Harness A is
# asked, writes nothing at all, and harness B writes a receipt naming itself — floor takes B's,
# because the first thing it ever learns about either is the name on the file in front of it.
# Refusing that needs `handed` to record the harness as an identity before the answer comes back,
# and `how` is prose for a person. **#332 leaves this open, and the README says so.**
#
# `context` and `fresh` stay optional for the reason `model` is not a key at all: **requiring a
# field is how a producer is made to invent one.** A runner with no thread to name would write
# `context unknown`, which reads in a record exactly like a handle somebody checked. What is gated
# is the shape — `fresh` needs a context to be about, and it says yes or no — never that the thread
# was new. Floor cannot verify a handle it did not issue.
RECEIPT_KEYS='run clause candidate role adapter brief verdict report round prior time
              context fresh
              requested_model    self_reported_model
              requested_provider self_reported_provider
              requested_effort   self_reported_effort'

# The three a receipt may not say plainly, and what to say instead. Outside the vocabulary already,
# so this only replaces the sentence — the one key an author reaches for first deserves the reason.
RECEIPT_UNPROVABLE='model provider effort'

#
# The ones without which it is not a receipt at all.
#
# **The rest are vouched for or absent, and absence is the honest answer.** An adapter that cannot
# say which model answered leaves `model` out; nothing here writes a default, and nothing writes
# `unknown`. A missing field says nobody checked, which is true. A filled-in one would be a claim.
RECEIPT_REQUIRED='run clause candidate role adapter brief verdict report round time'

#
# A judgement receipt — what a runner writes down when something judged this work.
#
# **This reads one. It produces none, and knows nothing about what did.** The file is the whole
# contract: any harness able to write these lines satisfies a `Judged` clause here, and none of them
# is named in this repository. That is the difference between consuming evidence and depending on a
# producer.
#
# `verdict` above takes a judgement typed by hand — five things, and five refusals. This takes one a
# runner made, makes every refusal that one makes, and adds what the extra fields let it ask. It
# extends that verb rather than replacing it.
#
# **A receipt is a record and never a credential.** Every field in it was written by whatever wrote
# the file, and none of them proves who answered — #156 owns making the actor real. What this adds
# is that a receipt cannot claim what it did not check.
#
receipt() {
    dir=$1; file=${2:-}

    refuse_a_malformed_receipt "$file"
    refuse_a_claim_nobody_checked "$file"

    # Every field read before `enter_work_tree`, because that leaves this directory for good and a
    # caller may have named the receipt relative to the one it started in.
    clause=$(said_in "$file" clause)
    judge=$(said_in "$file" role)
    candidate=$(said_in "$file" candidate)
    outcome=$(said_in "$file" verdict)
    brief=$(said_in "$file" brief)
    report=$(said_in "$file" report)
    vouched=$(attested "$file")

    code=$(code_for_judgement "$outcome") || exit 2
    version=$(charter_version "$dir")

    refuse_a_receipt_from_another_run "$dir" "$(said_in "$file" run)"
    refuse_a_kind_that_is_not_judged "$dir" "$clause"
    refuse_a_judge_that_is_the_worker "$judge"
    refuse_a_judge_nobody_asked "$dir" "$clause" "$judge"

    enter_work_tree "$dir"
    refuse_a_revision_nobody_reviewed "$candidate"
    refuse_a_judge_never_handed_the_bar "$dir" "$clause" "$judge" "$candidate" "$version"
    refuse_a_brief_that_changed "$dir" "$clause" "$judge" "$candidate" "$version" "$brief"

    stamp_receipt "$dir" "$clause" "$code" "$candidate" \
        "$judge: $outcome, report $report" "$judge" "$vouched"
}

# Whether the file is a receipt at all, before anything asks what it says.
refuse_a_malformed_receipt() {
    refuse_an_unreadable_receipt "$1"
    refuse_a_line_that_is_not_a_receipt_line "$1"
    refuse_a_field_that_is_not_there "$1"
}

#
# Three ways there is nothing to read, and each one is its own guard.
#
# They were one function, and a break on the middle one still exited 37 through the third — so the
# only thing that could tell them apart was the sentence. **A refusal a mutant cannot reach alone is
# a refusal resting on its neighbour**, which is the shape `craft-sh` splits.
refuse_an_unreadable_receipt() {
    refuse_a_receipt_nobody_named "$1"
    refuse_a_receipt_that_is_not_there "$1"
    refuse_a_receipt_holding_nothing "$1"
}

# The caller named no file. Ahead of the two below, because every reader here is handed `$1` as a
# filename, and awk given an empty one answers about a file nobody asked for.
refuse_a_receipt_nobody_named() {
    [ -n "$1" ] && return 0

    note "receipt needs the file to read"
    exit 2
}

#
# The refusal the whole contract rests on. **Green gates do not reach here** — a `Judged` clause is
# answered by a judge's record and by nothing else, so a run with every gate passing and no receipt
# is a run nothing has judged.
#
# **No mutation makes a missing receipt satisfy anything**, and that is worth writing down rather
# than mistaking for an untested path. Blind this and the next guard answers 37; blind that too and
# the required-field reader answers 37; blind that and the outcome is empty, which is not one of the
# five. It fails closed four deep, so what a break here changes is which sentence a reader gets.
refuse_a_receipt_that_is_not_there() {
    [ -f "$1" ] && return 0

    note "no receipt at [$1], and a Judged clause is answered by one"
    exit 37
}

refuse_a_receipt_holding_nothing() {
    [ -r "$1" ] && [ -s "$1" ] && return 0

    note "[$1] is there and holds nothing this can read as a receipt"
    exit 37
}

#
# The grammar, in one pass, and the first bad line is named.
#
# Four ways a line is not a receipt line — a key that would claim what nobody checked, a key with no
# reading at all, a key said twice, and a key claiming nothing. One reader for all four, because the
# remedy for each is that same line.
#
# **Two answers is not one.** A key said twice leaves whoever reads it choosing which was meant, and
# §2.2's rule for ambiguity is that it escalates rather than resolves itself.
refuse_a_line_that_is_not_a_receipt_line() {
    said=$(awk -v known="$RECEIPT_KEYS" -v unprovable="$RECEIPT_UNPROVABLE" '
        BEGIN { n = split(known, key);      for (i = 1; i <= n; i++) reads[key[i]] = 1
                n = split(unprovable, said); for (i = 1; i <= n; i++) claims[said[i]] = 1 }

        /^[ \t]*#/ || !NF { next }

        $1 in claims { print "[" $1 "] would state what ran, and nothing checked it" \
                             " — say requested_" $1 " or self_reported_" $1; exit }
        !($1 in reads) { print "[" $1 "] is a key floor has no reading for"; exit }
        $1 in seen     { print "[" $1 "] is said twice, and two answers is not one"; exit }
        NF < 2         { print "[" $1 "] claims nothing, so nothing is what it says"; exit }

        { seen[$1] = 1 }' "$1" 2>/dev/null)

    [ -n "$said" ] || return 0

    note "$1: $said"
    exit 37
}

# A required key absent, named one at a time so a reader fixes one line and asks again.
refuse_a_field_that_is_not_there() {
    said=$(awk -v want="$RECEIPT_REQUIRED" '
        !/^[ \t]*#/ && NF { seen[$1] = 1 }
        END { n = split(want, keys, " ")
              for (i = 1; i <= n; i++) if (!(keys[i] in seen)) { print keys[i]; exit } }' "$1" 2>/dev/null)

    [ -n "$said" ] || return 0

    note "$1 carries no [$said], and a receipt without one is evidence of nothing"
    exit 37
}

# A field standing on one that is not there. Each of these reads as checked and rests on nothing.
refuse_a_claim_nobody_checked() {
    refuse_a_freshness_about_nothing "$1"
    refuse_a_freshness_that_answers_neither "$1"
    refuse_a_round_that_is_not_a_count "$1"
    refuse_a_round_with_no_prior "$1"
}

# Fresh about what? A context nobody named can be neither new nor used, so the claim has no subject.
refuse_a_freshness_about_nothing() {
    fresh=$(said_in "$1" fresh)

    [ -n "$fresh" ] || return 0
    [ -n "$(said_in "$1" context)" ] && return 0

    note "$1 says the context was [$fresh] and names none, so the claim is about nothing"
    exit 37
}

#
# Yes or no, and nothing else. A thread was new or it was carried on, and there is no third answer.
#
# **This gates the shape and never the truth.** Floor did not issue the handle and cannot go and
# look, so `fresh yes` is the producer's word — a record, like every other field. What it stops is
# free text in the one column the charter calls attestable, where `probably` or `n/a` would read as
# an answer to a question nobody put.
refuse_a_freshness_that_answers_neither() {
    case "$(said_in "$1" fresh)" in
        ''|yes|no) return 0 ;;
    esac

    note "$1 says fresh [$(said_in "$1" fresh)], and a thread was new or it was not"
    exit 37
}

# `[ abc -gt 1 ]` is not a comparison. The shell complains to stderr and returns non-zero, so the
# guard below would read as having passed — a round nobody can count is refused before one counts it.
refuse_a_round_that_is_not_a_count() {
    round=$(said_in "$1" round)
    is_a_count "$round" && return 0

    note "$1 says round [$round], and a round is counted from one"
    exit 37
}

is_a_count() {
    case "$1" in
        ''|*[!0-9]*|0) return 1 ;;
    esac
    return 0
}

# Round two answers round one. A later round naming no prior verdict is a first round wearing a
# number, and the chain it says it is in is one nobody can follow.
refuse_a_round_with_no_prior() {
    round=$(said_in "$1" round)

    [ "$round" -gt 1 ] || return 0
    [ -n "$(said_in "$1" prior)" ] && return 0

    note "$1 says round [$round] and names no prior verdict, so the round before it is missing"
    exit 37
}

#
# A receipt is about one run's work.
#
# One from another run is a judgement that really happened, about something else. Replaying it here
# credits this work with a reading nobody gave it — which is why `run` is a field at all.
#
# A run whose id will not read matches nothing, so it refuses. That is the safe way round: the
# alternative accepts every receipt on a run that cannot say its own name.
refuse_a_receipt_from_another_run() {
    [ "$2" = "$(recorded_id "$1")" ] && return 0

    note "this receipt answers for run [$2], and this run is [$(recorded_id "$1")]"
    exit 38
}

#
# The bar as it went over, against the bar the receipt answers.
#
# **Floor holds neither.** It compares two digests it was handed — one at the handoff, one on the
# receipt — and reads no brief, because what a brief is and where it lives belongs to whatever
# writes them. A brief edited between the handoff and the answer makes the two differ, and that is
# the whole of what this can see.
#
# **It proves consistency and never authorship.** One adapter writes both, so matching digests say
# the bar did not move under the judge. They do not say the digest is of the brief it claims.
refuse_a_brief_that_changed() {
    was=$(handed_brief "$1" "$2" "$3" "$4" "$5")

    refuse_a_brief_nothing_recorded "$was" "$2" "$3"
    [ "$was" = "$6" ] && return 0

    note "[$3] was handed brief [$was] and this receipt answers [$6]"
    exit 38
}

# Nothing to compare against is not a match. A handoff that recorded no brief leaves the receipt
# answering a bar nobody wrote down — unverifiable, rather than wrong.
refuse_a_brief_nothing_recorded() {
    [ -n "$1" ] && return 0

    note "nothing records which brief [$3] was handed for [$2], so this answers an unknown bar"
    note "  run.sh evidence handed <clause> <judge> <how> <brief> is what records it"
    exit 37
}

# The brief digest recorded when the bar went over. `was_handed` has already found this row, so an
# empty answer means the handoff carried no brief — never that there was no handoff.
handed_brief() {
    awk -F'\t' -v name="$2" -v judge="$3" -v ref="$4" -v version="$5" '
        $2 != "handed"      { next }
        $4 "" != name ""    { next }
        $8 "" != judge ""   { next }
        $6 "" != ref ""     { next }
        $7 "" != version "" { next }
        { said = $10 }
        END { print said }' "$(evidence_file "$1")" 2>/dev/null
}

#
# What the receipt says came back, as a code the ledger compares.
#
# The judge's three, and two the judge never gave. **A deadlock and an unavailable harness are not
# verdicts** — they are the runner recording that no judgement happened, which is a different fact
# from silence and takes a different remedy. Both are non-zero, so neither satisfies anything, and
# both stop the delivery where they stand.
#
code_for_judgement() {
    case "$1" in
        deadlock)    printf 3; return 0 ;;
        unavailable) printf 4; return 0 ;;
    esac

    # The judge's own three, with its sentence suppressed: it names three, a receipt may say five,
    # and a reader told the wrong list goes looking for a word that is there.
    code_for_outcome "$1" 2>/dev/null && return 0

    note "[$1] is not what a receipt may say — approve, reject, revise, deadlock or unavailable"
    return 1
}

#
# One key's value, and nothing when the receipt does not carry it.
#
# The value is the rest of the line, taken verbatim: a clause holding two spaces has to match the
# charter's text exactly, and awk rebuilding `$0` would collapse them.
said_in() {
    awk -v want="$2" '!/^[ \t]*#/ && NF && $1 "" == want "" {
                          sub(/^[ \t]*[^ \t]+[ \t]+/, ""); print; exit }' "$1" 2>/dev/null
}

#
# What the receipt vouched for, carried into the record so the run keeps it once the file is gone.
#
# Every key but the six the row already holds as columns. Written `k=v` for a person to read and
# never for a parser — a value may hold a space, and the receipt itself is the artefact anything
# parsing should read.
#
# **Only what is there.** A field the adapter left out is left out here too, so a record with no
# `model=` says nobody checked which model answered.
attested() {
    awk '!/^[ \t]*#/ && NF && $1 !~ /^(run|clause|candidate|role|verdict|report)$/ {
             key = $1; sub(/^[ \t]*[^ \t]+[ \t]+/, "")
             printf "%s%s=%s", sep, key, $0; sep = " " }' "$1" 2>/dev/null
}

#
# Authorisation — every refusal it can make without a human present.
#
# RFC-001 §2.2 gives this stage four conditions and two refusals. The four decide when a human is
# *asked*, and asking needs a work source that does not exist. The refusals ask nobody anything, so
# they are the half that can ship, and they are the half that fires without a human present.
#
# Both are the same question — does this run describe work a charter can grade? — and neither has an
# answer a person could give, which is why they refuse rather than ask.
#
#
# `charter_path` and `selection_path`, not `file`: `refuse_unselectable` and `add_target` both assign
# `file`, sh has no locals, and the second call would quietly rename the first's. That is `craft-sh`
# rule 10 — one name, one meaning — and it cost a debugging session here before the rule was applied.
#
authorise() {
    run_dir=$(active_run) || exit 1
    refuse_renamed_run "$run_dir"

    charter_path=$(charter_file "$run_dir")
    selection_path=$(unit_targets_file "$run_dir")

    # First of the selection refusals, and that ordering is the whole point. Every later check reports
    # what is wrong with the selection *now* and names a remedy that would edit it — `policy authorize`
    # this, select that. Once a selection is frozen those remedies are forbidden: the only answer is
    # a new run. Emptying the selection reaches the same fork, where the grades-nothing check would
    # otherwise fire first and report the symptom.
    #
    # The rename guard runs ahead of all of them and does not disturb this. Its remedy edits no
    # selection — move the directory back, or start again.
    refuse_moved_selection "$run_dir" "$selection_path" || exit 10

    refuse_unselectable "$run_dir" "$selection_path" || exit 5

    # The third consumer of the detector, and it needs what the other two need. `detect_gates` reads
    # the directory you are standing in, so without these an `authorise` run from anywhere holding a
    # `.foundry/gates` answers from that file — and this stage writes its answer down. Verified: a
    # plain directory declaring the charter's gates turned a correct exit 9 into exit 0 and a frozen
    # record. `refuse_wrong_repository` returns 0 for a run with no bootstrap, so the bare-CLI case
    # is untouched.
    refuse_wrong_repository "$run_dir"
    refuse_missing_resolver
    refuse_unreadable_declaration

    #
    # Condition 3 — a clause the pins still derive is gone. `underived_gates` already computes it and
    # `check` already reports it; this consumes that answer rather than asking the question twice.
    # `deleted:` alone: its other findings are drift, which is `check`'s to report and not a
    # violation of invariant 3.
    #
    # A refusal, not a question. The remedy is to restore the clause or stop the artifact deriving
    # it, and both are edits a person makes before the run, never answers a person gives during it.
    #
    # Ahead of the empty-charter refusal, because deleting the last clause satisfies both and only
    # this one is true: exit 8 would answer "declare a gate" where a gate is declared and the clause
    # was removed.
    #
    # The guard `check` carries. Without it a run that never derived is told it *lost* a clause, with
    # pins asserted that do not exist — verified by execution on a fresh run in a repo the detector
    # answers for.
    [ -f "$charter_path" ] || {
        note "this run has no charter — run \`charter derive\` first"
        exit 1
    }

    # What `deleted:` observes, said exactly: the detector yields a gate the charter holds no clause
    # for. A clause removed by hand is one way to reach that; a gate declared since the last
    # derivation is another, and growth is allowed. Re-deriving is the remedy for both, so the
    # refusal is right either way — but naming a loss that may not have happened is not.
    gates_with_no_clause=$(underived_gates "$charter_path" | awk '/^deleted: /')
    [ -z "$gates_with_no_clause" ] || {
        printf '%s\n' "$gates_with_no_clause" | while read -r _ kind name; do
            note "the detector yields $kind $name and the charter holds no clause for it"
        done
        note "re-derive, or stop the artifact declaring it"
        exit 12
    }

    [ "$(clause_count "$charter_path")" -gt 0 ] || {
        note "the charter holds no clause, so there is nothing to authorise"
        note "declare a gate this run's targets can be checked with, or write the requirement into an artifact derivation reads"
        exit 8
    }

    #
    # Condition 1 — a clause nothing pinned, and no channel to ask about it.
    #
    # Blocks rather than authorising. The clause may be perfectly good; what is missing is the human
    # act that says so, and §2.1 already defines what a source that cannot ask does — it forces every
    # ask to block. Proceeding would let a run introduce its own bar, which is the one thing invariant
    # 1 exists to prevent.
    #
    # **Condition 2 collapses into this.** No judge exists, so no clause reaches the semantic path at
    # all: every clause the mechanical path cannot establish arrives here instead. The gate therefore
    # blocks more often than it eventually will, never less — and nothing durable records the
    # ambiguity, because there is no ambiguity to record until something can answer.
    #
    # Ahead of the coverage refusal below. Both fire on an introduced `Gate:` clause naming a gate
    # nothing declares, and exit 9's remedy — declare that gate — would coach someone into making a
    # clause nobody authorised into a real bar, then tell them afterwards it had no provenance.
    # Provenance is the earlier question.
    #
    introduced=$(unauthorised_clauses "$run_dir" "$charter_path")
    [ -z "$introduced" ] || {
        ask_about_each "$run_dir" "$introduced" || exit 1
        note "a human owns this. Answer where the item is, naming the clause, and authorise again"
        exit 11
    }

    ungoverned=$(ungoverning_clauses "$run_dir" "$charter_path" "$selection_path")
    [ -z "$ungoverned" ] || {
        for id in $ungoverned; do
            note "clause $id grades no selected target, so it is no bar"
        done
        note_coverage_remedy "$run_dir"
        exit 9
    }

    freeze_selection "$run_dir" "$selection_path"
}

# A run authorised before the rename holds `authorised-targets`, and it is
# read rather than refused. That name said who allowed the
# selection, which `policy` already answers.
#
# Silently, and on purpose. This is asked three
# times per command, and any note that fires
# that often is one people learn to skip.
frozen_selection_file() {
    named="$1/units/01/selection"
    [ -f "$named" ] && { printf '%s' "$named"; return 0; }

    before="$1/units/01/authorised-targets"
    [ -f "$before" ] && { printf '%s' "$before"; return 0; }

    printf '%s' "$named"
}

selection_is_frozen() { [ -f "$(frozen_selection_file "$1")" ]; }

# A refusal naming a remedy that leads to another refusal is worse than one remedy — and after the
# freeze, selecting a target is that other refusal.
note_coverage_remedy() {
    selection_is_frozen "$1" \
        || { note "declare the gate that clause names, or select a target it governs"; return; }

    note "declare the gate that clause names — the selection is frozen, so changing it is a new run"
}

#
# The selection, written down at the moment it stops moving.
#
# §4 freezes the selected set here, and until now that was a word with no mechanism: the only record
# of what was selected was the file being selected from, so nothing could tell a line added since
# from a line always there — and nothing at all could see a line **removed**. Revision 7 killed this
# same shape once already, when monotonicity turned out to be decorative.
#
# The lines, not a checksum of them. A digest answers *something moved* and a diff has to answer
# *what*, and the second question is the one a person asks. Two records of the same set would drift;
# this is the only one.
#
# Sorted, because §2.3 calls it a set. Reordering the file is not a different selection, and a
# refusal that fired on it would teach people to ignore refusals.
#
freeze_selection() {
    frozen=$(frozen_selection_file "$1")
    mkdir -p "${frozen%/*}" || die_unwritable "$frozen"
    normalised_selection "$2" > "$frozen" || die_unwritable "$frozen"
}

#
# `-u` as well as sorted. `add_target` does not dedupe, so selecting one target twice would otherwise
# read as a set that moved — a refusal on a selection nobody changed, which is the thing sorting is
# here to avoid.
#
# `$1 = $1` rebuilds the line on single spaces, so a hand-added tab or a doubled space is not a
# selection that moved. Same reason as the sort and the dedupe: only a changed *set* may refuse.
normalised_selection() { list_targets "$1" | awk '{ $1 = $1; print }' | LC_ALL=C sort -u; }

#
# Authorising twice over a selection that moved in between.
#
# §4's remedy is a new run, never a re-run: the frozen set is what completion will grade against, so
# quietly re-freezing would let the selection be edited after the moment it was fixed, which is the
# whole thing the freeze exists to stop.
#
# Deletion is why this reads the frozen record rather than re-checking policy. A removed line leaves
# nothing behind to check, and `refuse_unselectable` cannot see an absence.
#
refuse_moved_selection() {
    frozen=$(frozen_selection_file "$1")
    [ -f "$frozen" ] || return 0

    [ "$(normalised_selection "$2")" = "$(cat "$frozen")" ] && return 0

    note "the selection moved after it was authorised, so this run is no longer the one that was authorised"
    note "start a new run — §4 makes a changed selection a new attempt, not a re-authorisation"
    return 1
}

clause_count() {
    [ -f "$1" ] || { printf '0\n'; return 0; }
    awk '$1 == "clause" && NF >= 2' "$1" | wc -l | tr -d ' '
}

#
# Which clauses grade nothing.
#
# §2.2: every clause governs every selected target, with one derived exception — a `Gate:` clause
# governs each selected target that declares that gate. A target whose declarations cannot be read
# **stays governed**, and detection reads the bootstrap checkout only, so every other selected target
# is unreadable and therefore governed by everything.
#
# Two cases follow, and only two: nothing is selected, or the sole selected target is the bootstrap
# and it declares no gate by that name. Both are computed here rather than assumed, so the day a
# workspace gives each target a checkout this reads the same and answers differently.
#
ungoverning_clauses() {
    dir=$1
    file=$2
    targets_file=$3

    [ -f "$file" ] || return 0

    selected=$(list_targets "$targets_file" | wc -l | tr -d ' ')
    [ "$selected" -gt 0 ] || { awk '$1 == "clause" { print $2 }' "$file"; return 0; }

    boot=$(bootstrap_identity "$dir") || return 0
    only_boot=$(list_targets "$targets_file" | awk -v b="$boot" '$1 != b' | wc -l | tr -d ' ')
    [ "$only_boot" -eq 0 ] || return 0

    declared=$(detect_gates | awk '{ print $1 }')
    awk -v names="$declared" '
        BEGIN { split(names, seen, "\n"); for (i in seen) has[seen[i]] = 1 }
        $1 == "clause" && $3 == "Gate" && !($4 in has) { print $2 }
    ' "$file"
}

#
# A clause's identity is its meaning, so re-deriving the same clause finds the same record rather
# than adding a second. `cksum` is POSIX and everywhere; no hashing tool needs installing.
#
# **The kind is not part of it.** Folding it in gave `Gate: tests` and `Decided: tests` different
# ids, so the weakening check looked for a clause that could never be there and monotonicity was
# decorative. One meaning, one clause, one strength.
#
clause_id() { printf '%s' "$1" | cksum | awk '{ print $1 }'; }

#
# The three kinds, and deliberately no order over them.
#
# An earlier version ranked them — Gate over Judged over Decided — to decide whether a kind change
# was a tightening. It is neither. `Judged: the interface is understandable` raised to `Gate:` asks
# for a command that cannot exist, and `Decided:` carries authority no command can hold. The kinds
# say how truth is established, not how much of it there is.
#
# What monotonicity actually needs is `dropped_clauses`: a clause is its text, so a changed
# requirement is a different clause, and every weakening is therefore a removal.
#
is_kind() {
    case "$1" in
        Gate | Judged | Decided) return 0 ;;
    esac
    return 1
}

#
# Clause text is one line of a line-oriented file. A newline in it would be a second record.
#
# Measured, not matched. `case "$x" in *"$(printf '\n')"*)` looks right and is not: command
# substitution strips trailing newlines, so the pattern is `*""*` and matches everything.
#
# One newline, carriage return or tab, and it is not one line.
#
# The three characters are read once, because a process costs 60ms and `case` costs nothing.
# The two pipes this replaced spawned five processes for every field of every record.
NEWLINE='
'
CARRIAGE_RETURN=$(printf '\r')
TAB=$(printf '\t')

is_one_line() {
    [ -n "$1" ] || return 1

    case $1 in
        *"$NEWLINE"*|*"$CARRIAGE_RETURN"*|*"$TAB"*) return 1 ;;
    esac

    return 0
}

# What the charter already says about one meaning, or nothing.
clause_kind() {
    awk -v want="$2" '$1 == "clause" && $2 == want { print $3; exit }' "$1" 2>/dev/null
}

print_clause() { printf 'clause %s %s %s\n' "$1" "$2" "$3"; }

#
# One record per meaning, in the place the meaning already had.
#
# Appending a tightened clause leaves the weaker record first, and every reader here takes the first
# match — so the tightening was accepted, written down, and had no effect on anything.
#
#
# One id, one meaning — or refuse.
#
# `cksum` is 32 bits, so two texts can land on the same id. Every reader here takes the first record
# for an id, so a collision silently replaces the wrong clause and makes monotonicity compare two
# meanings that are not the same. The text is stored beside the id, which is what makes the collision
# visible at all; refusing is the only answer that cannot corrupt a charter.
#
refuse_collision() {
    was=$(clause_text "$1" "$2")
    [ -z "$was" ] || [ "$was" = "$3" ] || {
        note "id $2 already means [$was] — refusing to reuse it for [$3]"
        return 1
    }
}

put_clause() {
    file=$1
    line="clause $2 $3 $4"

    refuse_collision "$file" "$2" "$4" || exit 6

    awk -v id="$2" -v line="$line" \
        '$1 == "clause" && $2 == id { print line; replaced = 1; next }
         { print }
         END { if (!replaced) print line }' "$file" 2>/dev/null > "$file.put" \
        || die_unwritable "$file"

    mv "$file.put" "$file" || die_unwritable "$file"
}
print_pin()    { printf 'pin %s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5"; }

#
# What a gate name resolved to at the base.
#
# A third record, not a sixth field on `pin`. A pin says where a clause's meaning came from; this
# says what that meaning currently resolves to, and only gates have one. Folding it into `pin` would
# make the record variable-length for one kind of clause, and `check` needs both facts separately:
# a moved source and a moved command are different findings.
#
print_gate() { printf 'gate %s %s\n' "$1" "$2"; }

# The command a gate resolved to when the charter was written.
# A count, not a pattern, was the bug: blanking two fields of a three-field record leaves two spaces,
# but of a two-field one — a gate pinned with no command — it leaves a single space. `moved_resolutions`
# then read that space as a command and reported drift from the empty string to the empty string.
pinned_command() {
    awk -v want="$2" '$1 == "gate" && $2 == want { $1 = ""; $2 = ""; sub(/^ +/, ""); print; exit }' \
        "$1" 2>/dev/null
}

# Resolve this repository's gates. The only caller of the one file that knows what an ecosystem is.
#
# Resolve this repository's gates, through whichever resolver is in use.
#
# The resolver is an adapter, and an adapter you cannot replace without editing its caller is not
# one. `FOUNDRY_GATES` names another; the shipped one is the default, and it is the only file here
# permitted to know an ecosystem exists. Nothing above this line learns which resolver answered.
#
# **It is never the target's.** `FOUNDRY_GATES` belongs to whoever runs this, who can already run
# anything. A repository supplies data — `.foundry/gates` — and the resolver reads it and executes
# nothing.
#
# What it yields *is* executed, by `gate_held`, and that is the job. From the charter, pinned when it
# was derived and compared against the base ever after: a worker owning the checkout can change what
# the file says and cannot change what runs, because the run refuses instead of running it.
#
gate_resolver() { printf '%s' "${FOUNDRY_GATES:-$SELF_DIR/../lib/detect-gates.sh}"; }

#
# Always the repository root, never the working directory.
#
# `detect_gates .` let the directory you happened to stand in decide what the charter says. Running
# `charter derive` one level down found no gates, wrote an empty charter, and exited 0 — the silent
# emptying `dropped_clauses` exists to refuse, arriving through the front door instead.
#
detect_gates() { sh "$(gate_resolver)" "$(repo_root)"; }

# The same question about judgement. Its own resolver, because a gate and a judged clause are
# different declarations and a repository may make either without the other.
judged_resolver() { printf '%s' "${FOUNDRY_JUDGED:-$SELF_DIR/../lib/detect-judged.sh}"; }

detect_judged() { sh "$(judged_resolver)" "$(repo_root)"; }

#
# A bar the repository declares and nothing here can read.
#
# Beside `refuse_missing_resolver` at all three readers, because the answer is the same shape: the
# resolver cannot do its job, and a stage that carries on grades against a guess. In `derive` it is
# also ahead of `refuse_moved_resolution`, which sees a base declaring gates this checkout does not
# and reports a move — true of the answer, wrong about the cause, and it names the wrong remedy.
#
refuse_unreadable_declaration() {
    detect_gates >/dev/null
    [ "$?" -ne 22 ] && return 0

    note "the bar this repository declares cannot be read"
    exit 22
}

#
# The same question, asked of the base. A temporary worktree, because the resolver reads a directory
# and a base is a commit — read-only, and removed either way. Not the workspace seam.
#
detect_gates_at_base() {
    scratch="${TMPDIR:-/tmp}/floor-base-$$"

    git worktree add --detach --quiet "$scratch" "$1" >/dev/null 2>&1 || return 1
    sh "$(gate_resolver)" "$scratch"
    git worktree remove --force "$scratch" >/dev/null 2>&1
}

#
# What the resolver answers for the base, and what it answers now.
#
# Comparing pinned sources one by one cannot see a source that stopped being yielded. Delete a
# level-2 declaration in the checkout and detection falls back a level, so the clause survives under
# a different source and every remaining pin still matches — a bar the worker authored by deleting a
# file. RFC-001 §2.2 asks for both halves: the resolved command must not differ between the base and
# what is delivered, *and* no file the detector read may differ.
#
# Only what the base declared and no longer resolves the same way. A content change keeps its source
# and is `refuse_moved_from_base`'s to report; a source that appears is `no sha`'s. Widen this past
# the case nothing else covers and it answers first for all three, in the vaguest of the words.
refuse_moved_resolution() {
    # A base nobody can read yields no declaration, and this passes. It is the pin check that refuses
    # that case — it reads the same base for a sha and cannot get one. Measured: remove the base
    # commit's object and the run is refused by `no sha ... pin refused`, never by this. Safe because
    # of a neighbour, so the neighbour is checked.
    declared=$(detect_gates_at_base "$1") || return 0

    moved=$(printf '%s\n' "$declared" | awk -v now="$(detect_gates)" '
        BEGIN {
            rows = split(now, row, "\n")
            for (i = 1; i <= rows; i++) {
                split(row[i], field)
                if (field[1] != "") source[field[1]] = field[2]
            }
        }
        # Somewhere else, never nowhere. A gate that stops resolving at all is a clause about to be
        # dropped, and invariant 3 refuses that by name — this would answer first and call it a move.
        $1 != "" && source[$1] != "" && source[$1] != $2 { print $1 }
    ')

    [ -z "$moved" ] && return 0

    note "the base declares these gates elsewhere than this checkout resolves them: $moved"
    note "commit the change and start a new run — a run cannot author the bar it is graded by"
    return 1
}

# The repository this call stands in, asked once.
#
# `git rev-parse --show-toplevel` costs about half a second here, and `charter derive` asked it
# five times for one answer. A process cannot move while it is asking, so the second question
# always had the first one`s answer.
#
# **The two places that `cd` clear it**, because there the answer really does change.
# The repository this call stands in.
#
# **A cache was tried here and removed.** Every caller reads it as `$(repo_root)`, and a command
# substitution runs in a subshell — so the assignment died with the subshell and the next call
# computed it again. The saving was claimed and never delivered.
#
# Caching it properly means reading a variable at each of the six call sites rather than calling
# a function, or computing it eagerly for every verb including those that never ask. Neither is
# worth 497ms on a shell where the whole gate already runs in 29 minutes.
repo_root() { git rev-parse --show-toplevel 2>/dev/null || printf '.'; }

#
# A resolver that is not there answers "no gates", and no gates is what a clean charter looks like.
#
# Checked by the caller, never inside `detect_gates`: every reader of it runs in a pipe or a command
# substitution, where `exit` leaves the subshell and the command carries on reporting nothing.
#
refuse_missing_resolver() {
    [ -f "$(gate_resolver)" ] || { note "no gate resolver at [$(gate_resolver)]"; exit 3; }
}

# The sha of one path at one ref. Empty means it could not be captured, and a pin that cannot be
# captured is not written — `write_bootstrap`'s rule, for the same reason.
#
# `--verify`, or a failure looks like an answer.
#
# Plain `git rev-parse main:gone` sends its `fatal:` to stderr and then echoes `main:gone` to
# stdout. Discarding stderr leaves that string looking exactly like a captured sha, and it gets
# pinned. `--verify --quiet` prints nothing and exits non-zero.
#
blob_sha() { git rev-parse --verify --quiet "$1:$2" 2>/dev/null; }

# What the file says right now, whoever wrote it. Rooted at the repository, because a gate's source
# is named from there and `derive` may be run from any directory inside it.
worktree_sha() { git -C "$(repo_root)" hash-object -- "$1" 2>/dev/null; }

#
# A run may establish provenance only from its base — RFC-001 invariant 1, issue #99.
#
# The detector reads the checkout; the pin resolves at the base. Let those disagree and the charter
# holds the base's blob beside the worker's command, so `check` passes on a bar nobody human wrote.
# Re-deriving was the remedy for drift, which made it the way to launder an edit into authority.
#
# A later run's base holds the commit and derives from it normally.
#
refuse_moved_from_base() {
    [ "$(worktree_sha "$1")" = "$2" ] && return 0

    note "[$1] differs from the base at $3, so this run cannot derive from it"
    note "commit it and start a new run — a run cannot author the artifact its own bar comes from"
    return 1
}

#
# Derive clauses from the repository this is run in.
#
# Only this repository, because a target is declared and never cloned — §2.3. There is nothing on
# disk to read for any other target until the workspace seam exists, so clauses for those targets
# cannot be derived yet, and inventing them would be introduction wearing provenance.
#
derive_charter() {
    dir=$1
    boot=$(bootstrap_identity "$dir") || {
        note "this run has no bootstrap target, so there is nothing to derive from"
        exit 1
    }
    refuse_wrong_repository "$dir"
    refuse_missing_resolver
    refuse_unreadable_declaration

    # The base, not the branch. Derive through a name and a worker that commits has rewritten the
    # artifact its own bar comes from — RFC-001 invariant 1, issue #99.
    ref=$(bootstrap_base "$dir") || {
        note "this run recorded no base commit, so nothing can say where its provenance came from"
        note "start a new run — one made before this rule cannot prove what it derived from"
        exit 6
    }

    refuse_moved_resolution "$ref" || exit 6

    file=$(charter_file "$dir")
    draft="$file.draft"

    # Everything is checked and staged before the charter moves. A refusal leaves it untouched.
    : > "$draft" || die_unwritable "$draft"
    detect_gates | while_reading_gates "$file" "$draft" "$boot" "$ref" || {
        rm -f "$draft"
        exit 6
    }

    detect_judged | while_reading_judged "$file" "$draft" "$boot" "$ref" || {
        rm -f "$draft"
        exit 6
    }

    keep_introduced "$file" "$draft" >> "$draft" || { rm -f "$draft"; die_unwritable "$draft"; }

    #
    # The set of requirements may grow. It may never shrink — RFC-001 §2.2, invariant 3.
    #
    # The draft is built from nothing, so a clause the detector has stopped yielding simply fails to
    # reappear. That is a removal, and it used to happen at exit 0 with an empty charter and a silent
    # `check`. Removing a requirement is a human act; it does not happen because a file moved.
    #
    lost=$(dropped_clauses "$file" "$draft")
    [ -z "$lost" ] || {
        rm -f "$draft"
        note "refusing to drop what no longer derives:"
        printf '%s\n' "$lost" >&2
        exit 6
    }

    mv "$draft" "$file" || die_unwritable "$file"
    say_what_derived "$file"
}

#
# Silence read as success. Derive on a repository declaring no gates wrote an empty charter and said
# nothing, so *found nothing* and *worked* looked identical — and the refusal arrived two stages
# later, at `authorise` exit 8, about a file the reader thought was fine.
#
# Not a refusal. An empty charter is a legitimate step: derive finds nothing mechanical, a human
# introduces a clause, and the charter is real. Only the silence was wrong.
#
say_what_derived() {
    held=$(awk '$1 == "clause"' "$1" 2>/dev/null | wc -l | tr -d ' ')

    [ "$held" = 1 ] && { note "the charter holds one clause"; return 0; }
    [ "$held" = 0 ] || { note "the charter holds $held clauses"; return 0; }
    note "nothing here declares a gate, so the charter is empty — \`charter introduce\` puts a bar in it"
}

#
# Clauses the charter holds that the draft does not. Empty when nothing would be lost.
#
# `FILENAME == draft`, never `NR == FNR`. When the draft is empty — which is exactly the case this
# exists to catch — awk goes straight to the second file, where `NR == FNR` is still true for its
# first line. The one clause being dropped was read as if it had been kept, so nothing was reported.
#
dropped_clauses() {
    [ -f "$1" ] || return 0
    awk -v draft="$2" '
         FILENAME == draft { kept[$2] = 1; next }
         $1 == "clause" && !($2 in kept) { $1 = ""; sub(/^ /, ""); print }' "$2" "$1"
}

#
# Turn each detected gate into a clause, a pin and a resolution.
#
# Refuses rather than notes: a gate whose source has no sha at the base ref is a pin that cannot be
# captured, and half a record is worse than none.
#
while_reading_gates() {
    held=$1; draft=$2; target=$3; ref=$4

    while read -r name source command; do
        [ -n "$name" ] || continue

        id=$(clause_id "$name")
        refuse_collision "$held" "$id" "$name" || return 1

        sha=$(blob_sha "$ref" "$source")
        [ -n "$sha" ] || { note "no sha for [$source] at [$ref] — pin refused"; return 1; }

        refuse_moved_from_base "$source" "$sha" "$ref" || return 1

        print_clause "$id" Gate "$name" >> "$draft" || return 1
        print_pin    "$id" "$target" "$ref" "$source" "$sha" >> "$draft" || return 1
        print_gate   "$id" "$command" >> "$draft" || return 1
    done
    return 0
}

#
# A declared judged clause, pinned exactly as a gate is.
#
# The pin is what makes it answerable. An introduced clause rests on none, so invariant 1 reports it
# `introduced` and no verdict ever reaches satisfaction. #332 is that gap, and this closes it.
#
# `judge` records who may answer. Floor does not check that the name is real — §2.5 — but a clause
# blocking with no judge named tells a reader nothing about who to ask.
#
# The reach table is read once and handed down, never asked for per member. It is the same answer
# every time, and a resolver run per judge is a process per judge for it.
while_reading_judged() {
    held=$1; draft=$2; target=$3; ref=$4
    reaches=$(declared_reaches)

    while read -r judge source text; do
        [ -n "$judge" ] || continue
        [ "$judge" = reach ] && continue
        [ -n "$text" ] || { note "a judged clause names who answers it and what it says"; return 1; }

        id=$(clause_id "$text")
        refuse_collision "$held" "$id" "$text" || return 1

        sha=$(blob_sha "$ref" "$source")
        [ -n "$sha" ] || { note "no sha for [$source] at [$ref] — pin refused"; return 1; }

        refuse_moved_from_base "$source" "$sha" "$ref" || return 1

        print_clause "$id" Judged "$text" >> "$draft" || return 1
        print_pin    "$id" "$target" "$ref" "$source" "$sha" >> "$draft" || return 1
        print_judges "$id" "$judge" "$reaches" >> "$draft" || return 1
    done
    return 0
}

# Who may answer this clause, as the repository named them, and how each is reached.
#
# One record per member of the panel.
#
# A panel is several minds, and a clause naming one is not a panel. Each member is written on its own
# line, so a charter says who sits and completion can name whichever has not spoken.
print_judges() {
    printf '%s\n' "$2" | tr ',' '\n' | while IFS= read -r who; do
        [ -n "$who" ] || continue
        print_judge "$1" "$who" "$(reach_of "$3" "$who")"
    done
}

# One member's record. Two shapes, because a blank third field leaves a trailing space and
# `judge_command` would read it as a command of one space — the defect `pinned_command` paid for.
print_judge() {
    [ -n "$3" ] || { printf 'judge %s %s\n' "$1" "$2"; return 0; }

    printf 'judge %s %s %s\n' "$1" "$2" "$3"
}

# Every reach the repository declares now, as `who command...`.
declared_reaches() { detect_judged | awk '$1 == "reach" { $1 = ""; sub(/^ +/, ""); print }'; }

# How one judge is reached, from that table. `""` on both sides: a judge named `01` and one named
# `1` are two judges, and an `-v` assignment compares as a number.
reach_of() {
    printf '%s\n' "$1" | awk -v who="$2" '$1 "" == who "" { $1 = ""; sub(/^ +/, ""); print; exit }'
}

# Every member, one per line, in the order the repository declared them.
named_judges() { awk -v want="$2" '$1 == "judge" && $2 == want { print $3 }' "$1" 2>/dev/null; }

# The command the charter pins for one member of one clause's panel, or nothing.
#
# Three fields blanked, and `+` rather than a count: blanking three of a three-field record — a judge
# nobody said how to reach — leaves two spaces where a four-field one leaves three.
judge_command() {
    awk -v id="$2" -v who="$3" '$1 == "judge" && $2 "" == id "" && $3 "" == who "" {
             $1 = ""; $2 = ""; $3 = ""; sub(/^ +/, ""); print; exit }' "$1" 2>/dev/null
}

#
# Clauses nothing derived survive a re-derivation, unless this run has just derived them.
#
# Without the second file, `introduce Gate tests` followed by `derive` re-appended the pin-less
# record next to the pinned one — a duplicate clause that also reads as having provenance it was
# never given.
#
#
# A clause nothing pinned. That is invariant 1's *introduced*, and one predicate answers both
# questions asked of it: which introduced clauses a re-derivation must carry forward, and which ones
# authorisation has to stop for. Two readers of one rule, never two statements of it.
#
introduced_clauses() {
    [ -f "$1" ] || return 0
    awk '$1 == "clause" { held[$2] = $0 }
         $1 == "pin"    { pinned[$2] = 1 }
         END { for (id in held) if (!(id in pinned)) print held[id] }' "$1"
}

# Introduced, and still unanswered. §2.2's authorisation answer says the clause may exist — nothing
# about whether it was met, which is completion's and arrives through the same channel.
unauthorised_clauses() {
    introduced_clauses "$2" | while read -r _ id _ text; do
        authorised_by_a_human "$1" "$text" || printf '%s %s\n' "$id" "$text"
    done
}

#
# **The source is the store.** A resumed run re-reads rather than remembering, so replaying changes
# nothing and no second ledger appears — §2.2 refuses one, and an answer that outlived its run is
# what a stored pending question would let through.
#
# The answer names the clause or it authorises nothing. Silence is not approval and neither is a
# decline; both leave the run exactly where it was.
#
authorised_by_a_human() {
    said=$(source_says receive "$(item_id "$1")" "$(question_id "$1" authorisation "$2")" 2>/dev/null) || return 1

    case "$said" in
        *"$(clause_id "$2")"*) return 0 ;;
    esac

    return 1
}

#
# Every introduced clause, asked about.
#
# One question that did not arrive is the whole stage failing. Reporting *a human owns this* after
# putting the question nowhere sends someone to answer where nothing was written, and the run blocks
# for ever with nothing saying why.
#
ask_about_each() {
    while read -r id text; do
        note "clause $id is introduced, and nothing derives it: $text"
        ask_to_authorise "$1" "$text" || return 1
    done <<CLAUSES
$2
CLAUSES
}

# Put the question where the human already is. Asking twice with the same words is one question, so
# a blocked run that authorises again does not pile them up.
ask_to_authorise() {
    said=$(source_says ask "$(item_id "$1")" "$(question_id "$1" authorisation "$2")" \
        "May this clause exist? Nothing derives it: $2. Answer with $(clause_id "$2") to authorise it." 2>&1)
    asked=$?

    [ "$asked" -eq 0 ] && return 0

    # This one blocks rather than exits, because authorisation
    # names every introduced clause before it stops
    # and a reader needs all of them.
    [ "$asked" -eq 2 ] && {
        note "this work source can only be read, so nothing can carry that question"
        return 1
    }

    note "the work source could not carry that question: $said"
    return 1
}

#
# Introduced, minus whatever this derivation just produced. `FILENAME` names the draft; stdin is `-`.
#
# Captured before the pipe, not piped into it: a pipeline reports its last stage, so a charter that
# cannot be read would exit 0 here and `derive` would replace it with a draft holding no introduced
# clause. The single awk this replaced could not hide that, and the refactor must not either.
#
keep_introduced() {
    [ -f "$1" ] || return 0

    carried=$(introduced_clauses "$1") || return 1
    [ -n "$carried" ] || return 0

    printf '%s\n' "$carried" | awk -v draft="$2" '
         FILENAME == draft { fresh[$2] = 1; next }
         !($2 in fresh)' "$2" -
}

#
# Compare the charter against what its pins say now.
#
# A charter derived once and trusted after is a bar the worker can move in silence. This is the
# moment that catches it — and only accident and unattended drift, because a worker editing the
# charter and its pins together defeats it. That is the workspace boundary's, and it does not exist.
#
check_charter() {
    dir=$1
    file=$(charter_file "$dir")
    [ -f "$file" ] || { note "this run has no charter"; exit 1; }

    # The same guard `derive` carries. Half of what `check` reports comes from running the detector
    # here, so without it the answer depends on which directory you happened to be in.
    refuse_wrong_repository "$dir"
    refuse_missing_resolver
    refuse_unreadable_declaration

    # Captured, not accumulated in a variable: every reader below walks a pipe, and a count raised
    # inside one dies with its subshell. Output survives; a flag would not.
    findings=$(
        forged_ids "$file"
        ambiguous_ids "$file"
        unsound_records "$file"
        underived_gates "$file"
        underived_judged "$file"
        moved_sources "$file"
        moved_resolutions "$file"
        moved_reaches "$file"
    )

    [ -n "$findings" ] || return 0
    printf '%s\n' "$findings"

    # An uncheckable pin is reported, never counted. It says this stage cannot verify another
    # repository from here, which is true of every multi-target charter — failing on it would make
    # `check` useless for the shape it is meant to support.
    printf '%s\n' "$findings" | grep -qv '^uncheckable: ' || return 0
    exit 7
}

#
# One id carrying two meanings.
#
# `cksum` is 32 bits, so this is possible. Every reader here takes the first record for an id, so a
# charter in this state answers questions about the wrong clause — silently. Reported here because
# this is the only place it can be: `refuse_collision` guards the write, but a write can only
# collide when two texts share a checksum, which no test can arrange on purpose.
#
ambiguous_ids() {
    awk '$1 == "clause" {
             t = $0; sub(/^clause [^ ]+ [^ ]+ /, "", t)
             if (($2 in seen) && seen[$2] != t) print "ambiguous: id " $2 " names two meanings"
             seen[$2] = t
         }' "$1" | sort -u
}

#
# A clause whose text is not the text its id was made from.
#
# "A clause is its text" is the premise everything else rests on — `dropped_clauses` keys on the id,
# so rewriting the text under its id changes the requirement while every other check still matches.
# Nothing enforced the premise until here.
#
#
# Every record judged as a record, in one pass. `check`'s other readers walk the detector or the pin
# list, so a record missing its half is invisible to all of them, and four separate tampers each
# reached the gate stage because no reader here was asking.
#
# **A whole `clause`, `pin` and `gate` written together still passes.** Nothing outside the file
# contradicts a triple that agrees with itself, and this reader is inside it. §2.2's boundary, not a
# gap here.
#
# Subscripts, because they compare as text. `awk -v id=123` against a field is a strnum, so
# `$2 == id` matches `0123` — `has_record` called such a gate pinned while a subscript called it
# another gate. Five of those comparisons are still in this file; what changed is that the disagreement
# now refuses, because this reader answers `unpinned` and `unclaused` for the id nobody wrote.
#
unsound_records() {
    awk '
        $1 == "clause" { kind[$2] = $3 }
        $1 == "pin"    { pinned[$2] = 1 }
        $1 == "gate"   { held[$2]++ }
        END {
            for (id in held) {
                if (held[id] > 1)    print "repeated: gate " id
                if (!(id in pinned)) print "unprovenanced: gate " id

                if (!(id in kind)) { print "unclaused: gate " id; continue }
                if (kind[id] != "Gate") print "notagate: " kind[id] " " id
            }
        }' "$1"
}

forged_ids() {
    awk '$1 == "clause" { t = $0; sub(/^clause [^ ]+ [^ ]+ /, "", t); print $2 " " t }' "$1" \
    | while read -r id text; do
        [ "$(clause_id "$text")" = "$id" ] || printf 'forged: id %s was not made from [%s]\n' "$id" "$text"
    done
}

# Whether one record type carries an id at all.
has_record() { awk -v kind="$2" -v id="$3" '$1 == kind && $2 == id { seen = 1 } END { exit !seen }' "$1"; }

#
# A pin on *this* repository, which is the only kind that can be verified from here.
#
# A pin's target is self-asserted. Relabelling that one field made a local pin read foreign, so
# `moved_sources` printed `uncheckable:` and stopped comparing shas, and asking merely whether *some*
# pin carried the id was satisfied by the relabelled one. Neutralising a gate cost a single word.
#
has_local_pin() {
    awk -v id="$2" -v here="$3" '$1 == "pin" && $2 == id && $3 == here { seen = 1 } END { exit !seen }' "$1"
}

#
# Every gate the detector yields, judged against what the charter holds for it.
#
# Driven from the detector rather than from the charter's own records, because each finding used to
# be gated on the record a tamper deletes: no `gate` record meant no unpinned finding, and `deleted`
# asked only whether some clause held the id. Deleting two lines left a `Gate:` resting on nothing
# and `check` called it clean.
#
underived_gates() {
    here=$(this_repository)

    detect_gates | while read -r name _ command; do
        [ -n "$name" ] || continue
        id=$(clause_id "$name")

        [ "$(clause_kind "$1" "$id")" = Gate ] || { printf 'deleted: Gate %s\n' "$name"; continue; }
        has_local_pin "$1" "$id" "$here" || printf 'unpinned: Gate %s\n' "$name"
        has_record "$1" gate "$id"       || printf 'unresolved: Gate %s\n' "$name"
    done
}

# The same three questions about a declared judgement. `judge` is its resolution,
# the way `gate` is a gate's, so a clause with no judge rests on nothing.
#
# A reach line is not a clause and answers none of the three. Read as one it would name a judge
# nobody declared, and `check` would report a Judged clause deleted that never existed.
underived_judged() {
    here=$(this_repository)

    detect_judged | while read -r who _ text; do
        [ "$who" = reach ] && continue
        [ -n "$text" ] || continue
        id=$(clause_id "$text")

        [ "$(clause_kind "$1" "$id")" = Judged ] || { printf 'deleted: Judged %s\n' "$text"; continue; }
        has_local_pin "$1" "$id" "$here" || printf 'unpinned: Judged %s\n' "$text"
        has_record "$1" judge "$id"      || printf 'unresolved: Judged %s\n' "$text"
    done
}


# `$4` is the first word of the clause, so a finding used to name half its own subject.
#
# `+` for the same reason `pinned_command` has it: blanking three fields of a three-field record —
# a clause with no text — leaves two spaces, not three, and a fixed count returns them as the name.
#
# `forged_ids` does not cover it, though it looks as though it should: `clause_id ""` is a value like
# any other, so a clause whose id was made from no text is not forged and `check` passes it.
clause_text() {
    awk -v id="$2" '$1 == "clause" && $2 == id { $1 = ""; $2 = ""; $3 = ""; sub(/^ +/, ""); print; exit }' \
        "$1" 2>/dev/null
}

#
# A pinned artifact whose sha no longer matches. The bar may have moved under the clause.
#
# Only pins on **this** repository. `git rev-parse` answers from whatever checkout it is standing
# in, so verifying `acme/web@release` here either invents a failure, because no such ref is local,
# or invents a pass, because a local branch of that name happens to match. Both certify a repository
# nobody read. The rest are named as uncheckable and left to the workspace seam.
#
moved_sources() {
    here=$(this_repository)

    while read -r record id target ref source sha; do
        [ "$record" = pin ] || continue
        [ "$target" = "$here" ] || { printf 'uncheckable: %s at %s@%s\n' "$source" "$target" "$ref"; continue; }
        # Against the checkout, not against the pinned ref. The pin names a commit now, and a commit
        # cannot move — comparing it with itself would answer "unchanged" while the file a gate
        # actually reads had been rewritten.
        [ "$(worktree_sha "$source")" = "$sha" ] && continue
        printf 'moved: %s at %s@%s\n' "$source" "$target" "$ref"
    done < "$1"
}

# The identity of the repository this command is standing in, or nothing.
this_repository() { repo_identity "$(git remote get-url origin 2>/dev/null)" 2>/dev/null; }

# Both `derive` and `check` run the detector here, so both answer for whatever repository they are
# standing in. Only one repository is the right one.
refuse_wrong_repository() {
    boot=$(bootstrap_identity "$1") || return 0
    here=$(this_repository) || here=''

    [ "$here" = "$boot" ] || {
        note "run this inside [$boot], not [${here:-nowhere}]"
        exit 6
    }
}

#
# A gate name that resolves to a different command than it did at the base.
#
# Separate from a moved source, because they catch different hands. Editing `.foundry/gates` moves a
# sha. Adding a file the detector prefers moves the answer while every pinned sha still matches.
#
moved_resolutions() {
    detect_gates | while read -r name _ command; do
        [ -n "$name" ] || continue
        was=$(pinned_command "$1" "$(clause_id "$name")")
        [ -n "$was" ] || continue
        [ "$was" = "$command" ] || printf 'resolves elsewhere: %s was [%s] now [%s]\n' "$name" "$was" "$command"
    done
}

#
# A judge the charter reaches one way, and the declaration now reaches another.
#
# Driven from the charter's own records rather than from the detector, because three edits are the
# same finding: the reach changed, the reach went, and a reach appeared for a judge derived without
# one. A reader driven by the declaration would see only the first two.
#
# **An empty command on either side is a reading, never a skip.** `moved_resolutions` skips a gate the
# charter pinned no command for, because a gate always has one and an empty pin is its own defect.
# A judge may honestly have none, so *had none, has one now* is drift and says so.
#
moved_reaches() {
    now=$(declared_reaches)

    every_judge_record "$1" | while read -r id who command; do
        [ -n "$who" ] || continue
        was=$(reach_of "$now" "$who")
        [ "$was" = "$command" ] && continue
        printf 'reaches elsewhere: %s was [%s] now [%s]\n' "$who" "$command" "$was"
    done | sort -u
}

# Every judge the charter names, as `id who command...`. One line per member, so a panel of two
# reaching two harnesses is two records and two findings.
every_judge_record() {
    awk '$1 == "judge" { $1 = ""; sub(/^ +/, ""); print }' "$1" 2>/dev/null
}


introduce_clause() {
    dir=$1; kind=$2; text=$3

    is_kind "$kind"     || { note "a clause is Gate, Judged or Decided — not [$kind]"; exit 2; }
    is_one_line "$text" || { note "a clause is one line of text"; exit 2; }

    file=$(charter_file "$dir")
    id=$(clause_id "$text")
    #
    # A human may not change how a requirement is established.
    #
    # Deciding that `tests` is checked differently is new meaning, and new meaning belongs in a
    # human-owned artifact where derivation finds it. Writing it here instead pins the claim to
    # nothing. Only `derive` sets a kind, and only by establishing provenance.
    #
    was=$(clause_kind "$file" "$id")
    [ -z "$was" ] || [ "$was" = "$kind" ] || {
        note "this clause is already $was — only derivation may make it $kind"
        exit 6
    }

    [ -f "$file" ] || : > "$file" || die_unwritable "$file"
    put_clause "$file" "$id" "$kind" "$text"
}

#
# The work source — RFC-001 §2.1. Where a work item comes from, where a delivery is reported, and
# where a human is asked.
#
# **Transport, and nothing else.** It carries an item's words, a delivery's identity, a question and
# an answer. It reads none of them. What an item means is planning's; what an answer means belongs to
# the stage that asked it, and §2.5 keeps those two apart by which store the record lands in.
#
# **Nothing here authorises anything.** An answer arriving widens no allowlist, moves no clause and
# selects no target. Reading one is the authorisation stage's, and that stage does not read one yet —
# `evidence record` shipped the same way, one stage ahead of the gate that consumes it.
#
# The rename guard, because a question's identity is the run's name: a renamed run derives a
# different question and asks a human the same thing twice.
#
work_source() {
    dir=$(active_run) || exit 1
    refuse_renamed_run "$dir"
    refuse_missing_source

    case "${1:-}" in
        read)    shift; read_work_item   "$dir" "$@" ;;
        kind)    shift; work_kind        "$dir" ;;
        publish) shift; publish_delivery "$dir" "$@" ;;
        ask)     shift; ask_about        "$dir" "$@" ;;
        receive) shift; receive_answer   "$dir" "$@" ;;
        *)       usage; exit 2 ;;
    esac
}

#
# The source is an adapter, and an adapter you cannot replace without editing its caller is not one.
# `FOUNDRY_SOURCE` names another; the shipped one is the default, and it is the only file here
# permitted to know a provider exists. Nothing above this line learns which source answered.
#
source_resolver() { printf '%s' "${FOUNDRY_SOURCE:-$SELF_DIR/../lib/source.sh}"; }

# A source that is not there answers "no item", and no item is what an unread run looks like.
#
# Checked here rather than inside `source_says`, whose callers all run in a command substitution —
# where `exit` leaves the subshell and the caller carries on reporting nothing.
refuse_missing_source() {
    [ -f "$(source_resolver)" ] || { note "no work source at [$(source_resolver)]"; exit 3; }
}

# The one place floor speaks to a work source. Its refusals explain themselves on stderr, so nothing
# swallows them here.
source_says() { sh "$(source_resolver)" "$@"; }

#
# **The source could not be asked.** Distinct from every answer it gives, *nothing there* included: a
# run that reads an unreachable source as an empty one states a fact nobody observed, and sends the
# reader to a work item when the remedy is a host.
#
refuse_unasked() {
    [ "$1" -eq 3 ] || return 0

    note "the work source could not be asked for that $2"
    exit 20
}

#
# What the source answered, in floor's terms.
# The caller names what a refusal costs. A delivery the source rejected and
# a run that never existed both left by the same door, and 1 is the
# door marked nothing to answer with. 4 stays floor's own.
refuse_unless_answered() {
    [ "$1" -eq 0 ] && return 0

    # A source with no way to carry this is not a source that failed
    # today. One is a shape a caller picks and the other is a fault
    # it should retry, and a single message made them look alike.
    [ "$1" -eq 2 ] && {
        note "this work source can only be read, so nothing here can carry a $2"
        exit 27
    }

    [ "$1" -eq 4 ] && {
        note "this run already sent the work source another $2"
        note "send the one it sent, or start a new run"
        exit 17
    }

    note "the work source could not carry that $2"
    exit "$3"
}

#
# Pull the item's words into the run.
#
# **There is no parameter for the words.** The caller names an item and the source says what it
# holds — the shape that makes `evidence record` take a command and no result. A worker puts words in
# `item.md` only by putting them where the source can be asked for them.
#
read_work_item() {
    dir=$1; item=${2:-}

    [ "$#" -le 2 ] || { note "read names an item — its words are the source's to say, not yours"; exit 2; }
    [ -n "$item" ]  || { note "read needs an item to read"; exit 2; }
    refuse_another_item "$dir" "$item"

    said=$(source_says read "$item"); code=$?
    refuse_unasked "$code" "item [$item]"
    [ "$code" -eq 0 ] || { note "the work source holds no item [$item]"; exit 1; }

    printf '%s\n' "$said" > "$dir/item.md" 2>/dev/null || die_unwritable "$dir/item.md"
    printf '%s\n' "$item" > "$(source_file "$dir")" 2>/dev/null || die_unwritable "$(source_file "$dir")"
    record_kind "$dir" "$item"
    emit "$dir" item.read item="$item"
    printf '%s\n' "$said"
}

#
# What the source says this work is, in core's own word. GitHub carries a label and a directory
# carries a field; both answer here in the same word, and core never learns either spelling.
#
# **A kind is not authority and not a bar.** Nothing here widens an allowlist, moves a clause or
# selects a target — so a source that cannot say leaves the run with no kind, and nothing waits.
#
record_kind() {
    kind_said=$(source_says kind "$2") || return 0
    [ -n "$kind_said" ] || return 0

    refuse_two_kinds "$2" "$kind_said"
    printf '%s\n' "$kind_said" > "$(kind_file "$1")" 2>/dev/null || die_unwritable "$(kind_file "$1")"
}

# An item is one kind. Two labels answered as two lines and both were kept,
# so `source kind` printed a pair and every reader of it chose in silence.
refuse_two_kinds() {
    [ "$(printf '%s\n' "$2" | grep -c .)" -le 1 ] && return 0

    note "the source says item [$1] is more than one kind:"
    printf '%s\n' "$2" | sed 's/^/floor:   /' >&2
    note "an item is one kind — the inventory is short on purpose"
    exit 31
}

# Beside `source`, which records which item this run reads. This records what that item is.
kind_file() { printf '%s/kind' "$1"; }

# Nothing when the source said nothing. A run with no kind is ordinary — most sources classify
# nothing — so this answers 1 rather than refusing.
work_kind() {
    [ -f "$(kind_file "$1")" ] || return 1
    cat "$(kind_file "$1")"
}

#
# Which item this run reads. One line, beside `bootstrap`, which records the same kind of fact about
# a repository — and **not the same kind of thing**. A work source never becomes a target because an
# item arrived from it, so nothing here touches the allowlist or the selection.
#
source_file() { printf '%s/source' "$1"; }
delivery_file() { printf '%s/delivery' "$1"; }
substitutions_file() { printf '%s/substitutions' "$1"; }

item_id() { [ -f "$(source_file "$1")" ] && read -r held < "$(source_file "$1")" && printf '%s' "$held"; }

#
# A run reads one item. A second, different one is refused: a delivery and a question are both
# addressed to the item, so swapping it mid-run sends this run's work somewhere nobody asked for.
#
refuse_another_item() {
    held=$(item_id "$1")
    [ -z "$held" ] && return 0
    [ "$held" = "$2" ] && return 0

    note "this run reads item [$held], not [$2]"
    note "start a new run — one item has many runs, and a second item is one of them"
    exit 17
}

# A question and a delivery are both addressed to the item, so a run that has read none has nowhere
# to put either.
refuse_unaddressed() {
    [ -n "$(item_id "$1")" ] && return 0

    note "this run has read no item, so there is nowhere to address that"
    exit 1
}

#
# Report this run's delivery, and answer with the identity the source gave it.
#
# **The run answers before the source does.** This reverses what stood here — *floor keeps no copy* —
# and the reason it stood is still true of the wrong noun. A delivery's *state* goes stale, so floor
# never asks for it. Its *identity* cannot: a pull request URL is fixed at birth.
#
# What forced the reversal is that the source cannot always answer. GitHub's body index is eventually
# consistent, so a lookup seconds after a delivery says *nothing* — truthfully — and nothing is what
# the adapter reads as *not delivered yet*. It answers by opening a second one. Only GitHub refusing a
# duplicate head has been stopping that, and a merged delivery is not refused.
#
# A run holding no record still asks. That is a run made before this rule, and a source lookup is the
# right answer for it.
#
# Publishing the branch itself is the delivery seam's, and §9 orders it after this stage.
#
publish_delivery() {
    dir=$1; branch=${2:-}; title=${3:-}

    [ "$#" -le 4 ] || { usage; exit 2; }
    [ -n "$branch" ] && [ -n "$title" ] || { note "publish needs a branch and a title"; exit 2; }
    refuse_unaddressed "$dir"
    refuse_a_second_branch "$dir" "$branch"

    delivered_already "$dir" && return

    send_and_record "$dir" "$branch" "$title" "${4:-}"
}

# `<branch> <url>`, and a branch holds no space — the adapter's shape, so one reader fits both.
recorded_delivery() { cat "$(delivery_file "$1")" 2>/dev/null; }

# One run, one delivery. The source's own refusal, because a record that answers first must never
# answer differently.
refuse_a_second_branch() {
    had=$(recorded_delivery "$1")

    [ -n "$had" ] || return 0
    [ "${had%% *}" = "$2" ] && return 0

    refuse_unless_answered 4 delivery 19
}

delivered_already() {
    had=$(recorded_delivery "$1")
    [ -n "$had" ] || return 1

    printf '%s\n' "${had##* }"
}

# Written after the send, so it can only ever describe a delivery that happened. One that cannot be
# written is said out loud and not fatal — asking the source is the fallback, and it is what every run
# had before this.
# `Closes` is GitHub's keyword and it shuts the issue on merge.
# A run may not say its own item is finished, so the word
# is `Refs` until `policy closes` says otherwise.
closure_word() {
    may_close_item "$1" && { printf 'Closes'; return 0; }

    printf 'Refs'
}

send_and_record() {
    said=$(source_says publish "$(item_id "$1")" "${1##*/}" "$2" "$3" \
        "$(closure_word "$1")" "$(brief_if_kept "$1")")
    refuse_unless_answered "$?" delivery 19

    record_delivery "$1" "$2" "${4:-}" "$said"
    printf '%s\n' "$said"
}

# `<branch> <commit> <url>`, and two fields when nothing was pushed. `source
# publish` tells the source where the work is, so it cannot say what landed.
record_delivery() {
    line=$2
    [ -n "$3" ] && line="$line $3"

    printf '%s %s\n' "$line" "$4" > "$(delivery_file "$1")" \
        || note "delivered [$4], but this run could not record it — a resume will ask the source"
}

# The commit this run pushed. A record written
# before floor kept one has two fields, and
# the middle one is what separates them.
delivered_head() {
    had=$(recorded_delivery "$1")
    rest=${had#* }

    [ "$rest" = "${rest#* }" ] && return 1
    printf '%s\n' "${rest%% *}"
}

#
# Ask a human about one clause, where they already are.
#
# The caller says what to put, because what makes a question worth answering — the decision, the
# evidence, what each option causes — is known by the stage that found it and by nothing here.
#
# **`receive` carries nothing back**, and that asymmetry is the whole of it: a run may put a question
# and may never put its answer.
#
ask_about() {
    dir=$1; stage=${2:-}; clause=${3:-}; text=${4:-}

    [ "$#" -le 4 ] || { usage; exit 2; }
    [ -n "$text" ] || { note "ask needs a stage, a clause and the question to put"; exit 2; }
    refuse_impossible_question "$dir" "$stage" "$clause"

    id=$(question_id "$dir" "$stage" "$clause")

    source_says ask "$(item_id "$dir")" "$id" "$text"
    refuse_unless_answered "$?" question 1

    printf '%s\n' "$id"
}

#
# The answer a human left, and no reading of it.
#
# **There is no parameter for the answer.** A worker puts one here only by putting it where a human's
# answer lives, which is the gap §2.5 names for the evidence ledger and closes no further.
#
# Silence never comes back as an answer: nothing on stdout and a code that says nothing is there. A
# refusal comes back exactly as an approval does, because deciding which one it is belongs to
# whoever asked — a transport that read the words would be answering for the human.
#
receive_answer() {
    dir=$1; stage=${2:-}; clause=${3:-}

    [ "$#" -le 3 ] || { note "receive names a stage and a clause — an answer is not something you pass"; exit 2; }
    refuse_impossible_question "$dir" "$stage" "$clause"

    said=$(source_says receive "$(item_id "$dir")" "$(question_id "$dir" "$stage" "$clause")"); code=$?
    refuse_unasked "$code" answer
    [ "$code" -eq 0 ] || exit 1
    printf '%s\n' "$said"

    [ "$stage" = completion ] && accept_answer "$dir" "$clause" "$said"
    return 0
}

#
# §2.5's `human` evidence, and the only writer of it. The stage already decided the meaning — an
# answer read at completion says the clause was met, where the same answer read at authorisation says
# only that it may exist.
#
# **The answer names the clause or it is not one.** `receive` carries whatever a human wrote, "no"
# included, so an answer that satisfied by merely existing would turn every reply into a yes. Naming
# the id is the difference between deciding and being present.
#
accept_answer() {
    id=$(clause_id "$2")

    case "$3" in
        *"$id"*) ;;
        *) note "the answer does not name [$id], so nothing here says the clause was met"; return 0 ;;
    esac

    enter_work_tree "$1"
    stamp "$1" human "$2" 0 "$(delivered_ref)" "$3"
}

#
# `run + stage + clause`, and nothing else — RFC-001 §2.1.
#
# Derived, never issued. A resumed run recomputes all three from where it is, which stage is asking
# and the clause's text, so it finds the question it already asked rather than asking a second one —
# and nothing stores a pending question, which is the ledger §2.2 refuses.
#
# Each term keeps one wrong answer away from a reader:
#
#     run      unique over all time, so no later run derives an earlier one's question
#     stage    the reader, so the answer permitting a clause never says the clause was met
#     clause   its text, so an edited requirement is a different question
#
question_id() { printf '%s.%s.%s' "${1##*/}" "$2" "$(clause_id "$3")"; }

#
# A question nothing could ever read is refused before it is put anywhere.
#
# Called, never captured: each of these exits, and an `exit` inside a command substitution leaves the
# subshell and lets the caller carry on.
#
refuse_impossible_question() {
    is_stage "$2" || { note "a question is asked at authorisation or at completion, not at [$2]"; exit 2; }

    refuse_unheld_clause "$1" "$3"
    refuse_a_kind_a_person_cannot_answer "$1" "$2" "$3"
    refuse_unaddressed "$1"
}

# `verdict` refuses a clause that is not Judged and names what does answer it. Nothing refused the
# other way, so a person could answer a Judged clause at
# completion and satisfy nothing by it.
#
# Silent is what made it worth a guard. The answer arrives, `accept_answer` stamps it `human`, and
# satisfaction wants `judged` — so the record says a person
# answered while completion still calls it unmet.
#
# Authorisation is every kind's, because whether a clause may exist at all is nobody else's call.
# Only completion asks what met it, and only there does the
# kind decide who may answer.
refuse_a_kind_a_person_cannot_answer() {
    [ "$2" = completion ] || return 0
    [ "$(clause_kind "$(charter_file "$1")" "$(clause_id "$3")")" = Judged ] || return 0

    note "[$3] is a Judged clause, so a person's answer would satisfy nothing about it"
    note "record a verdict instead — \`evidence verdict\` names who judged it and what they said"
    exit 2
}

#
# Authorisation or completion — §2.1's stage is the reader, never the moment. Authorisation is
# re-evaluated at completion, so a clock would stamp both questions alike and collide them.
#
# A third name is a reader nothing has: the question goes out, a human answers it, and the run never
# looks there again.
#
is_stage() {
    case "$1" in
        authorisation | completion) return 0 ;;
    esac
    return 1
}

# A question names a clause this run's charter holds. Both stages ask about the charter's clauses, so
# a question about anything else is the same silence — asked, answered, and never read.
refuse_unheld_clause() {
    [ -n "$(clause_kind "$(charter_file "$1")" "$(clause_id "$2")")" ] && return 0

    note "this run's charter holds no clause [$2], so nothing would ever read an answer about it"
    exit 1
}

main "$@"
