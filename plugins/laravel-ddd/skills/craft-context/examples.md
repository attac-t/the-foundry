# Context: Examples

Patterns for parameter encapsulation.

---

## The Pattern

### ✅ Private Constructor + Invariant Validation
**Why?** Invalid context impossible. Intent explicit.
```php
readonly class SyncSalesContext
{
    private function __construct(
        public string $provider,
        public Carbon $startDate,
        public Carbon $endDate,
        public bool $dryRun,
        public ?int $batchId,
    ) {
        // Invariant: dates must be valid range
        if ($startDate->isAfter($endDate)) {
            throw new InvalidArgumentException('Start date must be before end date');
        }

        // Invariant: provider must be supported
        if (! in_array($provider, ['sage', 'myob', 'quickbooks'])) {
            throw new InvalidArgumentException("Unsupported provider: {$provider}");
        }
    }

    public static function forProvider(
        string $provider,
        Carbon $startDate,
        Carbon $endDate,
        bool $dryRun = false,
    ): self {
        return new self($provider, $startDate, $endDate, $dryRun, null);
    }

    public static function forBatch(
        string $provider,
        int $batchId,
    ): self {
        return new self(
            $provider,
            now()->subDays(30),
            now(),
            dryRun: false,
            batchId: $batchId,
        );
    }
}
```

---

## Usage

### ✅ From Controller
```php
public function sync(SyncSalesRequest $request): RedirectResponse
{
    $context = SyncSalesContext::forProvider(
        provider: $request->provider,
        startDate: $request->start_date,
        endDate: $request->end_date,
        dryRun: $request->dry_run,
    );

    $this->syncSales->execute($context);

    return back()->with('success', 'Sync started');
}
```

### ✅ From Command
```php
public function handle(): int
{
    $context = SyncSalesContext::forProvider(
        provider: $this->argument('provider'),
        startDate: now()->subDays(7),
        endDate: now(),
    );

    $this->syncSales->execute($context);

    return 0;
}
```

---

## Passed Through Chains

### ✅ Context Flows Through Actions
```php
class SyncSalesAction
{
    public function __construct(
        private FetchSalesAction $fetchSales,
        private ProcessSalesAction $processSales,
        private RecordSyncAction $recordSync,
    ) {}

    public function execute(SyncSalesContext $context): SyncResult
    {
        $sales = $this->fetchSales->execute($context);
        $processed = $this->processSales->execute($context, $sales);

        return $this->recordSync->execute($context, $processed);
    }
}
```

---

## Anti-Pattern: Parameter Explosion

### ❌ Don't: Too Many Parameters
```php
public function execute(
    string $provider,
    Carbon $startDate,
    Carbon $endDate,
    bool $dryRun,
    ?int $batchId,
    bool $verbose,
): SyncResult
```

### ✅ Do: Context Object
```php
public function execute(SyncSalesContext $context): SyncResult
```
