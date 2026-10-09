#!/bin/bash
# What `bin/gates.sh fast` runs, and what the full run still runs.
#
# **In a lab, never the real gates.** Each case copies `bin/gates.sh` into a directory of its own.
# Every path a gate line names holds a stand-in that writes its gate's name down and passes. So a
# case reads which gates ran, in seconds, and no lab gate runs this file again.
#
# **The plugin suites come from the disk, never from the copy under test.** A copy that drops one
# from its own list would otherwise agree with itself.
#
# **No plugin suite is named here after `sh` or `bash`.** Floor pins every file a gate's command
# names, so a literal one would grade later work with the base's copy of that suite.
#
# Driven by `sh bin/gates.sh audit`. No gate runs it, so the count stands.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

echo "gates"

tmp="${TMPDIR:-/tmp}/gates-suite-$$"
lab=$tmp/lab
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# Every plugin that ships a suite, read off the disk.
suites_on_disk() {
  for suite in "$root"/plugins/*/tests/run.sh; do
    [ -f "$suite" ] || continue
    suite=${suite%/tests/run.sh}
    printf '%s\n' "${suite##*/}"
  done | sort
}

#
# A gate line's name and path, wherever on the line they sit. A plant that guards a gate line keeps
# it a gate line here, so a copy cannot hide the gate it then skips.
gate_lines() {
  awk '{
    for (i = 1; i + 3 <= NF; i++) {
      if ($i != "gate") continue
      if ($(i + 2) != "sh" && $(i + 2) != "bash") continue
      if ($(i + 3) ~ /\$/) continue
      print $(i + 1), $(i + 3)
    }
  }' "$1"
}

# It writes its gate's name down, and fails when the lab's `fails` names it.
stand_in() {
  mkdir -p "$lab/$(dirname "$2")"
  cat > "$lab/$2" <<EOF
#!/bin/sh
echo $1 >> "$lab/ran"
grep -qx $1 "$lab/fails" 2>/dev/null && exit 1
exit 0
EOF
}

# A lab around one copy of `bin/gates.sh`: a stand-in for each gate line, and for each suite on disk.
a_lab() {
  rm -rf "$lab" && mkdir -p "$lab/bin" && cp "$1" "$lab/bin/gates.sh" || return 1

  gate_lines "$lab/bin/gates.sh" | while read -r name path; do stand_in "$name" "$path"; done
  for suite in $(suites_on_disk); do stand_in "$suite" "plugins/$suite/tests/run.sh"; done
}

#
# The lab's copy, run in one mode. **Its own home, and nothing kept**, so a red run writes nowhere
# outside the lab. Git stops at the lab too, whatever repository holds `TMPDIR`.
graded_in_the_lab() {
  ( cd "$lab" && HOME="$lab/home" FOUNDRY_HOME="$lab/home/.foundry" FOUNDRY_EPHEMERAL=1 \
      GIT_CEILING_DIRECTORIES="$tmp" sh bin/gates.sh "$@" 2>&1 )
}

# What the lab's `list` names, less the suites on disk.
listed_but_the_suites() {
  graded_in_the_lab list | sort > "$tmp/listed"
  suites_on_disk > "$tmp/suites"
  comm -23 "$tmp/listed" "$tmp/suites"
}

# The gates that ran in the lab, one line each time one ran.
what_ran() { sort "$lab/ran" 2>/dev/null; }

# `fast` ran every gate `list` names but the plugin suites, each once, and no suite.
fast_runs_the_rest() {
  a_lab "$1" || return 1
  graded_in_the_lab fast > "$tmp/said"

  what_ran > "$tmp/ran"
  listed_but_the_suites > "$tmp/wanted"
  cmp -s "$tmp/ran" "$tmp/wanted"
}

# The full run ran every gate `list` names and every suite on disk, each once.
full_runs_them_all() {
  a_lab "$1" || return 1
  graded_in_the_lab > "$tmp/said"

  what_ran > "$tmp/ran"
  { graded_in_the_lab list; suites_on_disk; } | sort -u > "$tmp/wanted"
  cmp -s "$tmp/ran" "$tmp/wanted"
}

# Never `ALL GREEN`, and the last line names what was left out.
says_it_is_not_a_grade() {
  grep -q 'ALL GREEN' "$1" && return 1
  tail -1 "$1" | grep -q '^fast — the plugin suites did not run: '
}

#
# A plant must change the copy, and the check must then refuse it. **A plant that changed nothing
# reads exactly like a blind check**, so it is reported apart.
a_plant_is_caught() {
  sed "$3" "$root/bin/gates.sh" > "$tmp/planted.sh"

  cmp -s "$tmp/planted.sh" "$root/bin/gates.sh" && { bad "$1 — the plant changed nothing"; return; }
  "$2" "$tmp/planted.sh" && { bad "$1 — the check passed it"; return; }

  ok "$1"
}

#
# --- what fast runs ---
#
fast_runs_the_rest "$root/bin/gates.sh" \
  && ok  "fast runs every gate list names, but the plugin suites" \
  || bad "fast runs every gate list names, but the plugin suites"

