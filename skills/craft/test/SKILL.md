---
name: craft-test
description: Crafting tests with Pest v3. Confidence, not coverage.
---

# Skill: Craft Test

> "Tests are confidence. Red to Green to Refactor."

## The Standard

1. **Pest v3**: `describe()`, `it()`, `expect()`.
2. **Factories**: Never `new Model()`. Always factories.
3. **Selective**: Test logic, not Laravel.
4. **Arrange-Act-Assert**: Clear structure.

## What to Test

| Test                 | Skip                 |
|----------------------|----------------------|
| Actions with logic   | Simple CRUD wrappers |
| Complex validations  | Basic DTO structure  |
| Happy path + 1 error | Every edge case      |
| Domain integrations  | Framework internals  |

## Real-World Examples

See [examples.md](examples.md).
