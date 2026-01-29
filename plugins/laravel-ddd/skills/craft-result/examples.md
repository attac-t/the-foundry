# Result: Examples

Patterns for rich operation outcomes.

---

## The Pattern

### ✅ Named Constructors with Context
**Why?** Outcomes carry meaning. Why did it fail? What was skipped?
```php
readonly class SyncResult
{
    private function __construct(
        public bool $success,
        public ?string $reason,
        public int $processed,
        public int $skipped,
        public array $errors,
    ) {}

    public static function success(int $processed, int $skipped = 0): self
    {
        return new self(
            success: true,
            reason: null,
            processed: $processed,
            skipped: $skipped,
            errors: [],
        );
    }

    public static function failed(string $reason, array $errors = []): self
    {
        return new self(
            success: false,
            reason: $reason,
            processed: 0,
            skipped: 0,
            errors: $errors,
        );
    }

    public static function skipped(string $reason): self
    {
        return new self(
            success: true,
            reason: $reason,
            processed: 0,
            skipped: 0,
            errors: [],
        );
    }

    public function isSuccess(): bool
    {
        return $this->success;
    }

    public function wasSkipped(): bool
    {
        return $this->reason !== null && $this->processed === 0;
    }
}
```

---

## Usage

### ✅ In Action
```php
class SyncSalesAction
{
    public function execute(SyncSalesContext $context): SyncResult
    {
        if ($context->dryRun) {
            return SyncResult::skipped('Dry run mode');
        }

        try {
            $sales = $this->fetchSales($context);
            $count = $this->processSales($sales);

            return SyncResult::success(processed: $count);
        } catch (ApiException $e) {
            return SyncResult::failed(
                reason: 'API error',
                errors: [$e->getMessage()],
            );
        }
    }
}
```

### ✅ In Controller
```php
public function sync(SyncRequest $request): RedirectResponse
{
    $result = $this->syncSales->execute($context);

    if ($result->wasSkipped()) {
        return back()->with('info', $result->reason);
    }

    if (! $result->isSuccess()) {
        return back()->with('error', $result->reason);
    }

    return back()->with('success', "Processed {$result->processed} records");
}
```

---

## Anti-Pattern: Boolean Returns

### ❌ Don't: Lose Context
```php
public function execute(Context $context): bool
{
    // Why did it return false? No idea.
    return $this->doSomething();
}
```

### ✅ Do: Rich Result
```php
public function execute(Context $context): SyncResult
{
    if (! $this->canSync()) {
        return SyncResult::failed('Provider not configured');
    }
    // ...
}
```

---

## Aggregating Results

### ✅ Batch Processing
```php
class BatchSyncAction
{
    public function execute(array $providers): BatchResult
    {
        $results = [];

        foreach ($providers as $provider) {
            $results[$provider] = $this->syncProvider->execute($provider);
        }

        return BatchResult::fromResults($results);
    }
}
```
