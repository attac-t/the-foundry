---
name: craft-slide-over
description: Slide-over state machine. Form + Edit + Delete modes.
---

# Skill: Craft Slide-Over

> "Three refs. Three modes. Mutually exclusive."

## The Standard

1. **Three state refs**: `isFormVisible`, `isEditMode`, `deleteConfirmationFor`.
2. **Mutual exclusion**: Only one mode active at a time.
3. **Reset on close**: Watch visibility, clear all state.
4. **Inline form**: Form renders inside slide-over, not separate dialog.

## The Anti-Patterns

| Don't                  | Do                  | Why                |
|------------------------|---------------------|--------------------|
| Boolean soup           | Named state refs    | Clarity            |
| Forget cleanup         | Watch close, reset  | No stale state     |
| Modal for edit         | Inline form         | Context preserved  |
| Separate delete dialog | Inline confirmation | Cohesive UX        |

## Real-World Examples

See [examples.md](examples.md).
