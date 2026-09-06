#!/bin/bash
# What a repository's judged declaration says once `adopt.sh` has written it.
#
# **The subject is a repository.** `host.sh` reads `join.sh`, whose header promises it writes nothing
# here. `model.sh` reads the runner. This file reads the one command floor ships that changes a
# checkout, so every check below is about a file in somebody's tree.
#
# No fixture names a remote and nothing here pushes, so the transport isolation the other suites need
# has nothing to isolate.
#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u

# Pinned, because a check reads a digest back out of a file and a locale that collates differently
# would sort the adapters this plugin ships into another order.
LC_ALL=C
export LC_ALL

here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

adopt="$root/bin/adopt.sh"
tmp="${TMPDIR:-/tmp}/floor-declared-$$"
mkdir -p "$tmp"
trap 'chmod -R u+rwX "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT

echo "adopt"

# --- the command, read rather than run ---

#
# Nothing here commits and nothing here pushes, and that is a claim about the text.
#
# The behavioural half is below — a fixture whose commit count does not move. This half is what
# catches the line somebody adds later for convenience, on a path no fixture happens to take.
#
# Comments stripped first. The header says a person commits the change, and a raw search would read
# its own explanation as the thing it forbids.
code=$(grep -v '^[[:space:]]*#' "$adopt")

lacks "the command makes no commit"     "$code" "git commit"
lacks "and pushes nothing"              "$code" "git push"
lacks "and stages nothing"              "$code" "git add"

# --- a plugin tree this suite can rewrite under a pin ---

#
# Built from the command under test, never from this file's own plugin.
#
# `wreck_adopt` breaks a copy and points `PLUGIN_ROOT` at it, so a fixture built from the original
# would hand every mutant an unbroken command and every break below would survive.
#
# **The space in the name is deliberate.** A plugin installs under a user's home, and a home holding
# a space is ordinary on Windows. `model.sh` keeps one for the same reason.
#
a_plugin_shipping() {
  mkdir -p "$tmp/a plugin/bin" "$tmp/a plugin/adapters/$1" || return 1
  cp "$adopt" "$tmp/a plugin/bin/adopt.sh" || return 1

  printf '%s' "$2" > "$tmp/a plugin/adapters/$1/run.sh"
}

# What a shipped adapter is pinned to: the content, as git names it. Taken here the way `bin/judged.sh`
# takes it, so a suite agreeing with the command by computing it a second way is not what passes.
pin_of() { git hash-object --no-filters -- "$tmp/a plugin/adapters/$1/run.sh" 2>/dev/null; }

# The command, through the plugin tree above. An adapter resolves under the script's own plugin root,
# so a check about one needs a root it can put an adapter in.
adopt_at() {
  dir=$1; shift
  ( cd "$dir" 2>/dev/null || exit 9; sh "$tmp/a plugin/bin/adopt.sh" "$@" 2>&1 )
}

code_of() { "$@" >/dev/null 2>&1; printf '%s' "$?"; }

#
# Make a git repository, or say it could not be done.
#
# **A name is owned by one check.** `mkdir -p` succeeds on a directory that is already there, so a
# reused name would hand the second check the first one's declaration — and a check that read a
# reach somebody else wrote proves nothing about the command that was supposed to write it.
#
make_repo() {
  mkdir "$1" 2>/dev/null || { echo "  FIXTURE  $1 is already taken" >&2; return 1; }
  git init -q "$1" >/dev/null 2>&1 || return 1

  [ -d "$1/.git" ] || return 1
}

# A fixture repository has no checkout behind it and no account in front of it, so git must be told
# who commits or it refuses. `.claude/rules/identity.md` names this as its one exception.
commit_all() {
  git -C "$1" add -A >/dev/null 2>&1 || return 1
  git -C "$1" -c user.email=a@b.c -c user.name=a commit -qm x >/dev/null 2>&1
}

