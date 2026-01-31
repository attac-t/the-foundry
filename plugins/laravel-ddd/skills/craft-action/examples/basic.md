# Action: Basic Patterns

Single-unit business logic with chainable steps.

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

---

## Single Responsibility

### ✅ One Thing Well
**Why?** Each private method: one step, returns `$this`.
```php
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
