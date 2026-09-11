#!/bin/sh
#
# Turn a machine that has Docker into a Foundry host, in one command.
#
#   sh bin/host.sh              a shell, and the runs kept on this machine
#   sh bin/host.sh --volume     the runs kept in a Docker volume instead
#
# Give it a command and it runs that instead of a shell, which is what a script wants.
#
# **The ordinary path takes no flag.** Runs land in the home `run.sh` already derives — the same
# answer `join.sh` prints — so a person opens them in an editor with no Docker running.
#
# `--volume` is the other choice and stays a flag. It is portable and costs the reading: what a
# volume holds is reachable only through Docker.
#
# **Nothing here is baked into the image.** The identity, the home and the sign-in are the host's,
# and they arrive when the container starts. `bin/gates.Dockerfile` carries only binaries.
#
# **Two sign-ins, and this asks for both every run.**
#
#     the forge     `gh auth login`, or delivery cannot open a request
#     the harness   whatever runs the worker, or nothing works at all
#
# **Neither store is mounted, so neither survives.** `gh` keeps its token under
# `~/.config/gh` and the harness keeps its own beside it; only `.foundry` comes across.
#
# **That is a choice, not an oversight.** Mounting a token store into a container hands every process
# in it a credential, and `bin/secrets.sh` exists because this repository refuses that in a build
# recipe. #682 owns whether it should be refused here too.
#
# **This is not the grading lane.** `bin/gates.sh linux` keeps `--rm` and `FOUNDRY_EPHEMERAL`, so
# the run inside it keeps nothing on purpose. That is right for grading and wrong for working.
#
# Exit codes:
#
#   0   the container ran and said what it said
#   2   Docker is not answering
#   3   the image would not build
#   4   this machine has no home to keep runs in

set -u

#
# **The flag is read here, not in a function.** A function shifts its own copy of the arguments and
# the caller keeps all of them — so `--volume` reached `docker run` and Docker printed its usage.
#
# It is the only flag and it takes no value, so nothing here can leave a `shift` short.
main() {
    [ "${1:-}" = audit ] && { prove_it_can_go_red; return $?; }

    keep=home
    case ${1:-} in --volume) keep=volume; shift ;; esac

    ensure_docker_answers
    ensure_the_image_is_built

    run_in_the_container "$@"
}

#
# **Through a `docker` the suite writes.** The real one is absent on most machines that grade this
# repository, and a gate that needs it goes red on a train — the same reason `bin/comments.sh` is
# gated on its audit rather than a live read.
#
# So nothing here starts a container. What is graded is the command line.
prove_it_can_go_red() {
    command -v bash >/dev/null 2>&1 || {
        say "FAIL — bash is not on this host, so the suite did not run."
        exit 3
    }

    bash "$root/tests/host.sh"
}

docker_is_answering() { docker info >/dev/null 2>&1; }

ensure_docker_answers() {
    docker_is_answering && return 0

    fail "docker is not answering. Start it, then run this again." 2
}

#
# The same image the gates lane builds, from the same file. **One Dockerfile**, so a host and a
# grade never disagree about what is installed.
#
# Git Bash says `/c/Users/…`, which Docker on Windows cannot read, and rewrites `/src` on the way
# in. `cygpath -m` fixes the first and `MSYS_NO_PATHCONV` stops the second. No-ops anywhere else.
ensure_the_image_is_built() {
    command -v cygpath >/dev/null 2>&1 && { root=$(cygpath -m "$root"); export MSYS_NO_PATHCONV=1; }

    docker build -q -t foundry-host -f "$root/bin/gates.Dockerfile" "$root" >/dev/null && return 0

    fail "the image would not build. Run the same build without -q to see why." 3
}

#
# Where the runs go, and the whole of the choice. `run.sh home` answers it — `FOUNDRY_HOME`, else
# `$HOME/.foundry`, else it refuses — so **nothing new decides where a run lives.**
#
# A volume needs no path and no rewrite, which is why it is one word rather than one path.
where_runs_are_kept() {
    [ "$keep" = volume ] && { printf 'foundry-runs'; return 0; }

    home=$(sh "$root/plugins/floor/bin/run.sh" home 2>/dev/null)
    [ -n "$home" ] || fail "this machine has no home for runs. Set FOUNDRY_HOME, or set HOME." 4

    command -v cygpath >/dev/null 2>&1 && home=$(cygpath -m "$home")

    mkdir -p "$home" 2>/dev/null
    printf '%s' "$home"
}

stdin_is_a_terminal() { [ -t 0 ]; }

# **`-t` only where there is a terminal.** Docker refuses to attach one otherwise, and a script
# calling this has no terminal — so the flag that makes the first run pleasant made every later one
# impossible.
how_to_attach() {
    stdin_is_a_terminal && { printf '%s' "-it"; return 0; }

    printf '%s' "-i"
}

#
# `--rm` because the container is not the record. The home is, and it is on this machine.
#
# No command means a shell, which is what a person wants the first time. A command means one thing
# and out, which is what a script wants every time after.
#
# **Three things the host has and the image must not.** `FOUNDRY_WHO` is what a run records as its
# authority. The other two are git's, and without them a commit made in there is refused —
# `Author identity unknown`, which is how floor's own suite failed twelve times in this image before
# anything set them.
#
# **Carried, never overridden** — `identity.md` forbids the override, and a fresh container owns no
# address. Empty is honest: a host with none passes nothing, and git refuses inside as it does out.
#
# **Each one is quoted, and a function cannot hand them over.** They were built into one string and
# split on every space, so a host whose git name is two words started no container at all — Docker
# read the second word as the image name. A shell has one list of arguments, and this is it.
run_in_the_container() {
    kept=$(where_runs_are_kept) || return $?

    [ $# -eq 0 ] && set -- sh

    docker run --rm "$(how_to_attach)" \
        -v "$root:/src:ro" \
        -v "$kept:/home/forge/.foundry" \
        -e "FOUNDRY_WHO=${FOUNDRY_WHO:-$(git config user.email 2>/dev/null)}" \
        -e "GIT_AUTHOR_NAME=$(git config user.name  2>/dev/null)" \
        -e "GIT_AUTHOR_EMAIL=$(git config user.email 2>/dev/null)" \
        -e "GIT_COMMITTER_NAME=$(git config user.name  2>/dev/null)" \
        -e "GIT_COMMITTER_EMAIL=$(git config user.email 2>/dev/null)" \
        foundry-host "$@"
}

say()  { printf '%s\n' "$1"; }
fail() { say "host: $1" >&2; exit "$2"; }

root=$(cd "$(dirname "$0")/.." && pwd)

main "$@"
