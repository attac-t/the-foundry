# Registry: Examples

Patterns for multi-provider handler dispatch.

---

## The Pattern

### ✅ Interface + Registry
**Why?** New providers = new handler class. No switch statements.
```php
interface SyncHandler
{
    public function supports(string $provider): bool;
    public function sync(SyncContext $context): SyncResult;
}

class SyncHandlerRegistry
{
    /** @var SyncHandler[] */
    private array $handlers = [];

    public function register(SyncHandler $handler): void
    {
        $this->handlers[] = $handler;
    }

    public function get(string $provider): SyncHandler
    {
        foreach ($this->handlers as $handler) {
            if ($handler->supports($provider)) {
                return $handler;
            }
        }

        throw new UnknownProviderException("No handler for: {$provider}");
    }
}
```

---

## Handler Implementation

### ✅ Concrete Handler
```php
class XeroSyncHandler implements SyncHandler
{
    public function supports(string $provider): bool
    {
        return $provider === 'xero';
    }

    public function sync(SyncContext $context): SyncResult
    {
        // Xero-specific sync logic
        $client = app(XeroClient::class);
        $invoices = $client->getInvoices($context->dateRange);

        return SyncResult::success(count($invoices));
    }
}

class QuickBooksSyncHandler implements SyncHandler
{
    public function supports(string $provider): bool
    {
        return $provider === 'quickbooks';
    }

    public function sync(SyncContext $context): SyncResult
    {
        // QuickBooks-specific logic
    }
}
```

---

## Service Provider Registration

### ✅ Tagged Services (Laravel Way)
```php
// AppServiceProvider
public function register(): void
{
    $this->app->singleton(SyncHandlerRegistry::class, function ($app) {
        $registry = new SyncHandlerRegistry();

        foreach ($app->tagged('sync.handlers') as $handler) {
            $registry->register($handler);
        }

        return $registry;
    });

    $this->app->tag([
        XeroSyncHandler::class,
        QuickBooksSyncHandler::class,
    ], 'sync.handlers');
}
```

### ✅ Config-Driven
```php
// config/sync.php
return [
    'handlers' => [
        'xero' => XeroSyncHandler::class,
        'quickbooks' => QuickBooksSyncHandler::class,
    ],
];

// Registry
public function __construct()
{
    foreach (config('sync.handlers') as $provider => $class) {
        $this->handlers[$provider] = app($class);
    }
}
```

---

## Usage

### ✅ In Action
```php
class SyncSalesAction
{
    public function __construct(
        private SyncHandlerRegistry $registry,
    ) {}

    public function execute(SyncContext $context): SyncResult
    {
        $handler = $this->registry->get($context->provider);

        return $handler->sync($context);
    }
}
```

---

## Anti-Pattern: Switch Statement

### ❌ Don't: Hard-coded Dispatch
```php
public function sync(string $provider): void
{
    match ($provider) {
        'xero' => $this->syncXero(),
        'quickbooks' => $this->syncQuickBooks(),
        default => throw new Exception("Unknown: {$provider}"),
    };
}
```

### ✅ Do: Registry Dispatch
```php
public function sync(string $provider): void
{
    $this->registry->get($provider)->sync($context);
}
```
