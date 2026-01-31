# Model State: Examples

Patterns from spatie/laravel-model-states.

---

## The Pattern

### ✅ Abstract Base
**Why?** Centralizes transitions. Defines shared interface.
```php
abstract class PaymentState extends State
{
    abstract public function color(): string;

    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Pending::class)
            ->allowTransition(Pending::class, Paid::class)
            ->allowTransition(Pending::class, Failed::class, PendingToFailed::class);
    }
}
```

---

## Common Scenarios

### ✅ Concrete State
```php
class Pending extends PaymentState
{
    public function color(): string
    {
        return 'yellow';
    }
}
```

### ✅ Custom Transition
```php
class PendingToFailed extends Transition
{
    public function __construct(
        private Payment $payment,
        private string $reason,
    ) {}

    public function handle(): Payment
    {
        $this->payment->state = new Failed($this->payment);
        $this->payment->failure_reason = $this->reason;
        $this->payment->save();

        return $this->payment;
    }
}
```

### ✅ Model Integration
```php
class Payment extends Model
{
    use HasStates;

    protected $casts = [
        'state' => PaymentState::class,
    ];
}
```

---

## State-Specific Behavior

### ✅ Behavior Lives in State
**Why?** State knows what it can do. Model doesn't need conditionals.
```php
abstract class InvoiceState extends State
{
    abstract public function canBePaid(): bool;
    abstract public function color(): string;
}

class PendingInvoiceState extends InvoiceState
{
    public function canBePaid(): bool
    {
        // State has access to model via $this->getModel()
        return $this->getModel()->total_price > 0;
    }

    public function color(): string
    {
        return 'yellow';
    }
}

class PaidInvoiceState extends InvoiceState
{
    public function canBePaid(): bool
    {
        return false;  // Already paid
    }

    public function color(): string
    {
        return 'green';
    }
}
```

### ✅ Usage in Views/Controllers
```php
// No conditionals needed
<span class="badge bg-{{ $invoice->state->color() }}">
    {{ $invoice->state::$name }}
</span>

// Guard behavior
if ($invoice->state->canBePaid()) {
    $invoice->state->transitionTo(PaidInvoiceState::class);
}
```

### ✅ Transition with Side Effects
```php
class PendingToPaidTransition extends Transition
{
    public function handle(): Invoice
    {
        $invoice = $this->getModel();

        $invoice->state = new PaidInvoiceState($invoice);
        $invoice->paid_at = now();
        $invoice->save();

        // Side effects
        InvoicePaid::dispatch($invoice);
        History::log($invoice, 'Marked as paid');

        return $invoice;
    }
}
```
