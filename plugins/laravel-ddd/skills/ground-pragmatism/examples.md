# Pragmatism: Examples

Patterns for balancing purity with productivity.

---

## Breaking Rules Deliberately

### ✅ Justified Shortcut
```php
// TODO(JIRA-123): Extract to action when reused
// For now, inline is simpler
public function store(Request $request): Response
{
    $user = User::create($request->validated());
    Mail::send(new WelcomeEmail($user));

    return redirect()->route('users.show', $user);
}
```

### ❌ Unjustified Purity
```php
// Over-engineered for a one-off admin feature
interface UserCreationStrategyFactoryInterface
{
    public function create(UserCreationContext $context): UserCreationStrategy;
}
```

---

## Technical Debt as Tool

### ✅ Conscious Debt
```php
// DEBT: Hardcoded for MVP, make configurable in v2
// Ticket: JIRA-456
// Risk: Low (only affects internal reports)
private const REPORT_LIMIT = 100;
```

### ❌ Unconscious Debt
```php
// No comment, no ticket, no awareness
private const REPORT_LIMIT = 100;  // Why 100? Who knows.
```

---

## Context-Appropriate Rigor

### Startup (Ship Fast)
```php
// Good enough for 10 users
public function calculateTotal(): float
{
    return $this->items->sum('price');
}
```

### Enterprise (Build Robust)
```php
// Necessary for 10,000 transactions/day
public function calculateTotal(): Money
{
    return $this->items
        ->map(fn ($item) => $item->price)
        ->reduce(
            fn (Money $carry, Money $price) => $carry->add($price),
            Money::zero($this->currency),
        );
}
```

---

## The Pragmatist's Questions

```
1. "Will this matter in 3 months?"
   No → Ship it simple

2. "How many users will this affect?"
   Few → Accept more risk

3. "Can we fix it later without pain?"
   Yes → Ship now, iterate

4. "Is the team blocked on this decision?"
   Yes → Decide and move on
```

---

## Anti-Pattern: Analysis Paralysis

### ❌ Overthinking
```
Week 1: Research 5 caching strategies
Week 2: Benchmark all options
Week 3: Write ADR for decision
Week 4: Still no cache implemented
```

### ✅ Pragmatic Progress
```
Day 1: Add simple file cache
Day 2: Ship feature to users
Month 3: Users complain it's slow
Month 3: Upgrade to Redis (now we have real data)
```
