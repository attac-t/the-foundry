#!/bin/sh
#
# Git transport isolation for the suite. Sourced, never run.
#
# **The guarantee is exactly this: git refuses every transport but `file`.** `GIT_ALLOW_PROTOCOL`
# is git's own allowlist, checked in `transport_get` before a remote helper is chosen — so
# `https://`, `ssh://` and `git@host:` are refused with `transport 'x' not allowed` before any name
# is resolved, any helper is spawned, or any credential is asked for.
#
# **It is not a claim that nothing in the suite can reach a network.** A test running `curl`, `ssh`
# or `gh` directly is untouched by this. It governs git transports and says so.
#
# Fixtures address `github.com` because floor's `repo_identity` refuses a local path, so a fixture
# needs a remote-shaped URL to be a legal target at all. `pushInsteadOf` sends those pushes to a
# bare repository on this disk.
#
# **`pushInsteadOf`, never `insteadOf`.** The plain form rewrites what `git remote get-url` reports,
# and floor reads its own identity through that call. A fixture would then introduce itself as a
# local path and `repo_identity` would refuse it. The push form leaves the reported URL alone.
#
# A push to a name nothing pre-created fails against a missing directory, locally, at once. That is
# the right answer: the suite has 88 fixture names, and a bare repository per name would be a list
# to maintain rather than a rule.

# Every URL shape the fixtures use. `git@github.com:` is scp-style and carries no scheme, which is
# why it is listed rather than derived.
isolate_git_transport() {
    mkdir -p "$1/remotes" || return 1

    GIT_ALLOW_PROTOCOL=file

    GIT_CONFIG_COUNT=3
    GIT_CONFIG_KEY_0="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_0='https://github.com/'
    GIT_CONFIG_KEY_1="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_1='git@github.com:'
    GIT_CONFIG_KEY_2="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_2='ssh://git@github.com/'

    export GIT_ALLOW_PROTOCOL GIT_CONFIG_COUNT
    export GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
    export GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1
    export GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2
}
