# Arch Testing: Examples

Structure as code.

---

## The Pattern

### Built-in Presets
**Why?** Instant wins.
```php
// tests/Pest.php
arch()->preset()->php();        // no die(), var_dump(), deprecated
arch()->preset()->security();   // no eval(), exec(), shell_exec()
arch()->preset()->laravel();    // Laravel conventions
```

---

## Common Scenarios

### Namespace Constraints
```php
arch('models extend base')
    ->expect('App\Models')
    ->toExtend('Illuminate\Database\Eloquent\Model');

arch('actions are final')
    ->expect('Domain\*\Actions')
    ->toBeFinal();

arch('controllers are invokable')
    ->expect('App\Http\Controllers')
    ->toBeInvokable();
```

### Dependency Constraints
```php
arch('domain has no HTTP dependencies')
    ->expect('Domain')
    ->not->toUse('Illuminate\Http');

arch('models stay in their domain')
    ->expect('Domain\Order\Models')
    ->not->toBeUsedIn('Domain\User');
```

### Trait Enforcement
```php
arch('jobs use Queueable')
    ->expect('App\Jobs')
    ->toUse('Illuminate\Bus\Queueable');
```

### Ignoring Violations
```php
arch('actions are final')
    ->expect('Domain\*\Actions')
    ->toBeFinal()
    ->ignoring('Domain\Legacy\Actions'); // TODO: refactor legacy
```

---

## Quick Reference

| Rule          | Expectation                     |
|---------------|---------------------------------|
| No debug code | `->not->toUse(['dd', 'dump'])`  |
| Models extend | `->toExtend(Model::class)`      |
| Classes final | `->toBeFinal()`                 |
| No cross-deps | `->not->toBeUsedIn()`           |
| Invokable     | `->toBeInvokable()`             |

---

## Reference

- [Pest: Architecture Testing](https://pestphp.com/docs/arch-testing)
- [Honeybadger: Architecture Testing with Laravel Pest](https://www.honeybadger.io/blog/laravel-pest-architecture-testing/)
