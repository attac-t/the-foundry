# Extraction: Examples

Real-world examples of Action vs Inline decisions.

---

## Laravel Framework

### Illuminate\Auth\AuthManager
**Why?** Login is multi-step with events.
```php
// Framework extracts authentication logic
$this->guard()->attempt($credentials);

// Internally: validate, fire events, regenerate session
```

### Illuminate\Foundation\Bus
**Why?** Command dispatch is reusable.
```php
// Extracted to trait for reuse
use Illuminate\Foundation\Bus\Dispatchable;

class CreateOrder
{
    use Dispatchable;
}
```

---

## Vendor Packages

### Spatie Laravel Data
**Why?** Transformation is extracted to DTO.
```php
use Spatie\LaravelData\Data;

class OrderData extends Data
{
    public static function fromModel(Order $order): self
    {
        return new self(
            id: $order->id,
            total: $order->total,
        );
    }
}
```

### Spatie Media Library
**Why?** File handling extracted to dedicated actions.
```php
// Package extracts complex media operations
$model->addMedia($file)
    ->usingFileName('custom.jpg')
    ->toMediaCollection('images');
```

---

## The Rules

| Rule                           | Rationale                   |
| ------------------------------ | --------------------------- |
| One public method: `execute()` | Single responsibility       |
| Return Model or void           | Never DTO or Response       |
| No transactions                | Consumer controls atomicity |
| No try-catch                   | Let errors bubble           |

---

## Composition

### Action Composes Actions
**Why?** Orchestrates multiple focused actions.
```php
class ImportProductsAction
{
    public function execute(UploadedFile $file): ImportResult
    {
        $rows = $this->parseCsv->execute($file);

        return $rows->map(
            fn ($row) => $this->createProduct->execute($row)
        );
    }
}
```

---

## Anti-Patterns

### Action Wraps Simple CRUD
**Why wrong?** Unnecessary layer.
```php
// Bad: no business logic
class CreateUserAction
{
    public function execute($data): User
    {
        return User::create($data);
    }
}

// Good: inline in controller
$user = User::create($request->validated());
```

### Service Class
**Why wrong?** God class. Split into actions.
```php
// Bad: 10 methods
class OrderService
{
    public function create() {}
    public function update() {}
    public function cancel() {}
    public function ship() {}
}

// Good: separate actions
CreateOrderAction, CancelOrderAction, ShipOrderAction
```

### Transaction in Action
**Why wrong?** Prevents composition.
```php
// Bad: nested transactions ignored
class CreateOrderAction
{
    public function execute($dto)
    {
        DB::transaction(...);
    }
}

// Good: controller wraps
DB::transaction(fn () => $this->createOrder->execute($dto));
```
