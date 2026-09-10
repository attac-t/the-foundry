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
# **Through `additionalContext`, never stdout.** Only SessionStart, UserPromptSubmit and Setup
# inject what a hook prints; a tool event's stdout reaches the transcript and nobody reads it back.
# `tests/install.sh` refused the first draft of this file for exactly that, under WSL, where Git
# Bash saw nothing wrong.
#
# So the message is one line with no quote and no backslash in it. Building JSON in `sh` is a
# parser this plugin does not ship, and a line that needs escaping is a line that will be escaped
# wrongly.
#
# Reads a `PostToolUse` tool call as JSON on stdin.

set -u

case $(cat) in
    *plugin.json*) ;;
    *)             exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

#
# **Exit 1 is the answer this wants, and 0 is not.** `session` speaks on a broken read as well as on
# drift, and this once appended *pull it before the skill is asked for* to *nothing was installed
# here through a marketplace*.
#
# An install and an update are different remedies. A host told only that something is wrong goes off
# and runs the wrong one.
said=$(sh "$(dirname "$0")/../lib/plugins.sh" session "$root") && exit 0
[ -n "$said" ] || exit 0

one_line=$(printf '%s' "$said" | tr '\n' ';' | tr -d '"\\')

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":'
printf '"%s — pull it before the skill is asked for: claude plugin update <name>@<marketplace> -y, ' "$one_line"
printf 'and --scope project for this checkout. The restart is the half no pull reaches."}}\n'
