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
#   1  nothing to answer with — no run is active, no bootstrap target, or no charter yet
#   2  asked for something this does not do
#   3  nowhere to put a run, or the home cannot be written to
#   4  a target was refused: no portable identity, or a ref that is not one
#   5  a target was refused: nobody authorised it for this run
#   6  a clause was refused: it would weaken the charter, its pin could not be captured, or the run
#      would derive from an artifact it changed — including a run that recorded no base
#   7  the charter disagrees with its pins — something drifted or went missing
#   8  the charter grades nothing mechanically — it holds no clause, or none that pins a gate
#   9  a clause grades no selected target, so it is no bar
#  10  the selection moved after it was authorised — that is a new run, not this one
#  11  a clause is introduced and nothing can ask a human to authorise it
#  12  the detector yields a gate the charter holds no clause for — re-derive
#  13  the run directory was renamed, so the grants a human gave it are not there
#  14  a gate the charter pins did not pass — an answer, not a refusal
#
# Eight through twelve are one stage and five remedies: write a requirement down, select a target it
# governs, or start again. Collapsing them would make the exit code say *authorisation refused* and
# leave the caller to read prose for what to do about it.

set -u

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
        bootstrap) print_bootstrap ;;
        targets)   targets "$@" ;;
        policy)    policy "$@" ;;
        charter)   charter "$@" ;;
        evidence)  evidence "$@" ;;
        gates)     gates "$@" ;;
        authorise) authorise ;;
        *)         usage; exit 2 ;;
    esac
}

usage() {
    cat <<'EOF'
floor — where work happens.

  run.sh new <title>              make a run, and point this checkout at it
  run.sh path                     print the active run's directory, or exit 1
  run.sh home                     print the Foundry home
  run.sh bootstrap                print the run's bootstrap target, or exit 1
  run.sh targets                  list unit 01's targets
  run.sh targets add <repo> <ref> add one
  run.sh policy                   list what this run may change
  run.sh policy authorize <repo>  let this run change one more
  run.sh charter                  print what must be true for this run to be good
  run.sh charter derive           derive clauses from this repository, pinned at its base
  run.sh charter check            report clauses that drifted from their pins, or went missing
  run.sh charter introduce <kind> <text>
                                  add a clause nothing derived — it stays introduced
  run.sh evidence                 print what this run has proved
  run.sh evidence record <name> <command...>
                                  run it, and stamp what happened
  run.sh gates                    run every gate the charter pins, and record each — exit 14 if any
                                  did not pass
  run.sh authorise                refuse a run that describes no work, or whose selection moved
                                  — exit 1, 5, 8, 9, 10, 11 or 12
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

make_run() {
    title=$1
    [ -n "$title" ] || { note "new needs a title"; exit 2; }

    id=$(mint_id "$title") || die_unwritable "$RUNS"
    dir="$RUNS/$id"

    build_layout "$dir"        || die_unwritable "$dir"
    write_id "$dir" "$id"
    write_item "$dir" "$title" || die_unwritable "$dir/item.md"
    write_bootstrap "$dir"
    point_this_checkout_at "$id"

    printf '%s\n' "$dir"
}

# `<date>-<slug>-<first free slot>`.
mint_id() { claim_free_slot "$(date +%Y-%m-%d)-$(slug "$1")"; }

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
    [ "$named" = "$(basename "$1")" ] && return 0

    note "this run is at [$(basename "$1")] and calls itself [$named], so its grants are not here"
    note "move it back, or start a new run — authority a human gave is not renamed with a directory"
    exit 13
}

# A placeholder until the work-source contract lands in #74.
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
    named_run && return 0
    pointed_run
}

# `-d` matches the check kernel makes before it moves memory. Drop it and floor calls a run active
# that kernel has already fallen back from, while announce stays quiet because the variable is set.
named_run() {
    [ -n "${FOUNDRY_RUN:-}" ] && [ -d "$FOUNDRY_RUN" ] || return 1
    printf '%s' "$FOUNDRY_RUN"
}

# The run this checkout was pointed at, when it is still there.
pointed_run() {
    mark=$(pointer) || return 1
    [ -f "$mark" ] || return 1

    id=$(head -1 "$mark" 2>/dev/null)
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

targets() {
    dir=$(active_run) || exit 1
    refuse_renamed_run "$dir"

    file=$(unit_targets_file "$dir")

    case "${1:-}" in
        '')  refuse_unselectable "$dir" "$file" || exit 5
             list_targets "$file" ;;
        add) shift
             refuse_unselectable "$dir" "$file" || exit 5
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
        '')        list_policy "$dir" ;;
        authorize) shift; authorize "$dir" "${1:-}" ;;
        *)         usage; exit 2 ;;
    esac
}

