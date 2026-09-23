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
# person actually meets. `$2` does the same for `build`, and `$3` for the run that installs Foundry.
stub_docker() {
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> "%s/asked"\n' "$tmp"
    printf 'printf "%%s\\n" "$@" >> "%s/argv"\n' "$tmp"
    printf 'case "$*" in\n  *install.sh*) exit %s ;;\nesac\n' "${3:-0}"
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

# Whether docker was handed `-it` as an argument of its own. `asked` joins every argument into one
# line, so a checkout whose path held `-it` read as a terminal nobody asked for — #995.
asked_for_a_terminal() { grep -qx -- '-it' "$tmp/argv"; }
asked_for_stdin_alone() { grep -qx -- '-i' "$tmp/argv"; }

# `FOUNDRY_HOME` decides where runs go, so the suite names one rather than reading the machine's.
# **Stdin is closed, and that is the point.** `host.sh` decides `-it` from `[ -t 0 ]`, and this
# redirected only stdout and stderr — so every case below answered about the shell that ran the
# suite. `gates.sh` captures a gate's output and leaves stdin alone, so the gate refused on a
# terminal and passed without one, on code nobody had touched.
hosted() {
  ( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" sh "$root/bin/host.sh" "$@" >/dev/null 2>&1 </dev/null )
}

# The same, with a terminal on stdin. `script` is the only portable way to make one, and it is not
# everywhere — so the case that needs it says why it skipped rather than reporting absent as passed.
hosted_on_a_terminal() {
  script -qec "PATH=\"$tmp/bin:\$PATH\" FOUNDRY_HOME=\"$tmp/home\" sh \"$root/bin/host.sh\" $*" /dev/null >/dev/null 2>&1
}

a_terminal_can_be_made() { command -v script >/dev/null 2>&1; }

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
# attach a terminal where there is none, and a scripted run has none.
#
# **Two cases, because one proves nothing.** A single reading with stdin left alone answers about the
# caller's shell: green under a pipe, red on a terminal, and the code the same either way.
if asked_for_a_terminal; then
  bad "with no terminal, none is asked for — it asked anyway"
else
  ok  "with no terminal, none is asked for"
fi

if a_terminal_can_be_made; then
  stub_docker
  hosted_on_a_terminal true

  if asked_for_a_terminal; then
    ok  "with a terminal, one is asked for"
  else
    bad "with a terminal, one is asked for — it did not"
  fi
else
  printf '  skip  with a terminal, one is asked for — script is not on this machine
'
fi

# --- a checkout whose path holds `-it` ---
#
# **#995: the path is an argument too.** A run named `...-when-its-push` graded its own workspace, and
# this said a terminal was asked for. Nothing had asked. So the copy below runs from `my-items`.
#
# Two files make a root `host.sh` can run from: itself, and the one command it asks for the home.
odd="$tmp/my-items"
mkdir -p "$odd/bin" "$odd/plugins/floor/bin"
cp "$root/bin/host.sh" "$odd/bin/host.sh"
printf 'printf "%%s\n" "$FOUNDRY_HOME"
' > "$odd/plugins/floor/bin/run.sh"

stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" sh "$odd/bin/host.sh" true >/dev/null 2>&1 </dev/null )

case $(asked) in
  *"my-items:/src:ro"*) ok  "a checkout under a path holding -it is mounted" ;;
  *)                    bad "a checkout under a path holding -it is mounted — it was not" ;;
esac

if asked_for_a_terminal; then
  bad "and no terminal is asked for there either — it asked"
else
  ok  "and no terminal is asked for there either"
fi

# Absent `-it` could mean nothing was asked at all. The flag it should be is `-i`, alone.
if asked_for_stdin_alone; then
  ok  "and it asks for stdin alone, -i"
else
  bad "and it asks for stdin alone, -i — it did not"
fi

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

