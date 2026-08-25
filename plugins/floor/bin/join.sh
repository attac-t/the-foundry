#!/bin/sh
#
# Join this host to a repository that already carries Foundry.
#
# Seven things stand between a clean machine and a working system, and four are silent
# when wrong: no `gh` picks a different source, no git identity fails at commit, no
# `FOUNDRY_WHO` names the authority, and a rule can name a skill nobody reaches.
#
# It reports and exits. Nothing here is a daemon, nothing is installed, and nothing is written to the
# repository — the repository already says what may be graded, delivered and required.
#
# Usage: sh join.sh
#
# Exit: 0 joined, 1 the host must supply something, 2 asked for something this does not do,
#       3 this is not a repository that can be joined.

set -u

main() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    refuse_without_a_repository
    refuse_without_dependencies
    refuse_without_an_author
    refuse_without_an_authority

    report_home
    report_work_source
    report_what_the_repository_carries
    report_skills_the_rules_name
    say "joined."
}

usage() {
    say "join.sh — join this host to a repository that already carries Foundry."
    say ""
    say "  sh join.sh    say what is missing, and what this host would run as"
}

# --- what the host must supply ---

#
# `sh`, `git` and `awk`. Floor's contract names these three and nothing else, so a
# host that is missing any one of them can not run floor. Said by name, because
# *it did not work* sends a reader to the repository and not their machines.
#
refuse_without_dependencies() {
    missing=''

    for tool in git awk; do
        command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
    done

    [ -z "$missing" ] && return 0

    say "this host is missing:$missing"
    say "floor declares sh, git and awk. It declares nothing else, and needs all three."
    exit 1
}

refuse_without_a_repository() {
    git rev-parse --show-toplevel >/dev/null 2>&1 && return 0

    say "there is no repository here. Clone one that carries Foundry, then run this inside it."
    exit 3
}

#
# Git refuses a commit with no author, and it refuses it at the end — after a workspace is built and
# the work is done. Asked for here, where it costs nothing.
#
refuse_without_an_author() {
    [ -n "$(git config user.email 2>/dev/null)" ] \
        && [ -n "$(git config user.name 2>/dev/null)" ] && return 0

    say "this host has no git author. A commit made here would be refused by git, not by floor."
    say "  git config --global user.email you@example.com"
    say "  git config --global user.name  'Your Name'"
    exit 1
}

#
# `FOUNDRY_WHO` is the run's authority, and invariant 4 makes selecting the work
# a human act. Unset, a run records nobody at all, and completion will refuse
# it much later on, where it then reads as one bug in the work itself now.
#
refuse_without_an_authority() {
    [ -n "${FOUNDRY_WHO:-}" ] && return 0

    say "FOUNDRY_WHO is not set. A run made here would record nobody as having selected it,"
    say "and completion refuses a run that names nobody."
    say "  export FOUNDRY_WHO=you@example.com"
    exit 1
}

# --- what this host would run as ---

# Derived, never asked for. Saying which one it chose is the point: a home nobody named is a home
# nobody can find again, and two hosts that chose differently look like one that lost a run.
report_home() {
    home=$(run_home) || { say "home    nowhere. No FOUNDRY_HOME, and no HOME either"; return; }

    say "home    $home"
    [ -n "${FOUNDRY_HOME:-}" ] || say "        derived from HOME. Set FOUNDRY_HOME to put it elsewhere."
}

# `run.sh` owns the home, because `run.sh` is what puts a run in one. This
# used to derive its own, instead, and said `.foundry-runs` where a run
# would land in `.foundry`. So that is a home that no run ever used.
run_home() { sh "$(dirname "$0")/run.sh" home 2>/dev/null; }

#
# Which adapter answers, said out loud. This is the silent one:
# an adapter can change under a host without a word, and the
# one that answers may never have heard of Issues at all.
#
report_work_source() {
    say "who     $FOUNDRY_WHO"
    say "source  $(sh "$(source_resolver)" serves 2>/dev/null)"
}

# The same file `run.sh` asks, and the same override. Core names no provider, so it
# asks whatever resolver is installed and prints the sentence back.
source_resolver() { printf '%s' "${FOUNDRY_SOURCE:-$(dirname "$0")/../lib/source.sh}"; }

#
# The repository's half, printed beside the host's own. `.foundry/practice` states
# what may be graded now and what may be delivered; and `.foundry/gates` states
# what the bar is. Neither of these two is this one command's to write here.
#
report_what_the_repository_carries() {
    root=$(git rev-parse --show-toplevel)

    say "grants  $(count_lines "$root/.foundry/practice") in .foundry/practice"
    say "gates   $(count_lines "$root/.foundry/gates") in .foundry/gates"
}

# Comment and blank lines are not entries, and a file that is not there holds none.
count_lines() {
    [ -r "$1" ] || { printf 'none'; return; }

    printf '%s' "$(grep -cv '^[[:space:]]*\(#\|$\)' "$1" 2>/dev/null || printf '0')"
}


#
# The skills this repository's rules name, and whether this host can reach them.
#
# A rule that says to invoke `kernel:craft-sh` does nothing at all on a host
# where kernel is switched off, and nothing here said so. A session reads
# the rule, cannot reach the skill named, and then carries on past it.
#
# The repository states the need by naming skills in its rules. The host states what it has. Neither
# is written into the other, and nothing here installs anything.
#
report_skills_the_rules_name() {
    root=$(git rev-parse --show-toplevel)
    named=$(skills_named_in "$root/.claude/rules")

    [ -n "$named" ] || { say "skills  none named in .claude/rules"; return; }

    for one in $named; do
        say "$(noun_for "$root" "$one")   $one$(reachable "${one%%:*}")"
    done
}

# `/output-style kernel:craftsman` is not a skill at all, and a host that
# is told it is one goes looking for a skill that is not there at all.
# The plugin is on, or a rule reaches nothing at all that it names.
noun_for() {
    grep -rqE "/output-style +$2" "$1/.claude/rules" 2>/dev/null && { printf 'style'; return; }

    printf 'skill'
}

# `plugin:skill`, wherever a rule writes one. A rule is prose, so the mention is the declaration —
# there is no second list to drift from it.
skills_named_in() {
    [ -d "$1" ] || return 0

    grep -rhoE '[a-z][a-z-]*:[a-z][a-z-]*' "$1" 2>/dev/null \
        | grep -vE '^(https?|file|note|usage|exit|see|why|no):' \
        | sort -u
}

# Enabled, not merely installed: an installed plugin that is switched off is a skill nobody can
# invoke. Read from the settings file rather than the plugin directory for that reason.
reachable() {
    settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

    [ -r "$settings" ] || { printf '  — cannot tell, no %s' "$settings"; return; }
    grep -q "\"$1@" "$settings" && return

    printf '  — NOT enabled on this host'
}

say() { printf '%s\n' "$1"; }

main "$@"
