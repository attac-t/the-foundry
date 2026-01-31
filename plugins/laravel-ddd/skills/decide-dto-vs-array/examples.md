# DTO vs Array: Examples

When type safety is worth the overhead.

---

## Array Examples

### ✅ Local Transformation
**Why?** Never leaves the method. No one else sees it.
```php
public function execute(): void
{
    $data = ['count' => 0, 'total' => 0];

    foreach ($items as $item) {
        $data['count']++;
        $data['total'] += $item->price;
    }

    Log::info('Processed', $data);
}
```

### ✅ Framework Config
```php
return [
    'driver' => 'redis',
    'connection' => 'default',
];
```

---

## DTO Examples

### ✅ Request to Action
**Why?** Crosses controller → action boundary. Validation needed.
```php
// ❌ Array: What's in $data? Who knows.
public function execute(array $data): Invoice

// ✅ DTO: Contract is explicit.
public function execute(CreateInvoiceData $data): Invoice
```

### ✅ Reused Structure
**Why?** Same shape in controller, job, and test = DTO.
```php
// If you see this pattern:
$data = [
    'client_id' => $request->client_id,
    'items' => $request->items,
    'due_date' => $request->due_date,
];

// And then again:
$data = [
    'client_id' => $command->argument('client'),
    'items' => $parsedItems,
    'due_date' => now()->addDays(30),
];

// Create a DTO:
class CreateInvoiceData extends Data
{
    public function __construct(
        public int $client_id,
        public array $items,
        public Carbon $due_date,
    ) {}
}
```

### ✅ API Response
**Why?** Structure is documented. Breaking changes are visible.
```php
class InvoiceData extends Data
{
    public function __construct(
        public string $id,
        public string $number,
        public MoneyData $total,
        public Carbon $due_date,
    ) {}
}
```

---

## The Migration Path

### From Array to DTO
```php
// Step 1: Array works
$action->execute(['name' => $name, 'email' => $email]);

// Step 2: You see it twice → Create DTO
class CreateUserData extends Data
{
    public function __construct(
        public string $name,
        #[Email]
        public string $email,
    ) {}
}

// Step 3: Use DTO
$action->execute(CreateUserData::from($request));
```

---

## Anti-Pattern: Over-DTOing

### ❌ Don't: DTO for One-Time Local Use
```php
// Overkill
class TempCalculationData extends Data
{
    public function __construct(
        public int $count,
        public float $total,
    ) {}
}

$data = new TempCalculationData(0, 0.0);
```

### ✅ Do: Array for Throwaway Data
```php
$data = ['count' => 0, 'total' => 0.0];
```
