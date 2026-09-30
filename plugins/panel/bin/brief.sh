#!/bin/sh
#
# The brief a judge is handed: Panel's role, the skills that role declares, the bar it judges
# against, the work it answers, and the one clause it may speak to.
#
# A name like `codex:adversary` promises the role Panel ships. Without this the promise is a label,
# and whoever convenes the panel writes the reviewer's instructions — a quieter way of writing its
# verdict.
#
#   sh bin/brief.sh adversary "a clause" --charter FILE --work FILE --verdicts DIR --review ID \
#       --worktree DIR --evidence FILE
#
# **A path is not a handoff.** Every part is read here and printed, so what the judge was given is
# what this command emitted. An audit reads one stream, never a directory it hopes was reachable.
#
# Prints to stdout. Hand it to any model, on any host, however that host takes a prompt.
#
# Exit: 0 printed. 2 called wrongly. 3 no such role. 4 a named file could not be read.
#       5 the chain has no record of the round before this one.
#       6 the worktree named is not a checkout with a commit in it.
#       7 the work claims a grade and no log a grade kept came with it.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)

# How much of a failing gate's own output goes over. Its tail, because a gate prints what it found
# last, and a brief carrying every line would be the gate's log rather than a brief.
KEPT_LINES=40

main() {
    read_arguments "$@"
    locate_role
    locate_the_commit
    locate_the_prior
    locate_the_grade

    say_the_role
    say_the_skills
    say_the_bar
    say_the_tree
    say_the_work
    say_the_grade
    say_the_prior
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
    verdicts=
    round=
    review=
    worktree=
    evidence=

    [ -n "$role" ] && [ -n "$clause" ] || fail 2 'name a role and the clause it answers'
    [ "$#" -ge 2 ] && shift 2

    while [ "$#" -gt 0 ]; do
        case $1 in
            --charter) charter=${2:-}; refuse_unreadable charter "$charter" ;;
            --work)    work=${2:-};    refuse_unreadable work "$work" ;;
            --verdicts) verdicts=${2:-}; [ -n "$verdicts" ] || fail 2 "verdicts names a directory" ;;
            --review)  review=${2:-}; [ -n "$review" ] || fail 2 "review names the chain" ;;
            --worktree) worktree=${2:-}; [ -n "$worktree" ] || fail 2 "worktree names a checkout" ;;
            --evidence) evidence=${2:-}; refuse_unreadable evidence "$evidence" ;;
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
# `-f` as well as `-r`: a directory is readable, `cat` then fails, and `main` carried on to return 0
# with an empty charter block. A bar nobody can read and a bar nobody named are the same lie.
#
# The empty guard is first for the same reason it always is: `--charter` with nothing after it
# leaves `shift 2` short and the loop never ends.
refuse_unreadable() {
    [ -n "$2" ] || fail 2 "$1 names a file"
    [ -f "$2" ] || fail 4 "the $1 at [$2] is not a file"
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

#
# The commit the judge reads, taken once, before a word is printed.
#
# **A brief names a worktree, and a worktree is not a commit.** A judge reads files there for as
# long as it works, and a commit landing meanwhile changes what it reads. One did on 24 September:
# seventeen minutes, two commits, and a verdict naming three heads.
#
# Read here and never by the judge. A judge told to go and look reads whatever is there when it
# looks, which is the fault rather than the fix.
locate_the_commit() {
    commit=
    [ -n "$worktree" ] || return 0

    [ -d "$worktree" ] || fail 6 "the worktree at [$worktree] is not a directory"

    commit=$(git -C "$worktree" rev-parse --verify --quiet HEAD 2>/dev/null)
    [ -n "$commit" ] || fail 6 "no commit to read at [$worktree] — a worktree is a checkout"
}

#
# Absent is legal and it is said out loud, like the bar above. A brief naming no tree leaves nobody
# able to say afterwards whether the tree moved — not the judge, and not the recorder.
say_the_tree() {
    [ -n "$worktree" ] || { printf '\n---\n\n# The tree you read\n\nNOT SUPPLIED. Nobody named the checkout, so nothing can say whether it moved.\n'; return; }

    printf '\n---\n\n# The tree you read\n\n    %s\n' "$worktree"
    printf '    commit %s\n\n' "$commit"
    printf 'That commit is the work. A commit landing while you read changes the files under you,\n'
    printf 'and a verdict spanning two trees judges neither.\n\n'
    printf 'Your recorder is told the same commit, and refuses your verdict if that branch has\n'
    printf 'since moved to another tree.\n'
}

say_the_work() {
    [ -n "$work" ] || { printf '\n---\n\n# The work\n\nNOT SUPPLIED. Nobody told you what this change set out to do.\n'; return; }

    printf '\n---\n\n# What the work set out to do\n\n'
    cat "$work"
}

#
# The log a grade kept, and the refusal that stops a typed one standing in for it.
#
# **A judge was handed the grade as one line the convener wrote** — *the 25 gates at `<head>` — ALL
# GREEN* — so it could weigh the bar only as a claim. One review said so three rounds running.
#
# The remedy is the same one this file already applies to the bar, the tree and the prior round: the
# artefact, read here. A grade's log names each gate, the code it answered with, and what it printed.
# Nobody can type that, which is the whole of the difference.
#
# Asked before a word is printed. A brief that would go over as a claim must not go over at all.
#
locate_the_grade() {
    graded=

    refuse_a_typed_grade
    [ -n "$evidence" ] || return 0

    graded=$(grade_rows "$evidence")
    [ -n "$graded" ] || fail 7 "the log at [$evidence] records no gate, so no grade was read from it"
}

#
# A grade in the work file, with no log it came from.
#
# **The words are the grade's own, spelled the way its record spells them.** A work file shouting
# PASS, FAIL, ALL GREEN, AGREED or `N RED` is claiming a grade, and a claim is what this refuses.
#
# Lowercase prose saying the same thing gets through. That is the gap, and it is the gap every lint
# here has: this closes the path a convener takes without thinking, and nothing more.
refuse_a_typed_grade() {
    [ -n "$work" ] || return 0
    [ -z "$evidence" ] || return 0

    said=$(grade_word_in "$work")
    [ -n "$said" ] || return 0

    note "the work claims a grade — it says [$said] — and no log a grade kept came with it"
    note "a judge cannot weigh a grade it was told, only one it was shown"
    fail 7 "pass --evidence FILE, the ledger the grade wrote as it ran"
}

# The first grade word the work shouts, or nothing. One is enough: a work file claiming a grade twice
# is still one claim, and the refusal names one word so a convener can see which.
grade_word_in() {
    awk '/ALL GREEN/ { print "ALL GREEN"; exit }
         /[0-9] RED/ { print "RED"; exit }
         /AGREED/    { print "AGREED"; exit }
         /PASS/      { print "PASS"; exit }
         /FAIL/      { print "FAIL"; exit }' "$1"
}

#
# Each gate the log holds: its name, the code it answered with, the commit it read, and the line the
# log kept of what it printed.
#
# `machine` rows only, and seven tab-separated fields in the order the ledger writes them. A verdict
# and a handoff sit in the same file, and neither of them ran anything.
grade_rows() {
    awk -F'\t' '$2 != "machine" { next }
                { printf "    %s — exit %s, at %s\n        %s\n", $4, $5, $6, $7 }' "$1"
}

#
# Absent is legal and it is said out loud, like the bar and the tree. A judge that cannot tell an
# ungraded run from an unmentioned grade will assume the second.
say_the_grade() {
    [ -n "$evidence" ] || { printf '\n---\n\n# The grade\n\nNOT SUPPLIED. No gate ran for you, so nothing mechanical sits under this verdict.\n'; return; }

    printf '\n---\n\n# The grade, as the log the grade kept has it\n\n'
    printf '%s\n' "$graded"
    say_the_kept_logs

    printf '\nEvery line above was read out of [%s], which a grade wrote as it ran.\n' "$evidence"
    printf 'None of it was retyped. A name, an exit code or an output missing here is missing\n'
    printf 'from the record too, and that is a finding rather than an omission.\n'
}

#
# A failing gate's own output, carried rather than pointed at.
#
# The ledger flattens what a gate printed to one line, and a red one ends *kept in `<dir>`*. **That
# path is the fault this file's own header names**: a judge told to go and look is handed nothing. So
# the logs kept there are read here, and their tails go over.
say_the_kept_logs() {
    kept_dirs "$evidence" | while IFS= read -r where; do
        [ -n "$where" ] || continue
        say_one_kept_dir "$where"
    done
}

# Every directory the grade's own record says it kept output in. `sort -u` because a run's gates all
# keep in one place, and the line naming it is repeated per row.
kept_dirs() {
    awk -F'\t' '$2 == "machine" && match($7, /kept in /) { print substr($7, RSTART + RLENGTH) }' "$1" \
        | sort -u
}

say_one_kept_dir() {
    printf '\n    The output a failing gate printed was kept in\n\n        %s\n' "$1"
    [ -d "$1" ] || { printf '\n    It is not there now, so none of it could be read.\n'; return; }

    found=
    for kept in "$1"/*.log; do
        [ -f "$kept" ] || continue
        found=yes
        name=${kept##*/}
        printf '\n    %s — the last %s lines it printed\n\n' "${name%.log}" "$KEPT_LINES"
        last_lines "$kept"
    done

    [ -n "$found" ] || printf '\n    It holds no log, so none of it could be read.\n'
}

