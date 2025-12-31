# Events: Examples

Real-world examples of Events vs Direct Calls.

---

## Laravel Framework

### Illuminate\Auth\Events
**Why?** Authentication has multiple side effects.
```php
// Framework dispatches on login
event(new Login($guard, $user, $remember));

// You listen for analytics, logging, session setup
```

### Illuminate\Database\Events
**Why?** Model lifecycle has multiple observers.
```php
// Framework events
ModelCreated::class
ModelUpdated::class
ModelDeleted::class

// Trait usage
use Illuminate\Database\Eloquent\Concerns\HasEvents;
```

### ShouldDispatchAfterCommit
**Why?** Prevents listeners from acting on uncommitted data.
```php
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;

class OrderPlaced implements ShouldDispatchAfterCommit {}
```

---

## Vendor Packages

### Spatie Activity Log
**Why?** Automatic logging via model events.
```php
use Spatie\Activitylog\Traits\LogsActivity;

class Order extends Model {
    use LogsActivity;
}
```

### Laravel Cashier
**Why?** Billing events for multiple handlers.
```php
// Cashier dispatches
Cashier::dispatch('subscription.created', $subscription);

// Your app listens
SubscriptionCreated::class => [SendWelcomeEmail::class, SyncToCRM::class]
```

---

## The Chain Pattern

### Action → Event → Listener → Job
**Why?** Separates intent from consequences, sync from async.
```php
// Action: business logic
OrderCreated::dispatch($order);

// Listener: thin, dispatches job
SyncOrderToShopifyJob::dispatch($order->id);

// Job: actual external work
```

---

## Anti-Patterns

### Event for Single Consumer
**Why wrong?** Overengineering. Just call it.
```php
// Bad: event with one listener
OrderTotalCalculatedEvent::dispatch($order);

// Good: direct call
$total = $this->calculateTotal->execute($order);
```

### Listener Does Heavy Work
**Why wrong?** Listeners should delegate to Jobs for external calls.
```php
// Bad: listener calls API directly
$this->shopifyClient->createOrder($event->order);

// Good: listener dispatches job
SyncOrderToShopifyJob::dispatch($event->order->id);
```
