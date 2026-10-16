#
# Every code a function reached from `start` can leave with, one a line: `code<TAB>where`.
#
# Reads the runner twice: once for the functions it defines, once for what each body calls, returns
# and exits with.
#
# **Wide, never narrow.** A word in command position that names a function is a call, so a function
# the graph cannot rule out is reached. A code it adds wrongly is noise. One it drops is a run let go
# unseen, which is the fault #1159 names.
#
# **An exit through a variable is resolved or named, never dropped.** `exit "$3"` takes the third
# argument at each call from a reached function. `exit "$?"` takes every code the function it
# captured exits or returns with. Anything else, or an argument that is no number, prints `?`.
#
# **An exit belongs to the function it sits in.** `bin/refusals.sh` credits a guard's exit to the
# callee it guards, so `source_says` would lend `reconcile`'s 25 to `deliver`, and a page would say a
# run is let go on a code it never meets. The statement rule is refusals.sh's: prose names no code.
#

FNR == 1 { part++ }

part == 1 { if (match($0, /^[a-z_][a-z0-9_]*\(\) *[{(]/)) { f = $0; sub(/\(\).*/, "", f); defined[f] = 1 }; next }

match($0, /^[a-z_][a-z0-9_]*\(\) *[{(]/) {
    fn = $0; sub(/\(\).*/, "", fn)
    read_the_line(substr($0, RLENGTH + 1))
    if ($0 ~ /[})][ \t]*$/) fn = ""
    next
}

/^[})]/ { fn = ""; next }

fn != "" { read_the_line($0) }

function read_the_line(line,    words, w, rest, held) {
    sub(/^[ \t]*#.*/, "", line)
    gsub(/\047[^\047]*\047/, "", line)
    exits_through_a_variable(line)
    exits_by_number(line)

    held = line
    while (match(held, /return[ \t]+[0-9]+/)) {
        returned[fn] = returned[fn] " " substr(held, RSTART + 7, RLENGTH - 7)
        held = substr(held, RSTART + RLENGTH)
    }

    words = " " line
    while (match(words, /(^|[;&|({!]|\$\(|then |do |else )[ \t]*[a-z_][a-z0-9_]*/)) {
        w = substr(words, RSTART, RLENGTH); sub(/^.*[^a-z0-9_]/, "", w)
        rest = substr(words, RSTART + RLENGTH)
        words = rest
        if (!(w in defined) || w == fn) continue

        calls[fn, w] = 1
        sub(/[;|&)}].*/, "", rest)
        call_count[w]++
        call_from[w, call_count[w]] = fn
        call_args[w, call_count[w]] = rest
    }
}

function exits_by_number(line,    code) {
    while (match(line, /(^[ 	]*|[;{}&|][ 	]*)exit [0-9]+[ 	]*($|[;}])/)) {
        code = substr(line, RSTART, RLENGTH)
        sub(/^.*exit /, "", code); sub(/[^0-9].*/, "", code)
        site[fn] = site[fn] " " code
        line = substr(line, RSTART + RLENGTH)
    }
}

function exits_through_a_variable(line,    held, captured) {
    while (match(line, /exit[ \t]+"?\$[a-zA-Z_0-9?]+"?/)) {
        held = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        sub(/^exit[ \t]+"?\$/, "", held); sub(/"$/, "", held)

        if (held ~ /^[1-9]$/) { by_argument[fn] = by_argument[fn] " " held; continue }
        if (held == "?" && (captured = the_capture($0)) in defined) { inherits[fn] = inherits[fn] " " captured; continue }

        unresolved[fn] = 1
    }
}

function the_capture(line,    name) {
    if (!match(line, /\$\([ \t]*[a-z_][a-z0-9_]*/)) return ""
    name = substr(line, RSTART + 2, RLENGTH - 2); gsub(/[ \t]/, "", name)
    return name
}

END {
    reach[start] = 1
    for (grew = 1; grew; ) {
        grew = 0
        for (pair in calls) {
            split(pair, ends, SUBSEP)
            if ((ends[1] in reach) && !(ends[2] in reach)) { reach[ends[2]] = 1; grew = 1 }
        }
    }

    for (f in reach) {
        n = split(site[f], codes, " ")
        for (i = 1; i <= n; i++) print codes[i] "\t" f
        if (f in unresolved) print "?\t" f
        each_argument_code(f)
        each_inherited_code(f)
    }
}

function each_argument_code(f,    k, positions, p, i, arg, args) {
    if (!(f in by_argument)) return
    k = split(by_argument[f], positions, " ")
    for (p = 1; p <= k; p++) for (i = 1; i <= call_count[f]; i++) {
        if (!(call_from[f, i] in reach)) continue
        split(call_args[f, i], args, /[ \t]+/)
        arg = args[positions[p] + 1]; gsub(/"/, "", arg)
        print ((arg ~ /^[0-9]+$/) ? arg : "?") "\t" f " from " call_from[f, i]
    }
}

function each_inherited_code(f,    k, names, i, n, codes, j) {
    if (!(f in inherits)) return
    k = split(inherits[f], names, " ")
    for (i = 1; i <= k; i++) {
        n = split(site[names[i]] " " returned[names[i]], codes, " ")
        for (j = 1; j <= n; j++) print codes[j] "\t" f " through " names[i]
    }
}
