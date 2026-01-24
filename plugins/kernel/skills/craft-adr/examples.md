# ADR: Examples

Template and real-world patterns.

---

## Template

```markdown
# ADR-001: Title

**Status**: Accepted
**Date**: 2024-01-01

## Context

What is the problem? What constraints exist?

## Decision

What did we choose? Why?
What alternatives were rejected?

## Consequences

+ Positive outcome
+ Positive outcome
- Trade-off or risk
- Trade-off or risk
```

---

## Examples

### Package Choice
```markdown
# ADR-001: Use Structured Data Transfer Objects

## Context
We need type-safe data objects with validation.

## Decision
Use a DTO library with attribute-based validation.
Rejected: plain objects (no validation), manual serializers (too complex).

## Consequences
+ Validation via attributes
+ Auto-casting from requests
- Steeper learning curve
```

### Pattern Choice
```markdown
# ADR-002: Query Builders over Repository Pattern

## Context
We need reusable query logic.

## Decision
Use custom query builders, not repositories.
The ORM IS the abstraction; wrapping it adds no value.

## Consequences
+ Full ORM power retained
+ Composable query methods
- Team must learn query builder extension
```
