# Result: Usage Patterns

Using result objects in actions and controllers.

---

## In Action

### ✅ Return Rich Results
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

---

## In Controller

### ✅ Handle All Outcomes
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

### ❌ Lose Context
```php
public function execute(Context $context): bool
{
    // Why did it return false? No idea.
    return $this->doSomething();
}
```

### ✅ Rich Result
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
