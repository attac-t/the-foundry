#!/bin/bash
#
# setup.sh - Qualitative Test Environment Orchestrator
#
# Creates a Laravel DDD scaffold for plugin testing.
# Includes spatie/laravel-data v4 and laravel-media-library patterns.
#
# Usage: ./setup.sh [--reset]
#

set -e

TEST_ENV="/tmp/craftsman-test-env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Setting up qualitative test environment at $TEST_ENV"

# Handle existing environment
if [ -d "$TEST_ENV" ]; then
    echo "    Resetting existing environment..."
    "$SCRIPT_DIR/scripts/init-git.sh" reset "$TEST_ENV"
else
    echo "    Creating fresh environment..."
    mkdir -p "$TEST_ENV"
fi

cd "$TEST_ENV"

# 1. Create directory structure
"$SCRIPT_DIR/scripts/scaffold-ddd.sh" "$TEST_ENV"

# 2. Copy template files
"$SCRIPT_DIR/scripts/generate-stubs.sh" "$SCRIPT_DIR/templates" "$TEST_ENV"

# 3. Initialize git (only if not already initialized)
if [ ! -d "$TEST_ENV/.git" ]; then
    "$SCRIPT_DIR/scripts/init-git.sh" init "$TEST_ENV"
else
    # Commit any new changes
    git add -A
    git commit -m "Reset scaffold" 2>/dev/null || true
fi

echo ""
echo "==> Test environment ready at $TEST_ENV"
echo ""
echo "    Packages declared:"
echo "    - spatie/laravel-data ^4.0"
echo "    - spatie/laravel-media-library ^11.0"
echo "    - inertiajs/inertia-laravel ^1.0"
echo ""
echo "    Structure:"
find . -type f \( -name "*.php" -o -name "*.json" -o -name "*.vue" \) | sort | sed 's/^/    /'
