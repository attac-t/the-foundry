# Trait: Examples

Patterns from the framework and production code.

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
**Why?** Traits define Eloquent relationships. Always type the return.

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
**Why?** Encapsulate query logic in the trait, not scattered across controllers.

```php
public function scopeRole(Builder $query, string|BackedEnum $role): Builder
{
    return $query->whereHas('roles', fn ($q) => $q->where('name', $role));
}
```

### Configuration via Abstract Methods
**Why?** The trait defines the contract. The model fulfills it.

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
**Why?** Default (empty) implementations. Override only when needed.

```php
public function registerMediaConversions(?Media $media = null): void {}
public function registerMediaCollections(): void {}
```

### Accessor/Mutator Interception
**Why?** Transparent behavior. Call `parent::` for non-intercepted attributes.

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
**Why?** Two patterns. Choose based on semantics.

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

### Component Traits (Caleb Porzio / Livewire)
**Why?** `use Thing` works beyond models. Livewire traits compose component capabilities.

```php
class UserDirectory extends Component
{
    use WithPagination, WithFileUploads;

    public function updatedSearch(): void { $this->resetPage(); }        // From WithPagination
    public function save(): void { $this->photo->store('avatars'); }     // From WithFileUploads
}
```

Package authors: if your package enhances a component (Livewire, Filament, or custom), ship a trait.

### Concerns Decomposition (Taylor / Cashier)
**Why?** Split large traits into focused concerns. Compose into one user-facing trait.

```php
// src/Concerns/ — each concern is focused
trait HandlesTaxes { /* ... */ }
trait ManagesSubscriptions { /* ... */ }
// ... ManagesCustomer, ManagesInvoices, PerformsCharges

// src/Billable.php — the user-facing trait composes them
trait Billable
{
    use HandlesTaxes, ManagesCustomer, ManagesInvoices;
    use ManagesPaymentMethods, ManagesSubscriptions, PerformsCharges;
}
```

### Utility Traits from Laravel Core
**Why?** Beyond models. Any class can use these.

```php
class ReportBuilder
{
    use Conditionable; // when(), unless()
    use Tappable;      // tap()
    use Macroable;     // macro(), mixin()
}

// Conditionable
$query->when($request->has('sort'), fn ($q) => $q->orderBy('name'));

// Macroable
Collection::macro('toUpper', fn () => $this->map(fn ($v) => strtoupper($v)));
```
