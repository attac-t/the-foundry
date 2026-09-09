#!/bin/bash
# What a host must supply before a run, and what `join.sh` says when it does not.
#
# Three of these were silent when wrong before the command existed, and silence is the thing under
# test: a missing piece must name itself here rather than fail somewhere far from its cause.
#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

join="$root/bin/join.sh"
tmp="${TMPDIR:-/tmp}/floor-host-$$"
mkdir -p "$tmp"
# `chmod -R u+rwX` first, because two fixtures make a directory read-only to prove the runner
# refuses one — and `rm -rf` cannot empty a directory it may not write to. A killed run then leaks
# its whole tree, and they pile up until somebody clears them by hand.
trap 'chmod -R u+rwX "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT

# One host, one answer, and this suite decides what the host is. `env -u` rather than an empty
# value: unset and empty read alike to `join.sh`, and only one of them is what a fresh machine
# looks like. Both variables go, or the caller's own authority answers a check about not having one.
#
# Git's identity is not in the environment, so unsetting cannot reach it. A machine that took
# `join.sh`'s own advice and ran `git config --global user.name` answered the check about having no
# author, and floor's suite went red for following floor's instructions. `/dev/null` is an empty
# config file, and the author each check wants is added back per repository.
blind=(HOME="$tmp/home" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null)
joined()  { ( cd "$1" && shift && env -u FOUNDRY_HOME -u FOUNDRY_WHO "${blind[@]}" "$@" sh "$join" 2>&1 ); }
code_of() { ( cd "$1" && shift && env -u FOUNDRY_HOME -u FOUNDRY_WHO "${blind[@]}" "$@" sh "$join" >/dev/null 2>&1; echo $?; ); }

# A repository with nothing a host supplies. Each check below adds one piece back.
bare() {
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || return 1
  git init -q . && git symbolic-ref HEAD refs/heads/main
  cd - >/dev/null || return 1
}

#
# The dependency guard, which had no test and could not have passed one where it sat. It ran second,
# and the guard above it calls `git rev-parse` — so a host with no `git` was told there is no
# repository here, while standing in one. It runs first now, and this drives it.
#
# `PATH` is emptied rather than stripped of two names. A directory of symlinks is a different thing
# on each host this suite runs on; an absent `PATH` is the same everywhere. So `sh` is resolved to a
# full path first, because an emptied `PATH` cannot find the shell either.
shell=$(command -v sh)
blind_of()      { ( cd "$1" && env PATH=/nonexistent FOUNDRY_WHO=a@b "$shell" "$join" >/dev/null 2>&1; echo $?; ); }
without_tools() { ( cd "$1" && env PATH=/nonexistent FOUNDRY_WHO=a@b "$shell" "$join" 2>&1; ); }

mkdir -p "$tmp/nowhere"
is  "with no git and no awk it refuses" "$(blind_of "$tmp/nowhere")" "1"
has "and names both"                    "$(without_tools "$tmp/nowhere")" "missing: git awk"
has "and says what floor declares"      "$(without_tools "$tmp/nowhere")" "sh, git and awk"

is "outside a repository it refuses"  "$(code_of "$tmp/nowhere" FOUNDRY_WHO=a@b)" "3"
has "and says a repository is what it wants" \
    "$(joined "$tmp/nowhere" FOUNDRY_WHO=a@b)" "no repository here"

bare one || broke "could not make a repository to test against"

is "with no git author it refuses"    "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "1"
has "and says git is what refuses, not floor" \
    "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" "refused by git, not by floor"

git -C "$tmp/one" config user.email a@b
git -C "$tmp/one" config user.name a

is "with no authority it refuses"     "$(code_of "$tmp/one")" "1"
has "and names the variable"          "$(joined "$tmp/one")" "FOUNDRY_WHO"

# The authority is the run's, so a host that cannot name one has nothing to grade with. Named
# before a workspace exists, because completion refuses it long after and reads as a bug in
# the work.
has "and says what a run made there would record" "$(joined "$tmp/one")" "record nobody"

