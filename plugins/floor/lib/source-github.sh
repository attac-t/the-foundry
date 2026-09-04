#!/bin/sh
#
# A work source that is GitHub Issues. The first adapter, and not the model.
#
# Needs `gh`, which floor does not declare — so floor reaches this only where the remote is GitHub
# *and* `gh` is there, and `source-dir.sh` answers otherwise. §3's level 1, both halves.
#
# A question is a comment; its answer is what people wrote after it. The human is asked where they
# already are, and one marker line addresses one question among many:
#
#     floor-question: <question> <digest of the words>
#
# The marker carries a digest, not the words. Asking twice with the same words is one question
# and different words are refused, and comparing them means recovering the first ones out of a
# transcript GitHub formats however it likes. A digest needs no recovery and no parser.
#
# Only the question is marked. An answer is whatever a person wrote next — a marker they have to
# type is a command language, and the first person who met one answered and went unheard.
#
# Usage: sh source-github.sh read    <issue>
#        sh source-github.sh publish <issue> <run> <branch> <title> [word] [brief]
#        sh source-github.sh ask     <issue> <question> <text>
#        sh source-github.sh receive <issue> <question>
#
# Exit: 0 answered · 1 nothing there · 2 asked for something this does not do · 3 GitHub refused
#       4 this run already sent something else under that name
#

set -u

command -v gh >/dev/null 2>&1 || { echo "source-github: gh is not here" >&2; exit 2; }

#
# The issue's own words, and no interpretation of them. A transport carries; it does not read.
#
# A source that could not be asked is not an item that is not there. `gh` exits 1 for both, so its
# message is not what tells them apart. A second question is: a repository cannot be absent and an
# issue can — measured, bad credentials fail both, and a missing issue fails only the first.
#
# One case survives this and is not caught: a token that reads the repository and not its issues
# probes as reachable, and answers *nothing there* wrongly.
#
read_item() {
    gh issue view "$1" --json title,body --jq '.title, "", .body' && return 0

    repository_answers || return 3
    return 1
}

# Something that cannot be absent, asked only when the item could not be read.
repository_answers() { gh repo view --json name >/dev/null 2>&1; }

#
# What one run published, and the identity of it.
#
# GitHub keys a pull request on its head branch and knows nothing of runs, so the body carries the
# run and a search finds it. Keying on the branch instead would let one run open a second delivery
# by publishing a second branch, which is the case a resume must never look like.
#
publish_delivery() {
    had=$(delivery_of "$2") || return 3

    [ -z "$had" ] && { open_delivery "$1" "$2" "$3" "$4" "$5" "${6:-}"; return $?; }

    # `<branch> <url>`, and a branch holds no space.
    [ "${had% *}" = "$3" ] || return 4
    printf '%s\n' "${had##* }"
}

#
# What GitHub says it already has, or nothing, and the two are told apart. A search that
# failed used to return empty, which reads as no delivery yet and answers by
# opening a second one for work that already had one.
#
# GitHub matches words in a body and not substrings, so two runs made the same day share three
# tokens of four and each other's pull requests come back. The search narrows;
# the marker floor wrote is what decides. Named, so the `gh` line holds no pipe.
delivery_of() {
    shape=".[] | select(.body | contains(\"floor-run: $1\")) | .headRefName + \" \" + .url"

    found=$(gh pr list --state all --search "$1 in:body" --json headRefName,url,body --jq "$shape" 2>&1) || {
        printf 'source-github: could not ask what is already delivered: %s\n' "$found" >&2
        return 3
    }

    printf '%s\n' "$found" | head -1
}

# The caller says which word. `Refs` names the item and closes nothing.
# `Closes` is what GitHub acts on, and only a person grants that.
open_delivery() {
    gh pr create --head "$3" --title "$4" --body "$(body_for "$1" "$2" "${5:-Refs}" "${6:-}")" \
        || return 3
}

