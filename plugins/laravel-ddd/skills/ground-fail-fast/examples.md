# Fail Fast: Examples

Patterns for boundary validation.

---

## The Boundary Flow

```
┌─────────────────────────────────────────────┐
│  HTTP Request                               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  FormRequest (VALIDATE HERE)                │  ← Boundary
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  DTO (Type-safe, validated data)            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Action (Trusts input is valid)             │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Model (Persists valid data)                │
└─────────────────────────────────────────────┘
```

---

## Laravel Patterns

### ✅ `bail`: Stop on First Failure
**Why?** Don't waste cycles validating fields that won't matter.
```php
$request->validate([
    'email' => 'bail|required|email|unique:users',
    // If 'required' fails, 'email' and 'unique' won't run
]);
```

### ✅ `stopOnFirstFailure`: Stop All Validation
**Why?** Some forms should halt entirely on first error.
```php
class StoreUserRequest extends FormRequest
{
    protected $stopOnFirstFailure = true;

    public function rules(): array
    {
        return [
            'email' => 'required|email',
            'name' => 'required|string',
        ];
    }
}
```

---

## Anti-Patterns

### ❌ Validating Inside Actions
**Why?** Action should trust its input. Validation belongs at the boundary.
```php
// Bad: Action validates
class CreateOrderAction
{
    public function execute(array $data): Order
    {
        if (empty($data['customer_id'])) {
            throw new ValidationException('Customer required');
        }
        // ...
    }
}
```

### ✅ Boundary Validates, Action Trusts
```php
// Good: FormRequest validates
class CreateOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return ['customer_id' => 'required|exists:customers,id'];
    }
}

// Good: Action trusts
class CreateOrderAction
{
    public function execute(OrderData $data): Order
    {
        return Order::create([
            'customer_id' => $data->customerId,
        ]);
    }
}
```

---

## Self-Validating Objects

### ✅ Value Objects Fail on Construction
**Why?** Invalid state is impossible to represent.
```php
readonly class Email
{
    public function __construct(public string $value)
    {
        if (! filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException("Invalid email: {$value}");
        }
    }
}

// Can't create invalid email
$email = new Email('not-an-email');  // Throws immediately
```
