---
name: ground-action-composition
description: Action composition. Reuse without deep chains.
---

# Skill: Action Composition

> "Actions reduce the cognitive load that's introduced by such a system."

## The Standard

- **Flat Over Deep**: Maximum 3-4 levels of action calls.
- **Inject Dependencies**: Actions receive other actions via constructor.
- **Single Responsibility**: If an action does too much, split it.
- **Copy-Paste Is OK**: Sometimes duplication beats the wrong abstraction.

## The Check

Ask yourself:
- How many levels deep is my action chain?
- Can I test this action in isolation?
- Would debugging require traversing 5+ files?
- Am I abstracting because I should, or because I can?

## The Protocol

1. **Start Simple**: One action, one task.
2. **Extract On The Third**: Copy-paste the second occurrence and note it. The rule
   of three decides — see `decide-abstraction-timing`.
3. **Compose Don't Inherit**: Actions call actions, not extend them.
4. **Flatten When Deep**: If chain > 4 levels, rethink the design.

## Real-World Examples

See [examples.md](examples.md).
