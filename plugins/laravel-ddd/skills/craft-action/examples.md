# Action: Examples

Patterns for single-unit business logic.

---

## The Pattern

### ✅ Chainable Steps
**Why?** Fluent, readable, self-documenting flow.
```php
class ActivatePriceListAction
{
    protected PriceList $priceList;

    public function execute(PriceList $priceList): void
    {
        $this->priceList = $priceList;

        $this
            ->guardAlreadyActive()
            ->markAsActive()
            ->notify();
    }

    private function guardAlreadyActive(): self
    {
        if ($this->priceList->isActive()) {
            throw new PriceListAlreadyActiveException;
        }
        return $this;
    }

    private function markAsActive(): self
    {
        $this->priceList->activate();

        return $this;
    }

    private function notify(): self
    {
        PriceListActivated::dispatch($this->priceList);

        return $this;
    }
}
```

### ✅ Another Example
```php
class CreateOrderAction
{
    protected Order $order;

    public function execute(CreateOrderData $data): Order
    {
        $this->order = Order::create($data->all());

        $this
            ->ensureAvailability()
            ->calculateTotals()
            ->applyDiscounts()
            ->notify();

        return $this->order;
    }
}
```

---

## Single Responsibility

### ✅ One Thing Well
```php
// Each private method: one step, returns $this
private function ensureAvailability(): self { ... return $this; }
private function calculateTotals(): self { ... return $this; }
private function applyDiscounts(): self { ... return $this; }
private function notify(): self { ... return $this; }
```

---

## Calling Context

### ✅ From Controller
```php
public function store(CreateOrderData $data): RedirectResponse
{
    $order = DB::transaction(fn () => $this->createOrder->execute($data));
    return redirect()->route('orders.show', $order);
}
```

### ✅ From Job
```php
public function handle(): void
{
    $this->activatePriceList->execute($this->priceList);
}
```
