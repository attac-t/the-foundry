---
name: craft-blueprint
description: Crafting blueprints. Persistent task tracking with user confirmation.
---

# Skill: Craft Blueprint

> "A plan is a guess. A blueprint is a contract."

## When

Use blueprint when:
- Starting implementation from spec.md
- Tracking multi-task feature work
- Coordinating across sessions

## The Standard

1. **Source from Spec**: Tasks come from spec.md Low-Level Tasks. Never invent.
2. **User Confirms Completion**: Never mark `done` without user confirmation.
3. **Single In-Progress**: Exactly one task active at a time.
4. **Defer, Never Delete**: Out-of-scope tasks move to Deferred with reason.
5. **Log All Changes**: Every mutation recorded in Changes table.

## The Protocol

1. **Initialize**: Copy `templates/blueprint.md` to branch memory.
2. **Populate**: Extract tasks from spec.md Low-Level Tasks section.
3. **Work**: Mark one task `in-progress`. Sync to working.md Focus.
4. **Complete**: User confirms. Add date to Confirmed column. Mark `done`.
5. **Defer**: Move task to Deferred table with reason. Log in Changes.
6. **Evolve**: Any plan change logged in Changes with date and reason.

## Phases

The Status section tracks where you are in the lifecycle:

| Phase              | Trigger             | Activities                            |
|--------------------|---------------------|---------------------------------------|
| **Discovery**      | Blueprint created   | Reading spec, clarifying requirements |
| **Implementation** | First task started  | Writing code, marking tasks done      |
| **Testing**        | All code tasks done | Running tests, fixing failures        |
| **Refinement**     | Tests passing       | Polish, documentation, PR prep        |

Update Phase when transitioning. Log in Changes.

## The Anti-Patterns

| ❌ Don't                   | ✅ Do                      | Why                  |
|---------------------------|---------------------------|----------------------|
| Mark done without asking  | Request user confirmation | User owns completion |
| Multiple in-progress      | Single active task        | Focus and clarity    |
| Delete inconvenient tasks | Defer with reason         | Audit trail          |
| Silent plan changes       | Log in Changes table      | Traceability         |
| Invent tasks              | Source from spec.md       | Spec is the contract |

## Real-World Examples

See [examples.md](examples.md).
