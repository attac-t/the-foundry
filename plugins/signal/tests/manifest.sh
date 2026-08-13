#!/bin/bash
# Checks the plugin is wired up, ships no word data, and points at a real standard.
#
# The standard checks earn their place: word choice is a judgment now, so the skill has to name what
# it judges against. "Use plain words" citing nothing is the advice that already failed.
#
# There are no file-existence checks here. Every shipped file is exercised by another suite, so a
# missing one already fails loudly and twice.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$root/../.." && pwd)"
. "$root/tests/lib.sh"

manifest="$root/.claude-plugin/plugin.json"
market="$repo/.claude-plugin/marketplace.json"
hooks="$root/hooks/hooks.json"
skill="$root/skills/plain-english/SKILL.md"

# Read a value from a JSON manifest.
value() { awk -f "$root/lib/unjson.awk" -v key="$2" < "$1"; }

# Determine if a file holds the given text.
mentions() { grep -qF "$2" "$1"; }

# Get the version the marketplace lists for signal.
listed() { awk '/"name": "signal"/,/}/' "$market" | awk -F'"' '/"version"/ { print $4; exit }'; }

# Get every markdown file the plugin ships.
markdown() { find "$root" -name '*.md' | sort; }

# Count the example rows in a table.
rows() { awk '/^\| `/ { n++ } END { print n + 0 }' "$1"; }

echo "manifest"

# --- the manifests agree ---

version=$(value "$manifest" version)
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ok "plugin.json carries a version — $version" ;;
  *)                    bad "plugin.json version looks wrong — [$version]" ;;
esac

mentions "$market" '"name": "signal"' \
  && ok "the marketplace lists signal" \
  || bad "the marketplace does not list signal"
is "the two versions agree" "$(listed)" "$version"

mentions "$repo/README.md" 'plugins/signal/README.md' \
  && ok "the root README lists signal" \
  || bad "the root README does not list signal"

# --- the wiring ---

mentions "$hooks" '"Stop"' && mentions "$hooks" '"SessionEnd"' \
  && ok "hooks.json hooks Stop and SessionEnd" \
  || bad "hooks.json is missing an event"

mentions "$hooks" 'CLAUDE_PLUGIN_ROOT' \
  && ok "hooks.json uses the plugin root" \
  || bad "hooks.json hardcodes a path"

mentions "$hooks" '"UserPromptSubmit"' \
  && ok "hooks.json hooks UserPromptSubmit" \
  || bad "hooks.json never runs the brief, so nothing reaches the agent before it writes"

# Claude Code runs the hook as a command, so it needs one. Nothing else here would notice.
for script in signal brief preflight cleanup; do
  head -1 "$root/hooks/$script.sh" | grep -q '^#!' \
    && ok "$script.sh has a shebang" \
    || bad "$script.sh has no shebang"
done

# --- the gate has one home ---
# score.awk owns every default. A hook that names one again is a second gate, free to part company
# with the first: the block lines were raised in the scorer while the hook kept passing the old
# ones, and nothing was red.
if grep -qE 'SIGNAL_[A-Z_]+:-[0-9]' "$root/hooks/"*.sh; then
  bad "a hook restates a default — score.awk owns them, pass the dial through empty instead"
else
  ok "no hook restates a default"
fi

# --- no word data ships ---

is "lib holds code only, no word lists" "$(find "$root/lib" -type f ! -name '*.awk')" ""

grep -q 'banned' "$root/lib/score.awk" "$root/hooks/signal.sh" \
  && bad "something still reaches for a banned list" \
  || ok "nothing reaches for a banned list"

# --- the skill has to point somewhere real ---

for standard in 'asd-ste100.org' 'iso.org/standard/78907' 'VOA Special English' 'GOV.UK'; do
  mentions "$skill" "$standard" \
    && ok "the skill cites $standard" \
    || bad "the skill does not cite $standard"
done

mentions "$skill" 'ten-year-old' \
  && ok "the skill states the bar" \
  || bad "the skill never states the bar"

examples=$(rows "$skill")
[ "$examples" -ge 10 ] \
  && ok "the skill shows examples — $examples rows" \
  || bad "too few examples — $examples rows"

# --- no repeated prose, and the check must have real files to read ---
# `find`, not `git ls-files`: until these files are committed git lists none, and repeats.sh exits 0
# on an empty list. That is a green gate certifying nothing.

count=$(markdown | grep -c .)
[ "$count" -ge 2 ] \
  && ok "there is markdown to check — $count files" \
  || bad "found no markdown, so the repeats check would pass on nothing"

bash "$repo/bin/repeats.sh" $(markdown) >/dev/null 2>&1 \
  && ok "no sentence appears twice" \
  || bad "prose repeats — run bin/repeats.sh over plugins/signal for the list"

summary "manifest"
