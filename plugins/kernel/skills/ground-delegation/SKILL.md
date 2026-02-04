---
name: ground-delegation
description: Strategic sub-agent spawning. When to lead vs code.
---

# Skill: Delegation

> "A senior engineer knows when to code and when to lead."

## When

1. **At blueprint creation**: Assess each task and assign Owner (`self` or `agent`).
2. **Before each task**: Re-assess. Context may have changed.

## The Criteria

A task is **delegatable** when all four are true:

| Criterion        | Question                                                   |
|------------------|------------------------------------------------------------|
| **Bounded**      | Can you specify input and expected output in one sentence? |
| **Context-free** | Does it NOT require knowledge of other in-flight tasks?    |
| **Mechanical**   | Is the approach obvious once started?                      |
| **Verifiable**   | Can success be checked without judgment?                   |

All yes → `agent`. Any no → `self`.

## The Briefing

When delegating, provide:

```
Task: [one-sentence description]
Files: [list of files to read/modify]
Constraints: [boundaries, conventions, ADRs]
Success: [how to verify completion]
```

## The Workflow

1. **Assess**: Apply criteria to each task.
2. **Delegate**: Spawn agent with briefing. Mark status `delegated`.
3. **Review**: When agent completes, review output. Mark `in-review`.
4. **Integrate**: Commit if good. Re-delegate with context if not.

## Parallel Execution

- Up to 3 agents may run simultaneously (soft limit).
- Only delegate tasks with no dependencies on other in-flight work.
- Track all delegated tasks in blueprint.

## The Anti-Patterns

- **Over-delegating**: Spawning agents for trivial single-file changes.
- **Under-delegating**: Drowning in mechanical work instead of leading.
- **Vague briefs**: Delegating without clear success criteria.
- **Fire and forget**: Not reviewing agent output before committing.
