# Job: Examples

Patterns for queue orchestration.

---

## The Pattern

### ✅ Job Delegates to Action
**Why?** Job handles queue config, Action handles business logic.
```php
class SendInvoiceMailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public Invoice $invoice
    ) {}

    public function handle(): void
    {
        app(SendInvoiceMailAction::class)->execute($this->invoice);
    }
}
```

---

## Queueable Actions (Preferred)

### ✅ Skip the Job Class
**Why?** One line replaces boilerplate. Uses `spatie/laravel-queueable-action`.
```php
// Instead of:
dispatch(new SendInvoiceMailJob($invoice));

// Use ($sendInvoiceMail is injected):
$sendInvoiceMail->onQueue()->execute($invoice);
```

### ✅ Named Queue
```php
// onQueue() is an instance method; the queue name is its argument.
$sendInvoiceMail->onQueue('emails')->execute($invoice);
```

---

## Controller Dispatch

### ✅ Fire and Forget
```php
public function store(CreateInvoiceData $data): RedirectResponse
{
    $invoice = $this->createInvoice->execute($data);

    // Async notification
    $this->sendInvoiceMail->onQueue()->execute($invoice);

    return redirect()->route('invoices.show', $invoice);
}
```

---

## Anti-Pattern: Logic in Job

### ❌ Don't: Business Logic in handle()
```php
public function handle(): void
{
    // Business logic doesn't belong here
    $pdf = $this->generatePdf($this->invoice);
    Mail::send(new InvoiceMail($this->invoice, $pdf));
    $this->invoice->update(['sent_at' => now()]);
}
```

### ✅ Do: Delegate to Action
```php
public function handle(): void
{
    app(SendInvoiceMailAction::class)->execute($this->invoice);
}
```
