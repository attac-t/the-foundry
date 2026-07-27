# Queueable Action: Examples

Patterns for queue-dispatched actions.

---

## The Pattern

### ✅ Add Trait to Existing Action
**Why?** No new class needed. Same action, now queueable.
```php
use Spatie\QueueableAction\QueueableAction;

class SendInvoiceMailAction
{
    use QueueableAction;

    public function execute(Invoice $invoice): void
    {
        // Same business logic
        Mail::send(new InvoiceMail($invoice));
        $invoice->update(['sent_at' => now()]);
    }
}
```

---

## Usage

`onQueue()` is an instance method. Inject the action, or resolve it.

### ✅ Sync (Default)
```php
$action->execute($invoice);
```

### ✅ Async (Queued)
```php
$action->onQueue()->execute($invoice);
```

### ✅ Named Queue
```php
// The queue name is the argument. onQueue() returns a proxy whose only
// public method is execute() — nothing else chains onto it.
$action->onQueue('emails')->execute($invoice);
```

### ✅ Resolved from the Container
```php
app(SendInvoiceMailAction::class)
    ->onQueue('emails')
    ->execute($invoice);
```

### ✅ Connection, Delay, Retries
Configured on the action, not chained onto the call:
```php
class SendInvoiceMailAction
{
    use QueueableAction;

    public string $connection = 'redis';
    public int $tries = 3;

    public function backoff(): array
    {
        return [10, 60, 300];
    }

    public function execute(Invoice $invoice): void { /* ... */ }
}
```

---

## When to Use

### ✅ Good Candidates
```php
// Email sending
$sendWelcomeEmail->onQueue()->execute($user);

// PDF generation
$generateInvoicePdf->onQueue()->execute($invoice);

// External API calls
$syncToXero->onQueue()->execute($payment);
```

### ❌ Poor Candidates
```php
// Needs immediate result — a queued action returns nothing useful
$total = $calculateTotals->onQueue()->execute($cart);  // Won't work!

// Simple CRUD
$createUser->onQueue()->execute($data);  // Overkill
```

---

## Anti-Pattern: Job Wrapper

### ❌ Don't: Separate Job Class
```php
// Unnecessary boilerplate
class SendInvoiceMailJob implements ShouldQueue
{
    public function handle(): void
    {
        app(SendInvoiceMailAction::class)->execute($this->invoice);
    }
}

dispatch(new SendInvoiceMailJob($invoice));
```

### ✅ Do: Queueable Action
```php
$sendInvoiceMail->onQueue()->execute($invoice);
```
