# Collection: Examples

Patterns from Laravel Collections.

---

## The Pattern

### ✅ Custom Collection
**Why?** Domain methods on typed collection.
```php
/** @extends Collection<int, Order> */
class OrderCollection extends Collection
{
    public function pending(): self
    {
        return $this->filter(fn (Order $o) => $o->isPending());
    }

    public function totalValue(): Money
    {
        return $this->reduce(
            fn (Money $sum, Order $o) => $sum->add($o->total),
            Money::zero()
        );
    }
}
```

---

## Common Methods

### ✅ Filtering
```php
public function unpaid(): self
{
    return $this->filter(fn (Order $o) => ! $o->isPaid());
}
```

### ✅ Aggregation
```php
public function averageValue(): Money
{
    return $this->avg(fn (Order $o) => $o->total->cents());
}
```

### ✅ Grouping
```php
public function byStatus(): self
{
    return $this->groupBy(fn (Order $o) => $o->status->value);
}
```

---

## Registration

### ✅ Register on Model
```php
// In Model
public function newCollection(array $models = []): OrderCollection
{
    return new OrderCollection($models);
}
```
