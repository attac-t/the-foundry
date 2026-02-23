# Macro: Examples

Patterns from the framework and production code.

---

## The Pattern

### Single Macro Registration
**Why?** Adds one method to a class you don't own.
```php
Collection::macro('toUpper', function () {
    return $this->map(fn ($value) => strtoupper($value));
});

collect(['hello', 'world'])->toUpper(); // ['HELLO', 'WORLD']
```

### The Mixin Pattern (Grouped Macros)
**Why?** Double-closure: reflection invokes the outer, the inner becomes the macro bound to the target instance.
```php
class CollectionMixin
{
    public function toUpper()
    {
        return function () {
            return $this->map(fn ($v) => strtoupper($v));
        };
    }

    // toLower(), toTitle(), etc.
}

Collection::mixin(new CollectionMixin);
```

---

## Common Scenarios

### Request Macros
**Why?** Domain-specific accessors on the request object.
```php
Request::macro('tenantId', function () {
    return $this->header('X-Tenant-ID');
});
```

### Builder Macros
**Why?** Reusable query shortcuts across all models.
```php
Builder::macro('whereLike', function (string $column, string $value) {
    return $this->where($column, 'like', "%{$value}%");
});

User::whereLike('name', 'john')->get();
```

### Route Macros
**Why?** Fluent route-level middleware registration.
```php
Route::macro('role', function ($roles) {
    $this->middleware("role:{$roles}");
    return $this;
});

Route::get('/admin', AdminController::class)->role('admin');
```

### Macroable Classes in Laravel
**Why?** Check for `Macroable` before reaching for inheritance.
```text
Collection, Builder (Eloquent + Query), Request, Response,
Router, Str, Arr, ResponseFactory, Pennant\Decorator
```

### Conditionable and Tappable (Related Traits)
**Why?** Complement Macroable to form the runtime extension toolkit.
```php
$query->when($request->has('sort'), fn ($q) => $q->orderBy('name'));

$user->tap(fn ($u) => Log::info("Processing: {$u->id}"))->save();
```
