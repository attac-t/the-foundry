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

### ❌ WithCast on $dataClass DTO
**Why?** `#[WithCast]` only applies when DTO is hydrated from request. Ignored when DTO is used as `$dataClass` for a collection.
```php
// ❌ This cast is ignored when FeeData is a collection item
#[WithCast(SomeCaster::class)]
class FeeData extends Data { ... }

// In parent DTO:
#[DataCollectionOf(FeeData::class)]
public Collection $fees;  // FeeData's WithCast ignored here
```

### ✅ Cast at Property Level
```php
class OrderData extends Data
{
    #[WithCast(MoneyCast::class)]
    public Money $total,  // ✅ Cast applied here
}
```

> Rule: `#[WithCast]` belongs on the property receiving the data, not the DTO class itself.
