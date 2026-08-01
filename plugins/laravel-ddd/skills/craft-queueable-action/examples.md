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

### ✅ Sync (Default)
```php
$action->execute($invoice);
```

### ✅ Async (Queued)
```php
SendInvoiceMailAction::onQueue()->execute($invoice);
```

### ✅ With Queue Options
```php
SendInvoiceMailAction::onQueue('emails')
    ->delay(now()->addMinutes(5))
    ->execute($invoice);
```

### ✅ On Specific Connection
```php
SendInvoiceMailAction::onQueue()
    ->onConnection('redis')
    ->onQueue('high')
    ->execute($invoice);
```

---

## When to Use

### ✅ Good Candidates
```php
// Email sending
SendWelcomeEmailAction::onQueue()->execute($user);

// PDF generation
GenerateInvoicePdfAction::onQueue()->execute($invoice);

// External API calls
SyncToSageAction::onQueue()->execute($payment);
```

### ❌ Poor Candidates
```php
// Needs immediate result
$total = CalculateTotalsAction::onQueue()->execute($cart);  // Won't work!

// Simple CRUD
CreateUserAction::onQueue()->execute($data);  // Overkill
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
SendInvoiceMailAction::onQueue()->execute($invoice);
```
