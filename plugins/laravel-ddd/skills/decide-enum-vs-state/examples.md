# Enum vs State: Examples

When to use simple enums vs full state pattern.

---

## Enum Examples

### ✅ Priority (Just a Label)
**Why?** No behavior needed. Just display and filtering.
```php
enum Priority: string
{
    case Low = 'low';
    case Medium = 'medium';
    case High = 'high';
    case Critical = 'critical';
}

// Usage: just labels
<span class="badge">{{ $task->priority->value }}</span>
```

### ✅ Currency (Static Values)
```php
enum Currency: string
{
    case AUD = 'AUD';
    case USD = 'USD';
    case EUR = 'EUR';

    public function symbol(): string
    {
        return match($this) {
            self::AUD => '$',
            self::USD => '$',
            self::EUR => '€',
        };
    }
}
```

---

## State Pattern Examples

### ✅ Invoice State (Has Behavior)
**Why?** States determine what actions are allowed. Behavior varies by state.
```php
abstract class InvoiceState extends State
{
    abstract public function canBePaid(): bool;
    abstract public function canBeVoided(): bool;
    abstract public function color(): string;
}

class DraftInvoiceState extends InvoiceState
{
    public function canBePaid(): bool
    {
        return false;  // Must be sent first
    }

    public function canBeVoided(): bool
    {
        return true;
    }

    public function color(): string
    {
        return 'gray';
    }
}

class SentInvoiceState extends InvoiceState
{
    public function canBePaid(): bool
    {
        return $this->getModel()->total_price > 0;
    }

    public function canBeVoided(): bool
    {
        return true;
    }

    public function color(): string
    {
        return 'blue';
    }
}
```

### ✅ Transitions with Side Effects
**Why?** Moving between states triggers notifications, logging, etc.
```php
class SentToPaidTransition extends Transition
{
    public function handle(): Invoice
    {
        $invoice = $this->getModel();
        $invoice->state = new PaidInvoiceState($invoice);
        $invoice->paid_at = now();
        $invoice->save();

        // Side effects
        InvoicePaid::dispatch($invoice);
        $this->notifyClient($invoice);

        return $invoice;
    }
}
```

---

## The Gray Area

### ⚠️ When It's Close
```php
// Start with enum
enum OrderStatus: string
{
    case Pending = 'pending';
    case Processing = 'processing';
    case Shipped = 'shipped';
    case Delivered = 'delivered';
}

// Migrate to state when you see:
// - if ($order->status === OrderStatus::Pending) { ... }
// - if ($order->status === OrderStatus::Pending) { ... }  // Again elsewhere
// - if ($order->status === OrderStatus::Pending) { ... }  // Third time = refactor
```
