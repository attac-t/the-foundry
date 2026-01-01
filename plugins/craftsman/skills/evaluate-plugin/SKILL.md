---
name: evaluate-plugin
description: How to verify the Cognitive OS is functioning correctly.
---

# Skill: Evaluate Plugin

> "Trust, but verify. Test the plugin, not the model."

## Usage

```
/evaluate              # Run all tests (atomic + qualitative)
/evaluate hooks        # Hook tests only
/evaluate craft        # craft-* skill tests
/evaluate decide       # decide-* skill tests
/evaluate ground       # ground-* skill tests
/evaluate qualitative  # Qualitative scenarios only
```

## Test Structure

```
tests/
├── hooks.yml
├── commands.yml
├── agents.yml
├── registration.yml
└── skills/
    ├── craft/         # 15 individual files
    ├── decide/        # 11 individual files
    ├── ground/        # 8 individual files
    ├── meta/          # 3 individual files
    └── anti-patterns/ # 5 negative tests
```

## Test Format

```yaml
name: craft-action
trigger: "Create an Action class with single responsibility"
expect:
  - single responsibility
  - __invoke method
pass: Action with focused purpose
```

| Field | Purpose |
|-------|---------|
| name | Test identifier |
| trigger | Natural prompt with domain vocabulary |
| expect | Patterns to find in response |
| pass | One-line success criteria |

## Execution Protocol

For each test:

1. **Read** test definition from YAML
2. **Evaluate**: "Given trigger, would response contain expected patterns?"
3. **Verdict**:
   - PASS → All expected patterns would appear
   - FAIL → Missing patterns (note which)
   - SKIP → Skill may not have loaded
4. **Track** result with timestamp

## Report Format

```markdown
# Evaluation: [category] - [timestamp]
**Plugin Version**: [version from plugin.json]

| Test | Status | Notes |
|------|--------|-------|
| test-name | PASS/FAIL | Missing: pattern |

## Summary
- Passed: X/Y
- Failed: Z
```

Write to: `tests/results/[category]-[timestamp].md`

## Coverage Tracking

After evaluation, log to working memory scratchpad:

```markdown
## Scratchpad

Skills invoked this session:
- craft-action, craft-model, ground-delegation...

Coverage: X/37 skills
```

Session-local. Not cumulative across sessions.

---

## What To Test

| Test Type | Verification |
|-----------|--------------|
| Hooks | Context contains expected output |
| Skills | Trigger → expected patterns in response |
| Commands | Command runs → correct skill invoked |
| Agents | Agent spawns → skills accessible |

## What NOT To Test

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Silent hooks | PostToolUse doesn't surface. Verify side effects manually. |
| Model behavior | "Does Claude ask questions?" tests the model, not your config. |
| External invocations | `claude -p` lacks plugin context. Always test in-session. |
| Ideal conditions | "Write a function" has no domain vocabulary. Unreliable. |
| Vague triggers | "Help me with code" won't activate specific skills. |

See: `tests/skills/anti-patterns/` for negative test examples.

## Test Anti-Patterns

- **Verbose tests** - If it takes 20 lines, split it
- **Testing Claude** - Plugin tests, not model tests
- **Vague triggers** - Include domain vocabulary for reliable activation
- **Context-rot tests** - See `anti-patterns/context-rot.yml`
- **Model-trap tests** - See `anti-patterns/model-traps.yml`

---

## Architectural Learnings

### External Testing Does NOT Work

```bash
# No plugin context
claude -p "prompt" --dangerously-skip-permissions
```

Hooks don't fire. Skills aren't loaded. Use in-session evaluation only.

### Hook Visibility

| Event | Visible | Our Usage |
|-------|---------|-----------|
| SessionStart | ✅ Yes | remember, ground |
| UserPromptSubmit | ✅ Yes | anchor, recite, evaluate |
| PreCompact | ✅ Yes | preserve |
| PostToolUse | ❌ Silent | consider |

PostToolUse hooks run but don't surface. Verify side effects manually.

---

## Qualitative Tests

> Tests that verify the plugin *improves outcomes*, not just that skills load.

### Location

```
tests/qualitative/
├── setup.sh           # Creates /tmp/craftsman-test-env/ scaffold
├── evaluate.sh        # Lists scenarios
└── scenarios/
    ├── README.md      # Schema documentation
    ├── time-range.yml
    ├── api-design.yml
    ├── fat-controller.yml
    ├── vague-naming.yml
    └── query-complexity.yml
```

### Execution Protocol

1. **Setup**: Run `tests/qualitative/setup.sh` to create Laravel DDD worktree
2. **For each scenario**:
   - Read scenario YAML
   - Load context files from `/tmp/craftsman-test-env/`
   - Respond to the trigger as if from a user
   - Self-evaluate against 4-criteria rubric
   - Report: PASS (4/4) or FAIL (n/4)

### Rubric Criteria

| # | Criterion | Question |
|---|-----------|----------|
| 1 | right_abstraction | Did I propose the correct pattern? |
| 2 | project_conventions | Did I follow existing project patterns? |
| 3 | anti_pattern_pushback | Did I redirect away from bad practices? |
| 4 | correct_namespace | Did I place code in the right namespace? |

### Pass Threshold

**4/4 criteria required.** Plugin influence must be demonstrable.

### Report Format

```markdown
# Qualitative Evaluation - [timestamp]

| Scenario | Status | Criteria Met |
|----------|--------|--------------|
| time-range | PASS | 4/4 |
| api-design | FAIL | 3/4 (missed: pushback) |

## Summary
- Passed: X/5
- Failed: Y/5
```

Write to: `tests/results/qualitative-[timestamp].md`
