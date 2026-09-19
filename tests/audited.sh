#!/bin/bash
# What `bin/audited.sh` counts as a branch the audit can answer, and what it refuses to.
#
# **The check exists to stop paying for an answer nobody can change.** Measured 19 September:
# ten of fourteen merges touched no file under `plugins/`, and each ran a full 273-break audit.
#
# Driven against real trees this suite builds, so every check is the real script reading a real
# diff. A fixture of file names would prove the `case` and nothing about git.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 — [$3] missing from [$2]" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1 — [$3] is in [$2]" ;; *) ok "$1" ;; esac; }

echo "audited"

tmp="${TMPDIR:-/tmp}/audited-suite-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# A repository with the check in it, a base commit, and a branch off that base.
#
# **The check reads `git diff`, so a fixture needs real commits.** Naming files in a variable
# would grade the `case` arm and never the comparison it depends on.
repo="$tmp/r"
mkdir -p "$repo/bin" "$repo/plugins/floor/bin"
cp "$root/bin/audited.sh" "$repo/bin/audited.sh"
chmod +x "$repo/bin/audited.sh"

git -C "$repo" init -q .
git -C "$repo" config user.email fixture@example.invalid
git -C "$repo" config user.name fixture
printf 'seed\n' > "$repo/plugins/floor/bin/run.sh"
printf 'seed\n' > "$repo/.gitattributes"
printf 'seed\n' > "$repo/README.md"
git -C "$repo" add -A >/dev/null
git -C "$repo" commit -qm seed
git -C "$repo" branch -q base

asked() { ( cd "$repo" && sh bin/audited.sh base 2>&1 ); }
code()  { ( cd "$repo" && sh bin/audited.sh base >/dev/null 2>&1 ); printf '%s' "$?"; }

# Start every case from the base, so one case cannot leave a file for the next.
from_base() { git -C "$repo" checkout -q base && git -C "$repo" checkout -q -B probe; }

changed() {
    from_base
    printf '%s\n' "$2" > "$repo/$1"
    git -C "$repo" add -A >/dev/null
    git -C "$repo" commit -qm "touch $1"
}

# --- the plugin itself ---

changed plugins/floor/bin/run.sh 'changed'
is  "a change under plugins is audited" "$(code)" "0"
has "and it names the file"             "$(asked)" "plugins/floor/bin/run.sh"

# --- prose the audit never reads ---

changed README.md 'changed'
is  "a change to prose alone is not" "$(code)" "1"
has "and it says which file said so" "$(asked)" "README.md"

# --- what shapes the clone ---
#
# **Three files outside the plugin still reach it.** Line endings travel into every shipped script,
# what a clone holds at all is decided before the suite runs, and the gate that runs the suite can
# change how. Each is named in the script with its reason.

changed .gitattributes 'changed'
is "line endings are audited, though they are not under plugins" "$(code)" "0"

# --- a branch that changed nothing ---

from_base
is  "a branch level with its target is not audited" "$(code)" "1"
has "and it says there is nothing to grade"         "$(asked)" "nothing to grade"

# --- both at once ---
#
# One file the audit reads is enough. A branch is audited or it is not, and a majority is not the
# question.

from_base
printf 'changed\n' > "$repo/README.md"
printf 'changed\n' > "$repo/plugins/floor/bin/run.sh"
git -C "$repo" add -A >/dev/null
git -C "$repo" commit -qm both

is    "one file the audit reads carries the whole branch" "$(code)" "0"
has   "and that file is named"                            "$(asked)" "plugins/floor/bin/run.sh"
lacks "and the prose beside it is not"                    "$(asked)" "README.md"

# --- the exemption list says why ---
#
# **A name with no reason is an exemption nobody can argue with.** The list is typed because a
# derived one would have to guess which root file reaches a clone — so the reason is the check on
# the typing.

bare=$(awk '/^FORCES_AN_AUDIT=/, /^'"'"'$/' "$root/bin/audited.sh" |
       grep -E '^[.a-z/]+' | awk 'NF < 2 { print $1 }')

is "every exempt file says why it is there" "$bare" ""

# --- the check sits under the bar it guards ---
#
# **A check that says when the audit may be skipped can exempt itself.** The delegate named that
# when approving: a branch touching only `bin/audited.sh` is audited, or the guard guards nothing.

# **Appended, never replaced.** Overwriting the script is overwriting the thing under test, and
# the case then grades a missing file. It read 127 and looked like a refusal.
from_base
printf '
# a comment
' >> "$repo/bin/audited.sh"
git -C "$repo" add -A >/dev/null
git -C "$repo" commit -qm "touch the check"

is "the check that waives the audit is itself audited" "$(code)" "0"

# --- a waiver says so, in words the check writes ---
#
# **Twenty-five ran. Twenty-four graded their full claim, one graded less.** That is a different
# count, and the gate prints it so a person never types it.

changed README.md 'changed'
has "a waived audit prints the line a record carries" "$(asked)" "ALL GREEN, 25 of 25, audit waived:"
has "and the line says which files waived it"        "$(asked)" "README.md"

# --- a target that is not there ---

is  "a target nothing can compare against refuses" \
    "$( ( cd "$repo" && sh bin/audited.sh no-such-ref >/dev/null 2>&1 ); printf '%s' "$?" )" "3"

printf '\naudited — %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
