#!/bin/bash
# What `bin/host.sh` asks Docker for, and what it refuses to ask.
#
# **Through a `docker` this file writes.** The real one is not here on most machines that grade this
# repository, and a gate that needs it goes red on a train. `bin/comments.sh` and floor's codex
# adapter are driven the same way, for the same reason.
#
# So nothing below starts a container. What is graded is the command line — the mounts, the flags,
# and the two exit codes a person meets when their machine is not ready.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "host"

tmp="${TMPDIR:-/tmp}/host-suite-$$"
mkdir -p "$tmp/bin" "$tmp/home"
trap 'rm -rf "$tmp"' EXIT

# Docker on Windows cannot read a `/tmp/...` path, so `host.sh` hands it the rewritten one. A suite
# asserting the path before that rewrite asserts a mount the platform would refuse.
kept=$tmp/home
command -v cygpath >/dev/null 2>&1 && kept=$(cygpath -m "$tmp/home")

#
# It records every argument and answers `info` and `build` the way a working Docker does. `run` is
# recorded and never performed, which is the whole reason this stands in.
#
# `$1` decides whether `info` succeeds, because a machine without Docker is one of the two cases a
# person actually meets.
stub_docker() {
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> "%s/asked"\n' "$tmp"
    printf 'printf "%%s\\n" "$@" >> "%s/argv"\n' "$tmp"
    printf 'case "$1" in\n'
    printf '  info)  exit %s ;;\n' "${1:-0}"
    printf '  build) exit %s ;;\n' "${2:-0}"
    printf 'esac\n'
    printf 'exit 0\n'
  } > "$tmp/bin/docker"
  chmod +x "$tmp/bin/docker"
  : > "$tmp/asked"
  : > "$tmp/argv"
}

asked() { cat "$tmp/asked" 2>/dev/null; }

# `FOUNDRY_HOME` decides where runs go, so the suite names one rather than reading the machine's.
hosted() {
  ( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" sh "$root/bin/host.sh" "$@" >/dev/null 2>&1 )
}

code_of() { hosted "$@"; echo $?; }

# --- the ordinary path ---

stub_docker
hosted true

case $(asked) in
  *"$kept:/home/forge/.foundry"*)     ok "the home is mounted where a run will look" ;;
  *)                                  bad "the home is mounted where a run will look — it was not" ;;
esac

case $(asked) in
  *--volume*) bad "and no flag was passed — one was" ;;
  *)          ok  "and no flag was passed" ;;
esac

case $(asked) in
  *"/src:ro"*) ok "the source is mounted read-only" ;;
  *)           bad "the source is mounted read-only — it was not" ;;
esac

case $(asked) in
  *--rm*) ok "and the container is not the record" ;;
  *)      bad "and the container is not the record — no --rm" ;;
esac

# **The flag that made the first run pleasant made every scripted one impossible.** Docker refuses to
# attach a terminal where there is none, and a suite has none.
case $(asked) in
  *-it*) bad "a terminal is asked for only where there is one — it asked anyway" ;;
  *)     ok  "a terminal is asked for only where there is one" ;;
esac

# --- the volume ---

stub_docker
hosted --volume true

case $(asked) in
  *"foundry-runs:/home/forge/.foundry"*) ok "--volume keeps the runs in a volume" ;;
  *)                                     bad "--volume keeps the runs in a volume — it did not" ;;
esac

case $(asked) in
  *"$kept"*) bad "and the host's home is left alone — it was mounted too" ;;
  *)          ok  "and the host's home is left alone" ;;
esac

#
# **A function shifts its own copy of the arguments and the caller keeps all of them.** So `--volume`
# reached `docker run`, which printed its usage and did nothing.
case $(asked) in
  *"run"*"--volume"*) bad "and the flag never reaches docker — it did" ;;
  *)                  ok  "and the flag never reaches docker" ;;
esac

# --- what it does with no command ---

stub_docker
hosted

case $(asked) in
  *" sh"*) ok "no command means a shell" ;;
  *)       bad "no command means a shell — it asked for something else" ;;
esac

# --- the two refusals a person meets ---

stub_docker 1
is_two=$(code_of true)
[ "$is_two" = 2 ] && ok "a machine with no Docker is refused, and says so" \
                  || bad "a machine with no Docker is refused, and says so — exit was $is_two"

