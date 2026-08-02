# Registry: Laravel Integration

Service provider registration and usage patterns.

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
        LedgerSyncHandler::class,
        SpreadsheetSyncHandler::class,
    ], 'sync.handlers');
}
```

### ✅ Config-Driven
```php
// config/sync.php
return [
    'handlers' => [
        'ledger' => LedgerSyncHandler::class,
        'spreadsheet' => SpreadsheetSyncHandler::class,
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

## Anti-Pattern

### ❌ Switch Statement
```php
public function sync(string $provider): void
{
    match ($provider) {
        'ledger' => $this->syncLedger(),
        'spreadsheet' => $this->syncSpreadsheet(),
        default => throw new Exception("Unknown: {$provider}"),
    };
}
```

### ✅ Registry Dispatch
```php
public function sync(string $provider): void
{
    $this->registry->get($provider)->sync($context);
}
```
