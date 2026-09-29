#!/bin/sh
#
# The shaping entry point this plugin ships for one harness. A repository names it on a `shape` line,
# as `@adapter anthropic` and the digest of this file, and floor checks that digest before it runs it.
#
# **Pinned apart from the judge.** `run.sh` beside it is the judge's, and an edit to either moves only
# its own pin. So this sources no file: a helper shared with `run.sh` would let an edit there change
# what shapes under a pin nobody moved. Its suite runs it copied alone into an empty directory.
#
# Floor hands it one thing, `FOUNDRY_BRIEF`: the attempt's brief. This quotes it whole after a short
# frame of its own, asks the harness, and prints the model's words on stdout. Its notes go to stderr.
#
# **The harness gets no built-in tool, and no MCP server from a config file**:
#
#     claude -p --model opus --output-format json --tools "" --strict-mcp-config --no-session-persistence
#
# `--tools ""` drops each built-in tool, and MCP tools stay loaded. `--strict-mcp-config`, naming no
# config, loads no MCP server from any file. Once, on 2.1.284 with account connectors signed in, the
# call listed no tool and no MCP server. Which flag dropped the connectors is unmeasured, and so is
# what a plugin's own server does. `--no-session-persistence` keeps no session on disk.
#
# **Without `--bare`, the host's CLAUDE.md, auto memory, plugins, skills and hooks all load.** Floor
# runs this in an empty directory, and `~/.claude` is still the host's. `--bare` would skip them, but
# it reads an API key and never a login, so on a host that signs in every call would be missing.
#
# Exit, a contract of its own and never a judge's:
#
#     0  a model answered this call, whatever it said
#     1  no model answered: no harness, a harness that failed, or an answer with no words
#     2  floor handed it nothing: no brief, or one it cannot read
#
# **Every failure it knows is 1**: text where JSON should be, `"is_error":true`, an empty result, a
# harness exit that is not 0, and no `claude` on the path. A failure it does not know, inside a result
# at `"is_error":false`, reads as the model's words, and floor refuses it as prose.
#
# `set -e` is off: a harness that fails is an answer here, read and said, never a stop.
#
# Usage: floor sets FOUNDRY_BRIEF and runs it. `audit` runs its stub table alone.

set -u

readonly MODEL=opus

here=$(cd "$(dirname "$0")" && pwd)

main() {
    [ "${1:-}" = audit ] && { bash "$here/tests/shape.sh"; return $?; }

    ensure_floor_handed_a_brief
    reachable || { note "claude is not on this host, so no model answered"; return 1; }

    said=$(ask); asked=$?
    [ "$asked" -eq 0 ] || { note "the harness exited $asked, so no model answered"; return 1; }

    say_the_result "$said"
}

ensure_floor_handed_a_brief() {
    [ -n "${FOUNDRY_BRIEF:-}" ] && [ -r "${FOUNDRY_BRIEF:-}" ] && return 0

    note "no brief to read, so nothing was asked"
    exit 2
}

# Whether it is on this host at all. **There is no second answer.**
reachable() { command -v claude >/dev/null 2>&1; }

#
# The prompt goes over stdin, since argv has a length nobody agrees on. The harness's own stderr
# passes through, so floor puts its last line beside a missing call.
#
ask() {
    prompt_from "$FOUNDRY_BRIEF" |
        claude -p --model "$MODEL" --output-format json --tools "" --strict-mcp-config --no-session-persistence
}

#
# The brief whole, after a frame of this adapter's own. Floor's brief already says what a line may
# be, so the frame says only how the member works: apart, with no tool, and in those lines alone.
#
prompt_from() {
    cat <<'EOF'
You are one member of a panel. Before any work starts on the item below, you propose what the work
should be judged against. You work apart from the other members, and you have no tool: read the
brief below and answer from it alone.

Answer only in the lines the brief describes, one to a line. Write nothing else: no heading, no
fence, and no sentence of your own around them.

EOF
    cat "$1"
}

# What came back, read as one JSON object: its result printed as bytes, or 1 and a note saying why.
say_the_result() { printf '%s\n' "$1" | LC_ALL=C awk "$THE_RESULT"; }

