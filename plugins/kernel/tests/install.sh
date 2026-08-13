#!/bin/bash
# Runs the hooks the way Claude Code runs them, from the string Claude Code reads.
#
# The other suites call the lib scripts directly. That is a paraphrase of the wiring, and a
# paraphrase stays green through every failure that lives in hooks.json — which is where kernel's
# failures lived. Nine hooks named a bare path with no interpreter: they needed an executable bit to
# start, and Windows records no such bit. Nothing here would have noticed, because nothing here
# read the wiring.
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
tmp="${TMPDIR:-/tmp}/kernel-install-$$"
mkdir -p "$tmp/bare" "$tmp/mem"
trap 'rm -rf "$tmp"' EXIT

printf '**Objective**: Ship the harness\n'        > "$tmp/mem/working.md"
printf '| id | state |\n| 1 | in-progress |\n'    > "$tmp/mem/blueprint.md"

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

# List every script hooks.json wires.
wired() { wiring | cut -f2 | sort -u; }

# List every hook script the plugin ships. lib/ is left out — those are called by hooks, not by
# Claude Code, and nothing should wire them.
shipped_hooks() { find "$root/hooks" -maxdepth 1 -name '*.sh' -type f | sed 's|.*/||' | sort; }

# List every file the plugin needs at runtime.
shipped() { find "$root/hooks" -type f \( -name '*.sh' -o -name '*.awk' \) | sort; }

#
# Run a hook exactly as Claude Code would: its own shell, its own variable, JSON on stdin.
#
# The working directory is a plain directory with no git in it, so the memory resolver returns the
# fixture path untouched and the checks below can name what they expect.
#
fire() {
  ( cd "${FIRE_CWD:-$tmp/bare}" 2>/dev/null || exit 0
    printf '%s' "$2" \
      | CLAUDE_PLUGIN_ROOT="${FIRE_ROOT:-$root}" CLAUDE_MEMORY_DIR="$tmp/mem" FOUNDRY_RUN= TMPDIR="$tmp" \
        sh -c "$(command_for "$1")" 2>/dev/null )
}

# Determine if a file carries a carriage return.
has_cr() { tr -dc '\r' < "$1" | wc -c | tr -d ' ' | grep -qv '^0$'; }

#
# Determine if this filesystem records an executable bit at all.
#
# Windows does not. MSYS2 mounts with noacl, so chmod is accepted and ignored, and Git Bash decides
# what may run by reading the shebang instead. Checking a bit that cannot exist there would fail the
# suite for a difference that costs nothing, and quietly dropping the check to stay green would be
# worse. So ask the filesystem, and skip out loud when the answer is no.
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
#
# Three checks for the three ways the old wiring failed on Windows. Each one is a string in a JSON
# file, which is exactly the kind of thing that goes wrong quietly and stays wrong for releases.

for script in $(wired); do
  case "$(command_for "$script")" in
    "sh "*) ok "names an interpreter — $script" ;;
    *)      bad "$script runs a bare path — it needs an executable bit Windows will not give it" ;;
  esac
done

for script in $(wired); do
  is "declares its shell — $script" "$(shell_for "$script")" "bash"
done

placeholders=$(grep -cF '${CLAUDE_PLUGIN_ROOT}' "$hooks")
quoted=$(grep -cF '\"${CLAUDE_PLUGIN_ROOT}' "$hooks")
is "every plugin root is quoted" "$quoted" "$placeholders"

# --- the shipped invocation works ---
# These are the checks the release needed and did not have.

is  "preflight is silent when healthy"    "$(fire preflight.sh '{"source":"startup"}')" ""
has "remember loads working memory"       "$(fire remember.sh '{"source":"startup"}')" "Ship the harness"
has "ground demands grounding"            "$(fire ground.sh '{"source":"startup"}')" "GROUND NOW"
has "anchor echoes the objective"         "$(fire anchor.sh '{"prompt":"go"}')" "Ship the harness"
has "recite points at working memory"     "$(fire recite.sh '{"prompt":"go"}')" "working.md"
has "evaluate forces skill evaluation"    "$(fire evaluate.sh '{"prompt":"go"}')" "Skill Evaluation"
has "delegate fires with a blueprint"     "$(fire delegate.sh '{"prompt":"go"}')" "Delegation Check"
has "verify blocks on in-progress work"   "$(fire verify.sh '{"stop_hook_active":false}')" '"decision"'

# Once per turn, not eight. The payload above already carried the flag; nothing had ever read it.
is "verify stands down once a stop hook is driving the turn" \
   "$(fire verify.sh '{"stop_hook_active":true}')" ""

# --- the ADR nudge reads the payload ---
# The jq-shaped hole: with no reader, the path came back empty, nothing matched the skip list, and
# the nudge fired on every write it exists to stay out of.