declared() { cat "$1/.foundry/judged" 2>/dev/null; }
pin_in()   { awk -v who="$2" '$1 == "reach" && $2 == who { print $5 }' "$1/.foundry/judged" 2>/dev/null; }
reach_in() { awk -v who="$2" '$1 == "reach" && $2 == who' "$1/.foundry/judged" 2>/dev/null; }
commits()  { git -C "$1" rev-list --count --all 2>/dev/null || printf 'none'; }

a_plugin_shipping a-shipped 'the first content
' || broke "could not build a plugin tree to adopt from"

# --- what it refuses before it reads anything ---

mkdir -p "$tmp/nowhere"
is  "outside a repository it refuses"     "$(code_of adopt_at "$tmp/nowhere" upgrade)" "3"
has "and says a repository is what it wants" "$(adopt_at "$tmp/nowhere" upgrade)" "no repository here"

make_repo "$tmp/plain" || broke "could not make a repository to adopt in"

is  "a verb it does not have is refused"  "$(code_of adopt_at "$tmp/plain" wibble)" "2"
has "and the usage names both verbs"      "$(adopt_at "$tmp/plain" wibble)" "sh adopt.sh upgrade"

# Read from the adapters directory, never typed. Floor core names no vendor, so what a person needs
# to type is only ever knowable from what the plugin ships.
has "and names an adapter this plugin ships" "$(adopt_at "$tmp/plain" wibble)" "a-shipped"

# --- a repository with no reach gets one ---

#
# `$?` from the line above, never a second call.
#
# The first draft asked `upgrade` for this exit code, and `upgrade` moves a pin — so a break that
# made `adopt` write the wrong digest was repaired by the check reading it, and the audit recorded
# the break as caught three checks further down. A check that changes the state it grades.
#
before=$(commits "$tmp/plain")
said=$(adopt_at "$tmp/plain" adopt a-model:adversary a-shipped)
code=$?

is     "adopting a repository with no declaration succeeds" "$code" "0"
exists "and the declaration is there"              "$tmp/plain/.foundry/judged"
has    "and it holds a reach for the judge"        "$(declared "$tmp/plain")" "reach  a-model:adversary  @adapter a-shipped"

# The whole point of the command. A person who has to run a hash command and paste the answer is a
# person who can paste it wrongly, and a mistyped pin fails as a refusal nobody can read.
is "the pin is the digest of the adapter this plugin ships" \
   "$(pin_in "$tmp/plain" a-model:adversary)" "$(pin_of a-shipped)"

matches "and it is a git blob digest and nothing else" \
        "$(pin_in "$tmp/plain" a-model:adversary)" '^[0-9a-f]{40}$'

# A tag, a version and a range each read as an authorisation while the thing they name moves.
lacks "the field carries no version" "$(pin_in "$tmp/plain" a-model:adversary)" "."

is  "adopting adds no commit"        "$(commits "$tmp/plain")" "$before"
is  "and stages nothing"             "$(git -C "$tmp/plain" diff --cached --name-only)" ""
has "and leaves the change in the working tree" "$(git -C "$tmp/plain" status --porcelain)" ".foundry"
has "and says a person commits it"   "$said" "Read the change, then commit it."

# A reach says how a judge is asked. A clause says what must be judged, and a repository cannot be
# guessed into wanting one — so the command names the half it deliberately did not write.
has "it names the clause only a person can write" "$said" "a-model:adversary  a change to what a run may claim"

is  "a judge that already has a reach is refused" \
    "$(code_of adopt_at "$tmp/plain" adopt a-model:adversary a-shipped)" "1"
has "and names the verb that moves a pin instead" \
    "$(adopt_at "$tmp/plain" adopt a-model:adversary a-shipped)" "sh adopt.sh upgrade"

# --- the shipped adapter moves, and the repository is carried across ---

make_repo "$tmp/moved" || broke "could not make a repository to upgrade in"

adopt_at "$tmp/moved" adopt a-model:adversary a-shipped >/dev/null
commit_all "$tmp/moved" || broke "could not commit the declaration to upgrade from"

