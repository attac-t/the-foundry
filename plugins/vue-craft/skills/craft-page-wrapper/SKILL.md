---
name: craft-page-wrapper
description: Page as thin wrapper. Domain organism does the work.
---

# Skill: Craft Page Wrapper

> "Pages route props. Organisms think."

## The Standard

1. **Thin wrapper**: Page connects props to domain organism.
2. **Scaffold first**: `<EntityScaffold>` or layout component wraps content.
3. **Logic delegation**: Composables and organisms handle business logic.
4. **Validation at root**: Zod registry created at page level.

## The Anti-Patterns

| Don't                   | Do                      | Why               |
|-------------------------|-------------------------|-------------------|
| Business logic in page  | Composables + organisms | Testability       |
| Custom layouts per page | Scaffold components     | Consistency       |
| Inline handlers         | Delegated methods       | Clean template    |
| Scattered validation    | Registry at page root   | Aggregate control |

## Real-World Examples

See [examples.md](examples.md).
