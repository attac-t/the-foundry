---
name: craft-test
description: Testing philosophy. Confidence, not coverage. What to test, what to skip.
---

# Skill: Craft Test

> "Tests are confidence. Red to Green to Refactor."

## The Philosophy

Tests exist to give you confidence to change code. They are not a bureaucratic checkbox.

**The Question**: "If this breaks, will a test catch it?"

## What to Test

| Test This                     | Because                             |
| ----------------------------- | ----------------------------------- |
| Business logic with decisions | Logic branches can fail             |
| Complex validation rules      | Edge cases hide bugs                |
| Happy path + one error path   | Proves it works and fails correctly |
| Integration points            | Boundaries are where bugs live      |

## What to Skip

| Skip This                     | Because                         |
| ----------------------------- | ------------------------------- |
| Simple wrappers with no logic | Nothing can break               |
| Framework internals           | The framework is already tested |
| Every edge case               | Diminishing returns             |
| Implementation details        | Tests become brittle            |

## The Structure

Every test follows Arrange-Act-Assert:

1. **Arrange**: Set up the preconditions
2. **Act**: Execute the behavior
3. **Assert**: Verify the outcome

Keep this structure explicit. A reader should identify each section instantly.

## The Rules

1. **Test Behavior, Not Implementation**: Test what it does, not how it does it.
2. **One Assertion Per Concept**: A test should verify one logical concept (may need multiple assertions).
3. **Readable Names**: Test name describes the scenario. "it registers user with valid email" not "testCase1".
4. **Fast Feedback**: Tests should run quickly. Slow tests don't get run.
5. **Isolated**: Tests should not depend on each other or on external state.

## Confidence Hierarchy

| Level       | What it Tests        | Run Frequency |
| ----------- | -------------------- | ------------- |
| Unit        | Isolated logic       | Every change  |
| Integration | Connected components | Before commit |
| End-to-End  | Full user flows      | Before deploy |

Focus effort on the level that gives most confidence for that code.

## The Test Pyramid

```
        /\
       /E2E\        Few, slow, expensive
      /------\
     /  INT   \     Some, moderate
    /----------\
   /    UNIT    \   Many, fast, cheap
  /--------------\
```

More unit tests. Fewer E2E tests. Integration in the middle.

## When Tests Lie

Tests give false confidence when they:

- Test implementation instead of behavior
- Are so coupled to code that they break on refactor
- Mock so much that nothing real is tested
- Pass when the feature is actually broken

Guard against brittle tests. They are worse than no tests.
