#!/bin/bash
#
# generate-stubs.sh - Copy template files to target directory
#
# Usage: ./generate-stubs.sh [templates_dir] [target_dir]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${1:-$SCRIPT_DIR/../templates}"
TARGET_DIR="${2:-$(pwd)}"

echo "==> Generating stubs from templates"
echo "    Source: $TEMPLATES_DIR"
echo "    Target: $TARGET_DIR"

# Copy all template files preserving directory structure
cd "$TEMPLATES_DIR"
find . -type f | while read -r file; do
    # Remove leading ./
    relative_path="${file#./}"
    target_file="$TARGET_DIR/$relative_path"
    target_dir="$(dirname "$target_file")"

    # Create directory if needed
    mkdir -p "$target_dir"

    # Copy file
    cp "$file" "$target_file"
done

echo "    Copied $(find . -type f | wc -l | tr -d ' ') files"
