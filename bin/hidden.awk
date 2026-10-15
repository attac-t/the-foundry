# Each bare `|| return 0` after a command or a capture, inside a function some shipped file captures.
#
# The first file is the captured names, one a line; the second is the shipped file to read. A line
# is named unless the one above it opens `# empty:`. Read by `bin/shell.sh`, which says why. #1160.

FILENAME == ARGV[1] { captured[$0] = 1; next }

FNR == 1 { inside = ""; above = "" }

/^[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)[ \t]*\{/ { inside = $0; sub(/[ \t]*\(.*/, "", inside) }

!/^[ \t]*#/ && (inside in captured) && hides_a_failure($0) && above !~ /^[ \t]*# empty:/ {
    printf "  %s:%d %s\n", FILENAME, FNR, $0
}

/^\}/ || /^[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)[ \t]*\{.*\}[ \t]*$/ { inside = "" }

{ above = $0 }

# The left side failed and the answer is nothing. A `[ ]` test there is a guard, and fails by design.
function hides_a_failure(line,    left) {
    if (!match(line, /\|\|[ \t]*return 0([ \t;}#]|$)/)) return 0
    left = substr(line, 1, RSTART - 1)
    sub(/^[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)[ \t]*\{/, "", left)
    sub(/^[ \t]+/, "", left)
    return left !~ /^(!|\{)?[ \t]*\[ /
}
