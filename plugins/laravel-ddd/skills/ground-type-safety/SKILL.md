---
name: ground-type-safety
description: Type safety philosophy. Catch bugs at write time, not run time.
---

# Skill: Type Safety

> "Strong type systems allow developers to have much more insight into the program when writing the code, instead of having to run it."

## The Standard

- **Types Are Documentation**: A signature tells you what's expected.
- **Fail at Compile Time**: PHP 8+ gives us tools. Use them.
- **DTOs Over Arrays**: Named fields over string keys.
- **IDE as Partner**: If your IDE can't autocomplete, neither can your brain.

## The Check

Ask yourself:
- Can my IDE autocomplete this?
- Would a typo in a key cause a runtime error?
- Does the function signature tell me what it expects?
- Am I relying on documentation that might be stale?

## The Protocol

1. **Type Everything**: Return types, parameters, properties.
2. **Avoid Mixed**: If you write `mixed`, you've given up.
3. **Strict Mode**: `declare(strict_types=1);` in every file.
4. **Static Analysis**: Run PHPStan/Psalm. Trust the warnings.

## Real-World Examples

See [examples.md](examples.md).
