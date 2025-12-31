# Craftsman Installation Guide

## Quick Install

```bash
cd /home/user/the-foundry
./install-craftsman.sh
```

This will install craftsman hooks into `/root/.claude/settings.json`.

## Persistence in Docker Environments

### Check if Installation is Persistent

Run this command to check if `/root/.claude` is mounted as a persistent volume:

```bash
findmnt /root/.claude
```

- **If it shows a mount point**: Your installation will persist across container restarts ✓
- **If it says "Not a mount point"**: Your installation will be lost on container restart ⚠️

### Option 1: Make Docker Volume Persistent (Recommended)

Add this to your Docker configuration to persist Claude settings:

```yaml
volumes:
  - claude-config:/root/.claude
```

Or with docker-compose:

```yaml
services:
  your-service:
    volumes:
      - claude-config:/root/.claude

volumes:
  claude-config:
```

### Option 2: Auto-Install on Container Startup

If you can't modify Docker volumes, add this to your shell profile to auto-install on startup:

**For bash** (add to `/root/.bashrc`):
```bash
# Auto-install craftsman@the-foundry
if [ -f /home/user/the-foundry/auto-install-on-startup.sh ]; then
    source /home/user/the-foundry/auto-install-on-startup.sh
fi
```

**For zsh** (add to `/root/.zshrc`):
```zsh
# Auto-install craftsman@the-foundry
if [ -f /home/user/the-foundry/auto-install-on-startup.sh ]; then
    source /home/user/the-foundry/auto-install-on-startup.sh
fi
```

### Option 3: Manual Re-Install After Restart

Simply run the installer again after each container restart:

```bash
/home/user/the-foundry/install-craftsman.sh
```

The script is idempotent - it won't reinstall if already present.

## Verification

After installation, verify the hooks are active:

```bash
grep -c "craftsman/hooks" /root/.claude/settings.json
```

Should return `5` (one for each hook file).

## What Gets Installed

The installer adds these hooks to Claude Code:

- **SessionStart**:
  - `remember.sh` - Loads session context
  - `ground.sh` - Establishes working principles

- **UserPromptSubmit**:
  - `evaluate.sh` - Validates prompt alignment

- **Stop**:
  - `anchor.sh` - Saves session state
  - `recite.sh` - Summarizes session work

## Troubleshooting

### jq Not Found

The installer requires `jq`. Install it:

```bash
apt-get update && apt-get install -y jq
```

### Permission Denied

Ensure scripts are executable:

```bash
chmod +x /home/user/the-foundry/*.sh
```

### Hooks Not Running

Check if the settings file is valid JSON:

```bash
jq . /root/.claude/settings.json
```

If there's an error, restore from backup:

```bash
mv /root/.claude/settings.json.backup /root/.claude/settings.json
```
