# Polish: Examples

Universal patterns. Language-agnostic.

---

## Pass 1: Docblocks

### The Trial
**Why?** If the signature tells the story, the docblock is noise.

```
// Before — the signature says it all
/** Get the user's email address. */
function email(): string

// After — deleted. The name IS the doc.
function email(): string
```

### Earns Its Place
**Why?** Non-obvious behavior, type refinement, or external references justify a docblock.

```
// Earns it — warns the caller
/** @throws RateLimitException When more than 100 requests per minute. */
function send(message): Response

// Earns it — type the language can't express
/** @param items: Array<{id: string, quantity: number}> */
function calculateTotal(items): number

// Earns it — external reference
/** @see https://stripe.com/docs/api/charges/create */
function charge(amount, currency): ChargeResult
```

---

## Pass 2: Names

### Generic to Specific
**Why?** Generic names force the reader to track context. Specific names are self-documenting.

```
// Before
data = fetchData()
result = process(data)
return result

// After
orderPayload = fetchOrderPayload()
invoice = buildInvoice(orderPayload)
return invoice
```

### Boolean Prefix
**Why?** Booleans without prefix look like nouns.

```
// Before
eligible = checkEligibility(order)
receipted = order.hasReceipts()

// After
isEligible = checkEligibility(order)
isReceipted = order.hasReceipts()
```

---

## Pass 3: Methods

### The Two-Thing Split
**Why?** A blank line between "two things" is a method boundary waiting to happen.

```
// Before (validates AND transforms)
function processOrder(order) {
    if (!order.isValid()) throw new Error("Invalid")
    if (order.items.length === 0) throw new Error("Empty")

    total = order.items.sum(item => item.price)
    tax = total * TAX_RATE
    return { total, tax, net: total + tax }
}

// After
function ensureValid(order) {
    if (!order.isValid()) throw new Error("Invalid")
    if (order.items.length === 0) throw new Error("Empty")
}

function calculateTotals(order) {
    total = order.items.sum(item => item.price)
    tax = total * TAX_RATE
    return { total, tax, net: total + tax }
}
```

---

## Pass 4: Framework Internals

### Loop to Built-in
**Why?** Frameworks solve common patterns. Custom loops reinvent them.

```
// Before — manual accumulation
totals = {}
for item in items:
    key = item.category
    totals[key] = (totals[key] or 0) + item.amount

// After — framework method
totals = items.groupBy("category").mapValues(group => group.sum("amount"))
```

### Assign-Then-Return
**Why?** One expression beats three statements.

```
// Before
result = new Report()
result.title = title
result.generatedAt = now()
return result

// After — single expression (tap in PHP, let/also in Kotlin, Object.assign in JS)
return createWith(new Report(), r => { r.title = title; r.generatedAt = now() })
```

---

## Pass 5: Whitespace

### Code That Breathes
**Why?** A method without breathing room is a paragraph without punctuation.

```
// Before — suffocating
function resolve(order) {
    discount = Discount.for(order)
    if (discount.isEmpty()) {
        return null
    }
    invoice = buildInvoice(order, discount)
    validate(invoice)
    return invoice
}

// After — breathing
function resolve(order) {
    discount = Discount.for(order)

    if (discount.isEmpty()) {
        return null
    }

    invoice = buildInvoice(order, discount)
    validate(invoice)

    return invoice
}
```

---

## Pass 6: Conditionals

### Nested to Flat
**Why?** Early returns eliminate nesting. The happy path lives at level 0.

```
// Before — nested
function process(order) {
    if (order.isEligible()) {
        discount = Discount.for(order)
        if (!discount.isEmpty()) {
            return buildInvoice(order, discount)
        }
    }
    return null
}

// After — flat
function process(order) {
    if (!order.isEligible()) {
        return null
    }

    discount = Discount.for(order)

    if (discount.isEmpty()) {
        return null
    }

    return buildInvoice(order, discount)
}
```

---

## Report Template

```markdown
# Polish: {Scope}

**Date:** YYYY-MM-DD
**Files in Scope:** N
**Files Polished:** N
**Files Already Clean:** N
**Tests:** All passing (N tests, N assertions)

## File Manifest

| # | File | Status | Changes |
|---|------|--------|---------|
| 1 | `path/to/File.ext` | polished | Removed 2 docblocks, renamed 1 var |
| 2 | `path/to/Other.ext` | clean | — |

## Changes by Category

### Docblocks Removed/Rewritten
| File | Method | Reason |
|------|--------|--------|

### Names Changed
| File | Before | After | Reason |
|------|--------|-------|--------|

### Methods Extracted/Shortened
| File | Method | LOC Before | LOC After | What Changed |
|------|--------|-----------|----------|--------------|

### Framework Upgrades
| File | Before | After | Feature |
|------|--------|-------|---------|

### Conditional Flattening
| File | Method | Nesting Before | Nesting After |
|------|--------|---------------|---------------|

### Test Polish
| File | Test | Change |
|------|------|--------|

## Unchanged
[Files that needed no polish — and why they were already good]
```
