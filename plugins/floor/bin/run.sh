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
        '')  list_targets "$file" ;;
        add) shift; add_target "$dir" "$file" "${1:-}" "${2:-}" ;;
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

main "$@"
