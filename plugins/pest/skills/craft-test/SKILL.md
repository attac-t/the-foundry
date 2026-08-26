---
name: craft-test
description: Crafting a test. The unit of specification.
---

# Skill: Craft Test

> "Test behavior, not implementation."

## The Standard

1. **One Behavior Per Test**: A test verifies one thing. If the name has "and", split it.
2. **Arrange-Act-Assert**: Setup, execute, verify. No interleaving.
3. **Test the API**: Public interface only. Implementation changes shouldn't break tests.

## The Anti-Patterns

| Don't                  | Do                      | Why           |
| ---------------------- | ----------------------- | ------------- |
| Test private methods   | Test through public API | Coupling      |
| Assert implementation  | Assert behavior         | Fragility     |
| Multiple acts per test | One act, one test       | Clarity       |
| Dense setup chains     | Two-line setup          | Readability   |
| Vague names            | Complete sentences      | Documentation |

## Real-World Examples

See [examples.md](examples.md).