# --- the worker ---
#
# **Two images, one base.** The grading lane keeps the light one, because adding both providers to
# it would make every grade carry 1.3 GB it never calls. The worker is built `FROM` the host, so the
# two cannot disagree about what is installed.

stub_docker
hosted --worker true

case $(asked) in
  *'-t foundry:worker'*) ok  "--worker builds the worker image" ;;
  *)                     bad "--worker builds the worker image — it did not" ;;
esac

case $(asked) in
  *'-t foundry:host'*) ok  "and the host is built first, because the worker is built on it" ;;
  *)                   bad "and the host is built first — it was not" ;;
esac

grep -qx foundry:worker "$tmp/argv" \
  && ok  "and the container runs the worker image" \
  || bad "and the container runs the worker image — it ran something else"

# A worker carries no credential either. The sign-ins are the host's and #682 owns whether that
# changes; a second image must not answer that question by accident.
case $(asked) in
  *'.config'*|*'.claude'*|*TOKEN*) bad "and it mounts no credential store — one was" ;;
  *)                               ok  "and it mounts no credential store" ;;
esac

# --- the sign-ins, when a volume is named ---
#
# **One volume, three exact places.** The owner authorised persistence for this installation and
# asked that only the credential locations be mounted. A subpath per tool is what that means.

stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" FOUNDRY_KEYS=akeyvolume \
    sh "$root/bin/host.sh" true >/dev/null 2>&1 )

for want in .config/gh .claude .codex; do
  case $(asked) in
    *"target=/home/forge/$want"*) ok  "the volume is mounted at $want" ;;
    *)                                    bad "the volume is mounted at $want — it was not" ;;
  esac
done

case $(asked) in
  *'source=akeyvolume'*) ok  "and it is the volume the variable names" ;;
  *)                     bad "and it is the volume the variable names — it was not" ;;
esac

# A whole home would carry more than a sign-in. The grant was for the credential places only.
case $(asked) in
  *"target=/home/forge "*|*"target=/home/forge,"*) bad "and the whole home is not mounted — it was" ;;
  *)                                                 ok  "and the whole home is not mounted" ;;
esac

# **The directories are made before anything signs in.** A fresh volume is root's, and a login that
# cannot write its own token fails in a way nobody reads as permissions.
case $(asked) in
  *'chown -R 1000:1000'*) ok  "and the places are given to forge first" ;;
  *)                      bad "and the places are given to forge first — they were not" ;;
esac

# **A second mechanism, chosen by the value's own shape.** A bare name is a volume; anything with a
# slash is a directory here. Two shapes, one setting, and no word for what a reader can see.

stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" FOUNDRY_KEYS="$tmp/keys" \
    sh "$root/bin/host.sh" true >/dev/null 2>&1 )

case $(asked) in
  *'type=bind'*) ok  "a path is kept as a directory here" ;;
  *)             bad "a path is kept as a directory here — it asked for a volume" ;;
esac

case $(asked) in
  *'volume create'*) bad "and no volume is made for a path — one was" ;;
  *)                 ok  "and no volume is made for a path" ;;
esac

[ -d "$tmp/keys/gh" ] && ok  "and the places are made on this machine" \
                     || bad "and the places are made on this machine — they were not"

# --- and the ordinary path stays light ---

stub_docker
hosted true

case $(asked) in
  *worker*) bad "no flag builds nothing extra — it reached for the worker" ;;
  *)        ok  "no flag builds nothing extra" ;;
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

#
# --- a worker carries Foundry ---
#
# **Every name comes from the checkout the host started in.** So this builds one with names no real
# repository uses, and reads them back off the command line. #736's box 1.
#
a_checkout() {
  rm -rf "$tmp/co" && mkdir -p "$tmp/co/bin" "$tmp/co/.claude-plugin" "$tmp/co/.claude" "$tmp/co/plugins/floor/bin"
  cp "$root/bin/host.sh" "$root/bin/install.sh" "$tmp/co/bin/"
  printf '#!/bin/sh\nprintf "%%s\\n" "$FOUNDRY_HOME"\n' > "$tmp/co/plugins/floor/bin/run.sh"
  printf '{\n  "name": "fixture-market",\n  "plugins": [\n    {\n      "name": "one"\n    }\n  ]\n}\n' \
    > "$tmp/co/.claude-plugin/marketplace.json"
  declared_as github '"repo": "acme/fixture"'
  git -C "$tmp/co" init -q && git -C "$tmp/co" remote add origin https://example.invalid/acme/elsewhere.git
}

