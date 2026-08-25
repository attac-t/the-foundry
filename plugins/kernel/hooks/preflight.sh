#!/bin/sh
#
# SessionStart: prove kernel's hooks can still run, and say so when they cannot.
#
# Every way kernel fails is quiet. Not one of its hooks reports
# anything while it works, so a hook that cannot start looks
# exactly like a healthy hook with nothing at all to say.
#
# So we run the shipped code against known input and check the
# answer once at the top of a session. Quiet when it works,
# and one line when it does not. That is the whole hook.
#

root="$(cd "$(dirname "$0")" && pwd)"

main() {
  reader_finds_a_nested_value && resolver_gives_one_path && parser_reads_an_objective && exit 0

  awk_is_on_path || { warn "no awk on PATH. kernel needs sh and awk, nothing else."; exit 0; }

  warn "awk is there but hooks/lib did not answer. Reinstall the plugin."
}

reader_finds_a_nested_value() {
  [ "$(printf '{"tool_input":{"file_path":"ok"}}' \
      | awk -f "$root/lib/unjson.awk" -v path=tool_input.file_path 2>/dev/null)" = "ok" ]
}

#
# One line, and it starts where we told it to. Both halves earn it:
# a bashism here answers with two lines and git's output on top,
# so each hook resolving memory writes to whatever came back.
#
# An exported `FOUNDRY_RUN` makes this probe call kernel broken for doing its job.
#
resolver_gives_one_path() {
  resolved=$(FOUNDRY_RUN= CLAUDE_MEMORY_DIR=__kernel_probe__ sh "$root/lib/resolve-memory.sh" 2>/dev/null)
  [ "$(printf '%s\n' "$resolved" | grep -c .)" -eq 1 ] || return 1
  case "$resolved" in
    __kernel_probe__*) return 0 ;;
  esac
  return 1
}

#
# Needs a file, so it needs somewhere to put it. Where it cannot
# write, it declines to judge. And a check going red for what
# it never did is one that people learn to scroll on past.
#
parser_reads_an_objective() {
  probe="${TMPDIR:-/tmp}/kernel-preflight-$$.md"
  printf '**Objective**: ship it\n' > "$probe" 2>/dev/null || return 0
  objective=$(sh "$root/lib/extract-objective.sh" "$probe" 2>/dev/null)
  rm -f "$probe" 2>/dev/null
  [ "$objective" = "ship it" ]
}

awk_is_on_path() { command -v awk >/dev/null 2>&1; }

# Tell the user. This is the only line kernel ever prints unasked.
warn() { printf '{"systemMessage":"kernel: hooks not running — %s"}\n' "$1"; }

# Zero either way. This hook reports in its message, never in its status.
main "$@"
exit 0