was=$(pin_of a-shipped)
printf '%s' 'the second content
' > "$tmp/a plugin/adapters/a-shipped/run.sh"
now=$(pin_of a-shipped)

differs "rewriting the adapter changes its digest" "$was" "$now"

# The refusal at 40 is what a repository that declines the upgrade still meets, and `model.sh` holds
# that end to end. What this says is the half before it: nothing moves on its own.
is "a repository that has not upgraded still holds the pin it committed" \
   "$(pin_in "$tmp/moved" a-model:adversary)" "$was"

before=$(commits "$tmp/moved")
said=$(adopt_at "$tmp/moved" upgrade)
code=$?

is  "upgrading a stale pin succeeds"          "$code" "0"
has "it says the digest that was there"       "$said" "was $was"
has "and the one that is there now"           "$said" "now $now"

is  "and the declaration now names what this plugin ships" \
    "$(pin_in "$tmp/moved" a-model:adversary)" "$now"

matches "and the field it wrote is a digest" \
        "$(pin_in "$tmp/moved" a-model:adversary)" '^[0-9a-f]{40}$'

is  "upgrading adds no commit"       "$(commits "$tmp/moved")" "$before"
is  "and stages nothing"             "$(git -C "$tmp/moved" diff --cached --name-only)" ""
has "and leaves a tracked file changed in the working tree" \
    "$(git -C "$tmp/moved" status --porcelain)" "M .foundry/judged"

# Silence would read as success, and a second upgrade is what a person runs when they are unsure.
has "a declaration already at the shipped content says so" \
    "$(adopt_at "$tmp/moved" upgrade)" "already names the content this plugin ships"

# --- what upgrade must not touch ---

#
# A reach the repository owns is not this command's to move.
#
# `@custom` and a bare command are one behaviour and two records, and neither names an adapter this
# plugin ships. No digest here answers for either, so both come back byte for byte.
#
# The tab-separated line is the other half: floor reads fields, a person reads columns, and a writer
# that rebuilt the line through its own separator would land in the diff as a rewrite.
#
make_repo "$tmp/mixed" || broke "could not make a repository of mixed reaches"
mkdir -p "$tmp/mixed/.foundry"

custom='reach  own:reviewer  @custom  sh bin/review.sh --strict'
plain='reach  old:reviewer  sh bin/older.sh'
tabbed=$(printf 'reach\ttab:one\t@adapter a-shipped %s' "$(printf '%040d' 0)")

printf '# a header this repository wrote\n\n%s\n%s\n%s\nreach  gone:one  @adapter no-such-adapter %s\n\nown:reviewer  a sentence somebody meant\n' \
  "$custom" "$plain" "$tabbed" "$(printf '%040d' 0)" > "$tmp/mixed/.foundry/judged"

cp "$tmp/mixed/.foundry/judged" "$tmp/mixed-before"
answer=$(adopt_at "$tmp/mixed" upgrade)
code=$?

is "a custom reach is left exactly as it was" "$(reach_in "$tmp/mixed" own:reviewer)" "$custom"
is "and a bare command reach too"             "$(reach_in "$tmp/mixed" old:reviewer)" "$plain"

is "the line it did move keeps every space and tab around the pin" \
   "$(reach_in "$tmp/mixed" tab:one)" "$(printf 'reach\ttab:one\t@adapter a-shipped %s' "$now")"

is "and one line changed in the whole file" \
   "$(diff "$tmp/mixed-before" "$tmp/mixed/.foundry/judged" | grep -c '^[<>]')" "2"

# An adapter nobody here ships cannot be digested, so the reach stays and the command stays red. A
# declaration still not naming what this plugin ships is not a repository that upgraded.
is  "a reach it could not move leaves the command red" "$code" "1"
has "and it says which reach it left"                  "$answer" "left   gone:one"
is  "and that reach is untouched"                      "$(pin_in "$tmp/mixed" gone:one)" "$(printf '%040d' 0)"

