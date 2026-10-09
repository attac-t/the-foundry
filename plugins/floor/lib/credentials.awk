#
# The credential shapes floor reads a carried text for. It prints the earliest row the text holds,
# and nothing when it holds none. #1126.
#
# A row is a prefix, the run of characters after it, and the least that run may be. The run is
# counted here, since an interval like `{40}` is not in every awk.

BEGIN {
    row("a GitHub token", "gh[pousr]_", "[A-Za-z0-9]", 36)
    row("a GitHub token", "github_pat_", "[A-Za-z0-9_]", 22)
    row("a private key", "-----BEGIN [A-Z ]*PRIVATE KEY-----", "", 0)
    row("an AWS access key", "A[KS]IA", "[A-Z0-9]", 16)
    row("a model vendor's API key", "sk-(ant|proj)-", "[A-Za-z0-9_-]", 20)
    in_either_case("a signed link", "x-(amz|goog)-signature=", "[0-9a-f]", 64)
    row("a signed link", "sig=", "[A-Za-z0-9%+/=_-]", 46)
}

{ for (i = 1; i <= rows; i++) if (!(i in held) && holds(as_read(i, $0), i)) held[i] = 1 }

END { for (i = 1; i <= rows; i++) if (i in held) { print shape[i]; exit } }

function row(name, start, run, fewest) {
    rows++
    shape[rows] = name; prefix[rows] = start; runs[rows] = run; least[rows] = fewest
}

function in_either_case(name, start, run, fewest) { row(name, start, run, fewest); folded[rows] = 1 }

# A row read in either case sees the line in lower case, so its prefix and run are written so.
function as_read(i, line) { return (i in folded) ? tolower(line) : line }

# Every match of the prefix is read, not only the first, so a short one cannot hide a long one.
function holds(line, i,   rest) {
    rest = line
    while (match(rest, prefix[i])) {
        rest = substr(rest, RSTART + RLENGTH)
        if (run_at(rest, runs[i]) >= least[i]) return 1
    }
    return 0
}

# How many characters of the run open the text. A row with no run counts none.
function run_at(text, run) {
    if (run == "" || !match(text, "^" run "+")) return 0
    return RLENGTH
}
