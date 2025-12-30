# QueryBuilder: Examples

Patterns for custom Eloquent builders.

---

## The Pattern

### ✅ Custom QueryBuilder
**Why?** Scopes in dedicated class, not fat Model.
```php
class OrderQueryBuilder extends Builder
{
    public function pending(): self
    {
        return $this->where('status', OrderStatus::Pending);
    }

    public function forCustomer(Customer $customer): self
    {
        return $this->where('customer_id', $customer->id);
    }

    public function placedBetween(Carbon $start, Carbon $end): self
    {
        return $this->whereBetween('placed_at', [$start, $end]);
    }
}
```

---

## Composition

### ✅ Chainable Methods
**Why?** Build complex queries from simple parts.
```php
Order::query()
    ->pending()
    ->forCustomer($customer)
    ->placedBetween($start, $end)
    ->with('items')
    ->get();
```

---

## Aggregations

### ✅ WithCount, WithSum, WithAvg
**Why?** Avoid N+1 for aggregate data.
```php
public function withTotals(): self
{
    return $this
        ->withSum('items', 'quantity')
        ->withSum('items', 'price');
}
```

---

## Subqueries

### ✅ Select Subquery
**Why?** Complex calculations without raw SQL.
```php
public function withLatestPaymentDate(): self
{
    return $this->addSelect([
        'latest_payment_at' => Payment::query()
            ->whereColumn('order_id', 'orders.id')
            ->latest()
            ->select('created_at')
            ->limit(1),
    ]);
}
```
