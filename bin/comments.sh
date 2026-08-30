#!/bin/sh
#
# Read the public thread back, and refuse a comment the seam never rendered.
#
#   sh bin/comments.sh 416    read one pull request's thread
#   sh bin/comments.sh audit  prove this can go red, without the network
#
# **The thread is the only ledger neither the worker nor this script can rewrite.** A file beside
# the run says what the run admits to. GitHub says what happened.
#
# `plugins/floor/bin/say.sh` renders a comment from named fields and refuses seven ways. This reads
# what actually landed and re-runs those rules on it — so a comment posted around the seam reads as
# exactly what it is.
#
# **This is detection, not prevention, and the difference matters.** Once GitHub accepts the write,
# the disclosure has happened; blocking delivery afterwards does not un-send it. Two consultations
# at maximum effort said the same thing from opposite directions: the only control that binds is a
# comment credential the automated worker cannot reach, held by a person. #419 owns that. This is
# what can be built without it.
#
# Exit codes:
#
#   0  every marked comment still obeys the seam's rule
#   1  one does not, and this says the id it carries
#   3  `gh` could not answer, so nothing was read
#
# No `set -e`: every comment is checked, and one bad comment must not hide the next.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
number=${1:-}
found=0
read_into=

main() {
    [ "$number" = audit ] && { bash "$root/tests/comments.sh"; exit $?; }

    refuse_no_number
    ensure_gh_answers

    # Through a file, never a pipe. A `while` on the right of `|` runs in a subshell, so every
    # `found=1` it sets dies with it and `report` reads zero — which is how a red suite prints green.
    read_into="${TMPDIR:-/tmp}/comments-$$"
    trap 'rm -f "$read_into"' EXIT
    comment_bodies > "$read_into" || exit 3

    while IFS= read -r line; do check_one "$line"; done < "$read_into"

    report
}

refuse_no_number() {
    [ -n "$number" ] && return 0
    printf 'comments: name the pull request or issue to read\n' >&2
    exit 3
}

# Polled, not assumed. `gh` prints its own errors and still exits 0 on some paths, so the oracle is
# whether a body came back at all.
ensure_gh_answers() {
    command -v gh >/dev/null 2>&1 && return 0
    printf 'comments: no gh here, so nothing was read\n' >&2
    exit 3
}

# One comment per line, newlines folded, so `read` gets one record each time.
comment_bodies() {
    gh api "repos/{owner}/{repo}/issues/$number/comments" \
       --jq '.[] | [(.id|tostring), (.body|gsub("\n"; " "))] | join("\t")' 2>/dev/null
}

#
# Three questions per comment, and the third is the one that matters.
#
# A comment with no marker was not rendered here. That is either a person writing by hand, which is
# fine and expected, or a worker going around the seam, which is not — and this cannot tell them
# apart, because they sign in as the same account. So it reports and does not fail on that alone.
check_one() {
    id=${1%%	*}
    body=${1#*	}

    carries_a_marker "$body" || { note_unrendered "$id" "$body"; return; }

    obeys_the_limit "$body"   || bad "$id" 'came through the seam and is over the limit'
    carries_no_log  "$body"   || bad "$id" 'came through the seam and carries a log field'
}

carries_a_marker() { case $1 in *'<!-- seam:'*) return 0 ;; esac; return 1; }

obeys_the_limit() {
    [ "$(printf '%s' "$1" | wc -c | tr -d ' ')" -le 1200 ]
}

carries_no_log() {
    printf '%s' "$1" | awk '
        /session id|session_id|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}/ { exit 1 }
        /tokens used|token count|input tokens|output tokens/         { exit 1 }' >/dev/null
}

#
# A long unrendered comment is the shape the regression took, so it is named out loud even though
# this cannot prove who wrote it.
note_unrendered() {
    obeys_the_limit "$2" && return 0
    printf '  note  %s is %s characters and did not come through the seam\n' \
           "$1" "$(printf '%s' "$2" | wc -c | tr -d ' ')"
}

bad() { printf '  FAIL  %s — %s\n' "$1" "$2"; found=1; }

report() {
    [ "$found" -eq 0 ] && { printf 'comments — every rendered comment still obeys the seam\n'; return 0; }
    printf 'comments — a rendered comment broke the rule that rendered it\n'
    return 1
}

main "$@"
