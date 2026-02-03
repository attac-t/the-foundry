---
name: craft-composable
description: Base composable structure. Types separation. Return object pattern.
---

# Skill: Craft Composable

> "A composable is a function that returns reactive state."

## The Standard

1. **Directory structure**: `use-{feature}/` with colocated types and tests.
2. **Types separation**: `use{Feature}.types.ts` alongside implementation.
3. **Options object**: Accept reactive inputs via destructured options, not positional args.
4. **Return object**: Return named properties, not arrays.

## The Anti-Patterns

| Don't           | Do                    | Why                       |
|-----------------|-----------------------|---------------------------|
| Positional args | Options object        | Named, extensible         |
| Return array    | Return object         | Destructure what you need |
| Types inline    | Separate `.types.ts`  | Reusable, cleaner         |
| Root-level file | `use-{feature}/` dir  | Colocation                |

## Real-World Examples

See [examples.md](examples.md).
