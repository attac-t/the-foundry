# Laravel Craftsman - Installation Guide

A tiny cognitive OS for Claude Code.

---

## Prerequisites

- Claude Code CLI installed
- `jq` installed (for hooks)

---

## Installation

### Option A: Clone as Plugin Directory

```bash
# Clone to any location
git clone https://github.com/attac-t/laravel-craftsman.git ~/claude-plugins/laravel-craftsman

# Run Claude Code with the plugin
claude --plugin-dir ~/claude-plugins/laravel-craftsman
```

### Option B: Embed in Project

```bash
# Clone into your project
git clone https://github.com/attac-t/laravel-craftsman.git .claude/plugins/laravel-craftsman

# Run Claude Code with the plugin
claude --plugin-dir .claude/plugins/laravel-craftsman
```

---

## Configuration

### Memory Directory (Optional)

By default, working memory is stored at `.claude/memory/`. To customize:

```bash
export CLAUDE_MEMORY_DIR="docs/ai/memory"
```

### Create Working Memory

```bash
mkdir -p ${CLAUDE_MEMORY_DIR:-.claude/memory}
cp path/to/plugin/templates/working.md ${CLAUDE_MEMORY_DIR:-.claude/memory}/working.md
```

Or create manually:

```bash
mkdir -p .claude/memory
cat > .claude/memory/working.md << 'EOF'
# Working Memory (Cognitive RAM)

**Goal**: [What are we building/fixing?]

**Context**: [Key constraints, ADRs, decisions]

**Progress**:
- [ ] Step 1
- [ ] Step 2

**Failures Preserved**:
- None yet
EOF
```

### Make Hooks Executable

```bash
chmod +x path/to/plugin/hooks/*.sh
```

---

## Verification

Run the evaluation command:
```
/evaluate
```

You should see:
1. Ground philosophy loaded (8 skills listed)
2. Skill evaluation prompt on each message
3. Goal recitation after each response

---

## What Gets Installed

| Component    | Location              | Purpose                       |
|--------------|-----------------------|-------------------------------|
| Commands     | `commands/`           | `/design`, `/blueprint`, etc. |
| Agents       | `agents/`             | Architect, Reviewer           |
| Skills       | `skills/`             | ground, decide, craft, meta   |
| Hooks        | `hooks/`              | Automatic context injection   |
| Output Style | `output-styles/`      | Voice (direct, opinionated)   |
| Templates    | `templates/`          | working.md, spec.md, adr.md   |

---

## Hook Scripts

| Script        | Event            | Purpose                             |
|---------------|------------------|-------------------------------------|
| `remember.sh` | SessionStart     | Load working memory (cognitive RAM) |
| `ground.sh`   | SessionStart     | Load ground philosophy              |
| `evaluate.sh` | UserPromptSubmit | Force skill evaluation (YES/NO)     |
| `anchor.sh`   | Stop             | Echo objective (prevent drift)      |
| `recite.sh`   | Stop             | Prompt memory update                |
| `consider.sh` | PostToolUse      | Prompt ADR consideration            |

---

## Environment Variables

| Variable             | Default          | Purpose                  |
|----------------------|------------------|--------------------------|
| `CLAUDE_MEMORY_DIR`  | `.claude/memory` | Working memory location  |
| `CLAUDE_PLUGIN_ROOT` | (auto-set)       | Plugin installation path |

---

## For Plugin Developers

To use the plugin to develop itself:

```bash
mkdir -p .claude/plugins .claude/memory
cd .claude/plugins && ln -s ../.. laravel-craftsman && cd ../..

cat > .claude/config.json << 'EOF'
{
  "plugins": [{"name": "laravel-craftsman", "path": "./plugins/laravel-craftsman"}],
  "settings": {"model": "claude-opus-4-5-20251101"}
}
EOF
```

Meta-skills guide the plugin's own extension.

---

## Troubleshooting

Use the troubleshooting skills:
- `troubleshoot-hook` — Debug hook issues
- `troubleshoot-skill` — Debug skill activation issues

Quick checks:
- Scripts executable? `chmod +x hooks/*.sh`
- `jq` installed?