# The checkout's settings: its marketplace declared as one kind of source, and four plugins named.
declared_as() {
  printf '{\n  "extraKnownMarketplaces": {\n    "fixture-market": {\n      "source": {\n        "source": "%s",\n        %s\n      }\n    }\n  },\n' "$1" "$2" \
    > "$tmp/co/.claude/settings.json"
  printf '  "enabledPlugins": {\n    "one@fixture-market": true,\n    "off@fixture-market": false,\n    "else@elsewhere": true,\n    "two@fixture-market": true\n  }\n}\n' \
    >> "$tmp/co/.claude/settings.json"
}

# The host, started in that checkout, with a volume or without.
hosted_there() {
  ( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" sh "$tmp/co/bin/host.sh" "$@" >/dev/null 2>&1 </dev/null )
}

handed() { grep -qx -- "$1" "$tmp/argv"; }

a_checkout
stub_docker
FOUNDRY_KEYS=akeyvolume hosted_there --worker true

handed /src/bin/install.sh \
  && ok  "a worker with a volume installs Foundry" \
  || bad "a worker with a volume installs Foundry — nothing was installed"
handed acme/fixture \
  && ok  "from the source the checkout declares for its marketplace" \
  || bad "from the source the checkout declares for its marketplace — it named another"
handed https://example.invalid/acme/elsewhere.git \
  && bad "and never from its origin — it did" \
  || ok  "and never from its origin"
handed fixture-market \
  && ok  "and the marketplace that checkout names" \
  || bad "and the marketplace that checkout names — it named another"
handed one && handed two \
  && ok  "and each plugin its settings enable" \
  || bad "and each plugin its settings enable — one was missing"
handed off || handed else \
  && bad "and none it turns off or takes from elsewhere — one was named" \
  || ok  "and none it turns off or takes from elsewhere"

install_line=$(grep -n 'install.sh' "$tmp/asked" | head -n 1 | cut -d: -f1)
worker_line=$(grep -n 'foundry:worker true$' "$tmp/asked" | tail -n 1 | cut -d: -f1)
[ -n "$install_line" ] && [ -n "$worker_line" ] && [ "$install_line" -lt "$worker_line" ] \
  && ok  "and it installs before the worker starts" \
  || bad "and it installs before the worker starts — the order was otherwise"

stub_docker
FOUNDRY_KEYS=akeyvolume FOUNDRY_PLUGINS=three hosted_there --worker true
handed three && ! handed one \
  && ok  "FOUNDRY_PLUGINS names the plugins instead" \
  || bad "FOUNDRY_PLUGINS names the plugins instead — it did not"

stub_docker
hosted_there --worker true
handed /src/bin/install.sh \
  && bad "without a volume nothing is installed, since nothing would keep it — it installed" \
  || ok  "without a volume nothing is installed, since nothing would keep it"

stub_docker
FOUNDRY_KEYS=akeyvolume hosted_there true
handed /src/bin/install.sh \
  && bad "and the grading image installs nothing — it did" \
  || ok  "and the grading image installs nothing"

# **A machine with no home for runs is refused at 4, before any install.** Found by a judge: the
# install read the home first, and its own failure turned that 4 into a 6.
stub_docker
( PATH="$tmp/bin:$PATH" FOUNDRY_HOME= FOUNDRY_KEYS=akeyvolume sh "$tmp/co/bin/host.sh" --worker true \
    >/dev/null 2>&1 </dev/null )
is_four=$?
[ "$is_four" = 4 ] && ! handed /src/bin/install.sh \
  && ok  "a machine with no home for runs is refused at 4, before any install" \
  || bad "a machine with no home for runs is refused at 4, before any install — exit $is_four"

# **A failed install starts nothing.** A worker without Foundry is the gap this closes, so starting
# one anyway would hide it.
stub_docker 0 0 1
FOUNDRY_KEYS=akeyvolume hosted_there --worker true
is_six=$?
[ "$is_six" = 6 ] && ! grep -q 'foundry:worker true$' "$tmp/asked" \
  && ok  "a failed install stops the host at 6, and no worker starts" \
  || bad "a failed install stops the host at 6, and no worker starts — exit $is_six"

# A git URL is a source a container can clone too.
declared_as git '"url": "https://example.invalid/acme/fixture.git"'
stub_docker
FOUNDRY_KEYS=akeyvolume hosted_there --worker true
handed https://example.invalid/acme/fixture.git \
  && ok  "a marketplace declared by URL is installed from that URL" \
  || bad "a marketplace declared by URL is installed from that URL — it was not"

#
# **A source no container can reach installs nothing, and says 6.** A `path` is the host's own disk.
# The origin is not a fallback: added from its URL, the harness recorded `git` where the checkout
# said `github`, and `plugins.sh declared` then called a sound host faulty. Found by driving it.
declared_as directory '"path": "/somewhere/on/this/host"'
stub_docker
FOUNDRY_KEYS=akeyvolume hosted_there --worker true
is_six=$?
[ "$is_six" = 6 ] && ! handed /src/bin/install.sh \
  && ok  "a checkout declaring a source no container can reach installs nothing, and says 6" \
  || bad "a checkout declaring a source no container can reach installs nothing, and says 6 — exit $is_six"

said=$( PATH="$tmp/bin:$PATH" FOUNDRY_HOME="$tmp/home" FOUNDRY_KEYS=akeyvolume sh "$tmp/co/bin/host.sh" \
          --worker true 2>&1 </dev/null )
printf '%s' "$said" | grep -q 'declares no source' \
  && ok  "and says why, rather than exiting in silence" \
  || bad "and says why, rather than exiting in silence — it said nothing a person could act on"

#
# **No name is written in the code.** Both scripts read every name from the checkout, so neither may
# hold this repository's marketplace or its `owner/repo`. A planted line proves each half can see one.
#
# **Read through `cat`, never as grep's own files.** Given two, grep writes each file's path before
# every line it passes on, and a checkout named for the marketplace holds its name. #299's judge.
names_in_code() {
  cat "$@" | grep -v '^[[:space:]]*#' | grep -F -e "${market:-no-market-read}" -e "${repo:-no-repo-read}"
}

market=$(grep -m 1 '^  "name"' "$root/.claude-plugin/marketplace.json" | cut -d'"' -f4)
repo=$(git -C "$root" remote get-url origin 2>/dev/null | sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#')

[ -z "$(names_in_code "$root/bin/host.sh" "$root/bin/install.sh")" ] \
  && ok  "no script names this repository's marketplace or path" \
  || bad "no script names this repository's marketplace or path — one does"

mkdir -p "$tmp/named/${market:-market}/bin" && cp "$root/bin/host.sh" "$root/bin/install.sh" "$tmp/named/${market:-market}/bin/"
[ -z "$(names_in_code "$tmp/named/${market:-market}/bin/host.sh" "$tmp/named/${market:-market}/bin/install.sh")" ] \
  && ok  "and a checkout in a directory named for the marketplace names nothing either" \
  || bad "and a checkout in a directory named for the marketplace names nothing either — the path was read"

{ cat "$root/bin/host.sh"; printf 'market=%s\n' "$market"; } > "$tmp/planted-host.sh"
[ -n "$(names_in_code "$tmp/planted-host.sh")" ] \
  && ok  "and a planted marketplace is found" \
  || bad "and a planted marketplace is found — the check cannot see one"

# The path alone. It holds the marketplace's name too, so that half is emptied for the plant.
{ cat "$root/bin/install.sh"; printf 'from=%s\n' "$repo"; } > "$tmp/planted-install.sh"
if [ -z "$repo" ]; then
  printf '  skip  a planted path — this checkout has no origin to plant\n'
elif [ -n "$(market= names_in_code "$tmp/planted-install.sh")" ]; then
  ok  "and a planted path is found, on its own"
else
  bad "and a planted path is found, on its own — the check cannot see one"
fi

#
# --- the install, inside a worker ---
#
# **Against a harness this file writes.** It answers both lists from files, and adding or installing
# appends to them, so a second start finds what the first one left.
#
stub_harness() {
  mkdir -p "$tmp/harness"
  : > "$tmp/harness-asked"; : > "$tmp/markets"; : > "$tmp/installed"
  cat > "$tmp/harness/claude" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$tmp/harness-asked"
case "\$*" in
  "plugin marketplace list --json") cat "$tmp/markets" ;;
  "plugin list --json")             cat "$tmp/installed" ;;
  "plugin marketplace add "*)       [ "${1:-ok}" = ok ] || exit 1; printf '"name": "%s"\n' "${2:-fixture-market}" >> "$tmp/markets" ;;
  "plugin install ${3:-no-such-plugin}@"*) exit 1 ;;
  "plugin install "*)               printf '"%s"\n' "\$3" >> "$tmp/installed" ;;
