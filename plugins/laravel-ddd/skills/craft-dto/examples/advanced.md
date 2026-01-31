# DTO: Advanced Patterns

Immutability, optional fields, and validation.

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