#
# One run, one set of grants — kept beside the runs, never inside one.
#
# Scoped to the run because authorising a repository for today's work must not quietly authorise
# every work item this machine ever runs. Project-wide grants can come later, if asking twice turns
# out to be real friction rather than imagined friction.
#
grants_file() { printf '%s/%s/targets' "$GRANTS" "$(basename "$1")"; }

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

#
# Authorised because someone invoked Foundry there, or because someone said so since.
#
# The bootstrap target is never copied into the grants file. A copy is a second place the truth
# lives, and the two drift the first time a run is edited by hand.
#
is_authorised() {
    [ "$(bootstrap_identity "$1")" = "$2" ] && return 0

    grants=$(grants_file "$1")
    [ -f "$grants" ] || return 1
    grep -Fxq -- "$2" "$grants"
}

list_policy() {
    boot=$(bootstrap_identity "$1") && printf '%s\tbootstrap\n' "$boot"

    grants=$(grants_file "$1")
    [ -f "$grants" ] || return 0
    awk '!/^[ \t]*#/ && NF { print $0 "\tgranted" }' "$grants"
}

authorize() {
    dir=$1
    repo=$2

    [ -n "$repo" ] || { note "policy authorize needs a repo"; exit 2; }

    identity=$(repo_identity "$repo") || {
        note "no portable identity for [$repo] — needs a remote url, no local path, no space, no .."
        exit 4
    }

    is_authorised "$dir" "$identity" && return 0

    grants=$(grants_file "$dir")
    mkdir -p "$(dirname "$grants")" || die_unwritable "$grants"
    printf '%s\n' "$identity" >> "$grants" || die_unwritable "$grants"
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
# Two records, sharing an id:
#
#     clause  <id>  Gate|Judged|Decided  <text>
#     pin     <id>  <target>  <ref>  <source>  <sha>
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

    [ -n "$name" ] || { note "record needs a name and a command"; exit 2; }
    [ "$#" -gt 0 ] || { note "record needs a command to run — a result is not something you pass"; exit 2; }

    # A name is one line, or a newline in it writes a second record whose result the caller chose —
    # which is the one thing this stage exists to make impossible. `why` is flattened; a name is
    # refused, because a gate whose name holds a newline is a mistake, not something to tidy up.
    is_one_line "$name" || { note "a gate's name is one line: [$name]"; exit 2; }

    # Before the command runs. A recorded command that moves HEAD would otherwise stamp a sha whose
    # tree was never tested — evidence for work that did not exist when the work was graded.
    ref=$(delivered_ref) || { note "no commit to record evidence against"; exit 1; }

    stamp_command "$dir" "$ref" "$name" "$@"
}

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

    stamp "$dir" machine "$name" "$result" "$ref" "$why"
    return "$result"
}

# Append-only. One line, tab-separated, in the order §2.5 names.
stamp() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" 01 "$3" "$4" "$5" "$(one_line "$6")" \
        >> "$(evidence_file "$1")" 2>/dev/null || die_unwritable "$(evidence_file "$1")"
}

# A gate that printed nothing on failure still records the ref it applies to, so `why` is last and
# may be empty. `\r` as well as `\n`: Git Bash is a platform this ships on, and `is_one_line` counts
# all three.
one_line() { printf '%s' "$1" | tr '\n\r\t' '   '; }

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

    check_charter "$dir"

    # One ref for the whole run of them. Taken here rather than per gate, so a gate that commits
    # cannot move the tree the gates after it are recorded against.
    ref=$(delivered_ref) || { note "no commit to gate"; exit 1; }

    run_pinned_gates "$dir" "$ref"
}

#
# `pinned_command` answers with the first record for an id and `moved_resolutions` compares only that
# one, so a second `gate` line under the same id is a command nothing validated — and `check` reads
# the charter as clean. One line appended, no pin touched, which is less than the charter's own
# threat model asks of a worker.
#
refuse_repeated_ids() {
    repeated=$(printf '%s\n' "$1" | awk '{ if (++seen[$1] == 2) print $1 }')

    [ -z "$repeated" ] && return 0
    note "the charter pins more than one command under: $repeated"
    return 1
}

