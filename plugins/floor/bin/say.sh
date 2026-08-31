#!/bin/sh
#
# Render one public comment from named fields, or refuse to.
#
#   sh bin/say.sh --kind finding --subject '#416' --was proposed --now approved \
#                 --because '...' --next '...' --evidence 507a735 < published.txt
#
# **A comment is an interface, never a log.** `.claude/rules/writing.md` said so, and so did
# `product:cycle`, and so did a goal record. Guidance was in three places and an agent still posted
# twelve kilobytes of session ids, token counts and a duplicated transcript to a public thread.
#
# So this takes fields, never prose. Nothing reaches the body that was not named.
#
# **What this is not.** It cannot stop a caller running `gh` directly, because it holds no
# credential and the caller does. Two consultations at maximum effort agreed on that, separately:
# the only control that binds is a comment credential the automated worker cannot reach, and a
# person has to hold it. `bin/comments.sh` reads the public thread back and re-runs every rule here
# on what it finds, which is detection after the fact, not prevention. #419 owns the credential.
#
# Exit codes:
#
#   0   the body is on stdout
#   2   a field is missing, or the kind is not one of the three
#  50   no delta, and this kind needs one
#  51   this key is already on the thread
#  52   a field carries a session id, a token count, or a transcript
#  53   the evidence names nothing
#  54   over 180 words or 1,200 characters
#
# Stdin is the thread as it stands — every comment already published, concatenated. That is the
# ledger. A file beside the run would be one the same worker writes, and neither consultation would
# call that evidence.
#

set -u

kind=; subject=; was=; now=; because=; next=; evidence=; thread=; key=; found=

main() {
    read_arguments "$@"

    # Never `cat` bare. At a terminal that waits for ever, and the caller sees a hang with no
    # message — the one failure a refusal cannot explain.
    [ -t 0 ] && fail 2 'the thread arrives on stdin. Pass the published comments, or </dev/null'
    thread=$(cat)
    refuse_a_kind_nobody_named
    refuse_a_missing_field

    key=$(derive_key)

    refuse_no_delta
    refuse_a_key_already_said
    refuse_a_field_that_is_a_log
    refuse_evidence_naming_nothing

    body=$(render)
    refuse_a_body_too_long "$body"

    printf '%s\n' "$body"
}

# A flag with no value leaves `shift 2` short, so the loop never ends and the next flag becomes a
# value. Every one is guarded.
read_arguments() {
    while [ "$#" -gt 0 ]; do
        [ "$#" -ge 2 ] || fail 2 "[$1] takes a value"
        case $1 in
            --kind)     kind=$2     ;;
            --subject)  subject=$2  ;;
            --was)      was=$2      ;;
            --now)      now=$2      ;;
            --because)  because=$2  ;;
            --next)     next=$2     ;;
            --evidence) evidence=$2 ;;
            *)          fail 2 "[$1] is not a field this renders" ;;
        esac
        shift 2
    done
}

#
# Three kinds, and the list is closed.
#
# A fourth would be a caller's opinion about what deserves interrupting a subscriber. The whole
# defect this exists for was a run deciding that for itself.
refuse_a_kind_nobody_named() {
    case $kind in
        finding|decision|closure) return 0 ;;
    esac
    fail 2 'a comment is a finding, a decision or a closure'
}

refuse_a_missing_field() {
    [ -n "$subject"  ] || fail 2 'name what it is about'
    [ -n "$because"  ] || fail 2 'say what follows from it'
    [ -n "$next"     ] || fail 2 'say the next action, or the state it ends in'
    [ -n "$evidence" ] || fail 2 'name what can be checked'
}

# Derived, never given. A caller choosing its own key can publish the same thing twice by choosing
# twice — which both consultations named, unprompted.
derive_key() { printf '%s %s %s %s' "$kind" "$subject" "$was" "$now" | cksum | awk '{ print $1 }'; }

#
# A finding says what changed. Without a delta it is a status line, and status lines are what
# filled the thread.
#
# A decision and a closure are irreversible on their own, so neither needs one.
refuse_no_delta() {
    [ "$kind" = finding ] || return 0
    [ -n "$was" ] && [ -n "$now" ] && [ "$was" != "$now" ] && return 0

    fail 50 'a finding names what was true and what is true now, and they differ'
}

# The thread is the ledger. A key already on it was already said.
refuse_a_key_already_said() {
    # The whole marker, never the number alone. Keys are variable-length decimals, so `seam:123`
    # matched inside `seam:1234` and refused a key nobody had published.
    case $thread in
        *"<!-- seam:$key -->"*) fail 51 "[$key] is already on this thread" ;;
    esac
    return 0
}

#
# What leaked, named exactly.
#
# Not a noise regex — both consultations refused that, and a regex over prose is a filter a caller
# learns to phrase around. These are the field shapes that got published: a session identifier, a
# token count, a transcript marker.
refuse_a_field_that_is_a_log() {
    found=$(printf '%s %s %s %s %s %s' "$subject" "$was" "$now" "$because" "$next" "$evidence" | awk '
        BEGIN { IGNORECASE = 1 }
        /session id|session_id|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}/ { print "a session id"; exit }
        /tokens used|token count|input tokens|output tokens/         { print "a token count"; exit }
        /exec |thinking|```/                                         { print "a transcript"; exit }
        /seam:/                                                      { print "a seam marker"; exit }
    ')

    [ -z "$found" ] || fail 52 "this carries $found"
}

# A reference nobody can follow is the claim it was meant to replace.
refuse_evidence_naming_nothing() {
    case $evidence in
        none|n/a|-|pending) fail 53 'evidence names nothing that can be checked' ;;
    esac
    return 0
}

#
# One shape, drawn the same way every time.
#
# **Fixed on purpose.** `bin/comments.sh` reads the marker back and re-runs three of the six refusals
# on what landed. It does not re-derive this body and compare it byte for byte — its own read folds
# newlines to spaces, so a byte match through it is impossible by design.
#
# The marker is not a stamp and claims nothing about who wrote it. Whoever holds the account can type
# one. It says which key was published, so the same thing is not said twice.
render() {
    printf '**%s** — %s\n\n' "$(title_for "$kind")" "$subject"
    [ -n "$was" ] && printf '%s → %s\n\n' "$was" "$now"
    printf '%s\n\n' "$because"
    printf '%s\n\n' "$next"
    printf 'Evidence: %s\n\n' "$evidence"
    printf '<!-- seam:%s -->\n' "$key"
}

title_for() {
    case $1 in
        finding)  printf 'Finding'  ;;
        decision) printf 'Decision' ;;
        closure)  printf 'Closed'   ;;
    esac
}

#
# 180 words or 1,200 characters, whichever comes first.
#
# **The count is the last refusal, never the first.** Everything above it is the allowlist, and a
# caller who compressed noise to fit still fails those. A limit reached by shortening prose is one
# that taught the caller to write denser noise.
refuse_a_body_too_long() {
    words=$(printf '%s' "$1" | wc -w | tr -d ' ')
    chars=$(printf '%s' "$1" | wc -c | tr -d ' ')

    [ "$words" -le 180 ]  || fail 54 "$words words, and 180 is the limit"
    [ "$chars" -le 1200 ] || fail 54 "$chars characters, and 1200 is the limit"
}

# One voice. Every refusal says the number and the reason, on stderr, so a caller reading stdout
# gets a body or nothing at all.
fail() {
    printf 'say: %s\n' "$2" >&2
    exit "$1"
}

main "$@"
