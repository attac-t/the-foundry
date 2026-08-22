#
# Measure how hard a piece of English is to read.
#
#   printf '%s' "$text" | awk -f score.awk
#
# Reads text on stdin. Prints key=value lines. Exits 0 to pass, 1 to warn, 2 to block.
#
# Three counts, no word list. Hard words are an open set, so any list of them is a sample of
# something endless. We count shape instead. Which word is plainer is a judgment, and that belongs
# to the model reading signal:plain-english.
#
# Table cells do not count toward the word budget, because a table is easy to skim. They do count
# toward long words, because a hard word is hard wherever it sits.
#
# POSIX awk only.
#

#
# Warn is the working line, so it sits where good writing sits. Block costs the reader a second
# reply, so it sits at the 95th percentile of real ones. At 250 words it caught 78% of them.
#
BEGIN {
  if (long_warn   == "") long_warn   = 10
  if (long_block  == "") long_block  = 25
  if (sent_warn   == "") sent_warn   = 20
  if (sent_block  == "") sent_block  = 45
  if (words_warn  == "") words_warn  = 120
  if (words_block == "") words_block = 600

  # A share needs something to be a share of. Three long words in eleven is 27% and one word moves
  # that nine points, so a terse line blocked for being terse — which is what the
  # standard asks for. Five in fifteen is dense; three in eleven is a sentence.
  #
  # Four, and only on block. A warn costs nothing, so it keeps firing on the share alone.
  if (long_min    == "") long_min    = 4
  fence = 0

  # A block edge. END turns each one into a full stop, so no sentence runs across one.
  EDGE = " \001 "
}

# A fence that closes takes its contents out of every count. One that never closes does not, or
# opening a fence and leaving it open would hide the whole rest of the reply.
/^[ \t]*(```|~~~)/ { if (fence) fbuf = ""; fence = !fence; pbuf = pbuf EDGE; next }
fence               { fbuf = fbuf EDGE $0; next }

{
  line = $0
  gsub(/`[^`]*`/, " ", line)
  gsub(/!?\[[^]]*\]\([^)]*\)/, " ", line)
  gsub(/<[^ >]*>/, " ", line)
  gsub(/https?:\/\/[^ )]+/, " ", line)
  gsub(/[*_~>]/, " ", line)
}

/^[ \t]*\|/ {
  gsub(/\|/, " ", line)
  if (line !~ /^[ \t:|-]*$/) tbuf = tbuf " " line
  pbuf = pbuf EDGE
  next
}

# A sentence ends at punctuation or a block edge, never because a line wrapped. Ending it at every
# line break defeated the whole count: a 35-word sentence broken over three lines measured 13.
/^[ \t]*$/                       { pbuf = pbuf EDGE; next }
/^[ \t]*#+[ \t]/                 { sub(/^[ \t]*#+[ \t]*/, "", line); pbuf = pbuf EDGE line EDGE; next }
/^[ \t]*([-+*]|[0-9]+\.)[ \t]/   { sub(/^[ \t]*([-+*]|[0-9]+\.)[ \t]+/, "", line)
                                   sub(/^\[[ x]\][ \t]*/, "", line)
                                   pbuf = pbuf EDGE line; next }
                                 { pbuf = pbuf " " line }

# Determine if a token holds a readable word.
function is_word(t) { return t != "" && t ~ /[a-z]/ }

#
# Determine if a token is a name rather than a word.
#
# PostgreSQL is long, but a reader who knows the tool knows the word and no plainer one exists.
# Anchored to the first letter so punctuation cannot pose as a capital.
#
function is_name(raw) {
  return raw ~ /^[A-Z0-9]+$/ || raw ~ /^[A-Za-z0-9][A-Za-z0-9]*[A-Z]/
}

# Determine if a token is a path, a command or a symbol.
function looks_like_path(core) {
  return core ~ /[\/\\]/ || core ~ /\.[a-z][a-z]+$/ || core ~ /[_(){}=]/
}