#
# The promise in its header, and now a check.
#
# `join.sh` says nothing is written to the repository, and a reader relies on that. `adopt.sh` is the
# one command floor ships that does write to a checkout, and this line is what tells the two apart —
# a promise nothing measured is a promise the next edit can drop in silence.
#
# **The baseline is taken before the first join that succeeds.** A join that wrote a file would leave
# it there for every later call, so a before-and-after taken after one has already run compares two
# states that both hold it, and passes.
#
untouched=$(git -C "$tmp/one" status --porcelain 2>/dev/null)
history=$(git -C "$tmp/one" rev-list --count --all 2>/dev/null)

# **Superseded 8 September, by #573.** With the host's two supplied and the repository declaring
# nothing, this asserted `0` and `joined.` Both belong to the tree's half, which is checked further
# down once it carries something. What is proved here is the host half, and that it writes nothing.
is "with both, the host half is satisfied" "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "4"
has   "and says a run here would stop"     "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" "not joined."

# A refusal naming no way out is worse than the report it replaced, so each absent one is named
# with its file and what stops without it. Only the judges line carries a command; the other two
# are written by hand, and saying which file is the whole remedy there.
has   "and names the gates file"           "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" ".foundry/gates      no gate"
has   "and names the practice file"        "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" ".foundry/practice   no grant"
has   "and names the judged file"          "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" ".foundry/judged     no judge"

is "and it writes nothing to the repository" \
   "$(git -C "$tmp/one" status --porcelain 2>/dev/null)" "$untouched"
is "and it adds no commit" \
   "$(git -C "$tmp/one" rev-list --count --all 2>/dev/null)" "$history"

# --- what it reports, once it joins ---

said=$(joined "$tmp/one" FOUNDRY_WHO=a@b)

has "it says who this host runs as"   "$said" "who     a@b"
has "it says where the home is"       "$said" "home    "
has "an underived home says it was derived" "$said" "derived from HOME"

# The silent one. A remote that is not GitHub can only be answered by a directory, and saying so is
# the whole point — the adapter used to change without a word.
has "it says which source answers"    "$said" "source  a directory"

named=$( cd "$tmp/one" && FOUNDRY_WHO=a@b FOUNDRY_HOME="$tmp/elsewhere" sh "$join" 2>&1 )
has "a named home is reported as given" "$named" "$tmp/elsewhere"
lacks "and is not called derived"        "$named" "derived from HOME"

# One home, and the runner owns it. `join` used to derive its own and said `.foundry-runs` where a
# run lands in `.foundry`, so it named a home no run had ever used. Asking the runner
# is the fix, and comparing the two answers is the only thing that proves it.
#
# Whole field, never a substring. `.foundry` sits inside `.foundry-runs`, so a
# contains-check passes on the exact pair it exists to catch — which
# it did, silently, on the first draft of this very line.
run=$(dirname "$join")/run.sh
mine=$( cd "$tmp/one" && env -u FOUNDRY_HOME "${blind[@]}" FOUNDRY_WHO=a@b sh "$run" home 2>&1 )
theirs=$(printf '%s\n' "$said" | awk '$1 == "home" { print $2 }')
is "the home it reports is the home a run would use" "$theirs" "$mine"

# No home to derive from is not a home called nothing. It used to print `/.foundry-runs`, which is a
# path, and a path reads as somewhere a run went.
#
# Both variables go. Unsetting `HOME` alone leaves whatever the shell running this
# suite happened to export, so the check passed here and failed under a
# grade — which is the ambient environment grading itself.
homeless=$( cd "$tmp/one" && env -u HOME -u FOUNDRY_HOME FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "with no HOME it says there is nowhere"  "$homeless" "home    nowhere"
lacks "and names no path at all"             "$homeless" ".foundry-runs"

# --- what this host loaded ---

# The shape a harness writes: one key per line. A record on a single line is a rendering nobody
# serves, and a fixture that used one graded the reader against a file it will never meet.
installed() {
  mkdir -p "$home/plugins"
  record=$home/plugins/installed_plugins.json

  [ "$1" = none ] && { printf '%s\n' '{' '  "plugins": {}' '}' > "$record"; return; }

  # **Every argument is another install.** The key holds a list, one entry per scope and per
  # project that ever registered it. Fifty-two for one plugin on the machine that found this.
  {
    printf '%s
' '{' '  "plugins": {' '    "floor@x": ['
    for version in "$@"; do
      printf '      {
        "scope": "project",
        "version": "%s"
      },
' "$version"
    done
    printf '%s
' '    ]' '  }' '}'
  } > "$record"
}

