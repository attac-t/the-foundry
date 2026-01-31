# Value Object: Laravel Integration

Queue serialization and Eloquent casting.

---

## Queue Serialization

### ✅ Safe in Jobs
**Why?** Primitives + other VOs serialize cleanly.
```php
class ProcessBatchJob implements ShouldQueue
{
    public function __construct(
        public BatchIdentifier $batch,  // Serializes cleanly
    ) {}

    public function handle(): void
    {
        Log::info("Processing {$this->batch->toString()}");
    }
}
```

### ❌ Won't Serialize
**Why?** Closures and resources can't be serialized.
```php
readonly class BadValueObject
{
    public function __construct(
        public Closure $callback,  // Can't serialize
        public PDO $connection,    // Resource, can't serialize
    ) {}
}
```

---

## Eloquent Casting

### ✅ Cast to Value Object
**Why?** Database column ↔ typed VO.
```php
class MoneyCast implements CastsAttributes
{
    public function get($model, $key, $value, $attrs): Money
    {
        return new Money((int) $value);
    }

    public function set($model, $key, $value, $attrs): int
    {
        return $value->cents;
    }
}

// In model
protected $casts = [
    'price' => MoneyCast::class,
];
```
