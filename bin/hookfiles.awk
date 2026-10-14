#
# The top-level keys of one JSON object, a line each, however the file is laid out. #1074.
#
# A key is a string at depth one with a colon after it. A string is skipped whole, escapes and all,
# so key-like text inside one is never read, and depth counts braces outside strings only.
{ text = text $0 "\n" }

END {
    depth = 0; n = length(text); i = 1
    while (i <= n) {
        c = substr(text, i, 1)
        if (c == "\"") { i = a_string_from(i); continue }
        if (c == "{" || c == "[") depth++
        if (c == "}" || c == "]") depth--
        i++
    }
}

# Read the string opening at `at`, print it when it is a top-level key, and say where to read on.
function a_string_from(at,   end) {
    end = end_of_string(at)
    if (depth == 1 && colon_follows(end)) print substr(text, at + 1, end - at - 1)
    return end + 1
}

function end_of_string(at,   j, ch) {
    for (j = at + 1; j <= n; j++) {
        ch = substr(text, j, 1)
        if (ch == "\\") { j++; continue }
        if (ch == "\"") return j
    }
    return n
}

function colon_follows(at,   j, ch) {
    for (j = at + 1; j <= n; j++) {
        ch = substr(text, j, 1)
        if (ch ~ /[ \t\r\n]/) continue
        return ch == ":"
    }
    return 0
}
