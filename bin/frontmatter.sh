#!/usr/bin/env bash
#
# Fails when a plugin component is missing the frontmatter that registers it.
#
# Promoted after `craft-plugin-update` — the one skill CLAUDE.md mandates — was found with no
# frontmatter at all, 1 of 123. It still loaded: the harness falls back to the directory name and
# scrapes a description from the first blockquote. So it registered as "Bump, commit, push. In that
# order." — an epigraph standing in for a description, which is what the model reads when deciding
# whether the skill is relevant. Silent degradation, not a crash, which is why nothing caught it.
#
# A closed predicate: N field comparisons, machine-decidable, no thresholds and no corpus tuning.
#
# Exit: 0 clean, 1 a rule broken, 3 the gate could not read.

set -euo pipefail

cd "$(dirname "$0")/.."

# One awk call per file, not one across all of them. `ENDFILE` is the clean way to do the second and
# it is GNU-only — and needing one particular awk is the dependency this file was rewritten to drop.
faults_in() {
  awk -v want="$2" -v need="$3" '
    { sub(/\r$/, "") }

    NR == 1  { opened = ($0 == "---"); next }
    !closed && $0 == "---" { closed = 1; next }
    closed   { next }

    # A key sits flush against the left margin. An indented line continues the value above it and a
    # dash opens a list item, which is what `metadata:` and `allowed-tools:` are made of.
    /^[^ \t-][^:]*:/ {
      key = $0;   sub(/:.*/, "", key)
      value = $0; sub(/^[^:]*:[ \t]*/, "", value); sub(/[ \t]+$/, "", value)
      held[key] = value
    }

    END {
      # An unclosed block is not frontmatter either. Left open, the body reads as fields too, and a
      # skill carrying a `Name: x` line would answer for a field it never declared.
      if (!opened || !closed) { print "no frontmatter — the file does not open with ---"; exit }

      count = split(need, required, ",")
      for (i = 1; i <= count; i++)
        if (held[required[i]] == "") print "missing or empty `" required[i] ":`"

      if (want != "" && held["name"] != "" && held["name"] != want)
        print "`name: " held["name"] "` does not match `" want "`"
    }
  ' "$1"
}

# An unmatched glob stays literal, so every path is tested before it is counted as a component.
emit() {
  kind=$1
  shift
  for path in "$@"; do
    [ -f "$path" ] || continue
    printf '%s\t%s\n' "$kind" "$path"
  done
}

components() {
  emit skill   plugins/*/skills/*/SKILL.md
  emit agent   plugins/*/agents/*.md
  emit command plugins/*/commands/*.md
}

# What the harness registers the file as. A command is addressed by its path, so it declares no name
# and there is nothing to disagree with.
expected_name() {
  case $1 in
    skill) basename "$(dirname "$2")" ;;
    agent) basename "$2" .md ;;
  esac
}

required_fields() {
  case $1 in
    command) printf 'description' ;;
    *)       printf 'name,description' ;;
  esac
}

listed=$(components)

#
# An agent declares its tools in frontmatter, and the prose beside it repeats the list in words.
# **Change one and nothing makes you change the other.** A judge caught that on a live branch: the
# frontmatter granted two new tools and three sentences still named the old three, one of them the
# plugin's own guarantee.
#
# Narrow on purpose. It compares a declared string against strings, so it decides mechanically and
# needs no threshold. A plugin whose agents declare nothing is not asked.
TOOL='(Read|Glob|Grep|Write|Edit|Bash|WebSearch|WebFetch|Task)'

tool_lists_that_no_agent_declares() {
  for plugin in plugins/*/; do
    declared=$(grep -h '^tools:' "$plugin"agents/*.md 2>/dev/null | sed 's/^tools: *//') || true
    [ -n "$declared" ] || continue

    # Inside the loop, never past a pipe. The comparison needs `declared`, and a pipe stage runs in
    # its own shell where that name is empty — so every hit read as undeclared.
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      printf '%s\n' "$declared" | grep -qxF "${hit##*:}" && continue

      printf '  %s names [%s], and no agent in that plugin declares it\n' "${hit%:*}" "${hit##*:}"
    done <<< "$(grep -rnoE "$TOOL(, *$TOOL)+" "$plugin" --include='*.md' 2>/dev/null | grep -v '/agents/' || true)"
  done
}

# Nothing to check is not a clean check. `bin/shell.sh` wrote this convention and floor uses it in
# three places: a gate given nothing to read exits 3 and says so.
[ -n "$listed" ] || { echo "FAIL — no plugin components found. This gate read nothing."; exit 3; }

checked=0
faults=0
report=""

while IFS=$'\t' read -r kind path; do
  checked=$((checked + 1))
  found=$(faults_in "$path" "$(expected_name "$kind" "$path")" "$(required_fields "$kind")")
  [ -n "$found" ] || continue
  faults=$((faults + $(printf '%s\n' "$found" | grep -c .)))
  report+=$(printf '\n  %s\n%s\n' "$path" "$(printf '%s\n' "$found" | sed 's/^/      /')")
done <<< "$listed"

disagreeing=$(tool_lists_that_no_agent_declares)
if [ -n "$disagreeing" ]; then
  faults=$((faults + $(printf '%s
' "$disagreeing" | grep -c .)))
  report+=$(printf '
  a tool list no agent declares
%s
' "$disagreeing")
fi

if [ "$faults" -eq 0 ]; then
  echo "PASS — $checked components carry the frontmatter that registers them, and every tool list is declared."
  exit 0
fi

# Two faults with one count, so the line names both. A component that will not register is not a
# tool list that disagrees, and saying only the first read as a lie about the second.
echo "FAIL — $faults across $checked components: registering wrong, or naming a tool list no agent declares."
printf '%s\n' "$report"
exit 1
