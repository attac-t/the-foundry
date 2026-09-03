#!/usr/bin/env bash
#
# What `tests/isolate.sh` guarantees, and that removing any part of it is caught.
#
# **No case here contacts a hostname, including the ones about refusal.** A refused transport is
# refused by git before a helper runs, so the proof is that a local sentinel helper never executes.
#
# Usage: bash plugins/floor/tests/transport.sh

set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/floor-transport-$$"
mkdir -p "$tmp" || exit 3
# `chmod -R u+rwX` first, because two fixtures make a directory read-only to prove the runner
# refuses one — and `rm -rf` cannot empty a directory it may not write to. A killed run then leaks
# its whole tree, and they pile up until somebody clears them by hand.
trap 'chmod -R u+rwX "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT

passed=0
failed=0

echo "transport"

is() {
    [ "$2" = "$3" ] && { printf '  ok    %s\n' "$1"; passed=$((passed + 1)); return; }

    printf '  FAIL  %s — [%s] wanted [%s]\n' "$1" "$2" "$3"
    failed=$((failed + 1))
}

has() {
    case "$2" in
        *"$3"*) printf '  ok    %s\n' "$1"; passed=$((passed + 1)); return ;;
    esac

    printf '  FAIL  %s — [%s] missing from [%s]\n' "$1" "$3" "$2"
    failed=$((failed + 1))
}

moot() { printf '  MOOT  %s\n' "$1"; failed=$((failed + 1)); }

# --- a repository, and somewhere for its pushes to land ---

# One commit and a remote per URL shape. The bare repository sits under the same `remotes` directory
# the redirect points at, so a redirected push has somewhere real to arrive.
a_fixture() {
    mkdir -p "$1/remotes/acme"
    git init -q --bare "$1/remotes/acme/tp.git"

    git init -q "$1/w"
    git -C "$1/w" -c user.name=t -c user.email=t@x commit -q --allow-empty -m x

    git -C "$1/w" remote add https  https://github.com/acme/tp.git
    git -C "$1/w" remote add scpssh git@github.com:acme/tp.git
    git -C "$1/w" remote add urlssh ssh://git@github.com/acme/tp.git
    git -C "$1/w" remote add odd    sentinel://acme/tp.git
}

# The helper git would run for `sentinel://`. It writes a file and nothing else, so its absence
# after a push is the proof that git refused the transport before choosing a helper.
a_sentinel_helper() {
    mkdir -p "$1/bin"
    printf '#!/bin/sh\nprintf ran > "%s/ran"\nexit 1\n' "$1" > "$1/bin/git-remote-sentinel"
    chmod +x "$1/bin/git-remote-sentinel"
}

landed() {
    git --git-dir="$1/remotes/acme/tp.git" rev-parse --verify -q "$2" >/dev/null 2>&1 \
        && echo landed || echo "did not land"
}

# --- what the contract says ---

the_contract_holds() {
    home="$tmp/hold"
    mkdir -p "$home"
    a_fixture "$home" >/dev/null 2>&1
    a_sentinel_helper "$home"

    isolate_git_transport "$home"

    for shape in https scpssh urlssh; do
        git -C "$home/w" push -q "$shape" "HEAD:refs/heads/$shape" >/dev/null 2>&1
        is "a $shape push is redirected to the local bare repository" "$(landed "$home" "$shape")" landed
    done

    is "the commit there is the one that was made" \
        "$(git --git-dir="$home/remotes/acme/tp.git" rev-parse https 2>/dev/null)" \
        "$(git -C "$home/w" rev-parse HEAD 2>/dev/null)"

    is "get-url still reports the repository's own identity" \
        "$(git -C "$home/w" remote get-url https 2>/dev/null)" \
        'https://github.com/acme/tp.git'

    said=$(PATH="$home/bin:$PATH" git -C "$home/w" push odd HEAD:refs/heads/odd 2>&1)

    has "an unrecognised transport is refused by git"   "$said" "not allowed"
    is  "and its remote helper never ran"               "$(ran_or_never "$home")" never
}

ran_or_never() { [ -f "$1/ran" ] && echo ran || echo never; }

# --- and that removing any part of it is caught ---

#
# The isolation is one sourced file, so a break edits a copy of it and the same push runs against
# that copy. Nothing here mutates the tree.
#
# **Every variable is unset before the copy is sourced.** The parent exported them, a child inherits
# what it exports, and a mutant that removes a line would otherwise still see the parent's value and
# pass.
without() {
    name=$1; cut=$2; shape=$3; want=$4
    home="$tmp/$name"

    mkdir -p "$home"
    sed "$cut" "$root/tests/isolate.sh" > "$home/isolate.sh" || { moot "$name — the cut did not apply"; return; }
    cmp -s "$home/isolate.sh" "$root/tests/isolate.sh" && { moot "$name — the cut changed nothing"; return; }

    a_fixture "$home" >/dev/null 2>&1
    a_sentinel_helper "$home"

    got=$( unset GIT_ALLOW_PROTOCOL GIT_CONFIG_COUNT
           unset GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
           unset GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1
           unset GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2

           . "$home/isolate.sh"
           isolate_git_transport "$home" >/dev/null 2>&1

           PATH="$home/bin:$PATH" git -C "$home/w" push odd HEAD:refs/heads/odd >/dev/null 2>&1
           [ -f "$home/ran" ] && { echo "the helper ran"; exit 0; }

           git -C "$home/w" push -q "$shape" "HEAD:refs/heads/$shape" >/dev/null 2>&1
           landed "$home" "$shape" )

    is "$name" "$got" "$want"
}

# --- run them ---

. "$root/tests/isolate.sh"

the_contract_holds

# Without the allowlist, git chooses the sentinel helper and it runs. Nothing else is needed to
# show the guarantee is gone.
without "removing the transport allowlist is caught" \
    '/^    GIT_ALLOW_PROTOCOL=file$/d' https "the helper ran"

# Without a redirect, that shape is refused rather than redirected, so nothing arrives.
without "removing the https redirect is caught" \
    's#^    GIT_CONFIG_KEY_0=.*#    GIT_CONFIG_KEY_0=url.nowhere.pushInsteadOf; GIT_CONFIG_VALUE_0=nothing#' \
    https "did not land"

without "removing the scp-style ssh redirect is caught" \
    's#^    GIT_CONFIG_KEY_1=.*#    GIT_CONFIG_KEY_1=url.nowhere.pushInsteadOf; GIT_CONFIG_VALUE_1=nothing#' \
    scpssh "did not land"

without "removing the ssh:// redirect is caught" \
    's#^    GIT_CONFIG_KEY_2=.*#    GIT_CONFIG_KEY_2=url.nowhere.pushInsteadOf; GIT_CONFIG_VALUE_2=nothing#' \
    urlssh "did not land"

echo
printf 'transport — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ] || exit 1
