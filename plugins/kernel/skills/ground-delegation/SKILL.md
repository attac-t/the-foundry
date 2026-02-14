---
name: ground-delegation
description: Strategic delegation. When to lead, delegate, or collaborate.
---

# Skill: Delegation

> "A senior engineer knows when to code, when to delegate, and when to collaborate."

## When

1. **At blueprint creation**: Assess each task and assign Owner (`self`, `sub-agent`, or `team`).
2. **Before each task**: Re-assess. Context may have changed.

## The Primitives

Three delegation modes. Choose the right one.

| Primitive | Communication | Best For |
|-----------|--------------|----------|
| **Self** | — | Judgment-heavy, context-dependent, architectural |
| **Sub-agent** | Reports back only | Bounded, mechanical, verifiable |
| **Agent team** | Peer-to-peer | Research, competing hypotheses, cross-layer work |

## The Criteria

### Sub-agent — all four must be true:

| Criterion        | Question                                                   |
|------------------|------------------------------------------------------------|
| **Bounded**      | Can you specify input and expected output in one sentence? |
| **Context-free** | Does it NOT require knowledge of other in-flight tasks?    |
| **Mechanical**   | Is the approach obvious once started?                      |
| **Verifiable**   | Can success be checked without judgment?                   |

All yes → `sub-agent`. Any no → check if `team` fits.

### Agent team — when the work needs dialogue:

| Signal | Example |
|--------|---------|
| **Competing hypotheses** | "We don't know the root cause — investigate in parallel" |
| **Cross-layer coordination** | Frontend, backend, and tests need to move together |
| **Research with challenge** | Findings should be questioned, not just collected |
| **Peer review** | Multiple lenses on the same artifact |

If none → `self`.

## Privilege Attenuation

> Every delegation narrows scope. Never widens it.

**Sub-agents** receive **less** authority than the parent. Scope the briefing to the minimum:
- Only the files they need
- Only the conventions that apply
- Only the tools the task requires

Broad access means the task isn't bounded. Decompose further.

**Teammates** inherit full project context but are scoped by **task boundaries**. Each teammate owns a distinct set of files. Two teammates editing the same file leads to overwrites.

## Authority Gradient

> Sub-agents don't push back. They execute. Silently.

A flawed brief produces flawed output. No resistance, no warning.

Include in every sub-agent briefing:
> "Flag anything in this brief that seems inconsistent, incomplete, or wrong."

A false flag costs nothing. Silent compliance on a bad brief wastes the run.

**Agent teams partially solve this.** Teammates challenge each other's findings by design. Use adversarial investigation when the authority gradient is a concern.

## The Sub-agent Briefing

```
Task: [one-sentence description]
Files: [list of files to read/modify]
Constraints: [boundaries, conventions, ADRs]
Success: [how to verify completion]
Challenge: "Flag anything in this brief that seems wrong."
```

## The Team Briefing

Describe the task, the team structure, and each role's distinct focus. Key principles:
- **Separate file ownership** — no two teammates edit the same file
- **Distinct lenses** — each role sees the problem differently
- **Explicit deliverables** — what each teammate produces

Use **delegate mode** (Shift+Tab) when the lead should orchestrate, not implement.

## The Workflow

1. **Assess**: Apply criteria to each task. Choose primitive.
2. **Delegate**: Spawn agent or team with briefing. Mark status `delegated`.
3. **Review**: When complete, review output. Mark `in-review`.
4. **Integrate**: Commit if good. Re-delegate with context if not.

## Parallel Execution

- **Sub-agents**: Up to 3 simultaneously (soft limit).
- **Agent teams**: Size to the task. 5-6 tasks per teammate keeps everyone productive.
- Only delegate tasks with no dependencies on other in-flight work.
- Track all delegated tasks in blueprint.

## The Anti-Patterns

- **Over-delegating**: Spawning agents for trivial single-file changes.
- **Under-delegating**: Drowning in mechanical work instead of leading.
- **Vague briefs**: Delegating without clear success criteria.
- **Fire and forget**: Not reviewing agent output before committing.
- **Scope inflation**: Giving agents broader access than the task requires.
- **Blind obedience**: Agents executing flawed briefs without questioning. The `Challenge` line exists to prevent this.
- **Wrong primitive**: Using sub-agents when teammates need to talk. Using teams when a single agent would suffice.
- **File collisions**: Two teammates editing the same file. Split the work.
