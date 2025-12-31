#!/bin/bash
# Sets up hooks in .claude/settings.json
# Required workaround: https://github.com/anthropics/claude-code/issues/12151

MARKETPLACE_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$MARKETPLACE_DIR/plugins/craftsman"
SETTINGS=".claude/settings.json"

mkdir -p .claude

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

if [ -f "$SETTINGS" ]; then
  jq -s '.[0] * .[1]' "$SETTINGS" <(echo "$HOOKS") > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "Merged hooks into $SETTINGS"
else
  echo "$HOOKS" | jq '.' > "$SETTINGS"
  echo "Created $SETTINGS"
fi

echo ""
echo "Next steps:"
echo "  1. Add marketplace: /plugin marketplace add $MARKETPLACE_DIR"
echo "  2. Install plugin:  /plugin install craftsman@the-foundry"
