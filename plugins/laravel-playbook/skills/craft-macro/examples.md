# Macro: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Single Macro Registration
**Why?** Adds one method to a class you don't own.
```php
use Illuminate\Support\Collection;

// In your service provider's boot() method
Collection::macro('toUpper', function () {
    return $this->map(fn ($value) => strtoupper($value));
});

// Usage
collect(['hello', 'world'])->toUpper(); // ['HELLO', 'WORLD']
```

### The Mixin Pattern (Grouped Macros)
**Why?** Registers multiple related macros from a single class.
```php
class CollectionMixin
{
    public function toUpper()
    {
        return function () {
            return $this->map(fn ($v) => strtoupper($v));
        };
    }

    public function toLower()
    {
        return function () {
            return $this->map(fn ($v) => strtolower($v));
        };
    }
}

// Register all methods at once
Collection::mixin(new CollectionMixin);
```
The double-closure pattern: the mixin method is invoked by reflection. Its return value (the inner closure) becomes the macro, bound to the target instance.

---

## Common Scenarios

### Request Macros
```php
use Illuminate\Http\Request;

Request::macro('isApiRequest', function () {
    return $this->is('api/*');
});

Request::macro('tenantId', function () {
    return $this->header('X-Tenant-ID');
});
```

### Builder Macros
```php
use Illuminate\Database\Eloquent\Builder;

Builder::macro('whereLike', function (string $column, string $value) {
    return $this->where($column, 'like', "%{$value}%");
});

// Usage
User::whereLike('name', 'john')->get();
```

### Route Macros (Spatie Permission)
```php
// Spatie registers route macros in packageBooted()
Route::macro('role', function ($roles) {
    $this->middleware("role:{$roles}");
    return $this;
});

Route::macro('permission', function ($permissions) {
    $this->middleware("permission:{$permissions}");
    return $this;
});

// Usage
Route::get('/admin', AdminController::class)->role('admin');
```

### The Macroable Trait Internals
```php
trait Macroable
{
    protected static $macros = [];

    public static function macro($name, $macro)
    {
        static::$macros[$name] = $macro;
    }

    public static function mixin($mixin, $replace = true)
    {
        $methods = (new ReflectionClass($mixin))->getMethods(
            ReflectionMethod::IS_PUBLIC | ReflectionMethod::IS_PROTECTED
        );

        foreach ($methods as $method) {
            if ($replace || ! static::hasMacro($method->name)) {
                static::macro($method->name, $method->invoke($mixin));
            }
        }
    }

    public function __call($method, $parameters)
    {
        if (! static::hasMacro($method)) {
            throw new BadMethodCallException("Method {$method} does not exist.");
        }

        $macro = static::$macros[$method];

        if ($macro instanceof Closure) {
            $macro = $macro->bindTo($this, static::class);
        }

        return $macro(...$parameters);
    }
}
```
Key: `macro()` stores closures. `mixin()` extracts methods via reflection. `__call()` binds the closure to the calling instance so `$this` refers to the target object, not the mixin.

### Macroable Classes in Laravel
```php
// Classes that use the Macroable trait (partial list):
Illuminate\Support\Collection
Illuminate\Database\Eloquent\Builder
Illuminate\Database\Query\Builder
Illuminate\Http\Request
Illuminate\Http\Response
Illuminate\Routing\Router
Illuminate\Support\Str
Illuminate\Support\Arr
Illuminate\Routing\ResponseFactory
Laravel\Pennant\Decorator
```
Any class using `Macroable` is extensible at runtime. Check if the class uses the trait before reaching for inheritance.

### Conditionable and Tappable (Related Traits)
```php
// Conditionable — fluent conditional logic
$query->when($request->has('sort'), function ($q) {
    return $q->orderBy('name');
});

// Tappable — side effects without breaking the chain
$user->tap(function ($user) {
    Log::info("Processing user: {$user->id}");
})->save();
```
These traits complement Macroable. `Conditionable` adds `when()`/`unless()`. `Tappable` adds `tap()`. Together with macros, they form the runtime extension toolkit for Laravel classes.
