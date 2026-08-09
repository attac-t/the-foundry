#
# Read one top-level value out of a JSON object. No jq.
#
#   cat hook-input.json | awk -f unjson.awk -v key=last_assistant_message
#
# Prints the value with no trailing newline. Exits 0 if the key was there, 1 if not.
#
# This walks the object rather than searching it. The value we want is Claude's own text, and a
# reply that quotes `"stop_hook_active"` as prose would fool any search for the next matching key.
#
# `\uXXXX` becomes a space. An escape that survives to here is a symbol or an emoji, and neither
# changes a word count.
#
# POSIX awk only.
#

{ buf = buf $0 "\n" }

#
# Read the string starting at pos, unescaped. Sets ENDPOS to its closing quote.
#
function readstr(pos,   out, i, c, e) {
  out = ""
  i = pos + 1
  while (i <= LEN) {
    c = substr(BUF, i, 1)
    if (c == "\\") {
      e = substr(BUF, i + 1, 1)
      if      (e == "n") out = out "\n"
      else if (e == "t") out = out "\t"
      else if (e == "r") out = out ""
      else if (e == "b" || e == "f") out = out " "
      else if (e == "u") { out = out " "; i += 4 }
      else out = out e
      i += 2
      continue
    }
    if (c == "\"") { ENDPOS = i; return out }
    out = out c
    i++
  }
  ENDPOS = i
  return out
}

#
# Get the position just past the object or array starting at pos.
#
function skipnested(pos,   d, i, c) {
  d = 0
  i = pos
  while (i <= LEN) {
    c = substr(BUF, i, 1)
    if (c == "\"") { readstr(i); i = ENDPOS + 1; continue }
    if (c == "{" || c == "[") d++
    else if (c == "}" || c == "]") { d--; if (d == 0) return i + 1 }
    i++
  }
  return i
}

END {
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

    if (c == " " || c == "\t" || c == "\n" || c == "\r" || c == "," || c == ":") { i++; continue }
    if (c == "}") { depth--; i++; continue }
    if (c == "]") { i++; continue }

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
    lit = substr(BUF, i, j - i)
    if (depth == 1 && curkey == key) { printf "%s", lit; exit 0 }
    curkey = ""
    i = j
  }
  exit 1
}