# The brief first, then the two lines only a machine reads. A reader opens this
# to decide something, and a run marker above the reason is a transcript
# wearing a decision's clothes. The order is the whole point here.
#
# Nothing to say is legal, and says only which item this answers. Thin,
# and thin is honest: a body written to fill the space is worse than
# a shorter one, because a reader reads to the end to learn that.
body_for() {
    [ -n "$4" ] && [ -r "$4" ] && printf '%s\n\n' "$(without_its_own_reference "$4" "$1")"

    printf '%s #%s\n\nfloor-run: %s\n' "$3" "$1" "$2"
}

# A brief that names its own item gets named twice. The seam adds the reference, so one
# written by hand is dropped rather than argued about in prose nobody reads in time.
#
# Only this item, and only a line that is nothing else. A sentence
# mentioning the number is the writer's, and it stays.
without_its_own_reference() {
    awk -v item="$2" '
        $0 ~ "^(Closes|Refs) #" item "[.]?$" { next }
        { print }
    ' "$1" | without_trailing_blanks
}

without_trailing_blanks() {
    awk '{ held[NR] = $0 }
         END { last = NR
               while (last > 0 && held[last] ~ /^[[:space:]]*$/) last--
               for (i = 1; i <= last; i++) print held[i] }'
}

put_question() {
    asked=$(after_marker "$1" "floor-question: $2 ") || return 3
    said=$(digest "$3")

    [ -z "$asked" ] && { post_question "$1" "$2" "$said" "$3"; return $?; }

    [ "$asked" = "$said" ] || return 4
}

#
# Every comment floor writes carries the run that wrote it.
#
# The account is not provenance. Two people can share one, and a run can post
# under another. A stamp says which run, and `said_after` reads it first.
#
# The run is already the first field of the question id, so nothing new has to
# be threaded down here to know it.
post_question() {
    gh issue comment "$1" --body "floor-question: $2 $3
floor-run: ${2%%.*}

$4" >/dev/null || return 3
}

#
# A human's answer, as they wrote it. Nothing here reads it — what an answer means belongs to whoever
# asked, and a transport that decided would be answering for them.
#
read_answer() {
    said=$(said_after "$1" "floor-question: $2 ") || return 3
    [ -n "$said" ] || return 1

    printf '%s\n' "$said"
}


#
# Every comment on the item, as bodies, with a boundary this file chose.
#
# `--comments` is `gh`'s human transcript, and a layout is not a contract. It changes without
# notice, and on a client old enough for GitHub to reject its GraphQL it stopped being fetchable at
# all — `projectCards`, which nothing here asked for. `--json comments` returns the field on every
# client tested, and `--jq` is `gh`'s own, so this declares no parser.
#
# A body holding a line that is exactly the boundary spoofs one. The transcript had the same
# exposure through `author:` and its rule line; the difference is that this line is ours to change.
#
# Captured before it is handed anywhere: a pipeline reports its last stage, and `awk` succeeds on
# nothing at all.
#
comments_of() {
    # The `|` here is jq's, not the shell's — named so the line that runs `gh` holds no pipe at all,
    # which is the only thing `bin/shell.sh` can tell apart without a parser.
    shape='.comments[] | "floor-comment: " + .author.login, .body'

    seen=$(gh issue view "$1" --json comments --jq "$shape" 2>&1) || {
        printf 'source-github: could not read the comments: %s\n' "$seen" >&2
        return 3
    }

    printf '%s\n' "$seen"
}

#
# The words after a marker, in the first comment carrying it. No boundary is needed — the first line
# holding the mark is the one.
#
# A read that failed is not a question nobody asked. Empty is what `put_question` reads as *not
# asked yet*, and it answers by asking — so a resumed run whose lookup hit a network put the question
# to the human twice.
#
after_marker() {
    seen=$(comments_of "$1") || return 3

    printf '%s\n' "$seen" \
        | awk -v mark="$2" 'index($0, mark) { print substr($0, index($0, mark) + length(mark)); exit }'
}

