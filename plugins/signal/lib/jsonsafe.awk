#
# Reduce a string to characters that cannot break a JSON string literal.
#
#   printf '%s' "$text" | awk -f jsonsafe.awk
#
# Keeps letters, digits, space and `.,:%-`. Multi-line input comes back as one line.
#
# Everything signal prints is machine-built, so nothing legitimate needs a quote or a backslash.
# Stripping avoids gsub's replacement-backslash semantics, which differ between awks.
#

{
  gsub(/[^A-Za-z0-9 .,:%-]/, "")
  printf "%s%s", sep, $0
  sep = " "
}
