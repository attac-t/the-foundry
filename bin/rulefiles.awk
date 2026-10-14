# Each `.foundry/` path a file's code names, as `<name>\t<file>:<line>`, and `?` for a path whose
# name is not spelled out. A line whose first non-blank character is `#` is prose and names nothing.
#
# With `-v within=<function>` only that function's body is read: the refusal. #1184.

FNR == 1 { inside = (within == "") }

within != "" && index($0, within "() {") == 1 { inside = 1; next }
within != "" && inside && /^}/                { inside = 0 }

!inside { next }

{ bare = $0; sub(/^[ \t]+/, "", bare) }
bare ~ /^#/ { next }

{ name_each(FILENAME ":" FNR, $0) }

# Taken whole, digits and capitals with it, and a dot only between two parts, so a full stop ending
# a sentence is not read as part of a name.
function name_each(where, line) {
    while (match(line, /\.foundry\//)) {
        line = substr(line, RSTART + RLENGTH)
        if (match(line, /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*/)) print substr(line, 1, RLENGTH) "\t" where
        else print "?\t" where
    }
}
