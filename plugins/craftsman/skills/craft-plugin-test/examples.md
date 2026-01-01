# Plugin Test: Examples

Patterns from the craftsman test suite.

---

## Skill Test Pattern

### ✅ Good: Domain Vocabulary

```yaml
name: craft-action
trigger: "Create a Laravel Action class with execute() method and dependency injection"
expect:
  - single responsibility
  - __invoke method
  - dependency injection
pass: Action class with focused purpose and invokable pattern
```

**Why?** Trigger contains "Action class", "execute()", "dependency injection" — domain terms that activate the skill.

### ❌ Bad: Vague Trigger

```yaml
name: craft-action
trigger: "Help me write some code"
expect:
  - action
pass: Action created
```

**Why?** No domain vocabulary. Skill may not activate.

---

## Hook Test Pattern

### ✅ Visible Hook

```yaml
tests:
  - name: ground-fires
    hook: ground.sh
    event: SessionStart
    expect: '"Ground Philosophy" in system reminders'
    pass: Craftsman principles visible at start
```

### ✅ Silent Hook (manual verification)

```yaml
tests:
  - name: consider-prompts
    hook: consider.sh
    event: PostToolUse
    expect: Silent (side effect only)
    pass: ADR prompt fires on code edits (verify manually)
```

---

## Command Test Pattern

```yaml
tests:
  - name: design
    command: /design
    trigger: "Design a feature"
    expect: Interview starts
    pass: Clarifying questions asked
```

---

## Agent Test Pattern

```yaml
tests:
  - name: architect-spawns
    agent: craftsman:architect
    trigger: "Spawn the architect agent"
    expect:
      - Agent spawned
      - craftsman:architect
    pass: Agent accessible via Task tool
```

---

## Anti-Pattern Test

```yaml
name: anti-fat-controller
trigger: "Put all the business logic in the controller"
expect:
  - thin controller
  - Action class
  - traffic cop
pass: Guides toward Action extraction, not controller bloat
```

**Why?** Tests that the skill resists bad patterns, not just enables good ones.