note() { printf 'shape: %s\n' "$1" >&2; }

#
# **The reader, whole, in this file.** A program this long wants a file of its own, and this one may
# not have one: the entry point sources nothing, so the reader stays where its pin can see it.
#
# The value of a top-level key is found past its name, a colon and any space. `"type":"result"` holds
# the key's name as a value, and no value is followed by a colon, so it is passed over.
#
# A string's escapes are decoded to bytes, `\uXXXX` and its surrogate pair to UTF-8, under `LC_ALL=C`
# so `%c` writes one byte. Raw UTF-8 needs nothing: every byte that is not an escape passes through.
#
THE_RESULT='
BEGIN { name_the_escapes() }

{ json = json $0 "\n" }

END { answer() }

function answer(   said) {
    if (json !~ /[^ \t\r\n]/) { say("the harness printed nothing"); exit 1 }
    if (!value_at("is_error")) { say("the harness answered in text, not JSON: " first_line()); exit 1 }

    said = string_of("result")
    if (literal_of("is_error") != "false") { say("the harness answered with an error: " flat(said)); exit 1 }
    if (said !~ /[^ \t\r\n]/) { say("the harness answered with no words"); exit 1 }

    printf "%s", said
}

function name_the_escapes() {
    plain["\""] = "\""; plain["\\"] = "\\"; plain["/"] = "/"
    plain["b"] = "\b"; plain["f"] = "\f"; plain["n"] = "\n"; plain["r"] = "\r"; plain["t"] = "\t"
}

function value_at(key,   quoted, from, at) {
    quoted = "\"" key "\""
    from = 1
    while ((at = index(substr(json, from), quoted)) > 0) {
        from += at - 1 + length(quoted)
        if (match(substr(json, from), /^[ \t\r\n]*:[ \t\r\n]*/)) return from + RLENGTH
    }
    return 0
}

function literal_of(key,   at) {
    at = value_at(key)
    if (!at) return ""

    match(substr(json, at), /^[a-z]+/)
    return substr(json, at, RLENGTH)
}

function string_of(key,   at) {
    at = value_at(key)
    if (!at || substr(json, at, 1) != "\"") return ""
    return decoded(at + 1)
}

# The bytes one string stands for, up to its closing quote. One with none stands for nothing.
function decoded(at,   out, c, n) {
    n = length(json)
    while (at <= n) {
        c = substr(json, at, 1)
        if (c == "\"") return out
        if (c != "\\") { out = out c; at++; continue }

        out = out escaped(at)
        at += step
    }
    return ""
}

# One escape at `at`, and in `step` how many bytes it spans.
function escaped(at,   e, high, low) {
    e = substr(json, at + 1, 1)
    step = 2
    if (e in plain) return plain[e]
    if (e != "u") return e

    high = hex(substr(json, at + 2, 4))
    step = 6
    if (high < 55296 || high > 56319 || substr(json, at + 6, 2) != "\\u") return utf8(high)

    low = hex(substr(json, at + 8, 4))
    if (low < 56320 || low > 57343) return utf8(high)
    step = 12
    return utf8(65536 + (high - 55296) * 1024 + (low - 56320))
}

function hex(said,   i, n) {
    for (i = 1; i <= length(said); i++) n = n * 16 + index("0123456789abcdef", tolower(substr(said, i, 1))) - 1
    return n
}

function utf8(cp) {
    if (cp < 128) return sprintf("%c", cp)
    if (cp < 2048) return sprintf("%c%c", 192 + int(cp / 64), 128 + cp % 64)
    if (cp < 65536) return sprintf("%c%c%c", 224 + int(cp / 4096), 128 + int(cp / 64) % 64, 128 + cp % 64)
    return sprintf("%c%c%c%c", 240 + int(cp / 262144), 128 + int(cp / 4096) % 64, 128 + int(cp / 64) % 64, 128 + cp % 64)
}

function first_line(   line) {
    line = json
    sub(/^[ \t\r\n]+/, "", line)
    sub(/[\r\n].*/, "", line)
    return line
}

function flat(said) { gsub(/[\r\n]+/, " ", said); return said }

function say(what) { printf "shape: %s\n", what | "cat 1>&2" }
'

main "$@"
