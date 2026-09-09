#!/bin/sh
#
# Fails when a build recipe names a secret.
#
# **A layer is permanent.** Deleting a file in a later step leaves it in the one before, and anyone
# who can pull the image can read it. A secret committed to a `Dockerfile` cannot be taken back by
# editing the `Dockerfile`.
#
# #177 drew the line and this keeps it: the host holds the secret and the container is handed it.
# Passing one in when the container starts is not the same as baking one.
#
# **`ARG` is the trap.** Its value is recorded in the image history, so an argument that looks
# temporary is not — and a check reading `ENV` and missing `ARG` answers confidently and wrongly.
#
# **This grades the recipe and never the built image.** Reading an image needs Docker, a network and
# a build, and `.claude/rules/plugins.md` refuses a check that goes red on a train. What is inside a
# built layer is out of reach here, and saying so is the honest half of the answer.
#
# A comment may name a secret. The sentence above does.
#
# Usage: sh bin/secrets.sh
#
# Exit: 0 no recipe names one, 1 a recipe does, 3 the gate could not read
#
set -u

cd "$(dirname "$0")/.." || exit 3

# Whole words a reader would call a secret. `key` alone is not among them — it lives inside
# `keyring` and `monkey`, and a gate that cries at those is one people learn to ignore.
NAMES='token|secret|password|passwd|credential|api_key|apikey|private_key'

say()  { printf '%s\n' "$1"; }
fail() { printf 'secrets: %s\n' "$1" >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    recipes=$(build_recipes)

    [ -n "$recipes" ] || fail 'no build recipe here, so this gate read nothing'

    caught=$(named_in_a_recipe "$recipes")

    [ -z "$caught" ] || refuse "$caught"

    say "secrets  no recipe names one"
}

# Every recipe this repository ships, by name rather than by directory. A `Dockerfile` may sit
# anywhere, and a gate that looks in one place stops working the day somebody adds a second.
build_recipes() {
    git ls-files | grep -Ei '(^|/)[^/]*dockerfile[^/]*$' 2>/dev/null
}

named_in_a_recipe() {
    for recipe in $1; do
        [ -r "$recipe" ] || fail "$recipe could not be read"

        name_the_lines "$recipe"
    done
}

#
# A line whose first character is a hash is prose, and prose may name a secret — the header above
# does it four times.
#
# Three directives carry one, and each carries it differently. `ENV` bakes a value into the image.
# `ARG` records its value in the history whether or not the recipe gives one, so the name alone is
# the doorway. `COPY` brings a file in, and a deleted file stays in the layer that added it.
name_the_lines() {
    awk -v file="$1" -v names="$NAMES" '
        { bare = $0; sub(/^[[:space:]]+/, "", bare) }

        bare ~ /^#/                             { next }
        bare !~ /^(ENV|ARG|COPY|ADD)[[:space:]]/ { next }

        tolower(bare) ~ names { printf "         %s:%d  %s\n", file, NR, bare }
    ' "$1"
}

# Every line, never the first. A recipe with three is three edits, and a gate naming one sends the
# reader back twice for what it already knew.
refuse() {
    say "$1"
    say "secrets  a build recipe names a secret. The host holds one; the image never does."
    exit 1
}

main "$@"
