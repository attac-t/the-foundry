#!/bin/sh
# PostToolUse: after a plugin's version is written, say what this session is still running.
#
# **A version in `plugin.json` changes nothing in the session that wrote it.** The installed copy
# comes from the marketplace record, and that record does not move on its own.
#
# `.claude/rules/plugins.md` has said so for weeks and it kept happening — eight bumps in one day,
# each one leaving the session on the skill it had already loaded. A rule read at session start is
# not read again at the moment it applies.
#
# **The same reader as `drift.sh`, at a different moment.** That one asks at session start; this
# asks the second the number changes, which is when a person can act on the answer.
#
# Silent unless something is behind. On a directory-sourced marketplace the checkout *is* the
# marketplace, so a bump is drift the moment it lands and the answer is immediate.
#
# Reads a `PostToolUse` tool call as JSON on stdin.

set -u

case $(cat) in
    *plugin.json*) ;;
    *)             exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

said=$(sh "$(dirname "$0")/../lib/plugins.sh" session "$root") || exit 0
[ -n "$said" ] || exit 0

printf '%s\n' "$said"
printf 'pulled  not yet. `claude plugin update <name>@<marketplace> -y`, and `--scope project` for this checkout.\n'
printf '        The restart is the half no pull reaches.\n'
