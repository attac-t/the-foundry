# DTO: Advanced Patterns

Immutability, optional fields, upsert pattern, and validation.

---

## Upsert Pattern

### ✅ Optional ID for Create/Update
**Why?** Single DTO handles both create (no id) and update (has id).
```php
use Spatie\LaravelData\Attributes\FromRouteParameterProperty;
use Spatie\LaravelData\Optional;

class UpsertFeeDTO extends Data
{
    public function __construct(
        #[FromRouteParameterProperty('fee', 'id')]
        public readonly int|Optional $id,

        #[Max(255)]
        public readonly string $name,

        #[Min(0)]
        public readonly int $amount,
    ) {}
}
```

### ✅ Action Handles Optional
```php
// In UpsertFeeAction
Fee::updateOrCreate(
    attributes: ['id' => $dto->id instanceof Optional ? null : $dto->id],
    values: $dto->all(),  // ✅ Not ->except('id')->toArray()
);
```

> The DTO carries the data. The action decides how to use it.

---

## Immutability

### ✅ Mutate via with()
```php
// ❌ Don't mutate directly
$data->status = 'paid';

// ✅ Create new instance
$data = $data->with(status: 'paid');
```

---

## Optional Fields

### ✅ Optional Type for Partial Updates
**Why?** Distinguish "not provided" from "set to null".
```php
use Spatie\LaravelData\Optional;

class UpdatePostData extends Data
{
    public function __construct(
        public string|Optional $title,
        public string|Optional $body,
        public ?string $excerpt,  // null = clear it
    ) {}
}

// Usage:
$data = UpdatePostData::from(['title' => 'New Title']);
// $data->title = 'New Title'
// $data->body = Optional (not provided)
// $data->excerpt = null
```

### ✅ Checking Optional
```php
if (! $data->title instanceof Optional) {
    $post->title = $data->title;
}
```

---

## Validation Attributes

### ✅ Built-in Validation
```php
class CreateUserData extends Data
{
    public function __construct(
        #[Required, Max(255)]
        public string $name,
        #[Required, Email, Unique('users', 'email')]
        public string $email,
        #[Required, Min(8)]
        public string $password,
    ) {}
}
```

### ✅ Custom Rules
```php
#[Rule('exists:teams,id')]
public int $team_id,

#[Rule(new CustomRule())]
public string $code,
```

---

## Casting Pitfalls

### ❌ WithCast on Output-Only DTO
**Why?** `#[WithCast]` is for the input direction (request → DTO). If a DTO is only used for output (model → DTO), casts are never triggered.
```php
// FeeData used only as output (nested in parent DTO)
class FeeData extends Data
{
    #[WithCast(MoneyCast::class)]  // ❌ Never triggered
    public Money $amount,
}

// Parent output DTO:
class OrderData extends Data
{
    #[DataCollectionOf(FeeData::class)]
    public Collection $fees,  // FeeData created from model, not request
}
```

### ✅ Casts on Request DTOs
```php
// Input DTO — casts apply here
class CreateOrderData extends Data
{
    #[WithCast(MoneyCast::class)]
    public Money $total,  // ✅ Cast triggered on request hydration
}
```

> Rule: `#[WithCast]` is for input. If the DTO is output-only, casts are dead code.