# A cache keyed by version is how a skill reaches a session, so a rule can land on `main` and change
# nothing in the session that wrote it. This went unsaid until a person asked, and
# `signal` was two versions behind the tree that had just committed it.
# The repository ships the plugin, so the repository is what says which version. A target that
# vendors none has none to check, and the count says zero rather than nothing at all.
ships=9.9.9
mkdir -p "$tmp/one/plugins/floor/.claude-plugin"
printf '{ "name": "floor", "version": "%s" }\n' "$ships" \
  > "$tmp/one/plugins/floor/.claude-plugin/plugin.json"

home=$tmp/cfg
installed 0.0.1

behind=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "a plugin behind the tree is named"  "$behind" "floor ships $ships"
has "and it says what this host loaded"  "$behind" "and this host loaded 0.0.1"

# **A key holds a list, and reading the first entry hid four of five.** `join.sh` stopped at the
# first `"version"`, so a host running five kernels reported one and looked clean. Measured where
# it was found: kernel 52 installs, signal 48, and floor's two disagreeing on the day one moved.
installed 1.0.0 0.0.1 9.9.9
several=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "every version a host loaded is named" "$several" "this host loaded 0.0.1,1.0.0,9.9.9"

# One of three matching the tree is not silence, because the other two still do not.
installed 1.0.0 "$ships" 0.0.1
mixed=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "a match among several is still reported" "$mixed" "floor ships $ships"

installed "$ships"
matched=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
lacks "one install matching the tree says nothing" "$matched" "floor ships"

# Absent and behind are different remedies. One is an install and the other an update.
installed none
gone=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "a plugin nobody installed says so" "$gone" "floor $ships is NOT installed here"
lacks "and never calls that behind"      "$gone" "and this host loaded"

# Silence is the healthy reading, and the count is how a reader knows it looked.
installed "$ships"
current=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
lacks "a plugin that matches says nothing" "$current" "floor ships"
has "and the count says it was checked"    "$current" "shipped here, checked against"

# --- the repository's half ---

# **Superseded 8 September, by #573.** This asserted `0` for a repository carrying neither file, and
# that is the contract being replaced: a script cannot branch on an answer that never changes. Three
# of the six absences stop a run, so a tree missing one now refuses and does not say `joined.`
is "a repository declaring none of the three is refused" "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "4"
has "and says it carries no grants"   "$said" "grants  none"
has "and says it carries no gates"    "$said" "gates   none"

#
# The third declaration, and the only one a reader could not find. A repository with none is told
# the command that declares one, by its full path — the path being the thing nobody could locate.
#
has "and says it declares no judge"   "$said" "judges  none"
has "and names the command that declares one" "$said" "adopt.sh adopt <judge> <adapter>"
has "and gives it by a full path"     "$said" "/adopt.sh"

mkdir -p "$tmp/one/.foundry"
printf '# a comment\n\ngrade    https://github.com/acme/thing.git\ndeliver  https://github.com/acme/thing.git\n' \
    > "$tmp/one/.foundry/practice"
printf 'tests\tsh bin/check.sh\n' > "$tmp/one/.foundry/gates"

carried=$(joined "$tmp/one" FOUNDRY_WHO=a@b)

# Comments and blank lines are not grants. Counting them would report a repository that authorises
# more than a human wrote.
has "grants are counted"              "$carried" "grants  2"
has "gates are counted"               "$carried" "gates   1"

# A repository that has one is not told how to get one.
printf 'a-person  is this ready
' > "$tmp/one/.foundry/judged"
declared=$(joined "$tmp/one" FOUNDRY_WHO=a@b)
has  "judges are counted"             "$declared" "judges  1"
lacks "and a repository with one is not told how" "$declared" "no judge is declared"

# The other half, and it has to be measured rather than assumed. A refusal that never lifts is a
# refusal nobody can act on, so the tree that declares all three is the one this proves.
is    "a repository declaring all three joins"     "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "0"
has   "and says so"                                "$declared" "joined."
rm -f "$tmp/one/.foundry/judged"

git -C "$tmp/one" remote add origin https://github.com/acme/thing.git
remote=$(joined "$tmp/one" FOUNDRY_WHO=a@b)

if command -v gh >/dev/null 2>&1; then
  has "with gh here, GitHub is named as the source" "$remote" "source  GitHub"