#
# Provenance, which is invariant 1: a clause establishing neither derivation nor authorisation is
# *introduced*, and an introduced clause is what authorisation exists to stop.
#
# `check` looks for none of this. Its five readers walk the detector or the pin list, so a clause
# invented for an id nothing pinned is invisible to all of them — `forged_ids` accepts an id honestly
# made from the text beside it, and the rest never see the record at all. Two lines appended run a
# command no artifact declares, and the ledger cannot tell it from one a human agreed to.
#
refuse_unpinned_gates() {
    dir=$1

    unpinned=$(printf '%s\n' "$2" | while read -r id _; do
        [ -n "$id" ] || continue
        has_record "$(charter_file "$dir")" pin "$id" || printf '%s ' "$id"
    done)

    [ -z "$unpinned" ] && return 0
    note "the charter records where these gates came from nowhere: $unpinned"
    return 1
}

# Every gate the charter pins, as `id command...`. `print_gate` wrote them.
pinned_gates() {
    awk '$1 == "gate" { $1 = ""; sub(/^ /, ""); print }' "$(charter_file "$1")" 2>/dev/null
}

run_pinned_gates() {
    dir=$1; ref=$2
    failed=0

    pins=$(pinned_gates "$dir")
    [ -n "$pins" ] || { note "this charter pins no gate, so it grades nothing mechanically"; exit 8; }
    refuse_repeated_ids "$pins" || exit 7
    refuse_unpinned_gates "$dir" "$pins" || exit 7

    # §2.4: a gate runs with its target's checkout as the working directory. One checkout exists
    # today — a gate named `tests` in a two-repo workspace is otherwise ambiguous.
    #
    # Not restored, and nothing may run after this. `gates` ends here and `main` dispatches nothing
    # afterwards; a caller added below this line would inherit a directory it did not choose.
    cd "$(repo_root)" || { note "no checkout to run gates in"; exit 1; }

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
    return 14
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
    introduced=$(introduced_clauses "$charter_path")
    [ -z "$introduced" ] || {
        printf '%s\n' "$introduced" | while read -r _ id kind text; do
            note "clause $id is introduced: $kind $text"
        done
        note "nothing derives it, so a human must authorise it — and this run has no channel to ask through"
        note "the channel arrives with the work source; until then only a derived clause can authorise"
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

frozen_selection_file() { printf '%s/units/01/authorised-targets' "$1"; }

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
    mkdir -p "$(dirname "$frozen")" || die_unwritable "$frozen"
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
is_one_line() {
    [ -n "$1" ] || return 1
    [ "$(printf '%s' "$1" | tr -d '\n\r\t' | wc -c)" -eq "$(printf '%s' "$1" | wc -c)" ]
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
gate_resolver() { printf '%s' "${FOUNDRY_GATES:-$(dirname "$0")/../lib/detect-gates.sh}"; }

#
# Always the repository root, never the working directory.
#
# `detect_gates .` let the directory you happened to stand in decide what the charter says. Running
# `charter derive` one level down found no gates, wrote an empty charter, and exited 0 — the silent
# emptying `dropped_clauses` exists to refuse, arriving through the front door instead.
#
detect_gates() { sh "$(gate_resolver)" "$(repo_root)" 2>/dev/null; }

#
# The same question, asked of the base. A temporary worktree, because the resolver reads a directory
# and a base is a commit — read-only, and removed either way. Not the workspace seam.
#
detect_gates_at_base() {
    scratch="${TMPDIR:-/tmp}/floor-base-$$"

    git worktree add --detach --quiet "$scratch" "$1" >/dev/null 2>&1 || return 1
    sh "$(gate_resolver)" "$scratch" 2>/dev/null
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

        print_clause "$id" Gate "$name" >> "$draft"
        print_pin    "$id" "$target" "$ref" "$source" "$sha" >> "$draft"
        print_gate   "$id" "$command" >> "$draft"
    done
    return 0
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

    # Captured, not accumulated in a variable: every reader below walks a pipe, and a count raised
    # inside one dies with its subshell. Output survives; a flag would not.
    findings=$(
        forged_ids "$file"
        ambiguous_ids "$file"
        underived_gates "$file"
        moved_sources "$file"
        moved_resolutions "$file"
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

main "$@"
