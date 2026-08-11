#
# Find markdown tables whose pipes do not line up on screen. Prints the line each one starts on.
#
#   LC_ALL=C awk -f tables.awk notes.md
#
# Prints nothing when every table lines up. Exits 0 either way — the caller decides what a finding
# is worth. Exits 2 when it was invoked wrong, which is not the same as a clean file.
#
# `LC_ALL=C` is not decoration. This decodes UTF-8 by hand, so `substr` has to hand back bytes.
# mawk counts bytes already, gawk counts characters under a UTF-8 locale, and BSD awk changes its
# mind with the environment. One of those three gives every width here a different answer. Byte mode
# is the only setting all three agree on, so the file checks for it and refuses rather than guess.
#
# It reports and never repads. The repad is arithmetic over the cells and belongs where a whole
# repo can be swept at once — see bin/tables.sh in the-foundry. Here the model is already mid-write,
# so naming the table it just broke is enough to get it fixed.
#
# POSIX awk only.
#

BEGIN {
  # A byte to its number. Byte 0 is skipped: no text file carries one, and awk strings end at it.
  for (i = 1; i < 256; i++) ord[sprintf("%c", i)] = i

  if (length("é") != 2) {
    print "tables.awk: run me under LC_ALL=C — I decode UTF-8 myself." > "/dev/stderr"
    exit 2
  }

  # Codepoints that take two columns instead of one, from Unicode's East Asian Width table.
  #
  # The symbol blocks are listed exactly, because narrow and wide sit side by side there and real
  # documents use both — `✓` U+2713 is one column, `✅` U+2705 is two. The emoji planes above the
  # BMP are swept whole. Nearly every codepoint in them is wide, and listing the handful that are
  # not would cost more to maintain than it could ever catch in a markdown table.
  #
  # Ambiguous width is treated as one column. It resolves to two only in a CJK locale, and reading
  # it as two would break every table that is currently right.
  spread("1100-115F 231A-231B 2329-232A 23E9-23EC 23F0 23F3 25FD-25FE 2614-2615 2648-2653" \
         " 267F 2693 26A1 26AA-26AB 26BD-26BE 26C4-26C5 26CE 26D4 26EA 26F2-26F3 26F5 26FA" \
         " 26FD 2705 270A-270B 2728 274C 274E 2753-2755 2757 2795-2797 27B0 27BF 2B1B-2B1C" \
         " 2B50 2B55 2E80-303E 3041-33FF 3400-4DBF 4E00-9FFF A000-A4CF A960-A97F AC00-D7A3" \
         " F900-FAFF FE10-FE19 FE30-FE6F FF00-FF60 FFE0-FFE6" \
         " 16FE0-187F7 1F300-1F9FF 1FA70-1FAFF 20000-3FFFD")
}

# Read the range list into LO[] and HI[]. "4E00-9FFF" is a span, "2705" is one codepoint.
function spread(spec,   parts, count, i, edges) {
  count = split(spec, parts, " ")
  for (i = 1; i <= count; i++) {
    if (split(parts[i], edges, "-") == 2) { LO[i] = hex(edges[1]); HI[i] = hex(edges[2]); continue }
    LO[i] = hex(parts[i]); HI[i] = LO[i]
  }
  SPANS = count
}

# Hex text to a number. POSIX awk has no strtonum, and Unicode is written in hex.
function hex(text,   digits, i, value, place) {
  digits = "0123456789ABCDEF"
  value = 0
  for (i = 1; i <= length(text); i++) {
    place = index(digits, toupper(substr(text, i, 1)))
    value = value * 16 + place - 1
  }
  return value
}

function wide(code,   i) {
  for (i = 1; i <= SPANS; i++) if (code >= LO[i] && code <= HI[i]) return 1
  return 0
}

# Fold the continuation bytes after `pos` into the codepoint a lead byte started.
function fold(row, pos, size, code,   k) {
  for (k = 1; k < size; k++) code = code * 64 + ord[substr(row, pos + k, 1)] - 128
  return code
}

