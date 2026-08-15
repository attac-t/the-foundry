#!/bin/sh
#
# floor — make a run, and find the one you are in. See README.md.
#
# Making a run changes nothing in any repository. Keep it that way.
#
# `set -e` is off: `path` exits 1 when no run is active, which is an answer.
#
# Exit codes:
#   0  answered
#   1  nothing to answer with — no run is active, or the run has no bootstrap target
#   2  asked for something this does not do
#   3  nowhere to put a run, or the home cannot be written to
#   4  a target was refused: no portable identity, or a ref that is not one
#   5  a target was refused: nobody authorised it for this run
#   6  a clause was refused: it would weaken the charter, or its pin could not be captured
#   7  the charter disagrees with its pins — something drifted or went missing
#   8  the charter holds no clause, so it grades nothing
#   9  a clause grades no selected target, so it is no bar
#  10  the selection moved after it was authorised — that is a new run, not this one
#
# Eight, nine and ten are one stage and three remedies: write a requirement down, select a target it
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
  run.sh authorise                refuse a run that describes no work — exit 8
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

    id=$(mint_id "$title")
    dir="$RUNS/$id"

    build_layout "$dir"        || die_unwritable "$dir"
    write_item "$dir" "$title" || die_unwritable "$dir/item.md"
    write_bootstrap "$dir"
    point_this_checkout_at "$id"

    printf '%s\n' "$dir"
}

# `<date>-<slug>-<first free slot>`.
mint_id() { first_free_slot "$(date +%Y-%m-%d)-$(slug "$1")"; }

#
# `<base>-NNNN`, counting up from zero until nothing holds that name.
#
# Counting, not seeding from `$$`. Every `new` is a fresh process, so pid-seeded ids differed without
# the loop ever running once — and the test that claimed to prove uniqueness passed without
# exercising it. A hash would not help: `md5` is BSD's, `shasum` is not everywhere, and it would
# still need the loop.
#
#
# Free means nothing anywhere still speaks for the slot.
#
# Grants outlive the run directory by design, so a slot reclaimed after `rm -rf` would hand the next
# run the deleted run's allowlist — authority no human gave it.
#
slot_is_free() { [ ! -e "$RUNS/$1" ] && [ ! -e "$GRANTS/$1" ]; }

first_free_slot() {
    n=0

    while :; do
        candidate="$1-$(printf '%04x' "$n")"
        slot_is_free "$candidate" && { printf '%s' "$candidate"; return 0; }
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

    printf '%s %s' "$identity" "$ref"
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

#
# Authorisation — the two refusals, and nothing else yet.
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

    charter_path=$(charter_file "$run_dir")
    selection_path=$(unit_targets_file "$run_dir")

    refuse_unselectable "$run_dir" "$selection_path" || exit 5

    # Before the two refusals, not after: emptying the selection makes every clause grade nothing,
    # so the later check would fire first and report the symptom. *It moved* names the cause, and
    # its remedy — a new run — is the only one that applies.
    refuse_moved_selection "$run_dir" "$selection_path" || exit 10

    [ "$(clause_count "$charter_path")" -gt 0 ] || {
        note "the charter holds no clause, so there is nothing to authorise"
        note "declare a gate this run's targets can be checked with, or write the requirement into an artifact derivation reads"
        exit 8
    }

    ungoverned=$(ungoverning_clauses "$run_dir" "$charter_path" "$selection_path")
    [ -z "$ungoverned" ] || {
        for id in $ungoverned; do
            note "clause $id grades no selected target, so it is no bar"
        done
        note "declare the gate that clause names, or select a target it governs"
        exit 9
    }

    freeze_selection "$run_dir" "$selection_path"
}

frozen_selection_file() { printf '%s/units/01/authorised-targets' "$1"; }

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

normalised_selection() { list_targets "$1" | LC_ALL=C sort; }

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
    awk '$1 == "clause"' "$1" | wc -l | tr -d ' '
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
pinned_command() {
    awk -v want="$2" '$1 == "gate" && $2 == want { $1 = ""; $2 = ""; sub(/^  /, ""); print; exit }' \
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
# Plain `git rev-parse main:Makefile` sends its `fatal:` to stderr and then echoes `main:Makefile` to
# stdout. Discarding stderr leaves that string looking exactly like a captured sha, and it gets
# pinned. `--verify --quiet` prints nothing and exits non-zero.
#
blob_sha() { git rev-parse --verify --quiet "$1:$2" 2>/dev/null; }

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

    ref=$(awk 'NR == 1 { print $2; exit }' "$dir/bootstrap")
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
keep_introduced() {
    [ -f "$1" ] || return 0
    awk -v draft="$2" '
         FILENAME == draft { fresh[$2] = 1; next }
         $1 == "clause" { held[$2] = $0 }
         $1 == "pin"    { pinned[$2] = 1 }
         END { for (id in held) if (!(id in pinned) && !(id in fresh)) print held[id] }' "$2" "$1"
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
clause_text() {
    awk -v id="$2" '$1 == "clause" && $2 == id { $1 = ""; $2 = ""; $3 = ""; sub(/^   /, ""); print; exit }' \
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
        [ "$(blob_sha "$ref" "$source")" = "$sha" ] && continue
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
