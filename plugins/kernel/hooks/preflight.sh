#!/bin/sh
#
# SessionStart: prove kernel's hooks can still run, and say so when they cannot.
#
# Every way kernel fails is quiet. Not one of kernel's hooks has anything to report when it works —
# the memory hook prints nothing when there is no memory, the ADR hook prints nothing when the file
# is a document, and the delegation hook prints nothing when there is no blueprint. Silence is the
# healthy reading. So a hook that cannot start, a lib that did not ship, a clone that rewrote the
# line endings, and a shell that cannot parse the script all look exactly like a quiet afternoon.
#
# So we run the shipped code against known input and check the answer, once, at the top of the
# session. Silent when it works. One line when it does not.
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
# One line, and it starts where we told it to. Both halves earn their keep: resolve-memory.sh's
# header names a bashism that answers with two lines and git's own output on top, and every hook
# that resolves memory then writes to a directory named after whatever came back.
#
# `FOUNDRY_RUN=`, or a developer with one exported sees this probe call kernel broken for doing its
# job.
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
# Needs a file, so it needs somewhere to put one. Where it cannot write, it declines to judge: a
# read-only temp directory is not kernel being broken, and a check that goes red for something the
# plugin did not do is a check people learn to scroll past.
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