# --- nothing to upgrade is not everything upgraded ---

make_repo "$tmp/bare" || broke "could not make a repository with no declaration"

is  "upgrading a repository with no declaration is refused" "$(code_of adopt_at "$tmp/bare" upgrade)" "1"
has "and it says what writes the first reach"               "$(adopt_at "$tmp/bare" upgrade)" "sh adopt.sh adopt"

make_repo "$tmp/clauses" || broke "could not make a repository of clauses"
mkdir -p "$tmp/clauses/.foundry"
printf 'a-person  somebody read it and understood it\n' > "$tmp/clauses/.foundry/judged"

is  "a declaration naming no @adapter reach is refused" "$(code_of adopt_at "$tmp/clauses" upgrade)" "1"
has "and it says there was no pin to move"              "$(adopt_at "$tmp/clauses" upgrade)" "no @adapter reach"

# --- names a record cannot hold ---

is "the reserved first word is not a judge" "$(code_of adopt_at "$tmp/plain" adopt reach a-shipped)" "2"
is "nor is a name holding a space"          "$(code_of adopt_at "$tmp/plain" adopt 'two words' a-shipped)" "2"
is "nor is an adapter name with a path in it" \
   "$(code_of adopt_at "$tmp/plain" adopt ok:one ../../bin/run)" "2"

is  "an adapter this plugin does not ship is refused" \
    "$(code_of adopt_at "$tmp/plain" adopt ok:one no-such-adapter)" "1"
has "and it says what this plugin does ship" \
    "$(adopt_at "$tmp/plain" adopt ok:one no-such-adapter)" "this plugin ships: a-shipped"

# --- a file whose last line never ended ---
#
# The file this command exists to replace is hand-written, and plenty of editors leave the last
# line unterminated. Appending to one used to glue the reach onto whatever was there.

make_repo "$tmp/raw"
mkdir -p "$tmp/raw/.foundry"
printf '%s' 'a-person  is this ready' > "$tmp/raw/.foundry/judged"
commit_all "$tmp/raw"
adopt_at "$tmp/raw" adopt ok:one a-shipped >/dev/null 2>&1

is "a declaration with no final newline keeps its last line whole" \
   "$(awk 'NR == 1 { print $1, $2 }' "$tmp/raw/.foundry/judged")" "a-person is"
is "and the reach lands on a line of its own" \
   "$(awk '$1 == "reach" { print $2 }' "$tmp/raw/.foundry/judged")" "ok:one"
is "so the declaration holds two lines, not one" \
   "$(awk 'END { print NR }' "$tmp/raw/.foundry/judged")" "2"

make_repo "$tmp/ended"
mkdir -p "$tmp/ended/.foundry"
printf '%s\n' 'a-person  is this ready' > "$tmp/ended/.foundry/judged"
commit_all "$tmp/ended"
adopt_at "$tmp/ended" adopt ok:one a-shipped >/dev/null 2>&1

is "a declaration that did end gains no blank line" \
   "$(awk 'END { print NR }' "$tmp/ended/.foundry/judged")" "2"

# --- the repository that ships the adapter ---
#
# Floor's README said to change into the plugin directory and run it there. Followed word for word,
# a judge was declared in the plugin and the command exited 0.

is "adopting from inside the shipping repository is refused"    "$(cd "$root" && sh bin/adopt.sh adopt ok:one a-shipped >/dev/null 2>&1; printf '%s' "$?")" "1"
has "and it names the tree it would have written to"     "$(cd "$root" && sh bin/adopt.sh adopt ok:one a-shipped 2>&1)" "shipping the adapter"
has "and it gives the command that works"     "$(cd "$root" && sh bin/adopt.sh adopt ok:one a-shipped 2>&1)" "by its full path"
lacks "and it writes nothing"       "$(cd "$root" && git status --porcelain -- .foundry 2>/dev/null)" "judged"

summary "adopt"
