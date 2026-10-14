#!/bin/sh
#
# Fails when a plugin's `hooks.json` holds a top-level key but `hooks`, and `description` beside it.
#
# Claude Code reads `hooks`, and its hooks reference documents an optional `description`. Any other
# key it drops, with a warning at every start, and a warning that always fires teaches a reader to
# skip warnings. Kernel carried `outputStyle` there for weeks. #1036, #1074.
#
# **The keys are read by depth, never by indent.** A minified file, or one indented by four, hid
# every key from the `sed` this replaces. A key nested under `hooks`, or key-like text inside a
# string, is never read as top-level. `bin/hookfiles.awk` is the reader.
#
# **An empty read is not a clean one.** A file with no `hooks` fails, and a glob that finds no file
# exits 3, since a gate that read nothing has said nothing.
#
# Every plugin's file, by glob, so a plugin that ships one tomorrow is read with no edit here.
#
# POSIX `sh` and `awk`. `audit` also needs `bash`, because the suite is bash like every suite here.
#
# Usage: sh bin/hookfiles.sh
#        sh bin/hookfiles.sh audit   drive tests/hookfiles.sh first, then the check
#
# Exit: 0 every file holds hooks alone, 1 one does not, 3 no file was found to read
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

main() {
    [ "${1:-}" = audit ] && prove_it_can_go_red

    files=$(hooks_files)
    ensure_a_file_was_read

    wrong=$(each_fault_in "$files")
    verdict
}

hooks_files() {
    for file in plugins/*/hooks/hooks.json; do
        [ -f "$file" ] && printf '%s\n' "$file"
    done
}

ensure_a_file_was_read() {
    [ -n "$files" ] && return 0
    printf 'FAIL — no plugin ships a hooks.json, so nothing was read.\n'
    exit 3
}

# One line per fault, naming the file and the key, so a reader goes straight to it.
each_fault_in() {
    printf '%s\n' "$1" | while IFS= read -r file; do
        keys=$(awk -f bin/hookfiles.awk "$file")
        printf '%s\n' "$keys" | grep -qx '"hooks"' || printf '%s holds no hooks key\n' "$file"
        printf '%s\n' "$keys" | grep -vx -e '"hooks"' -e '"description"' -e '' \
            | sed "s|^|$file holds a key Claude Code drops: |"
    done
}

verdict() {
    [ -z "$wrong" ] && { printf 'PASS — every hooks.json holds hooks, and a description at most.\n'; exit 0; }

    printf 'FAIL — a hooks.json holds what Claude Code drops:\n'
    printf '%s\n' "$wrong" | sed 's/^/  /'
    exit 1
}

# A gate that has only ever been green proves nothing about what it would catch. The suite plants
# each fault in a copy and reads this script's exit and words.
prove_it_can_go_red() {
    command -v bash >/dev/null 2>&1 || {
        printf 'FAIL — bash is not on this host, so the suite did not run.\n'
        exit 3
    }
    bash "$root/tests/hookfiles.sh" || exit 1
    printf '\n'
}

main "$@"