has "consider nudges on code" \
    "$(fire consider.sh '{"tool_input":{"file_path":"/app/src/Order.php"}}')" "additionalContext"
is  "consider is quiet on docs" \
    "$(fire consider.sh '{"tool_input":{"file_path":"/app/README.md"}}')" ""
is  "consider is quiet on a unix test path" \
    "$(fire consider.sh '{"tool_input":{"file_path":"/app/tests/OrderTest.php"}}')" ""
is  "consider is quiet on a windows test path" \
    "$(fire consider.sh '{"tool_input":{"file_path":"C:\\app\\tests\\OrderTest.php"}}')" ""
is  "consider is quiet when it cannot read a path" \
    "$(fire consider.sh '{"tool_input":{}}')" ""
has "content holding a decoy path does not fool it" \
    "$(fire consider.sh '{"tool_input":{"file_path":"/app/src/A.php","content":"{\"file_path\":\"/x.md\"}"}}')" "additionalContext"

# --- a path with a space in it ---
# `C:\Program Files\ClaudeCode\plugins` is where Windows actually puts this. An unquoted variable in
# hooks.json splits on that space and the hook never starts.

if cp -R "$root" "$tmp/with space" 2>/dev/null; then
  has "the wired command survives a space in the path" \
      "$(FIRE_ROOT="$tmp/with space" fire ground.sh '{"source":"startup"}')" "GROUND NOW"
else
  skip "a space in the path — could not copy the plugin here"
fi

# --- the scripts parse where they will be run ---
# `sh -n` reads without running. It is the cheapest way to catch a bashism that would otherwise wait
# for the one user whose /bin/sh is dash.

for file in $(shipped); do
  case "$file" in
    *.sh) sh -n "$file" 2>/dev/null && ok "parses under sh — ${file##*/}" \
                                    || bad "will not parse under sh — ${file##*/}" ;;
  esac
done

# --- the files can start ---
# hooks.json names `sh` now, so the shell no longer needs this bit to start a hook. Keep it anyway.
# It is what a reader checks first when a hook goes quiet, and its absence is what made the old
# wiring — a bare path, no interpreter — fail on every install that recorded it.

if records_exec; then
  for file in $(shipped); do
    case "$file" in
      */lib/*.awk) ;;
      *.sh) [ -x "$file" ] && ok "executable — ${file##*/}" || bad "not executable — ${file##*/}" ;;
    esac
  done
else
  skip "executable bits — this filesystem does not record them"
fi

# --- line endings ---
# Git for Windows clones with core.autocrlf=true. A hook that arrives with CRLF does not merely
# fail: the shell dies parsing it, and a Stop hook that exits 2 means block. Every turn.

crlf=0
for file in $(shipped); do
  has_cr "$file" && { crlf=1; bad "carriage returns — ${file##*/} would not run on Windows"; }
done
[ "$crlf" -eq 0 ] && ok "every shipped file is LF only"

# --- and git will keep it that way ---
# Asked of the repo, never of PLUGIN_ROOT: attributes govern what gets committed, and a copy under
# /tmp has no git to ask. Pointing this at the copy would answer "no" to every mutation and turn the
# audit into a green light for anything.

for kind in sh awk; do
  case "$(cd "$here" && git check-attr eol -- "x.$kind" 2>/dev/null)" in
    *"eol: lf") ok "git pins .$kind files to LF" ;;
    *)          bad "nothing pins .$kind files to LF — add it to .gitattributes" ;;
  esac
done

# --- the preflight earns its place ---
# Take awk away and kernel cannot read a payload or trust a path. It has to say so.

#
# Determine if this platform can hand a shell a PATH holding `sh` and nothing else.
#
# Windows cannot. `ln -s` under Git Bash writes a copy, and a copied `sh.exe` cannot find the DLLs
# it lived beside, so nothing starts and the check below reads empty. A symlink failure wearing the
# costume of a preflight failure, red on the one platform the runtime gate exists to cover.
#
strippable() {
  mkdir -p "$tmp/noawk"
  ln -sf "$(command -v sh)" "$tmp/noawk/sh" 2>/dev/null || return 1
  PATH="$tmp/noawk" "$tmp/noawk/sh" -c 'exit 0' 2>/dev/null
}

if strippable; then
  out=$(printf '{"source":"startup"}' \
    | env PATH="$tmp/noawk" CLAUDE_PLUGIN_ROOT="$root" sh -c "$(command_for preflight.sh)" 2>/dev/null)
  has "with no awk the preflight speaks up" "$out" '"systemMessage"'
  has "and it names what is missing"        "$out" 'awk'
else
  skip "the preflight with no awk — this platform cannot build a PATH without it"
fi

summary "install"