stub_docker 0 1
is_three=$(code_of true)
[ "$is_three" = 3 ] && ok "an image that will not build is refused" \
                    || bad "an image that will not build is refused — exit was $is_three"

# **The refusal comes before the build.** A machine with no Docker must not wait for an image.
stub_docker 1
case $(asked) in
  *build*) bad "and nothing is built on a machine that cannot run it — it built" ;;
  *)       ok  "and nothing is built on a machine that cannot run it" ;;
esac

# --- what the host carries in ---

stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" FOUNDRY_WHO=someone@example.invalid \
    sh "$root/bin/host.sh" true >/dev/null 2>&1 )

case $(asked) in
  *"FOUNDRY_WHO=someone@example.invalid"*) ok "the authority is the host's, carried in" ;;
  *)                                       bad "the authority is the host's, carried in — it was not" ;;
esac

#
# **A commit needs an author and a committer, and a fresh container has neither.** Floor's own suite
# failed twelve times in this image with `Author identity unknown` before anything set them.
#
# Four names, because git wants all four and three would refuse just as loudly as none.
for want in GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL; do
  case $(asked) in
    *"$want"*) ok  "git's $want is carried in" ;;
    *)         bad "git's $want is carried in — it was not" ;;
  esac
done

#
# **A value with a space is one argument or it is none.** These were built into a single string and
# split on every space, so a host whose git name is two words started no container — Docker read the
# second word as the image name, and the suite could not see it because it read a flattened line.
stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" FOUNDRY_WHO="two words" \
    sh "$root/bin/host.sh" true >/dev/null 2>&1 )

grep -qx "FOUNDRY_WHO=two words" "$tmp/argv" \
  && ok  "a value with a space reaches docker whole" \
  || bad "a value with a space reaches docker whole — it was split"

# The image holds binaries and nothing a host supplies. A token passed here would be one baked into
# a command line that `ps` shows to every other user on the machine.
case $(asked) in
  *TOKEN*|*token*) bad "and no token is put on a command line — one was" ;;
  *)               ok  "and no token is put on a command line" ;;
esac

#
# **Two sign-ins, and neither store is mounted.** The forge keeps its token under `~/.config/gh` and
# the harness keeps its own beside it. Only `.foundry` comes across, so both are asked every run.
#
# **This holds that choice rather than the convenience.** Mounting a token store hands every process
# in the container a credential, which is what `bin/secrets.sh` refuses in a build recipe. #682 owns
# whether the same refusal belongs here.
case $(asked) in
  *".config"*|*".gitconfig"*|*".claude"*) bad "no credential store is mounted — one was" ;;
  *)                                      ok  "no credential store is mounted" ;;
esac

# Named where a person meets the command, because a sign-in asked twice is one nobody expected.
grep -q 'gh auth login' "$root/bin/host.sh" \
  && ok  "and the header names the sign-in a person must give" \
  || bad "and the header names the sign-in a person must give — it does not"

#
# --- the other lane, which must stay the other lane ---
#
# **One image, two lanes, and the difference is the whole point.** The grading lane keeps nothing on
# purpose; this one keeps everything on the host. A change that made them agree would look like a
# tidy-up and would lose a person's work.
#
# Read from the file rather than run, because running the grading lane takes forty minutes and
# proves the same three strings.

grep -q 'FOUNDRY_EPHEMERAL=1' "$root/bin/gates.sh" \
  && ok  "the grading lane still tells its run to keep nothing" \
  || bad "the grading lane still tells its run to keep nothing — it does not"

grep -q 'docker run --rm' "$root/bin/gates.sh" \
  && ok  "and still removes the container it graded in" \
  || bad "and still removes the container it graded in — it does not"

#
# **The sharp one.** A run made through `host.sh` must never be told to keep nothing, or the mount
# would hold a directory the run then refuses to write.
#
# **Code, not prose.** The first draft of this read the whole file and went red on the header, which
# explains the difference between the two lanes. A check that reads what a file says about itself is
# a check that grades the comment.
grep -v '^[[:space:]]*#' "$root/bin/host.sh" | grep -q 'FOUNDRY_EPHEMERAL' \
  && bad "and this lane never says it — it does" \
  || ok  "and this lane never says it"

printf '\nhost — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
