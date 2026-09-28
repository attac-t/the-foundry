#!/bin/sh
#
# Git transport isolation for the suite. Sourced, never run.
#
# **The guarantee is exactly this: git refuses every transport but `file` and `fixture`.**
# `GIT_ALLOW_PROTOCOL` is git's own allowlist, checked in `transport_get` before a remote helper is
# chosen — so `https://`, `ssh://` and `git@host:` are refused with `transport 'x' not allowed`
# before any name is resolved, any helper is spawned, or any credential is asked for.
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
#
# **`fixture` is this file's own transport, and it reaches only this disk.** A pass fetches its
# origin before it selects, #1060, and a remote-shaped origin could not be fetched at all. A remote
# whose `vcs` is `fixture` is served from the bare repository its `served-from` names instead.
#
# The URL stays as the fixture set it, so `get-url` still reports its identity, and the helper never
# reads it. A remote naming no `served-from` is refused, and one naming no `vcs` as it always was.

# Every URL shape the fixtures use. `git@github.com:` is scp-style and carries no scheme, which is
# why it is listed rather than derived.
isolate_git_transport() {
    mkdir -p "$1/remotes" || return 1
    serve_fixture_remotes "$1" || return 1

    GIT_ALLOW_PROTOCOL=file:fixture

    GIT_CONFIG_COUNT=3
    GIT_CONFIG_KEY_0="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_0='https://github.com/'
    GIT_CONFIG_KEY_1="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_1='git@github.com:'
    GIT_CONFIG_KEY_2="url.$1/remotes/.pushInsteadOf"; GIT_CONFIG_VALUE_2='ssh://git@github.com/'

    export GIT_ALLOW_PROTOCOL GIT_CONFIG_COUNT PATH
    export GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
    export GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1
    export GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2
}

#
# The helper git runs for a remote whose `vcs` is `fixture`. It answers `connect` and nothing else, to
# the bare repository the remote's `served-from` names, and it is written here so a copy carries it.
#
# A line in the remote's `on-serve` runs first, as a rival or a failure would arrive mid-fetch. It is
# kept off the protocol's pipes, and when it fails the helper refuses the call.
serve_fixture_remotes() {
    mkdir -p "$1/helpers" || return 1
    cat > "$1/helpers/git-remote-fixture" <<'HELPER' || return 1
#!/bin/sh
served=$(git config --get "remote.$1.served-from") || exit 1
hook=$(git config --get "remote.$1.on-serve")
[ -z "$hook" ] || sh -c "$hook" </dev/null >/dev/null 2>&1 || exit 1

while IFS= read -r asked; do
    case $asked in
        capabilities) printf 'connect\n\n' ;;
        'connect '*)  printf '\n'; exec git "${asked#connect git-}" "$served" ;;
        *)            exit 0 ;;
    esac
done
HELPER
    chmod +x "$1/helpers/git-remote-fixture" || return 1

    PATH="$1/helpers:$PATH"
}
