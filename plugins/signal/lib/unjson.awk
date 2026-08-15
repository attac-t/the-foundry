#
# Read one top-level value out of a JSON object. No jq.
#
#   cat hook-input.json | awk -f unjson.awk -v key=last_assistant_message
#
# Prints the value with no trailing newline. Exits 0 if the key was there, 1 if not.
#
# This walks the object rather than searching it. The value we want is the agent's own text, and a
# reply that quotes `"stop_hook_active"` as prose would fool any search for the next matching key.
#
# `\uXXXX` becomes a space. An escape that survives to here is a symbol or an emoji, and neither
# changes a word count.
#
# POSIX awk only.
#

BEGIN {
  ESC["n"] = "\n"
  ESC["t"] = "\t"
  ESC["r"] = ""
  ESC["b"] = " "
  ESC["f"] = " "
}

{ buf = buf $0 "\n" }

# Read the string starting at pos, unescaped. Sets ENDPOS to its closing quote.
function readstr(pos,   out, i, c, e) {
  out = ""
  i = pos + 1
  while (i <= LEN) {
    c = substr(BUF, i, 1)
    if (c == "\"") { ENDPOS = i; return out }
    if (c != "\\") { out = out c; i++; continue }

    e = substr(BUF, i + 1, 1)
    if (e == "u") { out = out " "; i += 6; continue }
    out = out ((e in ESC) ? ESC[e] : e)
    i += 2
  }
  ENDPOS = i
  return out
}

# Get the position just past the object or array starting at pos.
function skipnested(pos,   d, i, c) {
  d = 0
  i = pos
  while (i <= LEN) {
    c = substr(BUF, i, 1)
    if (c == "\"")             { readstr(i); i = ENDPOS + 1; continue }
    if (c == "{" || c == "[")  { d++; i++; continue }
    if (c == "}" || c == "]")  { d--; if (d == 0) return i + 1 }
    i++
  }
  return i
}

END {
  # Uppercase is what the functions share — BUF, LEN, ESC, and ENDPOS coming back. Everything else
  # below is END's own, which is why a function may declare its own `i` and leave this one alone.
  BUF = buf
  LEN = length(BUF)

  i = 1
  while (i <= LEN && substr(BUF, i, 1) != "{") i++
  if (i > LEN) exit 1
  i++
  depth = 1
  curkey = ""

  while (i <= LEN && depth > 0) {
    c = substr(BUF, i, 1)

    if (c ~ /[ \t\n\r,:]/)    { i++; continue }
    if (c == "}")             { depth--; i++; continue }
    if (c == "]")             { i++; continue }
    if (c == "{" || c == "[") { i = skipnested(i); curkey = ""; continue }

    if (c == "\"") {
      s = readstr(i)
      i = ENDPOS + 1
      j = i
      while (j <= LEN && substr(BUF, j, 1) ~ /[ \t\n\r]/) j++
      if (substr(BUF, j, 1) == ":") { curkey = s; i = j + 1; continue }
      if (depth == 1 && curkey == key) { printf "%s", s; exit 0 }
      curkey = ""
      continue
    }

    # `]` first so it is literal. A backslash inside a bracket expression is left to the
    # implementation by POSIX, and a strict reading would close the set early.
    j = i
    while (j <= LEN && substr(BUF, j, 1) !~ /[]},  \t\n\r]/) j++
    if (depth == 1 && curkey == key) { printf "%s", substr(BUF, i, j - i); exit 0 }
    curkey = ""
    i = j
  }
  exit 1
}
