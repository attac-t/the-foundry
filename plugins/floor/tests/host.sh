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

  # `none` means floor is not installed, and something else from the same marketplace is. A host
  # that took nothing at all has no marketplace in scope and nothing to be behind — which is a
  # different answer, and not the one *absent* was written to test.
  [ "$1" = none ] && {
    printf '%s\n' '{' '  "plugins": {' '    "kernel@x": [' '      {' \
      '        "scope": "user",' '        "version": "1.0.0"' '      }' '    ]' '  }' '}' > "$record"
    return
  }

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
#
# **The marketplace says what a plugin ships, not the working tree.** Reading the tree answered only
# where the tree was Foundry, so a repository that installs it heard nothing — which is the host
# #559 calls the harder case. The harness records where each marketplace lives, and a consumer's
# clone holds the same manifests a maintainer's checkout does.
ships=9.9.9
mkdir -p "$tmp/one/plugins/floor/.claude-plugin"
printf '{ "name": "floor", "version": "%s" }\n' "$ships" \
  > "$tmp/one/plugins/floor/.claude-plugin/plugin.json"

home=$tmp/cfg

# What the harness knows about the marketplace behind key `floor@x`. The manifest names where the
# plugin lives, because a layout guessed instead breaks on the first marketplace that keeps its
# plugins somewhere else — and one on the machine this was written on does.
offered() {
  mkdir -p "$home/plugins" "$1/.claude-plugin"

  printf '%s\n' '{' '  "x": {' "    \"installLocation\": \"$1\"" '  }' '}' \
    > "$home/plugins/known_marketplaces.json"

  printf '%s\n' '{' '  "name": "x",' '  "plugins": [' '    {' \
    '      "name": "floor",' '      "source": "./plugins/floor"' '    }' '  ]' '}' \
    > "$1/.claude-plugin/marketplace.json"
}

offered "$tmp/one"
installed 0.0.1

behind=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "a plugin behind the tree is named"      "$behind" "floor ships $ships"
has "and it says what this host registered" "$behind" "this host has 0.0.1 registered"
lacks "one install per version counts none" "$behind" "in 1 places"

# **A key holds a list, and reading the first entry hid four of five.** `join.sh` stopped at the
# first `"version"`, so a host running five kernels reported one and looked clean. Measured where
# it was found: kernel 52 installs, signal 48, and floor's two disagreeing on the day one moved.
installed 1.0.0 0.0.1 9.9.9
several=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "every version registered is named" "$several" "this host has 0.0.1,1.0.0,9.9.9 registered"

# **Five versions reads as five running copies. Five across fifty-two reads as debris.**
#
# Fifty of kernel's fifty-two rows named worktrees deleted weeks before, and nothing in the sentence
# said so. The count is the whole remedy — the rows cannot be told apart from a shell.
installed 1.0.0 1.0.0 0.0.1 0.0.1 0.0.1
repeated=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "two versions across five installs says so" "$repeated" "0.0.1,1.0.0 registered in 5 places"

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
lacks "and never calls that behind"      "$gone" "and this host has"

# Silence is the healthy reading, and the count is how a reader knows it looked.
installed "$ships"
current=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
lacks "a plugin that matches says nothing" "$current" "floor ships"
has "and the count says it was checked"    "$current" "offered here, checked against"

#
# **The consumer, and it is the case #559 calls the harder one.** A repository that installs Foundry
# has no `plugins/` directory, so reading the working tree found nothing and the count said zero —
# the host with no maintainer beside it, told the least.
#
# The marketplace lives elsewhere here, which is what a github source looks like. Nothing else about
# the fixture changes, and that is the point: one read answers for both.
bare two || broke "could not make a second repository"
git -C "$tmp/two" config user.email a@b
git -C "$tmp/two" config user.name a
mkdir -p "$tmp/two/.foundry"
cp "$tmp/one/.foundry/practice" "$tmp/one/.foundry/gates" "$tmp/two/.foundry/" 2>/dev/null

mkdir -p "$tmp/market/plugins/floor/.claude-plugin"
printf '{ "name": "floor", "version": "%s" }\n' "$ships" \
  > "$tmp/market/plugins/floor/.claude-plugin/plugin.json"
