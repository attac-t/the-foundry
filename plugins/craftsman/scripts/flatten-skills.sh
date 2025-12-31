#!/bin/bash
# Flatten nested skills directory structure for Claude Code compatibility
#
# Claude Code requires: skills/<skill-name>/SKILL.md
# Current structure:    skills/<category>/<skill-name>/SKILL.md
#
# This script:
# 1. Moves skills from nested to flat structure
# 2. Renames directories to match skill names in frontmatter

set -e

SKILLS_DIR="$(dirname "$0")/../skills"
cd "$SKILLS_DIR"

echo "=== Flattening skills directory ==="
echo "Working in: $(pwd)"
echo ""

# Track counts
moved=0
skipped=0

# Step 1: Move nested skills to flat structure
for skill_md in */*/SKILL.md; do
    [ -f "$skill_md" ] || continue

    category=$(dirname "$(dirname "$skill_md")")
    skill_dir=$(dirname "$skill_md")
    skill_name=$(basename "$skill_dir")

    if [ "$category" = "." ]; then
        ((skipped++))
        continue
    fi

    target_dir="$skill_name"

    if [ -d "$target_dir" ]; then
        echo "SKIP: $skill_name (target exists)"
        ((skipped++))
        continue
    fi

    echo "MOVE: $skill_dir -> $target_dir"
    mv "$skill_dir" "$target_dir"
    ((moved++))
done

# Step 2: Clean up empty category directories
echo ""
echo "=== Cleaning up empty directories ==="
for dir in */; do
    [ -d "$dir" ] || continue
    [ -f "$dir/SKILL.md" ] && continue

    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "REMOVE: $dir (empty)"
        rmdir "$dir"
    fi
done

# Step 3: Rename directories to match skill names in frontmatter
echo ""
echo "=== Syncing directory names with frontmatter ==="
renamed=0
for dir in */; do
    skill_md="$dir/SKILL.md"
    [ -f "$skill_md" ] || continue

    name=$(grep '^name:' "$skill_md" | sed 's/name: //')
    current=$(basename "$dir")

    if [ -n "$name" ] && [ "$name" != "$current" ]; then
        echo "RENAME: $current -> $name"
        mv "$dir" "$name"
        ((renamed++))
    fi
done

echo ""
echo "=== Summary ==="
echo "Moved:   $moved skills"
echo "Renamed: $renamed skills"
echo "Skipped: $skipped skills"
echo ""
echo "Done. Reinstall the plugin to update the cache:"
echo "  /plugin uninstall craftsman@the-foundry"
echo "  /plugin install craftsman@the-foundry"
