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
#       --worktree DIR --base COMMIT --evidence FILE
#
# **A path is not a handoff.** Every part is read here and printed, so what the judge was given is
# what this command emitted. An audit reads one stream, never a directory it hopes was reachable.
#
# Prints to stdout. Hand it to any model, on any host, however that host takes a prompt.
#
# Exit: 0 printed. 2 called wrongly. 3 no such role. 4 a named file could not be read.
#       5 the chain has no record of the round before this one.
#       6 the worktree named is not a checkout with a commit in it.
#       7 what it was handed as a grade cannot be read as one — the work claims a grade with no
#         log behind it, or the log names no gate.
#       8 the log grades a commit that is not the one in the tree the judge reads.
#       9 the check the base declares before judging is red, or cannot honestly run: the worktree is
#         dirty, or it declares a check and no base was named.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)

# How much of a failing gate's own output goes over. Its tail, because a gate prints what it found
# last, and a brief carrying every line would be the gate's log rather than a brief.
KEPT_LINES=40

# One line, a command: the cheap check a repository runs before a judge reads its work. Never the
# bar a change is graded on — that is the repository's gates.
DECLARATION=.panel/before-judging

main() {
    read_arguments "$@"
    locate_role
    locate_the_commit
    locate_the_prior
    locate_the_grade
    run_the_declared_check

    say_the_role
    say_the_skills
    say_the_bar
    say_the_tree
    say_the_check
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
    base=
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
            --base)    base=${2:-}; [ -n "$base" ] || fail 2 "base names a commit" ;;
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

#
# The check the repository declares before judging, run before a word is printed. #1208.
#
# **Read at the base, never from the tree under review.** A branch can change the line, and the
# change binds the next branch, never itself. What the line runs is still the branch's own code, so
# this stops an honest builder handing over red work. Tampering is the grade's to hold.
#
run_the_declared_check() {
    check_said=
    [ -n "$worktree" ] || { check_said='No worktree was named, so no declared check could run.'; return 0; }
    [ -n "$base" ] || { refuse_a_declaration_with_no_base; return 0; }

    refuse_a_base_that_is_no_commit
    read_the_declaration_at "$base"
    [ -n "$declared" ] || return 0

    refuse_a_dirty_worktree
    run_it_in_the_worktree
}

#
# A worktree whose own commit declares a check, convened with no base to read it at.
#
# A committed declaration is the repository claiming a check, and nothing backs it, as a claimed
# grade with no log is refused below. A branch that deleted the file is told so, never silent.
refuse_a_declaration_with_no_base() {
    check_said='No --base was named, so no declared check could run.'
    read_the_declaration_at "$commit"
    [ -n "$declared" ] || return 0

    note "the tree at [$commit] declares a check in $DECLARATION"
    fail 9 "name the commit to read it at with --base — on the branch it reviews, --base HEAD"
}

#
# The base, as the commit it names. **A `rev:path` whose rev holds a slash is rewritten by Git Bash**
# into a path list, so `origin/main:.panel/before-judging` read nothing there and the check was
# skipped in silence, on the host that convenes. A commit id holds no slash.
#
refuse_a_base_that_is_no_commit() {
    resolved=$(git -C "$worktree" rev-parse --verify --quiet "$base^{commit}" 2>/dev/null)
    [ -n "$resolved" ] || fail 2 "no commit [$base] in [$worktree] to read $DECLARATION at"

    base=$resolved
}