# The codepoint at `pos`, setting SIZE to the bytes it spans. A byte under 192 stands alone: ASCII,
# or a stray continuation byte that belongs to nothing.
function decode(row, pos,   lead) {
  lead = ord[substr(row, pos, 1)]
  if (lead < 192) { SIZE = 1; return lead }
  if (lead < 224) { SIZE = 2; return fold(row, pos, 2, lead - 192) }
  if (lead < 240) { SIZE = 3; return fold(row, pos, 3, lead - 224) }
  SIZE = 4
  return fold(row, pos, 4, lead - 240)
}

# How many columns one codepoint spends. Single-byte characters are ASCII and always spend one.
function screen_width(code, size) {
  if (size > 1 && wide(code)) return 2
  return 1
}

#
# Walk a row once and record the screen column of every pipe that splits cells.
#
# One walk does both jobs because they need the same two facts: how wide each character is, and
# whether a backslash shielded it. A pipe behind a backslash is text inside a cell. Backticks shield
# nothing — markdown splits a row inside a code span just the same.
#
# The cursor moves before the decision is made, so each case can bail out on its own line. `at` holds
# where the character started, because that is what a pipe has to report.
#
# Fills COLS[1..n] and returns n. Pipes are ASCII, and every byte of a multi-byte character is 128
# or above, so walking bytes can never mistake part of one character for a separator.
#
function pipe_columns(row,   bytes, i, code, at, column, count, shielded) {
  bytes = length(row)
  i = 1; column = 0; count = 0; shielded = 0

  while (i <= bytes) {
    code = decode(row, i)
    at = column
    column += screen_width(code, SIZE)
    i += SIZE

    if (shielded)    { shielded = 0; continue }
    if (code == 92)  { shielded = 1; continue }           # a backslash
    if (code == 124) COLS[++count] = at                   # a pipe that splits
  }
  return count
}

# The pipe columns of a row, as one string, so two rows can be compared for equality.
function signature(row,   count, i, out) {
  count = pipe_columns(row)
  out = ""
  for (i = 1; i <= count; i++) out = out COLS[i] ","
  return out
}

# Does this row hold only the dashes and colons a table's second row is made of?
#
# Every cell needs a dash of its own. The last test rejects a pair of pipes with nothing but spaces
# or a colon between them, which is what separates a real dash row from a line that merely looks
# like one.
function dash_row(row) {
  return row ~ /^[[:space:]|:-]+$/ && row ~ /-/ && row !~ /\|[[:space:]:]*\|/
}

function table_row(row,   text, pipes, i) {
  text = trim(row)
  if (substr(text, 1, 1) != "|" || substr(text, length(text), 1) != "|") return 0
  pipes = 0
  for (i = 1; i <= length(text); i++) if (substr(text, i, 1) == "|") pipes++
  return pipes >= 2
}

function trim(text) {
  sub(/^[[:space:]]+/, "", text)
  sub(/[[:space:]]+$/, "", text)
  return text
}

# A run of rows is a table only when its second row is the dash row. A flowchart drawn in pipes is
# not a table, and a lone quoted row is not one either.
function judge(start, height,   i, first) {
  if (height < 2 || !dash_row(held[start + 1])) return
  first = signature(held[start])
  for (i = start + 1; i < start + height; i++) {
    if (signature(held[i]) != first) { print start; return }
  }
}

{
  # A fenced block shows tables as specimens, so they are none of this file's business. Blanking the
  # block rather than dropping it keeps every line number honest.
  if (trim($0) ~ /^```/) { fenced = !fenced; held[NR] = ""; next }
  if (fenced) { held[NR] = ""; next }
  held[NR] = $0
}

END {
  if (SPANS == 0) exit 2                                  # BEGIN bailed out

  run = 0
  for (line = 1; line <= NR + 1; line++) {
    if (line <= NR && table_row(held[line])) {
      if (!run) start = line
      run++
      continue
    }
    if (run) judge(start, run)
    run = 0
  }
}
