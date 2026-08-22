#!/bin/sh
#
# Join this host to a repository that already carries Foundry.
#
# Six things stood between a clean machine and a working system, and three of them were silent when
# wrong: no `gh` picks a different work source, no git identity fails later at commit, and no
# `FOUNDRY_WHO` records an authority nobody granted. This names what is missing and changes nothing.
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
# `sh`, `git` and `awk`. Floor's dependency contract names these three and nothing else, so a host
# missing one is a host floor cannot run on — said by name, because "it did not work"
# sends the reader to look at the repository instead of at their machine.
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
# `FOUNDRY_WHO` is the run's authority — invariant 4 makes selecting the work the human act, and this
# is the only place that name comes from. Unset, a run records nobody and completion
# refuses it much later, which reads as a bug in the work.
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
    home=${FOUNDRY_HOME:-$HOME/.foundry-runs}

    say "home    $home"
    [ -n "${FOUNDRY_HOME:-}" ] || say "        derived from HOME. Set FOUNDRY_HOME to put it elsewhere."
}

#
# Which adapter answers, said out loud. This is the silent one: a GitHub remote with no `gh` still
# has a work source, and the directory that answers has never heard of Issues — so its
# nothing-there and an item nobody can reach read exactly alike.
#
report_work_source() {
    say "who     $FOUNDRY_WHO"

    remote_is_github || { say "source  a directory — this remote is not GitHub"; return; }
    command -v gh >/dev/null 2>&1 || {
        say "source  a directory, and the remote is GitHub. Install gh, or Issues stay unreachable."
        return
    }

    gh auth status >/dev/null 2>&1 || {
        say "source  GitHub, but gh is not signed in. Run: gh auth login && gh auth setup-git"
        return
    }

    say "source  GitHub"
}

remote_is_github() {
    case "$(git remote get-url origin 2>/dev/null)" in
        *github.com*) return 0 ;;
    esac

    return 1
}

#
# The repository's half, printed beside the host's. What may be graded and delivered is
# `.foundry/practice`; what the bar is, `.foundry/gates`. Neither is this command's to write, and a
# repository carrying neither is joinable and can do nothing yet.
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
# A rule saying "invoke `kernel:craft-sh` before the first character" does nothing on a host where
# kernel is not enabled, and nothing said so. The session read the rule, could not
# reach the skill, and carried on — the silent failure this command exists for.
#
# The repository states the need by naming skills in its rules. The host states what it has. Neither
# is written into the other, and nothing here installs anything.
#
report_skills_the_rules_name() {
    root=$(git rev-parse --show-toplevel)
    named=$(skills_named_in "$root/.claude/rules")

    [ -n "$named" ] || { say "skills  none named in .claude/rules"; return; }

    for skill in $named; do
        say "skill   $skill$(reachable "${skill%%:*}")"
    done
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