#
# Count the beats in a word.
#
# Vowel groups, then two corrections. Side-by-side vowels usually split — `ra-di-o`, `man-u-al` —
# so add a beat back. Not in -tion or -cial, where the pair is one "sh" sound; without that, every
# -tion word gained a beat it does not have. The trailing letter matters: `pa-tio` ends at the pair,
# where it really is two beats.
#
# Measured on 35 words of known length: 11 wrong with no exception, 4 unbounded, 2 now. Both
# survivors undercount, which misses a long word rather than inventing one.
#
function beats(t,   s, prev, k, v) {
  s = 0; prev = 0
  for (k = 1; k <= length(t); k++) {
    v = (substr(t, k, 1) ~ /[aeiouy]/)
    if (v && !prev) s++
    prev = v
  }
  if (t ~ /e$/ && s > 1) s--
  if (t ~ /(ia|io|ua|eo)/ && t !~ /[tcsx](ia|io)[nl]/) s++
  return (s < 1) ? 1 : s
}

#
# Count one chunk, and return the words a reader reads.
#
# Names and paths leave both sides of the long-word share. In the denominator alone, a wall of
# product names would water the percentage down.
#
function tally(chunk,   n, i, tok, raw, core, word, c) {
  n = split(chunk, tok, /[ \t]+/)
  c = 0
  for (i = 1; i <= n; i++) {
    raw = tok[i]
    core = raw
    gsub(/^[^A-Za-z0-9]+|[^A-Za-z0-9]+$/, "", core)
    if (core == "") continue
    if (looks_like_path(core)) continue
    word = tolower(core); gsub(/[^a-z'-]/, "", word)
    if (!is_word(word)) continue
    c++
    if (is_name(core)) continue
    measured_words++
    beat_total += beats(word)
    if (beats(word) >= 3) hard_words++
  }
  return c
}

# Get the separator between reasons.
function sep() { return (reason == "") ? "" : ". " }

END {
  if (fence) pbuf = pbuf EDGE fbuf

  gsub(/\001/, ".", pbuf)
  n = split(pbuf, sent, /[.!?]+[ \t]/)
  for (i = 1; i <= n; i++) {
    c = tally(sent[i])
    if (c == 0) continue
    prose_words += c
    sentences++
    if (c > longest) longest = c
  }
  tally(tbuf)

  long_pct = (measured_words > 0) ? 100 * hard_words / measured_words : 0

  # Flesch-Kincaid, reported and never judged: a line break lowers it while the words stay hard.
  grade = (sentences > 0 && measured_words > 0) \
        ? 0.39 * (prose_words / sentences) + 11.8 * (beat_total / measured_words) - 15.59 \
        : 0

  verdict = "pass"; reason = ""
  if (long_pct > long_warn)  { verdict = "warn"; reason = reason sep() sprintf("%.0f%% long words, aim for %d%%", long_pct, long_warn) }
  if (longest  > sent_warn)      { verdict = "warn"; reason = reason sep() sprintf("longest sentence %d words, aim for %d", longest, sent_warn) }
  if (prose_words > words_warn)  { verdict = "warn"; reason = reason sep() sprintf("%d words, aim for %d", prose_words, words_warn) }

  if (long_pct > long_block && hard_words >= long_min) verdict = "block"
  if (longest  > sent_block)     verdict = "block"
  if (prose_words > words_block) verdict = "block"

  # Set a warn line above its own block line and no warn fires, which used to leave a block with
  # nothing to say.
  if (verdict == "block" && reason == "")
    reason = sprintf("%d words, %.0f%% long words, longest sentence %d", prose_words, long_pct, longest)

  if (measured_words == 0 && prose_words == 0) { verdict = "pass"; reason = "" }

  # The working line, reported back for hooks/brief.sh to read out. Defaults live here and nowhere
  # else: the hook restated them once, and moving one moved half the gate.
  printf "words_warn=%d\n", words_warn
  printf "sent_warn=%d\n",  sent_warn
  printf "long_warn=%d\n",  long_warn
  printf "long_min=%d\n", long_min

  printf "words=%d\n",      prose_words
  printf "measured=%d\n",   measured_words
  printf "sentences=%d\n",  sentences
  printf "longest=%d\n",    longest
  printf "long_pct=%.1f\n", long_pct
  printf "grade=%.1f\n",    grade
  printf "verdict=%s\n",    verdict
  printf "reason=%s\n",     reason

  exit (verdict == "block") ? 2 : (verdict == "warn") ? 1 : 0
}
