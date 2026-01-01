#!/bin/bash
#
# init-git.sh - Initialize or reset git repository
#
# Usage: ./init-git.sh [init|reset] [target_dir]
#

set -e

ACTION="${1:-init}"
TARGET_DIR="${2:-$(pwd)}"

cd "$TARGET_DIR"

case "$ACTION" in
    init)
        echo "==> Initializing git repository"
        git init
        git add -A
        git commit -m "Initial Laravel DDD scaffold with Spatie packages" 2>/dev/null || true
        ;;
    reset)
        echo "==> Resetting git repository"
        git reset --hard HEAD 2>/dev/null || true
        git clean -fd 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 [init|reset] [target_dir]"
        exit 1
        ;;
esac

echo "    Done"
