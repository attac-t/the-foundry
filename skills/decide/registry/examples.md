# Registry: Examples

Real-world examples of the Registry pattern decision.

---

## Laravel Framework

### ✅ Gate (Authorization Registry)
**Why?** Abilities are registered at boot, resolved by name.
```php
// Registration
Gate::define('edit-post', fn (User $u, Post $p) => $u->id === $p->user_id);

// Resolution
Gate::allows('edit-post', $post);
```

### ✅ Blade Directives
**Why?** Custom directives are registered, resolved by name.
```php
// Registration
Blade::directive('money', fn ($expr) => "<?php echo money({$expr}); ?>");

// Usage
@money($price)
```

### ✅ Validation Rules
**Why?** Custom rules are registered, resolved by name.
```php
// Registration
Validator::extend('phone', fn ($attr, $val) => preg_match('/^\d{10}$/', $val));

// Usage
'phone' => 'required|phone'
```

---

## Spatie Packages

### ✅ Permission Registry (Database-backed)
**Why?** Roles/permissions are dynamic, user-defined.
```php
// Registration (to DB)
Permission::create(['name' => 'edit articles']);

// Resolution
$user->hasPermissionTo('edit articles');
```

---

## Production Patterns

### ✅ PrintRouteStrategyRegistry (Your Codebase)
**Why?** Strategies are selectable by user, extensible.
```php
class PrintRouteStrategyRegistry {
    public function register(PrintRouteStrategyInterface $strategy): void
    {
        $this->strategies[$strategy->getIdentifier()] = $strategy;
    }
    
    public function resolve(string $identifier): ?PrintRouteStrategyInterface;
    public function getOptions(): array; // For UI dropdown
}
```

### ✅ ConfigurationKeyRegistry
**Why?** Configuration keys are registered per-domain, validated dynamically.
```php
$keyRegistry->register('pos.grid.cols', new ConfigurationKeyDefinition(...));
```

### ✅ OperationHandlerRegistry
**Why?** PowerSync handlers are registered per-model, resolved by operation type.
```php
$registry->register(OrderOperationHandler::class);
```
