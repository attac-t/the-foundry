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

### ❌ Don't Pass Params Between Private Methods
**Why not?** Bloated signatures, no fluency, harder to read.
```php
class ActivatePriceListAction
{
    public function execute(PriceList $priceList): void
    {
        $this->guardAlreadyActive($priceList);
        $this->markAsActive($priceList);
        $this->notify($priceList);
    }

    private function guardAlreadyActive(PriceList $priceList): void { ... }
    private function markAsActive(PriceList $priceList): void { ... }
    private function notify(PriceList $priceList): void { ... }
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

---

## Upsert Pattern

### ✅ Single Action for Create/Update
**Why?** One action, one DTO. The `Optional` type distinguishes create from update.
```php
use Spatie\LaravelData\Optional;

final readonly class UpsertFeeAction
{
    public function execute(UpsertFeeDTO $dto): Fee
    {
        return Fee::updateOrCreate(
            attributes: ['id' => $dto->id instanceof Optional ? null : $dto->id],
            values: $dto->all(),
        );
    }
}
```

### ❌ Don't
```php
// Over-engineered
$dto->except('id')->toArray()
```

### Consider Upsert When
- Create and update share the same logic
- No distinct business rules per operation

> Separate actions are valid when create/update have different behaviors.