#
# The first line holding anything, into `declared`, or nothing. One line, a command, no format.
#
# **No file is an answer; a file git cannot read is not.** Folded together, a broken read would pass
# as a repository declaring nothing, and the check would be skipped by the fault it exists to catch.
# Set, never captured, so the refusal ends the brief rather than one subshell.
read_the_declaration_at() {
    declared=
    holds_a_declaration "$1" || return 0

    declaration=$(git -C "$worktree" show "$1:$DECLARATION")         || fail 9 "$DECLARATION is at [$1] and git could not read it"
    declared=$(printf '%s
' "$declaration" | awk 'NF { print; exit }')
}

holds_a_declaration() { git -C "$worktree" cat-file -e "$1:$DECLARATION" 2>/dev/null; }

# The check grades files, and the judge reads a commit. On a dirty tree the two are not the same.
refuse_a_dirty_worktree() {
    [ -z "$(git -C "$worktree" status --porcelain 2>/dev/null)" ] && return 0

    note "the worktree at [$worktree] holds changes its commit does not"
    fail 9 "the declared check would grade files the judge never reads — commit them, or clean the tree"
}

run_it_in_the_worktree() {
    said_by_the_check=$(cd "$worktree" && sh -c "$declared" 2>&1 </dev/null)
    answered=$?
    [ "$answered" -eq 0 ] && { check_said="\`$declared\`, declared at $base, ran in the tree you read and exited 0."; return 0; }

    note "\`$declared\`, declared in $DECLARATION at [$base], exited $answered"
    what_it_failed_on | while IFS= read -r line; do note "  $line"; done
    fail 9 "the check the repository runs before judging is red, so no judge is convened"
}

# Every line the check printed that says FAIL as a word, or its last line when none does. A word, as
# `grade_word_in` learned: `FAILING` in prose is not a gate that failed.
what_it_failed_on() {
    printf '%s\n' "$said_by_the_check" | awk '
        { padded = " " $0 " " }
        padded ~ /[^A-Za-z]FAIL[^A-Za-z]/ { print; failed = 1 }
        NF  { last = $0 }
        END { if (!failed) print last }'
}

# Said when the check ran, or when no tree or no base was named. A base declaring nothing says nothing.
say_the_check() {
    [ -n "$check_said" ] || return 0

    printf '\n---\n\n# The check before judging\n\n%s\n' "$check_said"
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

    refuse_a_grade_of_another_tree
}

#
# A grade of another tree.
#
# `locate_the_commit` holds the commit the judge reads, and every gate row names the commit it
# graded. **Both were in hand and nothing compared them.** A green ledger from an earlier commit, or
# from a sibling run, printed under this tree's head and said nothing.
#
# Only when a worktree was named. A brief with no tree has nothing to disagree with, and says so.
refuse_a_grade_of_another_tree() {
    [ -n "$commit" ] || return 0

    at=$(a_ref_that_is_not "$evidence" "$commit")
    [ -n "$at" ] || return 0

    note "the grade at [$evidence] graded [$at]"
    note "the tree the judge reads is at [$commit]"
    fail 8 "that is not this tree's grade — grade the commit the judge reads, or drop --worktree"
}

#
# The first gate ref that is not the commit given, or nothing.
#
# A prefix either way is the same commit. A ledger may abbreviate, and refusing an honest
# seven-character ref would be the check failing rather than the grade.
#
# A row naming no commit is skipped. Floor writes one, and an absent ref disagrees with nothing.
a_ref_that_is_not() {
    awk -F'\t' -v head="$2" '
        $2 != "machine" || $6 == "" { next }
        index(head, $6) == 1 || index($6, head) == 1 { next }
        { print $6; exit }' "$1"
}

#
# A grade in the work file, with no log it came from.
#
# **The words are the grade's own, spelled the way its record spells them.** A work file shouting
# PASS, FAIL, ALL GREEN, AGREED or `N RED` is claiming a grade, and a claim is what this refuses.
#
# Lowercase prose saying the same thing gets through. That is the gap, and it is the gap every lint
# here has: this closes the path a convener takes without thinking, and nothing more.
#
# **A work file quoting a grade is refused too, and that is right.** With no ledger beside it, the
# quoted line is the only grade in the brief, and a judge reads a grade where it finds one. So there
# is no flag that waves this through. The answer is `--evidence`, which is the answer either way.
refuse_a_typed_grade() {
    [ -n "$work" ] || return 0
    [ -z "$evidence" ] || return 0

    said=$(grade_word_in "$work")
    [ -n "$said" ] || return 0

    note "the work claims a grade — it says [$said] — and no log a grade kept came with it"
    note "a judge cannot weigh a grade it was told, only one it was shown"
    fail 7 "pass --evidence FILE, the ledger the grade wrote as it ran"
}

#
# The first grade word the work shouts, or nothing. One is enough: a work file claiming a grade twice
# is still one claim, and the refusal names one word so a convener can see which.
#
# **The word, never a word inside a word.** `PASS` matched `BYPASS` and `FAIL` matched `FAILING`, so
# ordinary prose was refused as a grade claim. The line is padded and the match is bounded by a
# non-letter each side — padding rather than anchors, because `^` inside a group is not something
# every awk here is promised to read.
#
# The count travels with `RED`. The record says `1 RED`, and reporting it as `RED` sent a convener
# looking for a word its own grade never printed.
grade_word_in() {
    awk '{ padded = " " $0 " " }
         padded ~ /[^A-Za-z]ALL GREEN[^A-Za-z]/  { print "ALL GREEN"; exit }
         match(padded, /[0-9]+ RED[^A-Za-z]/)    { print substr(padded, RSTART, RLENGTH - 1); exit }
         padded ~ /[^A-Za-z]AGREED[^A-Za-z]/     { print "AGREED"; exit }
         padded ~ /[^A-Za-z]PASS[^A-Za-z]/       { print "PASS"; exit }
         padded ~ /[^A-Za-z]FAIL[^A-Za-z]/       { print "FAIL"; exit }' "$1"
}

#
# Each gate the log holds: its name, the code it answered with, the commit it read, and the line the
# log kept of what it printed.
#
# `machine` rows only, and seven tab-separated fields in the order the ledger writes them. A verdict
# and a handoff sit in the same file, and neither of them ran anything.
#
# **The ledger appends, so one gate can hold several rows.** Grade a tree red, fix it, grade it
# green, and both rows stand. Printing both handed the judge two answers and no word on which was
# current, so the last row per gate wins and the count of the rest is said out loud.
#
# Said, not dropped. A gate that went red before it went green is the thing a judge most wants to
# know, and a reader who is not told it happened cannot ask.
grade_rows() {
    awk -F'\t' '
        $2 != "machine" { next }
        !($4 in times)  { order[++named] = $4 }
        { times[$4]++; code[$4] = $5; at[$4] = $6; why[$4] = $7 }
        END {
            for (i = 1; i <= named; i++) {
                gate = order[i]
                printf "    %s — exit %s, at %s\n", gate, code[gate], at[gate]
                if (times[gate] > 1)
                    printf "        graded %s times — this is the last of them\n", times[gate]
                printf "        %s\n", why[gate]
            }
        }' "$1"
}

#
# Absent is legal and it is said out loud, like the bar and the tree. A judge that cannot tell an
# ungraded run from an unmentioned grade will assume the second.
say_the_grade() {
    [ -n "$evidence" ] || { printf '\n---\n\n# The grade\n\nNOT SUPPLIED. No gate ran for you, so nothing mechanical sits under this verdict.\n'; return; }

    printf '\n---\n\n# The grade, as the log the grade kept has it\n\n'
    printf '%s\n' "$graded"
    say_the_kept_logs

    printf '\nEvery line above was read out of [%s], which whoever convened you named as the\n' "$evidence"
    printf 'ledger a grade wrote as it ran.\n\n'
    printf 'Nothing here proves it is one. A row is a line of text, and the convener could have\n'
    printf 'typed it. So weigh it as a record, never as a run.\n\n'
    printf 'What it buys is shape. Each gate arrives with a name, the code it answered with and\n'
    printf 'the commit it read — which one line saying ALL GREEN cannot carry, and which takes\n'
    printf 'more invention to fake. A gate missing here is missing from the record too, and that\n'
    printf 'is a finding rather than an omission.\n'
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

#
# Every directory the grade's own record says it kept output in. `sort -u` because a run's gates all
# keep in one place, and the line naming it is repeated per row.
#
# **The last `kept in ` in the field, not the first.** The ledger flattens a whole gate's output into
# one line and `gates.sh` prints that phrase last, so a gate that happened to print the words itself
# took the path — and the judge was then told the logs were gone.
kept_dirs() {
    awk -F'\t' '
        $2 != "machine" { next }
        {
            rest = $7; where = ""
            while (match(rest, /kept in /)) {
                rest = substr(rest, RSTART + RLENGTH)
                where = rest
            }
            if (where != "") print where
        }' "$1" | sort -u
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

If the charter, the work or the grade says NOT SUPPLIED above, say so in that paragraph first.
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