says_it_is_not_a_grade "$tmp/said" \
  && ok  "a green fast never says ALL GREEN, and its last line names what it left out" \
  || bad "a green fast never says ALL GREEN, and its last line names what it left out — $(tail -1 "$tmp/said")"

#
# Two gates fail: the first and the last that `fast` runs. **Each is named, and the exit is
# not 0.** A count alone would send a reader looking for which.
#
a_lab "$root/bin/gates.sh"
first=$(listed_but_the_suites | head -1)
last=$(listed_but_the_suites | tail -1)
printf '%s\n%s\n' "$first" "$last" > "$lab/fails"

graded_in_the_lab fast > "$tmp/said"
code=$?

[ "$code" -ne 0 ] && grep -q "^  FAIL  $first " "$tmp/said" && grep -q "^  FAIL  $last " "$tmp/said" \
  && ok  "a red fast exits non-zero, and names each gate that did not pass" \
  || bad "a red fast exits non-zero, and names each gate that did not pass — exit $code"

grep -q '^2 RED$' "$tmp/said" && says_it_is_not_a_grade "$tmp/said" \
  && ok  "a red fast counts them, and still ends naming what it left out" \
  || bad "a red fast counts them, and still ends naming what it left out"

#
# A gate line added to the copy, with no other edit. **`fast` reads the lines the full run reads**,
# so a gate that lands joins it.
#
awk '{ print } /^gate unnamed / { print "gate added       sh   bin/added.sh" }' \
  "$root/bin/gates.sh" > "$tmp/added.sh"

grep -q '^gate added ' "$tmp/added.sh" && fast_runs_the_rest "$tmp/added.sh" && grep -qx added "$lab/ran" \
  && ok  "a gate line added to the copy runs under fast, with no other edit" \
  || bad "a gate line added to the copy runs under fast, with no other edit"

#
# --- what the full run still does ---
#
full_runs_them_all "$root/bin/gates.sh" && [ "$(tail -1 "$tmp/said")" = "ALL GREEN" ] \
  && ok  "the full run runs every gate and every plugin suite, and ends ALL GREEN" \
  || bad "the full run runs every gate and every plugin suite, and ends ALL GREEN — $(tail -1 "$tmp/said")"

a_lab "$root/bin/gates.sh"
{ gate_lines "$lab/bin/gates.sh" | cut -d' ' -f1; suites_on_disk; } | sort > "$tmp/wanted"
graded_in_the_lab list | sort > "$tmp/listed"

cmp -s "$tmp/listed" "$tmp/wanted" \
  && ok  "list names each gate line and each plugin suite, and prints nothing else" \
  || bad "list names each gate line and each plugin suite, and prints nothing else"

grep -qx '        sh bin/gates.sh' "$root/bin/gates.sh" \
  && ok  "linux still runs the full run inside its container" \
  || bad "linux still runs the full run inside its container"

#
# --- a gate that is real ---
#
# **`unnamed` stands, with everything it reads.** A refusal planted in floor's runner has no row on
# the page, so `fast` goes red on that gate's own line. The exit of `fast` says nothing here.
#
unnamed_stands() {
  a_lab "$root/bin/gates.sh" || return 1

  for file in bin/unnamed.sh bin/refusals.sh tests/unnamed.sh .foundry/refusals.md \
              plugins/floor/bin/run.sh; do
    mkdir -p "$lab/$(dirname "$file")" && cp "$root/$file" "$lab/$file" || return 1
  done
}

unnamed_stands
graded_in_the_lab fast > "$tmp/said"

grep -q '^  PASS  unnamed$' "$tmp/said" \
  && ok  "with no plant, unnamed passes in the lab" \
  || bad "with no plant, unnamed passes in the lab — $(grep 'unnamed' "$tmp/said" | head -1)"

unnamed_stands
printf '\nrefuse_for_a_plant() {\n    note "a plant put this here"\n    exit 2\n}\n' \
  >> "$lab/plugins/floor/bin/run.sh"
graded_in_the_lab fast > "$tmp/said"

grep -q '^  FAIL  unnamed — a rule broken (exit 1)$' "$tmp/said" \
  && ok  "a refusal with no row turns fast red on unnamed, at exit 1" \
  || bad "a refusal with no row turns fast red on unnamed, at exit 1 — $(grep 'unnamed' "$tmp/said" | head -1)"

#
# --- the breaks ---
#
a_plant_is_caught "a plugin suite run under fast is caught" fast_runs_the_rest \
  's/^\[ "\$mode" = fast \] || for plugin in/for plugin in/'

a_plant_is_caught "a gate fast skips is caught" fast_runs_the_rest \
  's/^gate frontmatter /[ "$mode" = fast ] || gate frontmatter /'

a_plant_is_caught "a plugin suite the full run skips is caught" full_runs_them_all \
  's/^suites=.*/suites=kernel/'

a_plant_is_caught "a gate the full run skips is caught" full_runs_them_all \
  's/^gate taper /[ "$mode" = run ] || gate taper /'

printf '\ngates — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
