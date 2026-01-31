# Abstraction Timing: Examples

When to extract vs when to duplicate.

---

## Copy-Paste (Correct)

### ✅ First Time: Just Write It
```php
// OrderController
public function store(CreateOrderRequest $request): RedirectResponse
{
    $order = DB::transaction(fn () => $this->createOrder->execute(
        CreateOrderData::from($request),
    ));

    return redirect()->route('orders.show', $order);
}
```

### ✅ Second Time: Note the Pattern
```php
// InvoiceController - similar but different
public function store(CreateInvoiceRequest $request): RedirectResponse
{
    $invoice = DB::transaction(fn () => $this->createInvoice->execute(
        CreateInvoiceData::from($request),
    ));

    // Note: same pattern as OrderController
    // Don't abstract yet

    return redirect()->route('invoices.show', $invoice);
}
```

---

## Abstract (Correct)

### ✅ Third Time: Extract
```php
// Seeing it again in QuoteController, PaymentController...
// Time to extract

trait CreatesFromRequest
{
    protected function createAndRedirect(
        string $routeName,
        Data $data,
        callable $action,
    ): RedirectResponse {
        $model = DB::transaction(fn () => $action($data));
        return redirect()->route($routeName, $model);
    }
}
```

---

## Wrong Abstraction (Avoid)

### ❌ Premature: First Occurrence
```php
// Don't create a "ResourceController" base class
// just because you wrote one controller

abstract class ResourceController
{
    abstract protected function getAction();
    abstract protected function getDataClass();
    abstract protected function getRouteName();

    public function store(Request $request): RedirectResponse
    {
        // Over-engineered on day one
    }
}
```

### ❌ Wrong Abstraction: Forced Fit
```php
// Different contexts forced into same shape
class SyncAction
{
    public function execute(string $type, array $options): void
    {
        match ($type) {
            'invoices' => $this->syncInvoices($options),
            'payments' => $this->syncPayments($options),  // Needs different options!
            'reports' => $this->syncReports($options),    // Completely different flow!
        };
    }
}
```

### ✅ Right Abstraction: Same Pattern, Same Context
```php
// Three sync handlers, same interface, same flow
interface SyncHandler
{
    public function sync(SyncContext $context): SyncResult;
}

class InvoiceSyncHandler implements SyncHandler { ... }
class PaymentSyncHandler implements SyncHandler { ... }
class ReportSyncHandler implements SyncHandler { ... }
```

---

## The Cost of Wrong Abstraction

### ❌ Symptoms
```php
// You'll see:
// - Special cases multiplying
// - `if ($type === 'special')` appearing
// - Parameters ignored for certain types
// - "This doesn't quite fit but..."

class GenericProcessor
{
    public function process(string $type, array $data): void
    {
        if ($type === 'invoice') {
            // Special case 1
        }

        if ($type !== 'report') {
            // Skip for reports
        }

        // Original logic that only works for orders
    }
}
```

### ✅ Recovery: Delete and Duplicate
```php
// Sometimes the right move is:
// 1. Delete the abstraction
// 2. Inline each usage
// 3. Let patterns emerge naturally
// 4. Abstract only the TRUE common parts
```
