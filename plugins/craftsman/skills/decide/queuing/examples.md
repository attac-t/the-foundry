# Queuing: Examples

Real-world examples of Queue vs Sync decisions.

---

## Laravel Framework

### Illuminate\Mail\Mailable
**Why?** Email sending should never block users.
```php
use Illuminate\Contracts\Queue\ShouldQueue;

class OrderConfirmation extends Mailable implements ShouldQueue
{
    public $tries = 3;
    public $backoff = [60, 300, 900];
}
```

### Illuminate\Notifications
**Why?** Notifications naturally async.
```php
use Illuminate\Contracts\Queue\ShouldQueue;

class InvoicePaid extends Notification implements ShouldQueue {}
```

### Illuminate\Bus\Batch
**Why?** Process large operations in parallel.
```php
Bus::batch([
    new ProcessPodcast($podcast1),
    new ProcessPodcast($podcast2),
])->dispatch();
```

---

## Vendor Packages

### Spatie Media Library
**Why?** Image conversions are slow.
```php
public function registerMediaConversions(): void
{
    $this->addMediaConversion('thumb')
        ->queued();  // Runs async
}
```

### Laravel Horizon
**Why?** Dashboard for queue monitoring.
```php
// horizon.php
'supervisor-1' => [
    'connection' => 'redis',
    'queue' => ['default', 'emails'],
    'balance' => 'auto',
]
```

---

## Key Contracts

### ShouldBeUnique
**Why?** Prevents duplicate jobs for same resource.
```php
use Illuminate\Contracts\Queue\ShouldBeUnique;

class IndexPriceListJob implements ShouldQueue, ShouldBeUnique
{
    public function uniqueId(): string
    {
        return $this->priceListId;
    }
}
```

### Batchable
**Why?** Part of a batch with cancellation support.
```php
use Illuminate\Bus\Batchable;

class CreateProductJob implements ShouldQueue
{
    use Batchable;

    public function handle(): void
    {
        if ($this->batch()->cancelled()) {
            return;
        }
    }
}
```

---

## Anti-Patterns

### Passing Eloquent Models
**Why wrong?** Serialization issues, stale data.
```php
// Bad: model may be stale
public function __construct(public Order $order) {}

// Good: fetch fresh
public function __construct(public string $orderId) {}
```

### Sync External Call
**Why wrong?** Blocks user, no retry on failure.
```php
// Bad: user waits for Stripe
$this->stripe->createCustomer($user);

// Good: queue it
CreateStripeCustomerJob::dispatch($user->id);
```
