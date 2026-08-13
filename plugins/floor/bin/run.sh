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
#   1  no run is active — from `path` only
#   2  asked for something this does not do
#   3  nowhere to put a run, or the home cannot be written to
#   4  a repository has no portable identity, so nothing was recorded

set -u

main() {
    action=${1:-}
    [ "$#" -gt 0 ] && shift

    HOME_DIR=$(foundry_home) || die_homeless
    RUNS="$HOME_DIR/runs"

    case "$action" in
        new)       make_run "${1:-}" ;;
        path)      print_active_run ;;
        home)      print_home ;;
        bootstrap) print_bootstrap ;;
        targets)   targets "$@" ;;
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

#
# `<date>-<slug>-<first free slot>`.
#
# Counting from zero, not from `$$`. Every `new` is a fresh process, so pid-seeded ids differed
# without the loop ever running once — and the test that claimed to prove uniqueness passed without
# exercising it. A hash would not help: `md5` is BSD's, `shasum` is not everywhere, and it would
# still need the loop.
#
mint_id() {
    base="$(date +%Y-%m-%d)-$(slug "$1")"
    n=0

    while :; do
        candidate="$base-$(printf '%04x' "$n")"
        [ -e "$RUNS/$candidate" ] || { printf '%s' "$candidate"; return 0; }
        n=$((n + 1))
    done
}

# `sed`, not `tr -c`: the complement form needs its replacement set padded, and implementations
# disagree about who pads it.
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

# `-d` matches the check kernel makes before it moves memory. Drop it here and floor calls a run
# active that kernel has already fallen back from, while announce stays quiet because the variable
# is set.
active_run() {
    [ -n "${FOUNDRY_RUN:-}" ] && [ -d "$FOUNDRY_RUN" ] && { printf '%s' "$FOUNDRY_RUN"; return 0; }

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
# Credentials are stripped — a token in a remote URL is a secret, and a run directory is not where it
# belongs. `git@host:path` keeps its user, which is an ssh login rather than a credential.
#
# A host with no dot in it is a Windows drive letter, so `C:/repos/thing` cannot pass as scp-style.
# Anything that resolves to a path is refused rather than written down: a path is precisely what a
# target may not hold.
#
repo_identity() {
    url=$1

    case "$url" in
        '' | file://*) return 1 ;;
        *://*) printf '%s' "$url" | sed 's|://[^/@]*@|://|'; return 0 ;;
    esac

    case "$url" in
        *:*)
            host=${url%%:*}
            case "${host##*@}" in
                *.*) printf '%s' "$url"; return 0 ;;
            esac
            ;;
    esac

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
    id=$(repo_identity "$url") || return 1
    printf '%s %s' "$id" "$(base_ref)"
}

# Zero or one per run. Invoking Foundry inside a repository is the human act that makes that
# repository a target. Starting from a work source, a bare CLI call or a remote runner is equally
# valid and records none.
write_bootstrap() {
    line=$(bootstrap_here) || return 0
    printf '%s\n' "$line" > "$1/bootstrap" 2>/dev/null || note "could not write $1/bootstrap"
}

print_bootstrap() {
    dir=$(active_run) || exit 1
    [ -f "$dir/bootstrap" ] || exit 1
    cat "$dir/bootstrap"
}

# Authoritative targets belong to the unit, because a workspace belongs to a unit and targets belong
# to a workspace. One unit ships; the level is already there.
unit_targets() { printf '%s/units/01/targets' "$1"; }

targets() {
    dir=$(active_run) || exit 1
    file=$(unit_targets "$dir")

    case "${1:-}" in
        '')  list_targets "$file" ;;
        add) shift; add_target "$file" "${1:-}" "${2:-}" ;;
        *)   usage; exit 2 ;;
    esac
}

list_targets() {
    [ -f "$1" ] || return 0
    awk '!/^[ \t]*#/ && NF' "$1"
}

add_target() {
    file=$1
    repo=$2
    ref=$3

    [ -n "$repo" ] && [ -n "$ref" ] || { note "targets add needs a repo and a ref"; exit 2; }

    id=$(repo_identity "$repo") || {
        note "no portable identity for [$repo] — a target may not hold a local path"
        exit 4
    }

    printf '%s %s\n' "$id" "$ref" >> "$file" || die_unwritable "$file"
}

main "$@"
