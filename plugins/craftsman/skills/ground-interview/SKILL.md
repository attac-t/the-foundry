---
name: ground-interview
description: Spec refinement via AskUserQuestion. Extract requirements before implementation.
---

# Skill: Interview

> "The spec you don't write is the bug you will ship."

## When

Before implementing any feature that involves:
- Multiple files or domains
- UI/UX decisions
- Architectural choices
- Unclear requirements

## The Protocol

1. **Read** the minimal spec (spec.md, task description, or user prompt)
2. **Interview** using `AskUserQuestion` tool:
   - Technical implementation questions
   - UI & UX questions
   - Concerns and edge cases
   - Tradeoffs and alternatives
3. **Questions must NOT be obvious** - dig into the non-trivial
4. **Continue** until the spec is complete (40+ questions for big features)
5. **Write** the detailed spec to file

## Question Categories

| Category       | Example Questions                             |
|----------------|-----------------------------------------------|
| **Technical**  | "Should this use events or direct calls?"     |
| **UI/UX**      | "How should validation errors appear?"        |
| **Edge Cases** | "What happens when X is null?"                |
| **Tradeoffs**  | "Performance vs simplicity - which priority?" |
| **Scope**      | "Is Y in scope for this feature?"             |

## The Anti-Patterns

- **Assuming**: Making decisions without asking
- **Obvious questions**: "Do you want tests?" (yes, obviously)
- **Rushing**: 5 questions is not enough for a complex feature
- **Implementing without spec**: Code before clarity

## The Output

Write to `.claude/memory/spec.md`:
- High-level objective
- Mid-level objectives
- Implementation notes
- Low-level tasks
- Answered questions log

Then: NEW SESSION to execute.
