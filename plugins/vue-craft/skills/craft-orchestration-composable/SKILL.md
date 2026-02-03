---
name: craft-orchestration-composable
description: Multi-step flows. Scenario branching. Detection + dispatch.
---

# Skill: Craft Orchestration Composable

> "Complex flows deserve explicit paths."

## The Standard

1. **Detection first**: Analyze state to determine which scenario applies.
2. **Explicit branching**: If/else for each scenario, not nested conditions.
3. **Separate handlers**: Each scenario gets its own dialog/action.
4. **Edge cases**: Always handle the "all invalid" or "none found" case.

## The Anti-Patterns

| Don't                 | Do                        | Why      |
|-----------------------|---------------------------|----------|
| Nested conditionals   | Flat if/else              | Readable |
| Single generic dialog | Scenario-specific dialogs | Clear UX |
| Ignore edge cases     | Handle all scenarios      | Robust   |
| Logic in component    | Extract to composable     | Testable |

## Real-World Examples

See [examples.md](examples.md).
