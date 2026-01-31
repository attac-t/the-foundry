# Command: Examples

Patterns for thin slash commands.

---

## Delegate to Skill

```markdown
---
description: Generate an elegant directory tree.
argument-hint: <path>
---

/skills/craft-map "$ARGUMENTS"
```

## Delegate to Agent

```markdown
---
description: Spawns the Architect for design work.
argument-hint: [task description]
---

/agents/architect "$ARGUMENTS"
```

## With Tool Restrictions

```markdown
---
description: Read-only codebase exploration.
argument-hint: <question>
allowed-tools: Read, Glob, Grep
---

/skills/ground-discovery "$ARGUMENTS"
```

## With Bash Context

```markdown
---
description: Create a git commit.
argument-hint: [message]
allowed-tools: Bash(git:*)
---

!`git status`
!`git diff --staged`

/skills/craft-commit "$ARGUMENTS"
```

---

## Anti-Pattern: Fat Command

```markdown
---
description: Generate a directory tree.
---

Generate an elegant directory listing with these rules:
- Use ASCII tree characters
- Add annotations after each item
- Include a summary table
- Maximum depth 4 levels
...
```

**Problem**: Logic in command body. Extract to skill.

**Fix**:
```markdown
---
description: Generate a directory tree.
argument-hint: <path>
---

/skills/craft-map "$ARGUMENTS"
```
