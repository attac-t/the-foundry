# Plugin Self-Test

Verify the plugin works by using it.

---

## Limitations

### Stop Hook Output

Stop hooks execute but don't surface to conversation. By design.

| Event            | Visible        |
|------------------|----------------|
| SessionStart     | ✅              |
| UserPromptSubmit | ✅              |
| Stop             | ❌ verbose only |
| PostToolUse      | ❌ verbose only |

`anchor.sh` and `recite.sh` run silently. Use `Ctrl+O` to confirm.

---

## Setup

```bash
cd /path/to/the-foundry
claude
```

```
/plugin marketplace add .
/plugin install craftsman@the-foundry
```

---

## Phase 1: Infrastructure

```bash
/plugin marketplace list    # → the-foundry
/plugin list                # → craftsman@the-foundry
```

- [ ] Marketplace registered
- [ ] Plugin installed

---

## Phase 2: Hooks

New session. Ask: *"What did the session start hooks tell you?"*

| Hook          | Event            | Visible | Expect           |
|---------------|------------------|---------|------------------|
| `remember.sh` | SessionStart     | ✅       | Working memory   |
| `ground.sh`   | SessionStart     | ✅       | 8 principles     |
| `evaluate.sh` | UserPromptSubmit | ✅       | Skill evaluation |
| `anchor.sh`   | Stop             | ❌       | Goal echo        |
| `recite.sh`   | Stop             | ❌       | Memory prompt    |
| `consider.sh` | PostToolUse      | ❌       | ADR prompt       |

- [ ] ground.sh fires
- [ ] evaluate.sh fires
- [ ] Stop hooks run (verify: `Ctrl+O` or run manually)

---

## Phase 3: Skills

Prompt: `Help me create a new Action class for user registration`

- [ ] Skills evaluated
- [ ] Response shaped by skill

---

## Phase 4: Agents

Run `/refine`

- [ ] Reviewer spawns
- [ ] Craftsman voice

---

## Phase 5: Commands

| Command      | Result              |
|--------------|---------------------|
| `/evaluate`  | Plugin verification |
| `/design`    | Interview flow      |
| `/blueprint` | Load roadmap        |
| `/refine`    | Reviewer mode       |

- [ ] All four work

---

## Phase 6: Self-Extension

The plugin builds itself.

### Skill

```
Create ground skill "ground-patience" for deliberate response timing.
```

- [ ] Follows existing patterns
- [ ] Creates `skills/ground/patience/SKILL.md`

### Hook

```
Create hook for NotebookEdit → data validation reminder.
```

- [ ] Creates script in `hooks/`
- [ ] Updates plugin hooks configuration

### Command

```
Create /checkpoint to save progress to working memory.
```

- [ ] Creates `commands/checkpoint.md`
- [ ] Works immediately

---

## Phase 7: Context Stability

1. Set goal in working memory
2. 5-6 exchanges
3. Check for drift

Stop hooks are silent. Context stability comes from:
- SessionStart loading memory
- UserPromptSubmit enforcing evaluation
- Discipline

- [ ] Memory loads on start
- [ ] Goal persists across restarts

---

## Pass Criteria

| Layer                                 | Status    |
|---------------------------------------|-----------|
| Skills                                | ✅         |
| Agents                                | ✅         |
| Commands                              | ✅         |
| OutputStyles                          | ✅         |
| Hooks (SessionStart/UserPromptSubmit) | ✅         |
| Hooks (Stop/PostToolUse)              | ⚠️ silent |
