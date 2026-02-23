---
name: craft-exception
description: Crafting exceptions. Named constructors, contextual messages, one class per failure mode.
---

# Skill: Craft Exception

> "An exception that doesn't tell you how to fix it is just noise."

## The Standard

1. **Abstract Base + Specific Exceptions**: Organize by failure category. The base class groups related failures. Subclasses represent individual failure modes. One class per failure mode. Never a generic `PackageException`.

2. **Named Constructors**: Factory methods over `new Exception()`. Each constructor encapsulates message formatting and interpolates context. Centralizes message formatting, prevents drift.

3. **Messages That Teach**: Every message answers three questions: what went wrong, what value was invalid, and what is expected. Use backticks for technical names. Include the actual invalid value AND the valid alternatives.

4. **One Class Per Failure Mode**: Specific exception classes enable precise `catch` blocks. The caller decides which failures to handle. Catching the abstract base catches all related failures.

5. **HTTP Status Mapping**: API-facing exceptions extend `HttpException` or implement `getStatusCode()`. Map failures to the correct HTTP semantics.

   | Status | Meaning               | Example                                      |
   |--------|-----------------------|----------------------------------------------|
   | 400    | Invalid request input | `InvalidFilterQuery`, `InvalidSortQuery`     |
   | 403    | Unauthorized action   | `UnauthorizedException`                      |
   | 404    | Resource not found    | `PermissionDoesNotExist`, `RoleDoesNotExist` |
   | 422    | Validation failure    | `InvalidConfiguration`                       |

6. **Configurable Verbosity**: Security-sensitive packages control what appears in exception messages. Detailed context in development, redacted in production.

7. **`@throws` on every method**: Every method that can throw documents its exceptions in the docblock. IDE and consumers depend on it.

8. **Wrap vendor exceptions**: When your package wraps a third-party service, catch vendor exceptions and re-throw as your own. Taylor's pattern in Cashier: wrap Stripe exceptions so consumers catch your exception hierarchy, not the vendor's.

## The Anti-Patterns

| Don't                                    | Do                                             | Why                                                 |
|------------------------------------------|------------------------------------------------|-----------------------------------------------------|
| Generic `PackageException` class         | One class per failure mode                     | Precise `catch` blocks are impossible otherwise     |
| `"Invalid input"` messages               | Include what, actual value, and expected value | Developers should not have to debug your exceptions |
| `new Exception('...')` in business logic | Named constructors: `FileIsTooBig::create()`   | Centralizes message formatting, prevents drift      |
| Expose sensitive data unconditionally    | Config-driven verbosity toggle                 | Production error pages leak secrets                 |
| Use exceptions for flow control          | Exceptions are for exceptional failures        | Use return types and booleans for expected outcomes |
| Omit `@throws` annotations               | Document every throwable method                | IDE and consumers depend on it                      |
| Leak vendor exceptions to consumers      | Wrap in your own exception hierarchy           | Consumers should not catch Stripe or AWS exceptions |

## Real-World Examples

See [examples.md](examples.md).
