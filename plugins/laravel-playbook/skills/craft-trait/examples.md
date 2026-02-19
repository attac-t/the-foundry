# Trait: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Boot Method Convention
**Why?** `boot{TraitName}()` hooks into Eloquent lifecycle. Static. Event registration only.

```php
public static function bootLogsActivity(): void
{
    static::eventsToBeRecorded()->each(function ($event) {
        static::$event(function (Model $model) use ($event) {
            $model->logActivity($event);
        });
    });
}

public static function bootHasRoles(): void
{
    static::deleting(function ($model) {
        $model->roles()->detach();
    });
}
```

### Initialize Method Convention
**Why?** `initialize{TraitName}()` runs on every instance. Property setup only.

```php
public function initializeHasTranslations(): void
{
    $this->mergeCasts(
        array_fill_keys($this->getTranslatableAttributes(), 'array')
    );
}
```

---

## Common Scenarios

### Relationships via Traits
Traits define Eloquent relationships. Always type the return.

```php
public function roles(): BelongsToMany
{
    return $this->morphToMany(config('permission.models.role'), 'model', 'model_has_roles');
}

public function media(): MorphMany
{
    return $this->morphMany(config('media-library.media_model'), 'model');
}
```

### Query Scopes

```php
public function scopeRole(Builder $query, string|BackedEnum $role): Builder
{
    return $query->whereHas('roles', fn ($q) => $q->where('name', $role));
}
```

### Configuration via Abstract Methods
The trait defines the contract. The model fulfills it.

```php
// Trait declares:
abstract public function getActivitylogOptions(): LogOptions;

// Model implements:
public function getActivitylogOptions(): LogOptions
{
    return LogOptions::defaults()->logOnly(['name', 'email']);
}
```

### Optional Overrides
Default (empty) implementations. Override only when needed.

```php
public function registerMediaConversions(?Media $media = null): void {}
public function registerMediaCollections(): void {}
```

### Accessor/Mutator Interception
Transparent behavior. Call `parent::` for non-intercepted attributes.

```php
public function getAttributeValue($key)
{
    if ($this->isTranslatableAttribute($key)) {
        return $this->getTranslation($key, $this->getLocale());
    }

    return parent::getAttributeValue($key);
}
```

### Trait Naming Convention (Taylor)
Two patterns. Choose based on semantics.

```php
// Adjective -- describes what the model becomes
use Laravel\Scout\Searchable;
use Laravel\Cashier\Billable;

// Has{Thing} -- describes what the model gains
use Laravel\Sanctum\HasApiTokens;
use Laravel\Pennant\Concerns\HasFeatures;

class User extends Model
{
    use Searchable, Billable, HasApiTokens, HasFeatures;
}
```

### Concerns Decomposition (Taylor / Cashier)
Split large traits into focused concerns. Compose into one user-facing trait.

```php
// src/Concerns/ -- each concern is focused
trait HandlesTaxes { /* ... */ }
trait ManagesCustomer { /* ... */ }
trait ManagesInvoices { /* ... */ }
trait ManagesPaymentMethods { /* ... */ }
trait ManagesSubscriptions { /* ... */ }
trait PerformsCharges { /* ... */ }

// src/Billable.php -- the user-facing trait composes them
trait Billable
{
    use HandlesTaxes;
    use ManagesCustomer;
    use ManagesInvoices;
    use ManagesPaymentMethods;
    use ManagesSubscriptions;
    use PerformsCharges;
}

// Consumer adds one trait
class User extends Model
{
    use Billable;
}
```

### Utility Traits from Laravel Core
Beyond model traits. Any class can use these.

```php
use Illuminate\Support\Traits\Conditionable;
use Illuminate\Support\Traits\Tappable;
use Illuminate\Support\Traits\Macroable;

class ReportBuilder
{
    use Conditionable; // Adds when(), unless()
    use Tappable;      // Adds tap()
    use Macroable;     // Adds macro(), mixin()
}
```

### Conditionable in Action

```php
$query->when($request->has('sort'), function ($q) {
    return $q->orderBy('name');
});
```

### Macroable in Action

```php
// Single method
Collection::macro('toUpper', function () {
    return $this->map(fn ($value) => strtoupper($value));
});

// Bulk registration from a class
Collection::mixin(new CollectionMixin);
```
