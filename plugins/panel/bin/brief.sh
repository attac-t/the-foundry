#!/bin/sh
#
# The brief a judge is handed: Panel's own role, and the one clause it answers.
#
# A name like `codex:adversary` promises the role Panel ships. Without this the promise is a label,
# and whoever convenes the panel writes the reviewer's instructions — which is a quieter way of
# writing its verdict.
#
#   sh bin/brief.sh adversary "the interface is understandable"
#
# Prints to stdout. Hand it to any model, on any host, however that host takes a prompt.
#
# Exit: 0 printed. 2 called wrongly. 3 no such role.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)

role=${1:-}
clause=${2:-}

[ -n "$role" ] && [ -n "$clause" ] || {
    printf 'brief: name a role and the clause it answers\n' >&2
    exit 2
}

file="$root/agents/$role.md"
[ -r "$file" ] || { printf 'brief: no role [%s] in %s/agents\n' "$role" "$root" >&2; exit 3; }

# The frontmatter is for the harness that loads an agent. A model handed prose does not
# need it, and the `---` fences read as a heading rule.
role_body() { awk 'seen == 2 { print } /^---$/ { seen++ }' "$1"; }

printf '%s\n' "$(role_body "$file")"

printf '\n---\n\n# The clause you answer\n\n    %s\n\n' "$clause"

cat <<'ASK'
Answer that clause and nothing else. Do not propose patches. Do not edit anything.

End with exactly one line, on its own:

    VERDICT: approve
    VERDICT: reject
    VERDICT: revise

Then one paragraph saying why.
ASK
