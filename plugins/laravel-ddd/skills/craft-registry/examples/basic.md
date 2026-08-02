# Registry: Basic Pattern

Interface + registry for multi-provider dispatch.

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

### ✅ Concrete Handlers
```php
class LedgerSyncHandler implements SyncHandler
{
    public function supports(string $provider): bool
    {
        return $provider === 'ledger';
    }

    public function sync(SyncContext $context): SyncResult
    {
        $client = app(LedgerClient::class);
        $invoices = $client->getInvoices($context->dateRange);

        return SyncResult::success(count($invoices));
    }
}

class SpreadsheetSyncHandler implements SyncHandler
{
    public function supports(string $provider): bool
    {
        return $provider === 'spreadsheet';
    }

    public function sync(SyncContext $context): SyncResult
    {
        // Spreadsheet-specific logic
    }
}
```