# The tail of a file, without `tail`. Panel declares `sh`, `awk`, `sed`, `find`, `sort` and `git`,
# and a brief reaching for a seventh command stops working on a host that has six.
last_lines() {
    awk -v keep="$KEPT_LINES" '
        { line[NR % keep] = $0 }
        END {
            start = NR > keep ? NR - keep + 1 : 1
            for (i = start; i <= NR; i++) printf "        %s\n", line[i % keep]
        }' "$1"
}

#
# The round before this one, fetched through the chain rather than handed in.
#
# The Adversary refuses to judge a history it was told. A file on the command line is a telling: any
# prose naming the review would pass, and the convener would be writing the chain it claims to read.
#
# **The caller does not say which round this is.** It said `--round` once, and omitting it
# manufactured a round one — a reset anybody could take by leaving a flag out. The chain answers
# that question now, and the only way to be round one is for this review to have stamped nothing.
say_the_prior() {
    [ "$round" = 1 ] && { printf '\n---\n\n# The round before this one\n\nNONE. The chain at [%s] holds no round for [%s], so this is round one.\n' "$verdicts" "$review"; return; }

    printf '\n---\n\n# The round before this one, in full\n\n'
    cat "$prior_file"
    printf '\n`verdicts.sh prior` named that record, for review [%s] round [%s].\n' "$review" "$round"
    printf 'Nothing else was read. What that record holds is what you were given.\n'
    printf '\nPanel refuses a missing predecessor inside this chain. It cannot know this is the\n'
    printf 'chain for your review — whoever convened it owns that.\n'
}