#
# What people said after this question, and never another question.
#
# The marked comment holds the ask, so its own body is skipped — reading it would authorise a clause
# with the words that asked about it. The answer is whatever the next comment says.
#
# Questions bound this at both ends. One is asked per unauthorised clause, so several stand open at
# once, and the next one beginning means this one was passed over rather than answered.
#
said_after() {
    seen=$(comments_of "$1") || return 3
    self=$(posting_as) || return 3

    printf '%s\n' "$seen" \
        | awk -v mark="$2" -v self="$self" '
            /^floor-comment: / { decide(); who = substr($0, 16); next }
            /^floor-question: / { decide(); mine = index($0, mark) > 0; open = 0; next }
            { held[++n] = $0 }
            END { decide() }

            # One comment, judged whole. A stamp sits anywhere in the body, so
            # no line is printed before the last one has been read.
            function decide() {
                if (open && n) judge()
                open = open || mine; mine = 0; n = 0
            }

            # The stamp decides, then the account. An account is shared and
            # borrowed; a stamp says which run wrote the words.
            function judge(   i) {
                if (stamped()) { skipped("this run wrote it"); return }
                if (who == self) { skipped("it came from [" who "], the account this run posts as"); return }

                for (i = 1; i <= n; i++) if (held[i] ~ /[^ \t]/) print held[i]
            }

            function stamped(   i) {
                for (i = 1; i <= n; i++) if (held[i] ~ /^floor-[a-z]+: /) return 1
                return 0
            }

            # A dropped comment is the one thing a caller cannot infer. It sees an
            # unanswered clause, and an answer nobody wrote reads like a refusal.
            function skipped(why) {
                printf "source-github: skipped a comment — %s\n", why > "/dev/stderr"
            }'
}

#
# The account this run comments as. #373 is what a missing one costs: a
# note the run wrote, holding a clause number so that a person could
# copy it, was read back as the person saying yes to all of this.
#
# It fails closed. Not knowing who we are means not knowing whose these
# words are, and a source that cannot tell these apart really has to
# refuse rather than guessing in a way that suits its own favour.
#
posting_as() {
    said=$(gh api user --jq '.login' 2>&1) || {
        printf 'source-github: could not read who this run comments as: %s\n' "$said" >&2
        return 3
    }

    [ -n "$said" ] || { printf 'source-github: gh names nobody as this run\n' >&2; return 3; }
    printf '%s' "$said"
}

# 32 bits, so two texts can share one. A collision lets a rewritten question pass for the one already
# asked — the cost is a human holding words that changed, never a bar that moved.
digest() { printf '%s' "$1" | cksum | awk '{ print $1 }'; }

#
# What the source says about one run's delivery. A header, then the checks:
#
#     <head> <state> <mergeable> <target>
#     <conclusion> <check>
#
# One check line for every check the target requires, and none at all when it requires none.
#
# **Four questions in one call, because four calls are four moments.** A head that moves between them
# is the case a merge exists to refuse, and asking twice is how it slips through.
#
# What the target requires is a second call and not a fifth moment. A branch's rules are no property
# of the delivery, so they cannot move under the head the first call read.
#
# `headRefOid` and not the branch name. A branch is a pointer a push moves; the caller compares a
# commit against the one its evidence names, and only a commit answers that.
#
# The rollup holds every check that ran and says nothing about which of them the target insists on.
# Reporting all of them made the caller refuse on a bar nobody set, so the requiring is asked here
# and what crosses the seam is the answer.
#
delivery_state() {
    had=$(delivery_of "$1") || return 3
    [ -n "$had" ] || return 1

    said=$(delivery_facts "${had##* }") || return 3

    facts=$(printf '%s\n' "$said" | sed -n 1p)
    ran=$(printf '%s\n' "$said" | sed 1d)
    wanted=$(checks_required_on "${facts##* }") || return 3

    printf '%s\n' "$facts"
    say_what_the_target_requires "$wanted" "$ran"
}

