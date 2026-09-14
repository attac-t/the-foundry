#!/bin/sh
#
# Read what this repository claims, against the service.
#
#   sh bin/stale.sh          every issue the page cites, read live
#   sh bin/stale.sh debt     the exemption list this tree needs
#   sh bin/stale.sh audit    prove it can go red, no network
#
# **A page naming finished work as an open gap is worse than an open issue**, because nobody looks
# again. `closing.md` says the same of a box. #535 asked for this and it took five days to build,
# during which the page carried two.
#
# **It cannot read prose, so it does not try.** Every closed citation is reported, and a citation
# that is deliberately history sits in `bin/stale.debt` with the reason beside it. That is
# `taper.sh`'s shape, and for the same reason: the judgement is a person's and the list is the
# record of it.
#
# **An exemption that no longer applies is a failure too.** A debt line for an issue that reopened,
# or one nobody cites any more, is a stale record of a stale record.
#
# This is not a gate. `bin/gates.sh` must pass with no network, and this cannot answer without one.
# It runs on the delivery path, beside `bin/comments.sh`, which reads the same service for the same
# kind of fault.
#
# Exit codes:
#
#   0  every citation is open, or exempt and still cited
#   1  one is closed and not exempt, or an exemption no longer applies
#   2  asked for something this does not do
#   3  `gh` could not answer, so nothing was read

set -u

PAGE=.foundry/status.md
DEBT=bin/stale.debt
FORMS=.github/ISSUE_TEMPLATE/config.yml

main() {
    case ${1:-check} in
        check) check_the_page ;;
        debt)  print_the_debt ;;
        audit) prove_it_can_go_red ;;
        *)     fail 2 "stale: [$1] is not check, debt or audit" ;;
    esac
}

check_the_page() {
    ensure_the_page_is_here
    ensure_the_forge_answers

    closed=$(closed_citations)
    unused=$(exemptions_nobody_cites)

    report 'a closed issue the page cites as open work' "$(not_exempt "$closed")"
    report 'a named exemption that no longer applies'   "$unused"
    report 'a link on the new-issue page the service does not serve' "$(links_the_service_refuses)"

    say "stale  $(printf '%s\n' "$(cited)" | grep -c .) cited, $(printf '%s' "$closed" | grep -c .) closed, $(exempt_count) exempt"
}

# --- what the page names ---

# A number reaches here twice — as `#123` and inside an issues URL — and the page uses both. Sorted
# and unique, because a page citing one issue in four places is one question, not four.
cited() {
    grep -oE '#[0-9]{2,4}|issues/[0-9]+' "$PAGE" 2>/dev/null \
        | grep -oE '[0-9]+' | sort -un
}

# **A pull request is not a citation fault.** The page names merged requests for what landed, which
# is what a reader wants. Only an issue can be cited as an open gap.
closed_citations() {
    for number in $(cited); do
        [ "$(state_of "$number")" = CLOSED ] && printf '%s\n' "$number"
    done
}

state_of() {
    gh issue view "$1" --json state -q .state 2>/dev/null
}

#
# **A link that 404s is worse than no link.** Two on the new-issue page pointed at discussions for
# months, and discussions were never enabled — #425. Nothing read the config, so nothing said.
#
# One question to the service, never a fetch of each page. A feature that is off cannot serve a
# link into it, and that is decidable without leaving the API.
links_the_service_refuses() {
    [ -f "$FORMS" ] || return 0

    grep -q '/discussions' "$FORMS" 2>/dev/null || return 0
    [ "$(discussions_are_on)" = true ] && return 0

    printf 'the config links into discussions, and this repository has them off
'
}

discussions_are_on() { gh repo view --json hasDiscussionsEnabled -q .hasDiscussionsEnabled 2>/dev/null; }

# --- the list a person keeps ---

exempt_count() { printf '%s\n' "$(exemptions)" | grep -c . ; }

exemptions() {
    [ -f "$DEBT" ] || return 0

    awk '!/^[ \t]*#/ && NF { print $1 }' "$DEBT"
}

not_exempt() {
    [ -n "$1" ] || return 0

    for number in $1; do
        exemptions | grep -qx "$number" || printf '#%s\n' "$number"
    done
}

# A line for an issue the page stopped citing is a record of a record. It says a judgement was made
# about something nobody asks about now.
exemptions_nobody_cites() {
    for number in $(exemptions); do
        printf '%s\n' "$(cited)" | grep -qx "$number" || printf '#%s\n' "$number"
    done
}

print_the_debt() {
    ensure_the_page_is_here
    ensure_the_forge_answers

    for number in $(closed_citations); do
        printf '%s  closed, and the page cites it — say why this is history\n' "$number"
    done
}

# --- the two refusals ---

ensure_the_page_is_here() {
    [ -f "$PAGE" ] && return 0

    fail 2 "stale: [$PAGE] is not here, so this read nothing"
}

# **`gh` missing and an issue missing give the same empty answer**, so the absence is asked about
# once, ahead of every read. Without this a tree with no `gh` reported every citation open.
ensure_the_forge_answers() {
    command -v gh >/dev/null 2>&1 || fail 3 'stale: no gh here, so nothing was read'

    gh auth status >/dev/null 2>&1 && return 0

    fail 3 'stale: gh is here and not signed in, so nothing was read'
}

# --- proving it can go red ---

#
# The whole point is a service answer, and a gate may not reach one. So the audit swaps the reader
# for a stub and drives both refusals against a page it writes itself.
#
prove_it_can_go_red() {
    work=$(mktemp -d) || fail 2 'stale: no temp directory'
    trap 'rm -rf "$work"' EXIT

    a_closed_citation_is_named "$work"
    an_exemption_nobody_cites_is_named "$work"

    a_link_the_service_does_not_serve "$work"

    say 'stale    every refusal goes red on a page that earns it'
}

a_closed_citation_is_named() {
    printf 'the gap is #4242, and nothing owns it\n' > "$1/page"
    : > "$1/debt"

    PAGE=$1/page DEBT=$1/debt
    state_of() { printf 'CLOSED'; }

    [ -n "$(not_exempt "$(closed_citations)")" ] && return 0

    fail 1 'stale: a closed citation with no exemption was not named'
}

an_exemption_nobody_cites_is_named() {
    printf 'the gap is #4242, and nothing owns it\n' > "$1/page"
    printf '9999  nobody cites this\n' > "$1/debt"

    PAGE=$1/page DEBT=$1/debt

    [ "$(exemptions_nobody_cites)" = '#9999' ] && return 0

    fail 1 'stale: an exemption nobody cites was not named'
}

a_link_the_service_does_not_serve() {
    printf 'url: https://x/discussions/new\n' > "$1/forms"

    FORMS=$1/forms
    discussions_are_on() { printf 'false'; }

    [ -n "$(links_the_service_refuses)" ] && return 0

    fail 1 'stale: a link into a feature that is off was not named'
}

# --- one voice ---

report() {
    [ -z "$2" ] && return 0

    printf 'FAIL  %s\n' "$1" >&2
    printf '%s\n' "$2" | sed 's/^/      /' >&2
    exit 1
}

say()  { printf '%s\n' "$1"; }
fail() { code=$1; shift; printf '%s\n' "$1" >&2; exit "$code"; }

main "$@"
