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

set -u

main() {
    action=${1:-}
    [ "$#" -gt 0 ] && shift

    HOME_DIR=$(foundry_home) || die_homeless
    RUNS="$HOME_DIR/runs"

    case "$action" in
        new)  make_run "${1:-}" ;;
        path) print_active_run ;;
        home) print_home ;;
        *)    usage; exit 2 ;;
    esac
}

usage() {
    cat <<'EOF'
floor — where work happens.

  run.sh new <title>   make a run, and point this checkout at it
  run.sh path          print the active run's directory, or exit 1
  run.sh home          print the Foundry home
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

main "$@"
