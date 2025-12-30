# Template: Namespace README

For `domain/` and `support/` directories.

---

```markdown
# {Namespace}

{One sentence: what this namespace does.}

---

## When to Use

{2-3 bullet points. Be specific.}

- When you need to...
- When handling...
- When building...

---

## Key Classes

```
{ClassName}        {What it does}
{ClassName}        {What it does}
{ClassName}        {What it does}
```

---

## Quick Start

```php
// {Describe what this example does}
{Minimal working example}
```

---

## Common Patterns

### {Pattern Name}

```php
{Code example}
```

### {Pattern Name}

```php
{Code example}
```

---

## Related

- `{Namespace}/` — {Relationship}
- `{Namespace}/` — {Relationship}
```

---

## Example: domain/Orders

```markdown
# Orders

Manages order lifecycle from creation to fulfillment.

---

## When to Use

- Creating or modifying orders
- Processing payments against orders
- Tracking order status changes

---

## Key Classes

```
Order              Eloquent model. The aggregate root.
CreateOrder        Action. Creates order with items.
OrderData          DTO. Validated order input.
OrderQueryBuilder  Query builder. Scoped queries.
```

---

## Quick Start

```php
// Create an order
$order = app(CreateOrder::class)->execute(
    OrderData::from($request)
);
```

---

## Common Patterns

### Adding Items

```php
$order->items()->create([
    'product_id' => $product->id,
    'quantity' => 2,
    'unit_price' => $product->price,
]);
```

### Applying Discounts

```php
app(ApplyDiscount::class)->execute($order, $discount);
```

---

## Related

- `domain/Products/` — Items reference products
- `domain/Payments/` — Payments settle orders
```
