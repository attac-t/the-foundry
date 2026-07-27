#!/usr/bin/env bash
#
# Validate every plugin in this marketplace.
#
# CI runs this exact script. Run it before you push and there are no surprises.
#
#   ./.github/validate.sh
#
# Requires: claude CLI. ShellCheck is optional — that check skips without it.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

FAILED=0
COMPLETED=0

# A green summary printed after a crashed section is worse than no summary. If the
# script dies before the last line, say so and fail.
trap '[ "$COMPLETED" = 1 ] || {
    printf "\n\033[31m✘ validate.sh exited early — a check did not run.\033[0m\n"
    exit 1
}' EXIT

group() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }
pass() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
skip() { printf '  \033[33m—\033[0m %s\n' "$1"; }
fail() {
    printf '  \033[31m✘\033[0m %s\n' "$1"
    [ $# -gt 1 ] && printf '      %s\n' "${@:2}"
    FAILED=1
}

PLUGINS=$(find plugins -mindepth 1 -maxdepth 1 -type d | sort)

# ── Manifests ────────────────────────────────────────────────────────────────
# The official validator checks plugin.json, hooks.json, and the frontmatter of
# every skill, agent, and command. --strict promotes warnings to errors, which is
# what catches a misspelled field that would silently do nothing at runtime.

group "Manifests"

if ! command -v claude >/dev/null 2>&1; then
    fail "claude CLI not found" "Install: npm i -g @anthropic-ai/claude-code"
else
    if out=$(claude plugin validate . 2>&1); then
        pass "marketplace.json"
    else
        fail "marketplace.json" "$out"
    fi

    for dir in $PLUGINS; do
        if out=$(claude plugin validate "$dir" --strict 2>&1); then
            pass "$(basename "$dir")"
        else
            fail "$(basename "$dir")" "$out"
        fi
    done
fi

# ── Marketplace drift ────────────────────────────────────────────────────────
# A plugin missing from marketplace.json cannot be installed. This has shipped
# before, so it is a check and not a convention.

group "Marketplace drift"

MANIFEST=.claude-plugin/marketplace.json

for dir in $PLUGINS; do
    name=$(basename "$dir")
    if grep -q "\"$name\"" "$MANIFEST"; then
        pass "$name is listed"
    else
        fail "$name is not in marketplace.json" "Add an entry with source \"./$dir\"."
    fi
done

# plugin.json wins over the marketplace entry at install time, so a version in
# both is drift with no upside.
if grep -q '"version"' "$MANIFEST"; then
    fail "marketplace.json declares a version" \
        "plugin.json is the only source of truth. Remove it here."
else
    pass "no version duplicated from plugin.json"
fi

# ── Skills ───────────────────────────────────────────────────────────────────

group "Skills"

bad_name=0 bad_link=0 orphan=0 count=0

while IFS= read -r skill; do
    count=$((count + 1))
    dir=$(dirname "$skill")
    expected=$(basename "$dir")
    actual=$(awk '/^---$/{c++; if(c==2) exit; next}
                  c==1 && /^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$skill")

    # A name that disagrees with its directory is invoked under a name nobody expects.
    if [ "$actual" != "$expected" ]; then
        fail "$skill" "frontmatter name is '$actual', directory is '$expected'"
        bad_name=1
    fi

    # Every linked companion file must exist.
    while IFS= read -r target; do
        [ -z "$target" ] && continue
        if [ ! -e "$dir/$target" ]; then
            fail "$skill" "links $target, which does not exist"
            bad_link=1
        fi
    done < <(grep -oE '\]\([a-zA-Z0-9/_.-]+\)' "$skill" |
        sed 's/^](//; s/)$//' | grep -vE '^(https?:|#)')

    # Content nothing points at is content nobody reads.
    while IFS= read -r extra; do
        [ -z "$extra" ] && continue
        rel=${extra#"$dir"/}
        if ! grep -qF "$(dirname "$rel")/" "$skill" && ! grep -qF "$rel" "$skill"; then
            fail "$skill" "does not link $rel"
            orphan=1
        fi
    done < <(find "$dir" -name '*.md' ! -name 'SKILL.md' | sort)
done < <(find plugins -path '*/skills/*/SKILL.md' | sort)

[ $bad_name = 0 ] && pass "$count skills: name matches directory"
[ $bad_link = 0 ] && pass "$count skills: no broken links"
[ $orphan = 0 ] && pass "$count skills: every companion file is linked"

# ── Documented counts ────────────────────────────────────────────────────────
# READMEs advertise skill counts, and a badge advertises the total. Numbers in
# prose rot silently, so the build owns them.

group "Documented counts"

total=0
stale=0

for dir in $PLUGINS; do
    name=$(basename "$dir")
    actual=$(find "$dir/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    total=$((total + actual))

    # "46 skills, extracted from ..." — only checked when the README claims one.
    claimed=$(grep -oE '\b[0-9]+ skills\b' "$dir/README.md" 2>/dev/null |
        head -1 | grep -oE '[0-9]+')
    if [ -n "$claimed" ] && [ "$claimed" != "$actual" ]; then
        fail "$name/README.md says $claimed skills, found $actual"
        stale=1
    fi

    # The plugin table in the root README carries a per-plugin count.
    row=$(grep -oE "\*\*\[$name\]\([^)]*\)\*\*[^|]*\|[^|]*\|[[:space:]]*[0-9]+" README.md 2>/dev/null |
        grep -oE '[0-9]+$')
    if [ -n "$row" ] && [ "$row" != "$actual" ]; then
        fail "README.md table says $row skills for $name, found $actual"
        stale=1
    fi
done

badge=$(grep -oE 'skills-[0-9]+-' README.md 2>/dev/null | head -1 | grep -oE '[0-9]+')
if [ -n "$badge" ] && [ "$badge" != "$total" ]; then
    fail "README.md badge says $badge skills, found $total"
    stale=1
fi

[ $stale = 0 ] && pass "every advertised skill count matches ($total total)"

# ── Agent registry ───────────────────────────────────────────────────────────
# Sub-agents do not inherit skills. A kernel skill absent from the architect's
# `skills:` list does not exist as far as the architect is concerned.

group "Agent registry"

ARCHITECT=plugins/kernel/agents/architect.md
registered=$(awk '/^---$/{c++; if(c==2) exit; next}
                  c==1 && /^skills:/{sub(/^skills:[[:space:]]*/, ""); print; exit}' "$ARCHITECT")
unregistered=0

for dir in plugins/kernel/skills/*/; do
    name=$(basename "$dir")
    case ",${registered// /}," in
    *",$name,"*) ;;
    *)
        fail "$name is not registered" "Add it to skills: in ${ARCHITECT#plugins/kernel/}"
        unregistered=1
        ;;
    esac
done

[ $unregistered = 0 ] && pass "every kernel skill is registered with the architect"

# ── Hooks ────────────────────────────────────────────────────────────────────

group "Hooks"

HOOKS=()
while IFS= read -r hook; do
    HOOKS+=("$hook")
done < <(find plugins -path '*/hooks/*' -name '*.sh' | sort)

if [ ${#HOOKS[@]} -eq 0 ]; then
    skip "no hooks to check"
else
    # A hook without its executable bit fails silently at runtime.
    nonexec=0
    for hook in "${HOOKS[@]}"; do
        [ -x "$hook" ] || {
            fail "$hook is not executable" "chmod +x $hook"
            nonexec=1
        }
    done
    [ $nonexec = 0 ] && pass "${#HOOKS[@]} shell scripts under hooks/ are executable"

    # SECURITY.md promises these hooks make no network calls. Enforce the promise.
    if net=$(grep -nE '\b(curl|wget|nc|ncat|telnet)\b' "${HOOKS[@]}"); then
        fail "a hook makes a network call" "$net" \
            "Hooks are documented as read-only and offline. See SECURITY.md."
    else
        pass "no network calls in hooks"
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        if out=$(shellcheck --severity=warning "${HOOKS[@]}" 2>&1); then
            pass "shellcheck clean"
        else
            fail "shellcheck found problems" "$out"
        fi
    else
        skip "shellcheck not installed (brew install shellcheck)"
    fi
fi

# ── Result ───────────────────────────────────────────────────────────────────

COMPLETED=1

if [ $FAILED = 0 ]; then
    printf '\n\033[32m✔ All checks passed.\033[0m\n'
else
    printf '\n\033[31m✘ Validation failed.\033[0m\n'
fi

exit $FAILED