offered "$tmp/market"
installed 0.0.1

vendors_none=$( cd "$tmp/two" && CLAUDE_CONFIG_DIR="$home" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
lacks "the second repository vendors no plugins" "$(ls "$tmp/two")" "plugins"
has "and the drift is still named"    "$vendors_none" "floor ships $ships"
has "and so is what it registered"    "$vendors_none" "this host has 0.0.1 registered"
has "and the count is not zero"       "$vendors_none" "1 offered here"

#
# **Nothing to check is not a clean check.** A host with no record printed `0 offered here`, which
# reads the same as nought wrong — the fault `bin/gates.sh` refuses for every gate here.
#
# Two silences, and they are different absences. One host installed nothing at all; the other took
# something from a marketplace the harness has no home for.
nothing=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$tmp/emptycfg" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has  "a host that installed nothing says so"  "$nothing" "Nothing was installed here through a marketplace"
has  "and names the file that would say"      "$nothing" "installed_plugins.json"
lacks "and never prints a count instead"      "$nothing" "0 offered here"

mkdir -p "$tmp/ghostcfg/plugins"
printf '%s\n' '{' '  "plugins": {' '    "floor@ghost": [' '      { "version": "1.0.0" }' '    ]' '  }' '}' \
  > "$tmp/ghostcfg/plugins/installed_plugins.json"

ghost=$( cd "$tmp/one" && CLAUDE_CONFIG_DIR="$tmp/ghostcfg" FOUNDRY_WHO=a@b sh "$join" 2>&1 )
has "a marketplace with no home is named"     "$ghost" "ghost — this host registered from it"
has "and says what is missing about it"       "$ghost" "nothing says where it lives"

offered "$tmp/one"

# --- what this session could load ---

#
# **The narrow half, and the reason it exists is noise.** `host` reports everywhere this host ever
# registered anything, and on the machine that found this that is two shouting lines about
# worktrees deleted weeks ago. A hook firing at every session start has to be quiet or it is
# ignored inside a week.
#
# A row reaches a session when nobody scoped it to a project, or when the project is the one the
# session stands in. Everything else belongs to another directory and cannot arrive here.
#
lib=$(dirname "$join")/../lib/plugins.sh

# One row per line: `<scope> <path>`. A `user` row carries no path and reaches every session.
reachable() {
  mkdir -p "$home/plugins"
  {
    printf '%s\n' '{' '  "plugins": {' '    "floor@x": ['
    for row in "$@"; do
      rest=${row#* }
      printf '      {\n        "scope": "%s",\n' "${row%% *}"
      [ "${row%% *}" = project ] && printf '        "projectPath": "%s",\n' "${rest%% *}"
      printf '        "version": "%s"\n      },\n' "${row##* }"
    done
    printf '%s\n' '    ]' '  }' '}'
  } > "$home/plugins/installed_plugins.json"
}

reachable "user - $ships" "project $tmp/elsewhere 0.0.1"
theirs=$( CLAUDE_CONFIG_DIR="$home" sh "$lib" session "$tmp/one" 2>&1 )
lacks "a row for another project is not reported" "$theirs" "could load"

reachable "user - $ships" "project $tmp/one 0.0.1"
ours=$( CLAUDE_CONFIG_DIR="$home" sh "$lib" session "$tmp/one" 2>&1 )
has "a row for this repository is"     "$ours" "floor@x ships $ships"
has "and both versions are named"      "$ours" "could load 0.0.1,$ships"

# The key, not the plugin's bare name, because the remedy needs both halves and a hook printed
# `<name>@<marketplace>` for a day rather than hold them.
has "and the line names its own remedy" "$ours" "claude plugin update floor@x -y"

# Windows writes a path with escaped separators and `git` hands back the same place with forward
# slashes. Folded to one shape, they are the same repository — and the fold is why a hook on a
# healthy host says nothing at all.
reachable "user - $ships"
quiet=$( CLAUDE_CONFIG_DIR="$home" sh "$lib" session "$tmp/one" 2>&1 )
is "a session matching what it ships says nothing" "$quiet" ""

#
# **A path written by another machine, and it is the case that made this a comparison.** `[ -d ]`
# cannot answer for one — a Windows path is absent on Linux and a Linux path is absent on Windows,
# so a filesystem test would call every foreign row deleted.
#
# A comparison needs no such answer. Another machine's path is simply not this repository, whichever
# machine reads the record.
reachable "user - $ships" 'project D:\\Elsewhere\\repo 0.0.1'
foreign=$( CLAUDE_CONFIG_DIR="$home" sh "$lib" session "$tmp/one" 2>&1 )
lacks "a path from another machine is not this repository" "$foreign" "could load"

#
# **The fold needs one case where it has to match.** Every assertion above reads an absence, and a
# fold matching nothing produces that same absence — which is how an eight-backslash `gsub` ran
# green for a day here before a comparison caught it.
#
# This row is this repository, written the way Windows writes it.
windows=$(printf '%s' "$tmp/one" | sed 's|/|\\\\|g')
reachable "user - $ships" "project $windows 0.0.1"
folded=$( CLAUDE_CONFIG_DIR="$home" sh "$lib" session "$tmp/one" 2>&1 )
has "an escaped path folds to this repository" "$folded" "could load 0.0.1,$ships"

#
# **The same two absences, asked of the verb the hook runs.** `host` named both from the day it
# shipped and `session` named neither, so an unreadable record and a healthy host gave one output.
#
# An adversary found it, #650 owns it, and the fixtures are `host`'s own.
norecord=$( CLAUDE_CONFIG_DIR="$tmp/emptycfg" sh "$lib" session "$tmp/one" 2>&1 )
has "a session with no record says so"      "$norecord" "Nothing was installed here through a marketplace"
has "and names the file that would say"     "$norecord" "installed_plugins.json"

unplaced=$( CLAUDE_CONFIG_DIR="$tmp/ghostcfg" sh "$lib" session "$tmp/one" 2>&1 )
has "a marketplace with no home is named to a session" "$unplaced" "ghost — this host registered from it"

# A plugin offered and never installed is a third silence and stays one. It is an answer — this
# session could load none of it — where the two above are a read that failed. `theirs` above holds
# it, and `host` says it to the person who asked.

is "and the verb it does not take is refused" \
   "$( CLAUDE_CONFIG_DIR="$home" sh "$lib" nonsense >/dev/null 2>&1; echo $? )" "2"

#
# **The same reader, at the moment the number changes.** A version in `plugin.json` changes nothing
# in the session that wrote it, and `plugins.md` has said so for weeks while it kept happening —
# eight bumps in one day, each leaving the session on the skill it had already loaded.
#
# A rule read at session start is not read again when it applies. This is read then.
pulled=$(dirname "$join")/../hooks/pulled.sh
# The third argument is the host's config, and it defaults to the healthy one every case below uses.
# Two cases need a broken one, and a second helper differing by one value would be two names for one
# question.
asked_pulled() { ( cd "$1" && printf '%s' "$2" | CLAUDE_CONFIG_DIR="${3:-$home}" sh "$pulled" 2>&1 ); }

manifest='{"tool_name":"Edit","tool_input":{"file_path":"plugins/floor/.claude-plugin/plugin.json"}}'
other='{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}'

reachable "user - 0.0.1"
has  "a bump the session has not pulled is named" "$(asked_pulled "$tmp/one" "$manifest")" "ships $ships"
has  "and it names the command"                   "$(asked_pulled "$tmp/one" "$manifest")" "claude plugin update"
has  "and says the restart is separate"           "$(asked_pulled "$tmp/one" "$manifest")" "restart"

reachable "user - $ships"
is    "a session already on it says nothing"      "$(asked_pulled "$tmp/one" "$manifest")" ""
is    "and a file that is not a manifest says nothing" "$(asked_pulled "$tmp/one" "$other")" ""
is    "and outside a repository it says nothing"  "$(asked_pulled "$tmp/nowhere" "$manifest")" ""

#
# **The path the tool wrote, never the whole call.** A `Write` carries the file's content, so a
# rules page naming `plugin.json` in its prose fired this hook and reported drift nobody caused.
#
# The fixture is that page, near enough: a `.md` whose content holds the word.
prose='{"tool_name":"Write","tool_input":{"file_path":"rules/plugins.md","content":"a version in plugin.json changes nothing"}}'

reachable "user - 0.0.1"
is  "a page that merely names a manifest says nothing" "$(asked_pulled "$tmp/one" "$prose")" ""

# A remedy the reader has to fill in is one they get wrong or skip, and both halves were on the line
# above it. `plugins.sh` names the command because `plugins.sh` holds the key.
lacks "and a real bump leaves no placeholder"  "$(asked_pulled "$tmp/one" "$manifest")" "<name>"
lacks "nor the other half"                    "$(asked_pulled "$tmp/one" "$manifest")" "<marketplace>"
has   "it prints the command it means"        "$(asked_pulled "$tmp/one" "$manifest")" "claude plugin update floor@x -y"

#
# **Absent and behind are different remedies**, and for one day this hook gave the update to both.
# Making `session` speak on a broken read made its output non-empty, and this read only that.
#
# So a host that had installed nothing was told to pull. An adversary found it in round 2.
is "a bump on a host with no record says nothing" \
   "$(asked_pulled "$tmp/one" "$manifest" "$tmp/emptycfg")" ""
is "and one whose marketplace has no home says nothing" \
   "$(asked_pulled "$tmp/one" "$manifest" "$tmp/ghostcfg")" ""

# The exit code is the whole contract, because both absences speak and drift speaks. A caller
# reading only whether anything was said cannot tell them apart, and one shipped hook did exactly
# that.
session_at() { CLAUDE_CONFIG_DIR="$1" sh "$lib" session "$tmp/one" >/dev/null 2>&1; echo $?; }

reachable "user - 0.0.1"
is "drift exits 1"                        "$(session_at "$home")"          "1"
reachable "user - $ships"
is "and a healthy session exits 0"        "$(session_at "$home")"          "0"
is "a read that found no record exits 0"  "$(session_at "$tmp/emptycfg")"  "0"
is "and one with no marketplace home too" "$(session_at "$tmp/ghostcfg")"  "0"

#
# **The other hook, and nothing ran it until now.** `session` gained an exit code and `drift.sh`
# passed it straight through, so the SessionStart hook failed exactly when it had drift to report.
#
# A hook exiting non-zero is a non-blocking error and what it printed may never arrive. Three rounds
# of one shape: a caller of this library that no check executes.
drift=$(dirname "$join")/../hooks/drift.sh
drifted()    { ( cd "$tmp/one" && CLAUDE_CONFIG_DIR="${1:-$home}" sh "$drift" 2>&1 ); }
drift_code() { ( cd "$tmp/one" && CLAUDE_CONFIG_DIR="${1:-$home}" sh "$drift" >/dev/null 2>&1; echo $?; ); }

reachable "user - 0.0.1"
has "the session hook names the drift"        "$(drifted)"     "ships $ships"
is  "and exits 0 while it does"               "$(drift_code)"  "0"

reachable "user - $ships"
is  "a healthy session hears nothing"         "$(drifted)"     ""
is  "and that exits 0 too"                    "$(drift_code)"  "0"

# Unlike the bump hook, this one is read by a person at session start, so an absence is worth saying.
has "a host with no record is told"           "$(drifted "$tmp/emptycfg")" "Nothing was installed here"
is  "and exits 0"                             "$(drift_code "$tmp/emptycfg")" "0"
has "so is one whose marketplace has no home" "$(drifted "$tmp/ghostcfg")" "nothing says where it lives"
is  "and exits 0"                             "$(drift_code "$tmp/ghostcfg")" "0"

is  "outside a repository it says nothing"    "$( cd "$tmp/nowhere" && sh "$drift" 2>&1 )" ""

installed 0.0.1

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
#
# **Kept beside `bin/providers.sh`, deliberately.** That gate reads every file in core and belongs
# to this repository. This reads one file and ships with the plugin, so a consumer running floor's
# own suite still has the check the day `remote_is_github` was copied here.
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
