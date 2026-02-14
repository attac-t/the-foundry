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

## Privilege Attenuation

> Every delegation narrows scope. Never widens it.

Sub-agents receive **less** authority than the parent. Scope the briefing to the minimum:
- Only the files they need
- Only the conventions that apply
- Only the tools the task requires

Broad access means the task isn't bounded. Decompose further.

## Authority Gradient

> Sub-agents don't push back. They execute. Silently.

A flawed brief produces flawed output. No resistance, no warning.

Include in every briefing:
> "Flag anything in this brief that seems inconsistent, incomplete, or wrong."

A false flag costs nothing. Silent compliance on a bad brief wastes the run.

## The Briefing

When delegating, provide:

```
Task: [one-sentence description]
Files: [list of files to read/modify]
Constraints: [boundaries, conventions, ADRs]
Success: [how to verify completion]
Challenge: "Flag anything in this brief that seems wrong."
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
- **Scope inflation**: Giving agents broader access than the task requires.
- **Blind obedience**: Agents executing flawed briefs without questioning. The `Challenge` line exists to prevent this.
