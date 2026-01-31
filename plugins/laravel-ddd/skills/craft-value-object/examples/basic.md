# Value Object: Basic Patterns

Core value object implementation.

---

## The Pattern

### ✅ Immutable with Validation
**Why?** Invalid state is impossible. Safe to pass anywhere.
```php
readonly class BatchIdentifier
{
    public function __construct(
        public string $provider,
        public string $batchId,
        public Carbon $timestamp,
    ) {
        if (empty($provider)) {
            throw new InvalidArgumentException('Provider cannot be empty');
        }
        if (empty($batchId)) {
            throw new InvalidArgumentException('Batch ID cannot be empty');
        }
    }

    public function toString(): string
    {
        return "{$this->provider}:{$this->batchId}";
    }
}
```

---

## Common Value Objects

### ✅ Money
```php
readonly class Money
{
    public function __construct(
        public int $cents,
        public string $currency = 'AUD',
    ) {
        if ($this->cents < 0) {
            throw new InvalidArgumentException('Money cannot be negative');
        }
    }

    public function add(Money $other): Money
    {
        $this->assertSameCurrency($other);
        return new Money($this->cents + $other->cents, $this->currency);
    }

    public function format(): string
    {
        return number_format($this->cents / 100, 2) . ' ' . $this->currency;
    }
}
```

### ✅ DateRange
```php
readonly class DateRange
{
    public function __construct(
        public Carbon $start,
        public Carbon $end,
    ) {
        if ($start->isAfter($end)) {
            throw new InvalidArgumentException('Start must be before end');
        }
    }

    public function contains(Carbon $date): bool
    {
        return $date->between($this->start, $this->end);
    }

    public function overlaps(DateRange $other): bool
    {
        return $this->start->lte($other->end) && $this->end->gte($other->start);
    }
}
```

### ✅ Email
```php
readonly class Email
{
    public function __construct(
        public string $value,
    ) {
        if (! filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException("Invalid email: {$value}");
        }
    }

    public function domain(): string
    {
        return explode('@', $this->value)[1];
    }
}
```
