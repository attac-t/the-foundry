#!/bin/bash
# A `PATH` with one tool taken off it, for a case that drives a host without that tool. Sourced, never run.
#
# **Each directory holding the tool is swapped for one of links to everything else in it.** Dropping
# the directory would drop `sh`, `git` and `awk` with it wherever the tool sits beside them, and the
# grade image installs `gh` beside all three. Emptying `PATH` would leave the runner nothing to call.
#
# Built once under the directory named, and read back after that, so every case asking pays once.

path_without() {
  [ -s "$2/PATH" ] || write_a_path_without "$1" "$2" || return 1
  cat "$2/PATH"
}

write_a_path_without() {
  local dir kept='' n=0
  mkdir -p "$2" || return 1

  while IFS= read -r dir; do
    n=$((n + 1))
    holds "$dir" "$1" || { kept="$kept:$dir"; continue; }
    link_all_but "$1" "$dir" "$2/$n" || return 1
    kept="$kept:$2/$n"
  done <<EOF
$(printf '%s\n' "$PATH" | tr ':' '\n')
EOF

  printf '%s' "${kept#:}" > "$2/PATH"
}

# `-e` finds `gh.exe` as `gh` on Git Bash, which is where the second name below comes from.
holds() { [ -n "$1" ] && [ -e "$1/$2" ]; }

# One `ln` for the whole directory. One per name starts a process for each of a thousand names.
link_all_but() {
  local entry links=()
  mkdir -p "$3" || return 1

  for entry in "$2"/*; do
    case ${entry##*/} in "$1"|"$1.exe") continue ;; esac
    links+=("$entry")
  done

  [ "${#links[@]}" -eq 0 ] || ln -s "${links[@]}" "$3"/
}
