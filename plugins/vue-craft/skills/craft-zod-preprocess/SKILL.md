---
name: craft-zod-preprocess
description: Empty/zero preprocessing. Edge case normalization.
---

# Skill: Craft Zod Preprocess

> "Normalize before validating."

## The Standard

1. **Empty as undefined**: Empty strings become `undefined` for required validation.
2. **Zero as undefined**: Zero values become `undefined` for required numbers.
3. **Wrap schema**: `preprocessEmptyAsUndefined(z.string())` — preprocess wraps inner schema.
4. **Composable**: Preprocessing is reusable across schemas.

## The Anti-Patterns

| Don't                  | Do               | Why                    |
|------------------------|------------------|------------------------|
| Check empty in refine  | Preprocess       | Separation of concerns |
| Duplicate preprocessing | Reusable helpers | DRY                    |
| Mutate input           | Transform        | Purity                 |
| Skip null handling     | Include null check | Edge cases             |

## Real-World Examples

See [examples.md](examples.md).
