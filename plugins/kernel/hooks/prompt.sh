#!/bin/sh
# UserPromptSubmit: everything kernel says when a prompt arrives.
#
# **Four hooks were eight processes.** Claude Code starts one per hook, and three of the four
# resolved the memory directory separately — so eight starts produced two paragraphs. Two of the
# four printed nothing at all on an ordinary prompt and still cost a start each.
#
# Measured on this host, ten prompts, before: 2,511 ms each. #528 traced 1,030 ms on another.
#
# **The order is the contract.** A reader saw the objective, then where progress goes, then the
# skill evaluation, then the delegation check. It still does.
#
# The lib scripts are handed to `sh`, never run as programs. Windows records no executable bit, so
# a hook that needs one is a hook that does not start there at all.

dir=$(cd "$(dirname "$0")" && pwd)

main() {
    memory=$(sh "$dir/lib/resolve-memory.sh")

    say_the_objective
    say_where_progress_goes
    say_to_evaluate_the_skills
    say_to_check_delegation
}

# --- what each of the four said ---

say_the_objective() {
    working=$memory/working.md
    [ -f "$working" ] || return 0

    goal=$(sh "$dir/lib/extract-objective.sh" "$working")
    [ -n "$goal" ] || return 0

    # Not always the branch — a run and the bare fallback both land here too.
    printf '📎 [%s] %s\n' "$(basename "$memory")" "$goal"
}

#
# **`return`, never `exit`.** Apart, this one ended its own process and the other three still ran.
# Folded, an exit here would take the skill evaluation with it — the fault a fold invites.
say_where_progress_goes() {
    case $(git branch --show-current 2>/dev/null) in
        main|master|develop) printf '📝 Protected branch. See: ground-topic\n'; return 0 ;;
    esac

    printf '📝 Progress? Update `%s/working.md`. See: ground-recitation\n' "$memory"
}

# Scott Spence's forced evaluation pattern. Relevant skills get activated rather than ignored.
say_to_evaluate_the_skills() {
    cat <<'EOF'
---
**Skill Evaluation** (required before implementation)

**Step 0 - GROUND-STACK:**
⛔ `Skill(kernel:ground-stack)` — invoke if stack context detected and not yet grounded.

**Step 1 - EVALUATE:**
For each skill in <available_skills>: `[skill]` - YES/NO - [reason]

**Step 2 - ACTIVATE:**
For each YES → call `Skill(skill-name)` NOW.

**Step 3 - IMPLEMENT:**
Only after activation, proceed with the task.

⛔ **BLOCKING**: Do not implement until skills evaluated and activated.
EOF
}

say_to_check_delegation() {
    [ -f "$memory/blueprint.md" ] || return 0

    cat <<'EOF'
---
**Delegation Check** (ground-delegation)

Blueprint active. Before starting work:
1. Any `agent` tasks ready to delegate in parallel?
2. Any `pending` tasks that should be reassessed as `agent`?

Justify if keeping delegatable work as `self`.
EOF
}

main "$@"
