---
name: ground-topic
description: Isolate yourself. One branch, one memory.
---

# Skill: Topic

> "One topic, one branch, one memory."

## When

Run at session start. Ensures memory isolation per topic.

## The Protocol

1. **Detect** current git branch
2. **Resolve** memory path → `.claude/memory/<branch>/`
3. **On main/master/develop?** ⛔ Prompt to create a topic branch before implementation
4. **No memory?** Prompt to scaffold from templates

## The Anti-Patterns

- **Working on main**: Topics mix. Goals drift. Create a branch.
- **Skipping init**: No memory = cold start every session.

## The Output

State: "Topic: `<branch>`. Memory: `.claude/memory/<branch>/`"
