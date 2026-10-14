# Each `.foundry/` path a file's code names, as `<name>\t<file>:<line>`, and `?` for a path whose
# name is not spelled out. A line whose first non-blank character is `#` is prose and names nothing.
#
# With `-v within=<function>`, only that function's pathspec is read: the names after ` -- `, up to
# a redirect, a comment or a separator. A name anywhere else in it refuses nothing. #1184.

FNR == 1 { inside = (within == "") }

within != "" && index($0, within "() {") == 1 { open_the_refusal(); next }
within != "" && inside && /^}/                { inside = 0 }

!inside { next }

{ bare = $0; sub(/^[ \t]+/, "", bare) }
bare ~ /^#/ { next }

within != "" { read_the_pathspec(FILENAME ":" FNR, $0); next }

{ name_each(FILENAME ":" FNR, $0) }

# The signature line can hold the whole body, and then it closes on the same line.
function open_the_refusal(   rest) {
    rest = substr($0, length(within "() {") + 1)
    inside = (rest !~ /}[ \t]*$/)
    read_the_pathspec(FILENAME ":" FNR, rest)
}

function read_the_pathspec(where, line) {
    if (!index(line, " -- ")) return
    line = substr(line, index(line, " -- ") + 4)
    sub(/[ \t]*([0-9]?>|#|;|\||&|\)|}).*$/, "", line)
    name_each(where, line)
}

# Taken whole, digits and capitals with it, and a dot only between two parts, so a full stop ending
# a sentence is not read as part of a name.
function name_each(where, line) {
    while (match(line, /\.foundry\//)) {
        line = substr(line, RSTART + RLENGTH)
        if (match(line, /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*/)) print substr(line, 1, RLENGTH) "\t" where
        else print "?\t" where
    }
}
