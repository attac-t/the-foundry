#!/bin/bash
# Runs the hooks the way Claude Code runs them, from the string Claude Code reads.
#
# model.sh calls the runner directly. That is a paraphrase of the wiring, and a paraphrase stays
# green through every failure that lives in hooks.json — which is where kernel's and signal's
# failures both lived. So this suite restates nothing: it reads the command out of hooks.json,
# exports the variable Claude Code exports, and hands the whole thing to a shell.
#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

hooks="$root/hooks/hooks.json"
tmp="${TMPDIR:-/tmp}/floor-install-$$"
home="$tmp/home"
mkdir -p "$tmp/bare" "$home"
trap 'rm -rf "$tmp"' EXIT

#
# One line per wired hook: event, script, declared shell, and the command string Claude Code runs.
#
# Buffered and flushed, because the shell a hook declares sits on the line after its command, and a
# hook that declares none has to come out of here marked rather than silently paired with the next
# one's.
#
wiring() {
  awk '
    function flush() {
      if (pending == "") return
      script = pending
      sub(/.*\//, "", script)
      sub(/"[ \t]*$/, "", script)
      print pevent "\t" script "\t" (shell == "" ? "-" : shell) "\t" pending
      pending = ""; shell = ""
    }
    /^[ \t]*"[A-Z][A-Za-z]*"[ \t]*:[ \t]*\[/ {
      event = $0; sub(/^[ \t]*"/, "", event); sub(/".*/, "", event)
    }
    /"command"[ \t]*:/ {
      flush()
      cmd = $0
      sub(/^[^:]*:[ \t]*"/, "", cmd)
      sub(/",?[ \t]*$/, "", cmd)
      gsub(/\\"/, "\"", cmd)
      pending = cmd; pevent = event
    }
    /"shell"[ \t]*:/ {
      s = $0; sub(/^[^:]*:[ \t]*"/, "", s); sub(/".*/, "", s); shell = s
    }
    END { flush() }
  ' "$hooks"
}

# Get the command wired to a script.
command_for() { wiring | awk -F'\t' -v want="$1" '$2 == want { print $4; exit }'; }

# Get the shell a script declares.
shell_for() { wiring | awk -F'\t' -v want="$1" '$2 == want { print $3; exit }'; }

# Get the event a script is wired to.
event_for() { wiring | awk -F'\t' -v want="$1" '$2 == want { print $1; exit }'; }

# List every script hooks.json wires.
wired() { wiring | cut -f2 | sort -u; }

# List every hook script the plugin ships. bin/ is left out — that is floor's CLI, called by hooks
# and by people, and nothing should wire it.
shipped_hooks() { find "$root/hooks" -maxdepth 1 -name '*.sh' -type f | sed 's|.*/||' | sort; }

# List the path of every script the plugin runs — hooks and the CLI both.
runtime_scripts() { find "$root/hooks" "$root/bin" -type f -name '*.sh' | sort; }

# Run a hook exactly as Claude Code would: its own shell, its own variable, JSON on stdin.
fire() {
  ( cd "${FIRE_CWD:-$tmp/bare}" 2>/dev/null || exit 0
    printf '%s' "$2" \
      | CLAUDE_PLUGIN_ROOT="$root" FOUNDRY_HOME="$home" FOUNDRY_RUN="${FIRE_RUN:-}" TMPDIR="$tmp" \
        sh -c "$(command_for "$1")" 2>/dev/null )
}

# Make a run in a given directory, and print its path.
make_run_in() {
  ( cd "$1" 2>/dev/null || exit 9
    FOUNDRY_HOME="$home" FOUNDRY_RUN= sh "$root/bin/run.sh" new "$2" 2>/dev/null )
}

# Determine if a file carries a carriage return.
has_cr() { tr -dc '\r' < "$1" | wc -c | tr -d ' ' | grep -qv '^0$'; }

#
# Determine if this filesystem records an executable bit at all.
#
# Windows does not. MSYS2 mounts with noacl, so chmod is accepted and ignored, and Git Bash decides
# what may run by reading the shebang instead. Checking a bit that cannot exist there would fail the
# suite for a difference that costs nothing, and quietly dropping the check would be worse.
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

# --- everything shipped is wired, and everything wired is shipped ---

for script in $(shipped_hooks); do
  case " $(wired | tr '\n' ' ') " in
    *" $script "*) ok "hooks.json wires $script" ;;
    *)             bad "$script ships but nothing wires it" ;;
  esac
done

for script in $(wired); do
  [ -f "$root/hooks/$script" ] && ok "wired and present — $script" \
                               || bad "hooks.json wires $script, which did not ship"
done

# --- the wiring is the portable form ---
# Four ways the wiring fails, in the order checked below: no interpreter, no declared shell, an event
# that cannot inject, an unquoted root. kernel or signal shipped every one of them.

for script in $(wired); do
  case "$(command_for "$script")" in
    "sh "*) ok "names an interpreter — $script" ;;
    *)      bad "$script runs a bare path — it needs an executable bit Windows will not give it" ;;
  esac
done

for script in $(wired); do
  is "declares its shell — $script" "$(shell_for "$script")" "bash"
done

# Only SessionStart, UserPromptSubmit and Setup inject stdout. Move either hook to Stop and it still
# runs, still exits 0, and reaches nobody.
for script in $(wired); do
  is "fires on SessionStart — $script" "$(event_for "$script")" "SessionStart"
done

placeholders=$(grep -cF '${CLAUDE_PLUGIN_ROOT}' "$hooks")
quoted=$(grep -cF '\"${CLAUDE_PLUGIN_ROOT}' "$hooks")
is "every plugin root is quoted" "$quoted" "$placeholders"

# --- the shipped invocation works ---

is "preflight is silent when healthy" "$(fire preflight.sh '{"source":"startup"}')" ""
is "announce is silent with no run"   "$(fire announce.sh '{"source":"startup"}')"  ""

made=$(make_run_in "$tmp/bare" "Wired Up")
handed=$(FIRE_RUN="$made" fire announce.sh '{"source":"startup"}')

has   "announce names the run it was handed"            "$handed" "$(basename "$made")"
lacks "and says nothing about the variable when it is set" "$handed" "is not set"

announce_through_the_pointer() {
  git init -q "$tmp/pointed" >/dev/null 2>&1 && [ -d "$tmp/pointed/.git" ] \
    || { skip "announce through the pointer — git could not make a repo here"; return; }

  make_run_in "$tmp/pointed" "Via Pointer" >/dev/null
  spoke=$(FIRE_CWD="$tmp/pointed" fire announce.sh '{"source":"startup"}')

  has "announce finds a run through the pointer alone" "$spoke" "via-pointer"
  has "and warns that memory has not moved with it"    "$spoke" "FOUNDRY_RUN is not set"
}
announce_through_the_pointer

# --- the scripts parse where they will be run ---
# `sh -n` reads without running. The cheapest way to catch a bashism that would otherwise wait for
# the one user whose /bin/sh is dash.

for file in $(runtime_scripts); do
  sh -n "$file" 2>/dev/null && ok "parses under sh — ${file##*/}" \
                            || bad "will not parse under sh — ${file##*/}"
done

the_files_can_start() {
  records_exec || { skip "executable bits — this filesystem does not record them"; return; }

  for file in $(runtime_scripts); do
    [ -x "$file" ] && ok "executable — ${file##*/}" || bad "not executable — ${file##*/}"
  done
}
the_files_can_start

# --- line endings ---
# Git for Windows clones with core.autocrlf=true. A hook that arrives with CRLF does not merely
# fail: the shell dies parsing it.

crlf=0
for file in $(runtime_scripts); do
  has_cr "$file" && { crlf=1; bad "carriage returns — ${file##*/} would not run on Windows"; }
done
[ "$crlf" -eq 0 ] && ok "every shipped file is LF only"

# --- and git will keep it that way ---
# Asked of the repo, never of PLUGIN_ROOT: attributes govern what gets committed, and a copy under
# /tmp has no git to ask.

case "$(cd "$here" && git check-attr eol -- "x.sh" 2>/dev/null)" in
  *"eol: lf") ok "git pins .sh files to LF" ;;
  *)          bad "nothing pins .sh files to LF — add it to .gitattributes" ;;
esac

the_preflight_earns_its_place() {
  cp -R "$root" "$tmp/broken" 2>/dev/null \
    || { skip "the preflight with a broken runner — could not copy the plugin here"; return; }

  printf 'exit 7\n' > "$tmp/broken/bin/run.sh"
  out=$( cd "$tmp/bare" && printf '{"source":"startup"}' \
    | CLAUDE_PLUGIN_ROOT="$tmp/broken" sh -c "$(command_for preflight.sh)" 2>/dev/null )
  has "with a broken runner the preflight speaks up" "$out" '"systemMessage"'
}
the_preflight_earns_its_place

summary "install"
