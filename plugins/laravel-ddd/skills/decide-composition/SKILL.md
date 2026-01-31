---
name: decide-composition
description: When to use Trait+Interface vs Abstract Class. The art of mixing behaviors.
---

# Skill: Composition

> "Favor composition over inheritance."

## The Decision

**Use Trait + Interface when:**
- Behavior crosses inheritance hierarchies
- Multiple behaviors need mixing
- No clear IS-A relationship
- You want horizontal reuse

**Use Abstract Class when:**
- Clear parent-child relationship exists
- Significant shared implementation
- Template method pattern needed
- You want vertical inheritance

## The Heuristic

Ask: *"Does this class **have** this behavior, or **is it** this thing?"*

- **Has** → Trait
- **Is** → Abstract Class

## The Quick Test

| Ask Yourself | Answer | Use |
|--------------|--------|-----|
| Does every subclass need this? | Yes | Abstract |
| Can multiple unrelated classes need this? | Yes | Trait |
| Is there a clear IS-A relationship? | Yes | Abstract |
| Is this a capability/feature? | Yes | Trait |

## Real-World Examples

For concrete examples from Laravel, Spatie, and production code, see [examples.md](examples.md).
