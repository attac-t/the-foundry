---
name: decide-namespacing
description: When to place code in Support vs Domain. Namespace decisions.
---

# Skill: Namespacing

> "Support is a package. Domain is the business."

## The Doctrine

```
App/     → Thin orchestration (controllers, commands)
Domain/  → Business logic (models, actions, DTOs)
Support/ → Package-ready utilities (NEVER imports Domain)
```

## The Decision

**Place in Support when:**
- Could be extracted as a Composer package
- Has zero business entity awareness
- Works with primitives or its own Value Objects

**Place in Domain when:**
- References any Domain model or DTO
- Contains business rules
- Specific to this application's domain

## The Heuristic

Ask: *"If I copy this to another Laravel project, does it work without changes?"*

- **Yes** → Support
- **No** → Domain

## The Quick Test

| Ask Yourself             | Answer | Use     |
| ------------------------ | ------ | ------- |
| Uses `Domain\*` imports? | Yes    | Domain  |
| Could be a package?      | Yes    | Support |
| Contains business rules? | Yes    | Domain  |
| Just a utility?          | Yes    | Support |

## Real-World Examples

For concrete examples, see [examples.md](examples.md).
