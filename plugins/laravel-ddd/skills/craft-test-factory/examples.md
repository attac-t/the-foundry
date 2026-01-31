# Test Factory: Examples

Patterns for immutable, configurable test factories.

---

## The Pattern

### ✅ Immutable Factory with Auto-Increment
**Why?** Predictable, chainable, no test pollution.
```php
class InvoiceFactory
{
    private static int $number = 0;
    private ?string $status = null;

    public static function new(): self
    {
        return new self();
    }

    public function paid(): self
    {
        $clone = clone $this;
        $clone->status = PaidInvoiceState::class;
        return $clone;
    }

    public function pending(): self
    {
        $clone = clone $this;
        $clone->status = PendingInvoiceState::class;
        return $clone;
    }

    public function create(array $extra = []): Invoice
    {
        self::$number += 1;
        return Invoice::create(array_merge([
            'number' => 'I-' . self::$number,
            'status' => $this->status ?? PendingInvoiceState::class,
        ], $extra));
    }
}
```

---

## Usage

### ✅ Fluent, Self-Documenting
```php
it('can mark invoice as paid', function () {
    $invoice = InvoiceFactory::new()->pending()->create();

    $invoice->transitionTo(PaidInvoiceState::class);

    expect($invoice->status)->toBeInstanceOf(PaidInvoiceState::class);
});
```

### ✅ Multiple Invoices
```php
$pending = InvoiceFactory::new()->pending();

$invoices = collect([
    $pending->create(),
    $pending->create(),
    $pending->create(),
]);

// Numbers: I-1, I-2, I-3 (predictable)
```

---

## DTO Factory

### ✅ Beyond Models
**Why?** Laravel factories only create models. DTOs need factories too.
```php
class InvoiceDataFactory
{
    public static function new(): self
    {
        return new self();
    }

    public function create(array $extra = []): InvoiceData
    {
        return InvoiceData::from(array_merge([
            'client_id' => ClientFactory::new()->create()->id,
            'due_date' => now()->addDays(30),
            'lines' => [],
        ], $extra));
    }
}
```

---

## Testing Actions

### ✅ Setup → Execute → Expect
```php
it('can create an invoice', function () {
    // Setup
    $data = InvoiceDataFactory::new()->create();
    $action = app(CreateInvoiceAction::class);

    // Execute
    $invoice = $action->execute($data);

    // Expect
    expect($invoice)->toBeInstanceOf(Invoice::class);
    expect($invoice->status)->toBeInstanceOf(PendingInvoiceState::class);
});
```
