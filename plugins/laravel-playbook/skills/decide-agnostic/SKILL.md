---
name: decide-agnostic
description: When to build framework-agnostic. Core + bridge vs Laravel-only.
---

# Skill: Agnostic

> "The interface IS the package."

## The Decision

**Use framework-agnostic core + bridge when:**
- The problem is framework-independent (file storage, CSV parsing, OAuth, markdown)
- Multiple frameworks could consume the solution
- The abstraction boundary is clear and finite
- You want the core to be testable without booting a framework
- PSR compliance gives you interoperability for free

**Use Laravel-only when:**
- The package IS a framework feature (admin panel, Eloquent extension, Blade component)
- The value comes from deep framework integration (traits on models, Facade ergonomics, config publishing)
- The overhead of an adapter layer exceeds the portability benefit
- Your audience is 100% Laravel developers

## The Heuristic

Ask: *"Would this solve a PHP problem or a Laravel problem?"*

PHP problem: agnostic core + bridge. Laravel problem: Laravel-only.

## The Quick Test

| Ask                                    | Answer | Use           |
| -------------------------------------- | ------ | ------------- |
| Does this need the container?          | No     | Agnostic core |
| Does this need Eloquent?               | Yes    | Laravel-only  |
| Could Symfony developers use this?     | Yes    | Agnostic core |
| Is the value in framework integration? | Yes    | Laravel-only  |
| Are you wrapping an external API?      | Yes    | Agnostic core |
| Are you extending Laravel behavior?    | Yes    | Laravel-only  |

## Real-World Examples

See [examples.md](examples.md).
