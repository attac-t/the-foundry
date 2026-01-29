# Event-Driven Model: Examples

Patterns for decoupled model side effects.

---

## The Pattern

### ✅ Model Dispatches Events
```php
class Invoice extends Model
{
    protected $dispatchesEvents = [
        'saving' => InvoiceSavingEvent::class,
        'created' => InvoiceCreatedEvent::class,
    ];
}
```

### ✅ Event Carries Context
```php
class InvoiceSavingEvent
{
    public function __construct(
        public Invoice $invoice,
    ) {}
}
```

### ✅ Subscriber Handles Logic
```php
class InvoiceSubscriber
{
    public function __construct(
        private CalculateTotalsAction $calculateTotals,
    ) {}

    public function handleSaving(InvoiceSavingEvent $event): void
    {
        // Recalculate before save
        $this->calculateTotals->execute($event->invoice);
    }

    public function handleCreated(InvoiceCreatedEvent $event): void
    {
        // Log creation
        History::log($event->invoice, 'Invoice created');
    }

    public function subscribe(Dispatcher $events): array
    {
        return [
            InvoiceSavingEvent::class => 'handleSaving',
            InvoiceCreatedEvent::class => 'handleCreated',
        ];
    }
}
```

---

## Registration

### ✅ In EventServiceProvider
```php
protected $subscribe = [
    InvoiceSubscriber::class,
    OrderSubscriber::class,
];
```

---

## Common Use Cases

### ✅ Auto-Calculate on Save
```php
// Before save: recalculate totals
public function handleSaving(InvoiceSavingEvent $event): void
{
    $invoice = $event->invoice;
    $invoice->total_price = $invoice->lines->sum('total');
}
```

### ✅ Audit Trail
```php
public function handleCreated(InvoiceCreatedEvent $event): void
{
    AuditLog::create([
        'model' => Invoice::class,
        'model_id' => $event->invoice->id,
        'action' => 'created',
        'user_id' => auth()->id(),
    ]);
}
```

### ✅ Cascade Updates
```php
public function handleUpdated(InvoiceUpdatedEvent $event): void
{
    // Update related records
    $event->invoice->client->updateBalance();
}
```

---

## Anti-Pattern: Logic in boot()

### ❌ Don't: Hidden Logic
```php
protected static function boot()
{
    parent::boot();

    static::saving(function ($invoice) {
        // Hidden, hard to test, grows unbounded
        $invoice->total_price = $invoice->lines->sum('total');
        $invoice->tax = $invoice->total_price * 0.1;
        Mail::send(new InvoiceUpdatedMail($invoice));
        Log::info('Invoice saved');
    });
}
```

### ✅ Do: Events + Subscribers
```php
// Model is clean
protected $dispatchesEvents = [
    'saving' => InvoiceSavingEvent::class,
];

// Logic is in dedicated, testable subscriber
class InvoiceSubscriber
{
    public function handleSaving(InvoiceSavingEvent $event): void
    {
        $this->calculateTotals->execute($event->invoice);
    }
}
```