esac
EOF
  chmod +x "$tmp/harness/claude"
}

installed() {
  ( PATH="$tmp/harness:$PATH" sh "$root/bin/install.sh" https://example.invalid/acme/fixture.git fixture-market one two \
      >/dev/null 2>&1 )
}

harness_asked() { grep -qx -- "$1" "$tmp/harness-asked"; }

stub_harness
installed
harness_asked 'plugin marketplace add https://example.invalid/acme/fixture.git' \
  && ok  "the first start adds the marketplace from the source it was handed" \
  || bad "the first start adds the marketplace from the source it was handed — it did not"
harness_asked 'plugin install one@fixture-market' && harness_asked 'plugin install two@fixture-market' \
  && ok  "and installs each plugin from it" \
  || bad "and installs each plugin from it — one was not"
[ "$(grep -cx 'plugin list --json' "$tmp/harness-asked")" = 1 ] \
  && ok  "and asks what is installed once, however many plugins" \
  || bad "and asks what is installed once, however many plugins — it asked again"

: > "$tmp/harness-asked"
installed
grep -qE 'marketplace add|plugin install' "$tmp/harness-asked" \
  && bad "a second start adds and installs nothing — it asked again" \
  || ok  "a second start adds and installs nothing"

stub_harness refused
installed
is_one=$?
[ "$is_one" = 1 ] && ! grep -q 'plugin install' "$tmp/harness-asked" \
  && ok  "a marketplace that cannot be added fails the install, before any plugin" \
  || bad "a marketplace that cannot be added fails the install, before any plugin — exit $is_one"

stub_harness ok another-market
installed
is_one=$?
[ "$is_one" = 1 ] \
  && ok  "and so does one that arrives under another name" \
  || bad "and so does one that arrives under another name — exit $is_one"

# A plugin the harness will not install fails the install, and the worker never starts on half.
stub_harness ok fixture-market two
said=$( PATH="$tmp/harness:$PATH" sh "$root/bin/install.sh" https://example.invalid/acme/fixture.git \
          fixture-market one two 2>&1 )
is_one=$?
[ "$is_one" = 1 ] && printf '%s' "$said" | grep -q 'two@fixture-market could not be installed' \
  && ok  "a plugin that cannot be installed fails the install, and says which" \
  || bad "a plugin that cannot be installed fails the install, and says which — exit $is_one"

printf '\nhost — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
