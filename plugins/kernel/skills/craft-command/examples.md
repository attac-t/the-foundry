# Command: Examples

Patterns for thin slash commands.

A command body is a prompt. Name the skill you want and pass the arguments.

---

## Delegate to a Skill

```markdown
---
description: Generate an elegant directory tree.
argument-hint: "<path>"
---

Invoke the `kernel:craft-map` skill for: $ARGUMENTS
```

## Delegate to a Sub-agent

```markdown
---
description: Spawns the Architect for design work.
argument-hint: "[task description]"
---

Launch the `kernel:architect` sub-agent to design: $ARGUMENTS

Give it the files it needs and nothing more, and ask it to flag anything in the
brief that looks wrong.
```

## With Tool Restrictions

```markdown
---
description: Read-only codebase exploration.
argument-hint: "<question>"
allowed-tools: Read, Glob, Grep
---

Invoke the `kernel:ground-discovery` skill and answer: $ARGUMENTS
```

## With Bash Context

Backtick-bang lines run before the prompt reaches Claude, so their output becomes
part of the context.

```markdown
---
description: Create a git commit.
argument-hint: "[message]"
allowed-tools: Bash(git:*)
---

!`git status`
!`git diff --staged`

Write a Commitizen-format commit for the staged changes above. Message hint, if
given: $ARGUMENTS
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

**Problem**: judgment lives in the command body, so nothing else can reuse it, and
Claude can never apply it on its own.

**Fix**: move the rules into a skill; the command becomes a trigger.

```markdown
---
description: Generate a directory tree.
argument-hint: "<path>"
---

Invoke the `kernel:craft-map` skill for: $ARGUMENTS
```

---

## Anti-Pattern: Invented Invocation Syntax

```markdown
/skills/craft-map "$ARGUMENTS"
/agents/architect "$ARGUMENTS"
```

**Problem**: neither exists. There is no path-like syntax for calling a skill or
an agent from a command body. These appear to work only because Claude infers the
intent from the text — until it doesn't.

**Fix**: write the instruction, as above.
