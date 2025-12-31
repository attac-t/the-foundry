#!/bin/bash
# Auto-installer for craftsman@the-foundry plugin
# This script installs craftsman hooks into the Claude Code global settings

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/craftsman"
SETTINGS="/root/.claude/settings.json"

echo "=== Craftsman Plugin Installer ==="
echo ""

# Check if hooks are already installed
if [ -f "$SETTINGS" ] && grep -q "craftsman/hooks" "$SETTINGS" 2>/dev/null; then
    echo "✓ Craftsman hooks already installed in $SETTINGS"
    exit 0
fi

echo "Installing craftsman hooks..."

# Ensure Claude settings directory exists
mkdir -p "$(dirname "$SETTINGS")"

# Create hooks configuration
HOOKS=$(cat << EOF
{
  "hooks": {
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "$PLUGIN_DIR/hooks/remember.sh"}]},
      {"hooks": [{"type": "command", "command": "$PLUGIN_DIR/hooks/ground.sh"}]}
    ],
    "UserPromptSubmit": [
      {"hooks": [{"type": "command", "command": "$PLUGIN_DIR/hooks/evaluate.sh"}]}
    ],
    "Stop": [
      {"hooks": [{"type": "command", "command": "$PLUGIN_DIR/hooks/anchor.sh"}]},
      {"hooks": [{"type": "command", "command": "$PLUGIN_DIR/hooks/recite.sh"}]}
    ]
  }
}
EOF
)

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Merge or create settings
if [ -f "$SETTINGS" ]; then
    # Backup existing settings
    cp "$SETTINGS" "$SETTINGS.backup"

    # Merge hooks into existing settings
    jq -s '.[0] * .[1]' "$SETTINGS" <(echo "$HOOKS") > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    echo "✓ Merged craftsman hooks into existing $SETTINGS"
else
    # Create new settings file with schema
    echo '{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Skill"]
  }
}' | jq -s '.[0] * ('"$HOOKS"')' > "$SETTINGS"
    echo "✓ Created $SETTINGS with craftsman hooks"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed hooks:"
echo "  - SessionStart: remember.sh, ground.sh"
echo "  - UserPromptSubmit: evaluate.sh"
echo "  - Stop: anchor.sh, recite.sh"
echo ""
echo "The hooks will be active in your next Claude Code session."
