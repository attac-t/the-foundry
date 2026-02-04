# Examples: Delegation

> Real-world patterns for strategic sub-agent spawning.

---

## Applying the Criteria

### Task: "Create User model with authentication"

| Criterion    | Answer  | Why                                              |
|--------------|---------|--------------------------------------------------|
| Bounded      | No      | "Authentication" is vague. OAuth? JWT? Session?  |
| Context-free | No      | Depends on auth architecture decisions           |
| Mechanical   | No      | Requires judgment on field visibility, relations |
| Verifiable   | Partial | Model exists, but "correct" is subjective        |

**Result**: `self` — Requires architectural judgment.

---

### Task: "Write CRUD tests for User model"

| Criterion    | Answer | Why                                    |
|--------------|--------|----------------------------------------|
| Bounded      | Yes    | Input: model. Output: passing tests.   |
| Context-free | Yes    | Model already exists. No dependencies. |
| Mechanical   | Yes    | Follow existing test patterns.         |
| Verifiable   | Yes    | Tests pass or fail.                    |

**Result**: `agent` — Delegatable.

---

## Briefing an Agent

```
Task: Write CRUD tests for the User model.
Files:
  - app/Models/User.php (read)
  - tests/Feature/UserTest.php (create)
  - tests/Feature/PostTest.php (reference for patterns)
Constraints:
  - Use Pest syntax (see existing tests)
  - Include validation edge cases
Success: All tests pass. Coverage for create, read, update, delete.
```

---

## Parallel Delegation

```markdown
## Delegated

| # | Task | Agent | Started | Status |
|---|------|-------|---------|--------|
| 3 | Write User CRUD tests | general-purpose | 2026-02-04 | delegated |
| 4 | Write Post CRUD tests | general-purpose | 2026-02-04 | delegated |
| 5 | Add API documentation | general-purpose | 2026-02-04 | delegated |
```

Three independent tasks. No shared dependencies. Safe to parallelize.

---

## Reviewing Agent Output

```
Agent completed Task #3.

Review checklist:
- [ ] Tests follow project patterns
- [ ] Edge cases covered
- [ ] No hardcoded values
- [ ] Assertions are meaningful

Status: in-review → done (if good) or re-delegate (if issues)
```

---

## Re-delegating After Failure

```
Task #3 failed review: Missing validation tests.

Re-delegate with additional context:

Task: Add validation tests to User CRUD tests.
Files: tests/Feature/UserTest.php (modify)
Constraints:
  - Test required fields: name, email
  - Test email format validation
  - Test unique email constraint
Success: Validation edge cases covered. Tests pass.
```
