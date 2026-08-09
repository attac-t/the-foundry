#!/bin/sh
#
# SessionStart: prove kernel's hooks can still run, and say so when they cannot.
#
# Every way kernel fails is quiet. Nine hooks, and not one of them has anything to report when it
# works — the memory hook prints nothing when there is no memory, the ADR hook prints nothing when
# the file is a document, and the delegation hook prints nothing when there is no blueprint. Silence
# is the healthy reading. So a hook that cannot start, a lib that did not ship, a clone that
# rewrote the line endings, and a shell that cannot parse the script all look exactly like a quiet
# afternoon.
#
# So we run the shipped code against known input and check the answer, once, at the top of the
# session. Silent when it works. One line when it does not.
#

root="$(cd "$(dirname "$0")" && pwd)"

# Determine if the reader still finds a nested value in a hook payload.
reads() {
  [ "$(printf '{"tool_input":{"file_path":"ok"}}' \
      | awk -f "$root/lib/unjson.awk" -v path=tool_input.file_path 2>/dev/null)" = "ok" ]
}

#
# Determine if the memory resolver still answers with exactly one usable path.
#
# One line, and it starts where we told it to. Both halves earn their keep. When `&>` gets back into
# that script, dash reads it as "run in the background, then redirect": the guard cannot fail, and
# git's own output reaches stdout ahead of the path. The answer is two lines and the first is
# wherever git lives. Every hook that resolves memory then writes to a directory named after it.
#
resolves() {
  out=$(CLAUDE_MEMORY_DIR=__kernel_probe__ sh "$root/lib/resolve-memory.sh" 2>/dev/null)
  [ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ] || return 1
  case "$out" in
    __kernel_probe__*) return 0 ;;
  esac
  return 1
}

#
# Determine if the objective parser still reads an objective.
#
# Needs a file, so it needs somewhere to put one. Where it cannot write, it declines to judge: a
# read-only temp directory is not kernel being broken, and a check that goes red for something the
# plugin did not do is a check people learn to scroll past.
#
extracts() {
  probe="${TMPDIR:-/tmp}/kernel-preflight-$$.md"
  printf '**Objective**: ship it\n' > "$probe" 2>/dev/null || return 0
  out=$(sh "$root/lib/extract-objective.sh" "$probe" 2>/dev/null)
  rm -f "$probe" 2>/dev/null
  [ "$out" = "ship it" ]
}

# Tell the user. This is the only line kernel ever prints unasked.
warn() { printf '{"systemMessage":"kernel: hooks not running — %s"}\n' "$1"; }

reads && resolves && extracts && exit 0

command -v awk >/dev/null 2>&1 \
  || { warn "no awk on PATH. kernel needs sh and awk, nothing else."; exit 0; }

warn "awk is there but hooks/lib did not answer. Reinstall the plugin."
exit 0
