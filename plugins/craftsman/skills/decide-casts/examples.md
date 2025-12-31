# Casts: Examples

Real-world examples of Cast vs Accessor decisions.

---

## Laravel Framework

### Built-in Casts
**Why?** Framework provides common transformations.
```php
protected $casts = [
    'email_verified_at' => 'datetime',
    'options' => 'array',
    'is_admin' => 'boolean',
    'metadata' => AsCollection::class,
    'address' => AsEnumCollection::class.':'.AddressType::class,
];
```

### Illuminate\Database\Eloquent\Casts\Attribute
**Why?** Modern accessor syntax (Laravel 9+).
```php
use Illuminate\Database\Eloquent\Casts\Attribute;

protected function fullName(): Attribute
{
    return Attribute::make(
        get: fn () => "{$this->first_name} {$this->last_name}",
    );
}
```

### AsEncryptedCollection
**Why?** Bidirectional encryption cast.
```php
use Illuminate\Database\Eloquent\Casts\AsEncryptedCollection;

protected $casts = [
    'secrets' => AsEncryptedCollection::class,
];
```

---

## Vendor Packages

### Spatie Enum Cast
**Why?** Enum backed by package.
```php
use Spatie\Enum\Laravel\Casts\EnumCast;

protected $casts = [
    'status' => EnumCast::class.':'.OrderStatus::class,
];
```

### Brick\Money
**Why?** Money value object with cast.
```php
use Brick\Money\Money;

class MoneyCast implements CastsAttributes
{
    public function get($model, $key, $value, $attributes): Money
    {
        return Money::ofMinor($value, 'USD');
    }

    public function set($model, $key, $value, $attributes): int
    {
        return $value->getMinorAmount()->toInt();
    }
}
```

---

## Key Differences

### Cast: Same Logic Everywhere
**Why?** Phone formatting is identical across models.
```php
class PhoneNumberCast implements CastsAttributes
{
    public function get($model, $key, $value, $attributes): ?PhoneNumber
    {
        return $value ? PhoneNumber::parse($value) : null;
    }

    public function set($model, $key, $value, $attributes): ?string
    {
        return $value?->formatE164();
    }
}

// Reuse across models
User::class       => ['phone' => PhoneNumberCast::class]
Customer::class   => ['phone' => PhoneNumberCast::class]
```

### Accessor: Context-Dependent
**Why?** Return type depends on another attribute.
```php
protected function actionValue(): Attribute
{
    return Attribute::make(
        get: fn ($value) => match ($this->action_type) {
            ActionType::Percentage => Percentage::from($value),
            ActionType::Fixed => Money::ofMinor($value),
        },
    );
}
```

---

## Anti-Patterns

### Cast Depends on Other Attributes
**Why wrong?** Casts can't reliably access model state.
```php
// Bad: fragile
public function get($model, $key, $value, $attributes)
{
    return match ($model->type) {...};
}

// Good: use accessor
protected function value(): Attribute
{
    return Attribute::get(fn () => match ($this->type) {...});
}
```

### Same Accessor in Multiple Models
**Why wrong?** Extract to Cast.
```php
// Bad: copy-paste across models
User::formattedPhone()
Customer::formattedPhone()
Supplier::formattedPhone()

// Good: one cast
protected $casts = ['phone' => PhoneNumberCast::class];
```
