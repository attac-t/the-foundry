#!/bin/bash
# Auto-installer for craftsman@the-foundry on container/session startup
# Add this to your shell profile (.bashrc, .zshrc, etc.) to auto-install craftsman

# Determine the script directory (handles symlinks)
FOUNDRY_DIR="/home/user/the-foundry"

# Only run if the foundry directory exists and installer is present
if [ -d "$FOUNDRY_DIR" ] && [ -f "$FOUNDRY_DIR/install-craftsman.sh" ]; then
    "$FOUNDRY_DIR/install-craftsman.sh" 2>&1 | grep -E "(✓|Error)" || true
fi
