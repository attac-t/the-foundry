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
trap 'rm -rf "$tmp"' EXIT

# One host, one answer, and this suite decides what the host is. `env -u` rather than an empty
# value: unset and empty read alike to `join.sh`, and only one of them is what a fresh machine
# looks like. Both variables go, or the caller's own authority answers a check about not having one.
joined()  { ( cd "$1" && shift && env -u FOUNDRY_HOME -u FOUNDRY_WHO "$@" sh "$join" 2>&1 ); }
code_of() { ( cd "$1" && shift && env -u FOUNDRY_HOME -u FOUNDRY_WHO "$@" sh "$join" >/dev/null 2>&1; echo $?; ); }

# A repository with nothing a host supplies. Each check below adds one piece back.
bare() {
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || return 1
  git init -q . && git symbolic-ref HEAD refs/heads/main
  cd - >/dev/null || return 1
}

mkdir -p "$tmp/nowhere"
is "outside a repository it refuses"  "$(code_of "$tmp/nowhere" FOUNDRY_WHO=a@b)" "3"
has "and says a repository is what it wants" \
    "$(joined "$tmp/nowhere" FOUNDRY_WHO=a@b)" "no repository here"

bare one || bad "could not make a repository to test against"

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

is "with both, it joins"              "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "0"
has "and says so once"                "$(joined "$tmp/one" FOUNDRY_WHO=a@b)" "joined."

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

# --- the repository's half ---

is "a repository carrying neither file joins anyway" "$(code_of "$tmp/one" FOUNDRY_WHO=a@b)" "0"
has "and says it carries no grants"   "$said" "grants  none"
has "and says it carries no gates"    "$said" "gates   none"

mkdir -p "$tmp/one/.foundry"
printf '# a comment\n\ngrade    https://github.com/acme/thing.git\ndeliver  https://github.com/acme/thing.git\n' \
    > "$tmp/one/.foundry/practice"
printf 'tests\tsh bin/check.sh\n' > "$tmp/one/.foundry/gates"

carried=$(joined "$tmp/one" FOUNDRY_WHO=a@b)

# Comments and blank lines are not grants. Counting them would report a repository that authorises
# more than a human wrote.
has "grants are counted"              "$carried" "grants  2"
has "gates are counted"               "$carried" "gates   1"

git -C "$tmp/one" remote add origin https://github.com/acme/thing.git
remote=$(joined "$tmp/one" FOUNDRY_WHO=a@b)

if command -v gh >/dev/null 2>&1; then
  has "with gh here, GitHub is named as the source" "$remote" "source  GitHub"
else
  has "with no gh, it says a directory is answering" "$remote" "source  a directory"
  has "and names what would change that"             "$remote" "gh"
fi


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
