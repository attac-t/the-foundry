# Model: Examples

Patterns from Laravel Eloquent.

---

## Data Class

### ✅ Define $dataClass
**Why?** Links Model to its DTO representation.
```php
class Order extends Model
{
    protected string $dataClass = OrderData::class;
}
```

---

## Casts

### ✅ Enum Cast
**Why?** Type-safe status handling.
```php
protected $casts = [
    'status' => OrderStatus::class,
    'placed_at' => 'datetime',
];
```

### ✅ Value Object Cast
**Why?** Domain concepts deserve objects.
```php
protected $casts = [
    'total' => MoneyCast::class,
    'address' => AddressCast::class,
];
```

---

## Custom Builder

### ✅ Register Builder
**Why?** Scopes belong in dedicated QueryBuilder.
```php
/** @return OrderQueryBuilder<Order> */
public function newEloquentBuilder($query): OrderQueryBuilder
{
    return new OrderQueryBuilder($query);
}
```

---

## Custom Collection

### ✅ Register Collection
**Why?** Domain methods on collections.
```php
/** @return OrderCollection<int, Order> */
public function newCollection(array $models = []): OrderCollection
{
    return new OrderCollection($models);
}
```

---

## Relationships

### ✅ Latest Of Many
**Why?** Common pattern for "most recent" relations.
```php
public function latestPayment(): HasOne
{
    return $this->hasOne(Payment::class)->latestOfMany();
}
```

### ✅ Scoped Relationship
**Why?** Pre-constrained relationships.
```php
public function activeSubscription(): HasOne
{
    return $this->hasOne(Subscription::class)
        ->where('status', 'active');
}
```
