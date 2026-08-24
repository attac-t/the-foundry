# Reports a three-line comment block that does not step down by three.
#
# Its own file, because inside a single-quoted string it was six jobs
# with no names at all — the shape `craft-sh`
# refuses, and a string is no excuse.
#
# Usage: awk -v wide=90 -v step=3 -f taper.awk file.sh

# Defaulted here, not left to the caller. `shell.sh` names this file through a
# variable, so a restore takes one and not the other. #341 owns that gap.
BEGIN {
    if (step == "") step = 3
    if (wide == "") wide = 90
}

{ line[FNR] = $0 }

END { for (i = 1; i <= FNR; i++) if (block_at(i)) grade(i) }

# Three of them, nothing above, code below.
function block_at(i) {
    return opens(i) && prose(line[i + 1]) && prose(line[i + 2]) && above_code(i)
}

function opens(i) { return prose(line[i]) && !prose(line[i - 1]) }

# A shebang is not a sentence, and a bare `#` fences
# a paragraph rather than starting one. Both read
# as comment lines, and neither opens a taper.
function prose(said) {
    return said ~ /^#/ && said !~ /^#[[:space:]]*$/ && said !~ /^#!/
}

# The line under the block. Blank means the comment is
# floating, and another `#` means the block runs on
# past three lines, which this one cannot grade.
function above_code(i) {
    return line[i + 3] ~ /[^[:space:]]/ && line[i + 3] !~ /^#/
}

# Prose wrapped at the margin lands near a hundred
# and is not a taper. Nobody hand-shapes a line
# that wide, so a wide opener is left alone.
function grade(i,   a, b, c) {
    a = length(line[i]); b = length(line[i + 1]); c = length(line[i + 2])

    if (a >= wide || steps_by(a, b, c)) return
    printf "    %s:%d  %d %d %d  (steps %d %d, want %d %d)\n", \
        FILENAME, i, a, b, c, a - b, b - c, step, step
}

# Three bytes each time, and the same three twice.
# An even wedge that steps by eighteen reads as
# a triangle, which is the shape it refuses.
function steps_by(a, b, c) { return a - b == step && b - c == step }