# The header first, then the rollup one check to a line. `.name` is a check run and `.context` a
# status, and the caller cares which check it was, never which kind.
delivery_facts() {
    shape='(.headRefOid + " " + .state + " " + (.mergeable // "UNKNOWN") + " " + .baseRefName),
           (.statusCheckRollup[]? | (.conclusion // .state // "PENDING") + " " + (.name // .context))'

    said=$(gh pr view "$1" --json headRefOid,state,mergeable,baseRefName,statusCheckRollup \
               --jq "$shape" 2>&1) && { printf '%s\n' "$said"; return 0; }

    printf 'source-github: could not ask about the delivery: %s\n' "$said" >&2
    return 3
}

#
# Every check the target branch requires, one per line, and nothing when it requires none.
#
# `rules/branches` and not `branches/<b>/protection`. The protection endpoint answers 404 for a
# branch nobody protected *and* for a caller who may not look, and nothing in the
# reply tells the two apart — measured, `cli/cli` answers a
# stranger the way this repository answers its owner.
#
# A signal that cannot be read is worse than one that is missing, and this one reads for anybody
# with pull access. Rules set on the repository and rules set on the organisation both arrive here.
#
# **What it misses is the old `Branch protection rules` page.** Rulesets reach this endpoint and
# classic protection does not, so a check required only there goes unnamed. GitHub still refuses the
# merge itself, so nothing lands that should not; the message degrades, never the bar.
#
checks_required_on() {
    shape='[.[] | select(.type == "required_status_checks")
                | .parameters.required_status_checks[]?.context] | unique | .[]'

    said=$(gh api "repos/{owner}/{repo}/rules/branches/$1" --jq "$shape" 2>&1) \
        && { printf '%s\n' "$said"; return 0; }

    printf 'source-github: could not ask what [%s] requires: %s\n' "$1" "$said" >&2
    return 3
}

#
# What became of each required check, in the order the target names them.
#
# `MISSING` for one the rollup never mentions. A required check that never ran is not one that
# failed — the source lands neither, and only one of the two is a failure anybody can go and read.
#
say_what_the_target_requires() {
    printf '%s\n' "$2" | awk -v wanted="$1" '
        { ran[check_that_ran()] = $1 }
        END { say_each() }

        function check_that_ran(   name) { name = $0; sub(/^[^ ]* /, "", name); return name }

        function say_each(   i, n, want) {
            n = split(wanted, want, "\n")
            for (i = 1; i <= n; i++) {
                if (want[i] == "") continue
                if (want[i] in ran) { print ran[want[i]], want[i]; continue }
                print "MISSING", want[i]
            }
        }
    '
}

# `--merge`, never `--squash`. The delivery is the run's own history, and a squash throws away every
# commit the evidence was recorded against.
land_delivery() {
    had=$(delivery_of "$1") || return 3
    [ -n "$had" ] || return 1

    why=$(gh pr merge "${had##* }" --merge 2>&1) && return 0

    printf 'source-github: the merge was refused: %s\n' "$why" >&2
    return 3
}

#
# What the source says this work is. **The only place `foundry:` exists.**
#
# A repository Foundry does not own already has `bug`, `enhancement`, `blocked`. Reinterpreting those
# makes a stranger's vocabulary into Foundry's authority, so a namespace is what keeps them apart —
# `foundry:*` is Foundry's, everything else is the repository's, and nothing crosses.
#
# Core is told `defect`. How a source spells it is the adapter's, and that is the whole of the seam.
#
kind_of_item() {
    said=$(gh issue view "$1" --json labels --jq '.labels[].name' 2>&1) || {
        repository_answers || return 3
        return 1
    }

    printf '%s\n' "$said" | awk '/^foundry:/ { sub(/^foundry:/, ""); print }'
}


#
# Every delivery open against this source but this run's. A run never reads
# another run's workspace. The source knows, and a branch name is all that crosses.
open_deliveries() {
    # Named, because a `gh` line holding a pipe reads as one to the gate that grades this file.
    shape='.[] | .headRefName + "	" + .url'

    said=$(gh pr list --state open --json headRefName,url --jq "$shape" 2>&1) || {
        printf 'source-github: could not ask what else is open: %s\n' "$said" >&2
        return 3
    }

    printf '%s\n' "$said" | awk -F'\t' -v mine="$1" '$1 != mine && NF'
}

#
# Where the source read this item from, as a target identity. A directory
# is not a repository and says nothing; only a source
# that lives in one can answer.
#
# `.git` is appended because that is the identity floor compares against, and `gh` reports the
# browse URL. One shape on both sides, or the comparison silently never matches.
#
where_from() {
    said=$(gh repo view --json url --jq .url 2>&1) || return 1
    [ -n "$said" ] || return 1

    printf '%s.git
' "$said"
}


take_claim() {
    at=$(claim_tip "$1")
    [ -n "$at" ] && { holder_at "$at" "$2" || return 4; }

    made=$(claim_commit "$2" "$at") || return 3

    why=$(git push origin "$made:refs/heads/$(claim_ref "$1")" 2>&1) && return 0

    printf 'source-github: the claim was refused: %s\n' "$why" >&2
    return 4
}

# A commit on top of the one there, so the push is a fast-forward the server
# refuses if the tip moved. Creating the ref and renewing it are one step.
claim_commit() {
    tree=$(git hash-object -t tree /dev/null) || return 3

    [ -n "$2" ] || { printf 'claimed by %s\n' "$1" | git commit-tree "$tree" 2>/dev/null; return; }
    printf 'claimed by %s\n' "$1" | git commit-tree "$tree" -p "$2" 2>/dev/null
}

claim_tip() {
    listed=$(git ls-remote origin "refs/heads/$(claim_ref "$1")" 2>/dev/null) || return 0

    printf '%s' "${listed%%	*}"
}

holder_at() {
    git fetch origin "$1" >/dev/null 2>&1 || return 1
    said=$(git show -s --format='%s' "$1" 2>/dev/null) || return 1

    [ "${said##*claimed by }" = "$2" ]
}

# `%ct` is the commit's own time, so the age travels with the claim and no
# clock but the holder's wrote it. A reader elsewhere compares to its own.
read_claim() {
    at=$(claim_tip "$1")
    [ -n "$at" ] || return 1

    git fetch origin "refs/heads/$(claim_ref "$1")" >/dev/null 2>&1 || return 3

    said=$(git show -s --format='%cI	%ct	%s' "$at" 2>/dev/null) || return 3
    printf '%s\t%s\t%s\n' "${said%%	*}" "${said##*claimed by }" "$(printf '%s' "$said" | cut -f2)"
}

drop_claim() {
    git push origin --delete "refs/heads/$(claim_ref "$1")" >/dev/null 2>&1 || return 4
}

# One name, derived. A host choosing it could claim an item nobody filed.
claim_ref() { printf 'foundry/claim/%s' "$1"; }

case "${1:-}" in
    read)    shift; read_item        "${1:-}" ;;
    kind)    shift; kind_of_item     "${1:-}" ;;
    where)   shift; where_from ;;
    open)    shift; open_deliveries  "${1:-}" ;;
    claim)   shift; take_claim       "${1:-}" "${2:-}" ;;
    held)    shift; read_claim       "${1:-}" ;;
    release) shift; drop_claim       "${1:-}" "${2:-}" ;;
    publish) shift; publish_delivery "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" ;;
    ask)     shift; put_question     "${1:-}" "${2:-}" "${3:-}" ;;
    receive) shift; read_answer      "${1:-}" "${2:-}" ;;
    state)   shift; delivery_state   "${1:-}" ;;
    land)    shift; land_delivery    "${1:-}" ;;
    *)       echo "source-github: read <issue> | kind <issue> | claim <issue> <host> | held <issue> | release <issue> <host> | publish <issue> <run> <branch> <title> [word] [brief] | ask <issue> <question> <text> | receive <issue> <question> | state <run> | land <run>" >&2
             exit 2 ;;
esac
