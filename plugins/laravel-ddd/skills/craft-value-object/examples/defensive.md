# Value Object: Defensive Patterns

Making invalid states impossible.

---

## Clone to Modify

### ✅ Immutability Preserved
**Why?** Original unchanged. New instance returned.
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

    public function add(int $cents): self
    {
        return new self($this->cents + $cents, $this->currency);
    }

    public function subtract(int $cents): self
    {
        return new self($this->cents - $cents, $this->currency);
    }
}

$a = new Money(100, 'USD');
$b = $a->add(50);  // New: Money(150, 'USD')
// $a unchanged: Money(100, 'USD')
```

---

## Readonly Limitation

### ⚠️ Array Contents Can Change
**Why?** `readonly` prevents reassignment, not mutation of contents.
```php
readonly class Container
{
    public function __construct(
        public array $items,
    ) {}
}

$container = new Container(['a', 'b']);
$container->items[] = 'c';  // WORKS! Array contents can change
$container->items = ['x'];  // FAILS! Can't reassign property
```

---

## Named Factories

### ✅ Controlled Creation
**Why?** Intent is clear. Validation centralized.
```php
readonly class DateRange
{
    private function __construct(
        public Carbon $start,
        public Carbon $end,
    ) {
        if ($start->isAfter($end)) {
            throw new InvalidArgumentException('Start must be before end');
        }
    }

    public static function between(Carbon $start, Carbon $end): self
    {
        return new self($start, $end);
    }

    public static function lastDays(int $days): self
    {
        return new self(now()->subDays($days), now());
    }
}

// Can't bypass validation
$range = DateRange::lastDays(7);  // Always valid
```
