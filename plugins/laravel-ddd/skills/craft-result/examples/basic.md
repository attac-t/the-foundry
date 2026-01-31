# Result: Basic Pattern

Named constructors with rich context.

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
