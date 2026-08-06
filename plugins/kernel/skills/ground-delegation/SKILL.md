---
name: ground-delegation
description: Strategic delegation. When to lead, delegate, or collaborate.
---

# Skill: Delegation

> "A senior engineer knows when to code, when to delegate, and when to collaborate."

## When

1. **At blueprint creation**: Assess each task and assign Owner (`self`, `sub-agent`, or `team`).
2. **Before each task**: Re-assess. Context may have changed.

## Mechanism First

The epigraph says "when to code" — but that is not a delegation choice. `ground-mechanism` decides
the executor **kind** (code or model). This skill decides the executor **context** (self, sub-agent,
team).

Ask mechanism first. If the answer is code, there is nobody to delegate to.

## The Primitives

| Primitive      | Communication    | Best For                                          |
|----------------|------------------|---------------------------------------------------|
| **Self**       | —                | Judgment-heavy, context-dependent, architectural  |
| **Sub-agent**  | Reports back only | Bounded, mechanical, verifiable                  |
| **Agent team** | Peer-to-peer     | Research, competing hypotheses, cross-layer work  |

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

| Signal                       | Example                                           |
|------------------------------|---------------------------------------------------|
| **Competing hypotheses**     | Investigate the root cause in parallel             |
| **Cross-layer coordination** | Frontend, backend, and tests move together         |
| **Research with challenge**  | Findings should be questioned, not just collected  |
| **Peer review**              | Multiple lenses on the same artifact               |

If none → `self`.

## Privilege Attenuation

> Every delegation narrows scope. Never widens it.

**Sub-agents** receive **less** authority than the parent:
- Only the files they need
- Only the conventions that apply
- Only the tools the task requires

Broad access → task isn't bounded. Decompose further.

**Teammates** inherit full project context. Scope via **task boundaries** — each teammate owns distinct files.

## Authority Gradient

> Sub-agents don't push back. They execute. Silently.

A flawed brief produces flawed output. No resistance, no warning.

Include in every sub-agent briefing:
> "Flag anything in this brief that seems inconsistent, incomplete, or wrong."

A false flag costs nothing. Silent compliance wastes the run.

Teams solve this structurally — teammates challenge each other by design.

## The Sub-agent Briefing

```
Task: [one-sentence description]
Files: [list of files to read/modify]
Constraints: [boundaries, conventions, ADRs]
Success: [how to verify completion]
Challenge: "Flag anything in this brief that seems wrong."
```

## The Team Briefing

- **Separate file ownership** — no two teammates edit the same file
- **Distinct lenses** — each role sees the problem differently
- **Explicit deliverables** — what each teammate produces
- **Delegate mode** — lead orchestrates, not implements

## The Workflow

1. **Assess**: Apply criteria to each task. Choose primitive.
2. **Delegate**: Spawn agent or team with briefing. Mark status `delegated`.
3. **Review**: When complete, review output. Mark `in-review`.
4. **Integrate**: Commit if good. Re-delegate with context if not.

## Parallel Execution

- **Sub-agents**: Up to 3 simultaneously (soft limit).
- **Agent teams**: 5-6 tasks per teammate keeps everyone productive.
- No dependencies between in-flight work.
- Track all delegated tasks in blueprint.

## The Anti-Patterns

- **Over-delegating**: Spawning agents for trivial single-file changes.
- **Under-delegating**: Drowning in mechanical work instead of leading.
- **Vague briefs**: No clear success criteria.
- **Fire and forget**: Not reviewing output before committing.
- **Scope inflation**: Broader access than the task requires.
- **Blind obedience**: Executing flawed briefs without questioning. The `Challenge` line prevents this.
- **Wrong primitive**: Sub-agents when teammates need to talk. Teams when a single agent suffices.
- **File collisions**: Two teammates, same file. Split the work.