#
# Asked before anything is printed, so a chain that cannot answer stops the brief.
#
# Fail closed is the whole rule: a round claiming a predecessor nothing records must refuse, never
# proceed with the round unmentioned.
locate_the_prior() {
    prior_file=

    [ -n "$verdicts" ] && [ -n "$review" ] \
        || fail 2 'a brief names the chain it answers to — pass --verdicts and --review'

    # `round`, not `next`. `next` answers the slot the next file takes, which counts every review in
    # the directory — so a review opening in this repository's own `verdicts/` would have been told it
    # was on round 25, and asked for a round 24 it never had. It padded too, and `$(( ))` read `010`
    # as octal.
    #
    # No `2>/dev/null`. The chain says which of its refusals fired — a path nobody made, or a review
    # name carrying its own round — and hiding that left the line below guessing. It printed *could
    # not say which round this is* over *drop the [R2]*, which was the answer.
    #
    round=$(sh "$root/bin/verdicts.sh" round "$verdicts" "$review") \
        || fail 5 "the chain at [$verdicts] could not say which round [$review] is on"

    [ "$round" = 1 ] && return 0

    # Both refusals below now guard a race, not a mistake. `round` and `prior` read the same stamps,
    # so a chain that answered the first cannot fail the second — unless the directory changed
    # between the two processes. They stay for that, and neither has a mutant that could kill them.
    prior_file=$(sh "$root/bin/verdicts.sh" prior "$verdicts" "$round" "$review") \
        || fail 5 "no record of round $((round - 1)) for review [$review] in [$verdicts]"

    [ -n "$prior_file" ] && [ -r "$prior_file" ] \
        || fail 5 "the chain named no readable prior for review [$review] round [$round]"
}

say_the_clause() { printf '\n---\n\n# The clause you answer\n\n    %s\n\n' "$clause"; }

#
# The words, and which list binds.
#
# Your role names four outcomes and the recorder takes three. A judge reading both lists picks one
# nothing can store, and a verdict nothing stores is a verdict nobody gave.
#
# The line comes last. Floor's adapters read the last line that carries anything, and this used to
# ask for a paragraph after it, which a judge could not write and also end on the line. #1056.
say_what_is_wanted() {
    cat <<'ASK'
Answer that clause and nothing else. Do not propose patches. Do not edit anything.

Your role names four outcomes. Only three can be recorded, so use these words and no others.
A SPLIT or a DEADLOCK is a `revise`, and the paragraph says which it was.

First, one paragraph saying why. Name the severity, and what would have to change.

If the charter or the work says NOT SUPPLIED above, say so in that paragraph before anything else.
A verdict given without the bar is worth what it was given.

Then end with exactly one line, on its own, and nothing after it:

    VERDICT: approve
    VERDICT: reject
    VERDICT: revise
ASK
}

fail() {
    note "$2"
    exit "$1"
}

# A refusal worth more than one line. `fail` says the last of them and leaves.
note() { printf 'brief: %s\n' "$1" >&2; }

main "$@"
