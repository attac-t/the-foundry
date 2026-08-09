#!/bin/bash
# Runs the hooks the way Claude Code runs them, from the string Claude Code reads.
#
# The other suites call `bash hooks/signal.sh`. That is a paraphrase of the wiring, and it stayed
# green through a release where the shipped hook could not start at all: the file was not
# executable, so the real invocation died with "Permission denied" and the plugin scored nothing for
# every user who installed it.
#
# So this suite restates nothing. It reads the command out of hooks.json, exports the variable
# Claude Code exports, and hands the whole thing to a shell.
#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

hooks="$root/hooks/hooks.json"
tmp="${TMPDIR:-/tmp}/signal-install-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

bad='Additionally, it is worth noting that we should leverage this comprehensive functionality in order to facilitate a robust implementation.'
good='We cut it by ten. The hook reads what the agent said.'

# One line per wired hook: the event, a tab, the command string Claude Code will run.
wiring() {
  awk '
    /^[ \t]*"[A-Z][A-Za-z]*"[ \t]*:[ \t]*\[/ { event = $0; sub(/^[ \t]*"/, "", event); sub(/".*/, "", event) }
    /"command"[ \t]*:/ {
      cmd = $0
      sub(/^[^:]*:[ \t]*"/, "", cmd)
      sub(/",?[ \t]*$/, "", cmd)
      gsub(/\\"/, "\"", cmd)
      print event "\t" cmd
    }
  ' "$hooks"
}

# Get the command wired to an event.
command_for() { wiring | awk -F'\t' -v want="$1" '$1 == want { print $2; exit }'; }

# Run an event's hook exactly as Claude Code would: its own shell, its own variable, JSON on stdin.
fire() {
  printf '%s' "$2" | CLAUDE_PLUGIN_ROOT="${3:-$root}" sh -c "$(command_for "$1")" 2>/dev/null
}

# Build a Stop payload.
stop() { printf '{"session_id":"install-%s","prompt_id":"p1","stop_hook_active":false,"last_assistant_message":"%s"}' "$$" "$1"; }

# Get every file the plugin needs at runtime.
shipped() { find "$root/hooks" "$root/lib" -type f | sort; }

# Determine if a file carries a carriage return.
has_cr() { tr -dc '\r' < "$1" | wc -c | tr -d ' ' | grep -qv '^0$'; }

#
# Determine if this filesystem records an executable bit at all.
#
# Windows does not. MSYS2 mounts with noacl, so chmod is accepted and ignored, and Git Bash decides
# what may run by reading the shebang instead. Checking a bit that cannot exist there would fail the
# suite for a difference that costs nothing, and quietly breaking the check to keep it green would
# be worse. So ask the filesystem, and skip out loud when the answer is no.
#
records_exec() {
  probe="$tmp/exec-probe"
  : > "$probe"
  chmod +x "$probe" 2>/dev/null
  [ -x "$probe" ] || return 1
  chmod -x "$probe" 2>/dev/null
  [ ! -x "$probe" ]
}

echo "install"

# --- every wired hook is really there ---

events=$(wiring | cut -f1 | tr '\n' ' ')
has "hooks.json wires SessionStart" "$events" "SessionStart"
has "hooks.json wires Stop"         "$events" "Stop"
has "hooks.json wires SessionEnd"   "$events" "SessionEnd"

# --- the shipped invocation works ---
# This is the check the release needed and did not have.

out=$(fire Stop "$(stop "$bad")")
has "the wired Stop command blocks bad prose" "$out" '"decision":"block"'
is  "the wired Stop command passes good prose" "$(fire Stop "$(stop "$good")")" ""
is  "the wired SessionStart command is silent when healthy" "$(fire SessionStart '{"source":"startup"}')" ""
is  "the wired SessionEnd command is silent" "$(fire SessionEnd '{"session_id":"install-'"$$"'"}')" ""

# --- a path with a space in it ---
# `C:\Users\John Smith` and `/Users/me/My Plugins` are both ordinary. An unquoted variable in
# hooks.json splits on that space and the hook never starts.

cp -R "$root" "$tmp/with space" 2>/dev/null
out=$(fire Stop "$(stop "$bad")" "$tmp/with space")
has "the wired command survives a space in the path" "$out" '"decision":"block"'

# --- the files can start ---
# hooks.json names `sh` now, so the shell no longer needs this bit to start the hook. Keep it
# anyway. It is what a reader checks first when a hook goes quiet, and its absence is what made the
# old wiring — a bare path, no interpreter — fail on every install.

if records_exec; then
  for file in $(shipped); do
    case "$file" in
      *.sh) [ -x "$file" ] && ok "executable — ${file##*/}" || bad "not executable — ${file##*/}" ;;
    esac
  done
else
  skip "executable bits — this filesystem does not record them"
fi

# --- line endings ---
# Git for Windows clones with core.autocrlf=true. A hook that arrives with CRLF does not merely
# fail: bash dies parsing it and exits 2, and 2 on a Stop hook means block. Every turn.

crlf=0
for file in $(shipped); do
  has_cr "$file" && { crlf=1; bad "carriage returns — ${file##*/} would not run on Windows"; }
done
[ "$crlf" -eq 0 ] && ok "every shipped file is LF only"

# --- and git will keep it that way ---
# Asked of the repo, never of PLUGIN_ROOT: attributes govern what gets committed, and a copy under
# /tmp has no git to ask. Pointing this at the copy would answer "no" to every mutation and turn the
# audit below into a green light for anything.

for kind in sh awk; do
  case "$(cd "$here" && git check-attr eol -- "x.$kind" 2>/dev/null)" in
    *"eol: lf") ok "git pins .$kind files to LF" ;;
    *)          bad "nothing pins .$kind files to LF — add it to .gitattributes" ;;
  esac
done

# --- the preflight earns its place ---
# Take awk away and signal cannot judge anything. It has to say so.

mkdir -p "$tmp/noawk"
ln -sf "$(command -v sh)" "$tmp/noawk/sh"
out=$(printf '{"source":"startup"}' | env PATH="$tmp/noawk" CLAUDE_PLUGIN_ROOT="$root" sh -c "$(command_for SessionStart)" 2>/dev/null)
has "with no awk the preflight speaks up" "$out" '"systemMessage"'
has "and it names what is missing"        "$out" 'awk'

summary "install"
