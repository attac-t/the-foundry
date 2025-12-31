# Self-Development Test

Manual verification that the plugin uses itself during development.

---

## Known Limitation

Plugin hooks don't pass stdout to Claude ([#12151](https://github.com/anthropics/claude-code/issues/12151)).

**Workaround:** Run `setup.sh` to write hooks to `.claude/settings.json`.

---

## Prerequisites

```bash
cd /path/to/the-foundry
./setup.sh
claude
```

Then in Claude Code:
```
/plugin marketplace add .
/plugin install craftsman@the-foundry
```

---

## Phase 1: Infrastructure

```bash
# Marketplace registered
/plugin marketplace list

# Plugin installed
/plugin list

# Hooks in settings.json
cat .claude/settings.json | grep -A5 '"hooks"'
```

- [ ] Marketplace shows `the-foundry`
- [ ] Plugin shows `craftsman@the-foundry`
- [ ] settings.json contains hooks with absolute paths

---

## Phase 2: Hook Execution

Start a new session. Ask: "What did the session start hooks tell you?"

| Event | Hook | Verification |
|-------|------|--------------|
| SessionStart | `remember.sh` | Working memory loads |
| SessionStart | `ground.sh` | 8 ground principles |
| UserPromptSubmit | `evaluate.sh` | Skill evaluation |
| Stop | `anchor.sh` | Goal echoed |
| Stop | `recite.sh` | Memory update prompt |
| PostToolUse | `consider.sh` | ADR prompt on Write/Edit |

- [ ] ground.sh output received
- [ ] evaluate.sh fires on prompt
- [ ] anchor.sh fires on stop
- [ ] recite.sh fires on stop
- [ ] consider.sh fires on Write/Edit

---

## Phase 3: Skill Activation

**Prompt:** `Help me create a new Action class for user registration`

- [ ] Skills evaluated (craft-action, ground-discovery)
- [ ] Skills influence response

---

## Phase 4: Agent Spawning

**Test:** `/refine`

- [ ] Reviewer spawns
- [ ] Craftsman voice active

---

## Phase 5: Commands

| Command | Expected |
|---------|----------|
| `/evaluate` | OS verification |
| `/design` | Interview flow |
| `/blueprint` | Load implementation plan |
| `/refine` | Reviewer mode |

- [ ] /evaluate
- [ ] /design
- [ ] /blueprint
- [ ] /refine

---

## Phase 6: Self-Extension

The plugin extends itself.

### New Skill

```
Create ground skill "ground-patience" for deliberate response timing.
```

- [ ] Consults existing patterns
- [ ] Creates `plugins/craftsman/skills/ground/patience/SKILL.md`

### New Hook

```
Create hook for NotebookEdit → data validation reminder.
```

- [ ] Creates script in `plugins/craftsman/hooks/`
- [ ] Updates `.claude/settings.json`

### New Command

```
Create /checkpoint to save progress to working memory.
```

- [ ] Creates `plugins/craftsman/commands/checkpoint.md`
- [ ] Available immediately

---

## Phase 7: Context Stability

1. Set goal in working memory
2. 5-6 exchanges
3. Verify drift prevention

- [ ] Goal echoed after responses
- [ ] Memory prompts appear

---

## Success Criteria

All capabilities functional during self-development:

- ✅ Skills
- ✅ Agents
- ✅ Commands
- ✅ OutputStyles
- ⚠️ Hooks (via settings.json workaround)