else
  has "with no gh, it says a directory is answering" "$remote" "source  a directory"
  has "and names what would change that"             "$remote" "gh"
fi

# The sentence above comes from the resolver, never from `join.sh`. A copy of
# `remote_is_github` lived here once, which put a provider's name in core.
#
# Comments stripped first. A comment naming an adapter explains a case; a code path
# matching a hostname decides one, and only the second is core knowing a provider.
code=$(grep -v '^[[:space:]]*#' "$here/bin/join.sh" | tr 'A-Z' 'a-z')
lacks "core holds no provider name" "$code" "github"
lacks "nor any other"               "$code" "gitlab"

# A resolver `FOUNDRY_SOURCE` names is asked the same question. Whatever it prints is
# the answer, so a source that never heard of GitHub still reports itself.
printf '#!/bin/sh\n[ "${1:-}" = serves ] && { echo "a filing cabinet"; exit 0; }\nexit 1\n' > "$tmp/cabinet.sh"
theirs=$(joined "$tmp/one" FOUNDRY_WHO=a@b FOUNDRY_SOURCE="$tmp/cabinet.sh")
has "and another resolver answers for itself" "$theirs" "source  a filing cabinet"


# --- the skills the rules name ---

# A rule that names a skill nobody can invoke does nothing, and said nothing. The mention in the rule
# is the declaration, so there is no second list to drift from it.
mkdir -p "$tmp/one/.claude/rules" "$tmp/conf"
printf 'Invoke `kernel:craft-sh` before the first character.\n' > "$tmp/one/.claude/rules/shell.md"
printf 'The questions live in `signal:economy`.\n'              >> "$tmp/one/.claude/rules/shell.md"
printf 'See https://example.invalid/thing for more.\n'          >> "$tmp/one/.claude/rules/shell.md"

printf '{ "enabledPlugins": { "kernel@the-foundry": true } }\n' > "$tmp/conf/settings.json"
rules=$(joined "$tmp/one" CLAUDE_CONFIG_DIR="$tmp/conf" FOUNDRY_WHO=a@b)

has "a skill a rule names is listed"      "$rules" "skill   kernel:craft-sh"
has "one from a plugin that is off says so" "$rules" "signal:economy  — NOT enabled"
lacks "and an enabled one says nothing more" "$rules" "kernel:craft-sh  —"

# A URL holds a colon and is not a skill. Counting one would report a need no rule has.
lacks "a link is not a skill"             "$rules" "https:"

# `/output-style kernel:craftsman` is not a skill either, and a host told it is one goes looking for
# a skill that is not there. Same reachability question, different noun.
printf 'Voice: craftsman, always — `/output-style kernel:craftsman`.
' >> "$tmp/one/.claude/rules/shell.md"
styled=$(joined "$tmp/one" CLAUDE_CONFIG_DIR="$tmp/conf" FOUNDRY_WHO=a@b)
has   "an output style is named as one"   "$styled" "style   kernel:craftsman"
lacks "and never as a skill"              "$styled" "skill   kernel:craftsman"

# Enabled, not installed. A plugin switched off is a skill nobody can invoke, and the settings file
# is the only place that distinction lives.
printf '{ "enabledPlugins": { } }\n' > "$tmp/conf/settings.json"
has "an empty list leaves both unreachable" \
    "$(joined "$tmp/one" CLAUDE_CONFIG_DIR="$tmp/conf" FOUNDRY_WHO=a@b)" "kernel:craft-sh  — NOT enabled"

# Unknown is not absence. A settings file this host cannot read says so rather than reporting
# every skill as missing.
cannot=$(joined "$tmp/one" CLAUDE_CONFIG_DIR="$tmp/nowhere-at-all" FOUNDRY_WHO=a@b)
has "a settings file it cannot read says so" "$cannot" "cannot tell"
lacks "and does not call the skill missing"  "$cannot" "NOT enabled"

rm -rf "$tmp/one/.claude"
has "a repository whose rules name nothing says so" \
    "$(joined "$tmp/one" CLAUDE_CONFIG_DIR="$tmp/conf" FOUNDRY_WHO=a@b)" "skills  none named"

extra=$( cd "$tmp/one" && FOUNDRY_WHO=a@b sh "$join" extra >/dev/null 2>&1; echo $? )
is "an argument it does not take is refused" "$extra" "2"

summary "host"
