#
# Read one value out of a hook payload, addressed by a dotted path. No jq.
#
#   cat payload.json | awk -f unjson.awk -v path=tool_input.file_path
#
# Prints the value with no trailing newline. Exits 0 if the path was there, 1 if not.
#
# kernel ships its own reader rather than borrowing signal's. A plugin installs alone, so anything
# it needs at runtime has to sit inside it. The two are not the same reader either: signal reads
# top-level keys and steps over everything nested, and the field kernel wants is nested.
#
# This walks the object rather than searching it. `"file_path"` is an ordinary string, and a
# PostToolUse payload carries the file being written inside it — write a JSON fixture and the
# content holds the very key we are looking for. A search finds the wrong one. A walk knows the
# difference between a key at depth two and the same letters inside a value.
#
# Arrays are stepped over whole. Nothing kernel reads lives inside one, and an index syntax nobody
# calls is a thing to keep working for no one.
#
# `\uXXXX` becomes a space. What survives to here is a symbol or an emoji, and a path is matched,
# never measured.
#
# POSIX awk only.
#

BEGIN {
  esc["n"] = "\n"
  esc["t"] = "\t"
  esc["r"] = ""
  esc["b"] = " "
  esc["f"] = " "
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
    out = out ((e in esc) ? esc[e] : e)
    i += 2
  }
  ENDPOS = i
  return out
}

# Get the position just past the array starting at pos.
function skiparray(pos,   d, i, c) {
  d = 0
  i = pos
  while (i <= LEN) {
    c = substr(BUF, i, 1)
    if (c == "\"")            { readstr(i); i = ENDPOS + 1; continue }
    if (c == "[" || c == "{") { d++; i++; continue }
    if (c == "]" || c == "}") { d--; if (d == 0) return i + 1 }
    i++
  }
  return i
}

# Get the dotted path down to where the cursor now stands.
function here(   d, p) {
  p = ""
  for (d = 1; d <= depth; d++) p = (d == 1) ? stack[d] : p "." stack[d]
  return p
}

END {
  BUF = buf
  LEN = length(BUF)

  i = 1
  while (i <= LEN && substr(BUF, i, 1) != "{") i++
  if (i > LEN) exit 1

  depth = 0

  while (i <= LEN) {
    c = substr(BUF, i, 1)

    if (c ~ /[ \t\n\r,:]/) { i++; continue }
    if (c == "{")          { depth++; stack[depth] = ""; i++; continue }
    if (c == "}")          { depth--; if (depth < 1) exit 1; i++; continue }
    if (c == "[")          { i = skiparray(i); continue }

    # A string is a key when a colon follows it, and a value when one does not.
    if (c == "\"") {
      s = readstr(i)
      i = ENDPOS + 1
      j = i
      while (j <= LEN && substr(BUF, j, 1) ~ /[ \t\n\r]/) j++
      if (substr(BUF, j, 1) == ":") { stack[depth] = s; i = j + 1; continue }
      if (here() == path) { printf "%s", s; exit 0 }
      continue
    }

    # A number, or true, false, null. `]` leads the set so it reads as a literal: POSIX leaves a
    # backslash inside a bracket expression to the implementation, and a strict awk would take the
    # escape as the end of the set.
    j = i
    while (j <= LEN && substr(BUF, j, 1) !~ /[]},  \t\n\r]/) j++

    # Every branch above moves the cursor, and this one has to as well. A stray `]` is its own
    # terminator, so the scan stops where it started and the walk reads the same character forever.
    # Malformed JSON should cost an exit code, never a hung hook waiting out its timeout.
    if (j == i) { i++; continue }

    if (here() == path) { printf "%s", substr(BUF, i, j - i); exit 0 }
    i = j
  }
  exit 1
}
