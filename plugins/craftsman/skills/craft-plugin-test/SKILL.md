---
name: craft-plugin-test
description: Crafting plugin behavioral tests. Verify config, not Claude.
---

# Skill: Craft Plugin Test

> "Test the plugin, not the model."

## The Standard

1. **Domain Vocabulary**: Triggers must contain skill-specific terms. "Create an Action class" not "Help me with code".
2. **One Assertion**: Each test verifies one behavior. Split compound tests.
3. **Expect Patterns**: List keywords that prove the skill loaded and shaped the response.
4. **Pass Criteria**: One sentence describing success.

## The Formats

### Skill Tests (one per file)

```yaml
name: craft-action
trigger: "Create a Laravel Action class with execute() method"
expect:
  - single responsibility
  - __invoke method
  - dependency injection
pass: Action class with focused purpose
```

### Layer Tests (array per file)

```yaml
# hooks.yml, commands.yml, agents.yml
tests:
  - name: ground-fires
    hook: ground.sh
    event: SessionStart
    expect: '"Ground Philosophy" in system reminders'
    pass: Craftsman principles visible at start
```

## The Anti-Patterns

| ❌ Don't                      | ✅ Do                                           | Why                                  |
|------------------------------|------------------------------------------------|--------------------------------------|
| "Help me with code"          | "Create an Action class for user registration" | Vague triggers don't activate skills |
| "Does Claude ask questions?" | "Does /design start interview flow?"           | Plugin tests, not model tests        |
| Test 5 behaviors in one file | One test per skill file                        | Atomic, debuggable                   |
| Expect exact response text   | Expect keyword patterns                        | Responses vary, patterns persist     |

## Real-World Examples

See [examples.md](examples.md).
