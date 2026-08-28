#!/bin/sh
#
# The brief a judge is handed: Panel's role, the skills that role declares, the bar it judges
# against, the work it answers, and the one clause it may speak to.
#
# A name like `codex:adversary` promises the role Panel ships. Without this the promise is a label,
# and whoever convenes the panel writes the reviewer's instructions — a quieter way of writing its
# verdict.
#
#   sh bin/brief.sh adversary "the interface is understandable" --charter FILE --work FILE
#
# **A path is not a handoff.** Every part is read here and printed, so what the judge was given is
# what this command emitted. An audit reads one stream, never a directory it hopes was reachable.
#
# Prints to stdout. Hand it to any model, on any host, however that host takes a prompt.
#
# Exit: 0 printed. 2 called wrongly. 3 no such role. 4 a named file could not be read.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)

main() {
    read_arguments "$@"
    locate_role

    say_the_role
    say_the_skills
    say_the_bar
    say_the_work
    say_the_clause
    say_what_is_wanted
}

# `--charter` and `--work` name files, never text. A body is many lines, and a positional one is a
# shape a shell mangles.
read_arguments() {
    role=${1:-}
    clause=${2:-}
    charter=
    work=

    [ -n "$role" ] && [ -n "$clause" ] || fail 2 'name a role and the clause it answers'
    [ "$#" -ge 2 ] && shift 2

    while [ "$#" -gt 0 ]; do
        case $1 in
            --charter) charter=${2:-}; refuse_unreadable charter "$charter" ;;
            --work)    work=${2:-};    refuse_unreadable work "$work" ;;
            *)         fail 2 "unknown argument [$1]" ;;
        esac
        shift 2
    done
}

#
# In the caller's own shell, never inside a substitution.
#
# `exit` in `$(...)` ends the subshell and the script carries on. An unreadable charter became an
# absent one, the brief said NOT SUPPLIED, and the handoff was recorded as though the bar went over.
#
# The empty guard is first for the same reason it always is: `--charter` with nothing after it
# leaves `shift 2` short and the loop never ends.
refuse_unreadable() {
    [ -n "$2" ] || fail 2 "$1 names a file"
    [ -r "$2" ] || fail 4 "cannot read the $1 at [$2]"
}

locate_role() {
    file="$root/agents/$role.md"
    [ -r "$file" ] && return 0

    fail 3 "no role [$role] in $root/agents"
}

# The frontmatter is for the harness that loads an agent. A model handed prose does not
# need it, and the `---` fences read as a heading rule.
role_body() { awk 'seen == 2 { print } /^---$/ { seen++ }' "$1"; }

# The one frontmatter field a reader still needs, because the role names its skills there and the
# body never repeats them.
declared_skills() {
    awk -F': *' '/^skills:/ { print $2; exit }' "$1" | tr ',' '\n' | tr -d ' '
}

say_the_role() { printf '%s\n' "$(role_body "$file")"; }

#
# The skills the role declares, carried whole.
#
# A role saying `skills: craft-verdict` and arriving without it is a promise nobody kept. The
# reviewer cannot fetch what it was never told the path to.
say_the_skills() {
    declared_skills "$file" | while IFS= read -r skill; do
        [ -n "$skill" ] || continue
        say_one_skill "$skill"
    done
}

say_one_skill() {
    body="$root/skills/$1/SKILL.md"
    [ -r "$body" ] || { printf '\n---\n\n# Skill `%s` — NOT SUPPLIED, and it was declared\n' "$1"; return; }

    printf '\n---\n\n# The skill `%s`, which your role declares\n\n' "$1"
    cat "$body"
}

# Absent is legal and it is said out loud. A judge that cannot tell a missing bar from an
# unmentioned one will assume the second, and assume wrongly.
say_the_bar() {
    [ -n "$charter" ] || { printf '\n---\n\n# The charter\n\nNOT SUPPLIED. Nothing pinned this bar for you.\n'; return; }

    printf '\n---\n\n# The charter this run answers to\n\n```\n'
    cat "$charter"
    printf '```\n'
}

say_the_work() {
    [ -n "$work" ] || { printf '\n---\n\n# The work\n\nNOT SUPPLIED. Nobody told you what this change set out to do.\n'; return; }

    printf '\n---\n\n# What the work set out to do\n\n'
    cat "$work"
}

say_the_clause() { printf '\n---\n\n# The clause you answer\n\n    %s\n\n' "$clause"; }

#
# The words, and which list binds.
#
# Your role names four outcomes and the recorder takes three. A judge reading both lists picks one
# nothing can store, and a verdict nothing stores is a verdict nobody gave.
say_what_is_wanted() {
    cat <<'ASK'
Answer that clause and nothing else. Do not propose patches. Do not edit anything.

Your role names four outcomes. Only three can be recorded, so use these words and no others.
A SPLIT or a DEADLOCK is a `revise`, and the paragraph says which it was.

End with exactly one line, on its own:

    VERDICT: approve
    VERDICT: reject
    VERDICT: revise

Then one paragraph saying why. Name the severity, and what would have to change.

If the charter or the work says NOT SUPPLIED above, say so in that paragraph before anything else.
A verdict given without the bar is worth what it was given.
ASK
}

fail() {
    printf 'brief: %s\n' "$2" >&2
    exit "$1"
}

main "$@"
