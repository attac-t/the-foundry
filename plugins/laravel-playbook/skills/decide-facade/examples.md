# API Entry Point: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### Trait: Cashier's Billable
**Why?** Billing behavior belongs on the user model -- `$user->charge()` is natural.
```php
class User extends Model
{
    use Billable;
}

$user->charge(1000, 'pm_card_visa');
$user->newSubscription('default', 'price_monthly')->create('pm_card_visa');
```

### Facade: ResponseCache
**Why?** Caching is a global service -- no model owns it.
```php
ResponseCache::clear();
ResponseCache::forget('/users');
```

### Static Factory: QueryBuilder
**Why?** Entry point to a fluent chain. No model attachment, no global state.
```php
$users = QueryBuilder::for(User::class)
    ->allowedFilters(['name', 'email'])
    ->allowedSorts(['created_at'])
    ->get();
```

### Static Factory: Filament's ::make()
**Why?** Declarative schema building. Container resolution enables global extension.
```php
TextInput::make('name')
    ->required()
    ->maxLength(255)

Select::make('status')
    ->options(['draft' => 'Draft', 'published' => 'Published'])
```

### Manager: Scout's EngineManager
**Why?** Multiple search backends. Users pick a driver via config, extend with custom engines.
```php
$results = Product::search('laptop')->get();

Scout::extend('elasticsearch', function ($app) {
    return new ElasticsearchEngine($app['config']['scout.elasticsearch']);
});
```

### Manager: Socialite
**Why?** Each OAuth provider is a driver.
```php
return Socialite::driver('github')->redirect();

Socialite::extend('discord', function ($app) {
    return new DiscordProvider(/* ... */);
});
```

### Helper: activity()
**Why?** Logging activity is universal. Called from controllers, jobs, listeners -- everywhere.
```php
activity()->log('User signed up');
activity('audit')->performedOn($model)->log('Updated record');
```

---

## Production Patterns

### Combining Trait + Facade
```php
// Trait on the model
class User extends Model
{
    use HasRoles;
}

// Facade for cache management
app(PermissionRegistrar::class)->forgetCachedPermissions();
```

### The Manager Pattern Anatomy
```php
class EngineManager extends Manager
{
    public function createAlgoliaDriver() { /* ... */ }
    public function createMeilisearchDriver() { /* ... */ }

    public function getDefaultDriver()
    {
        return config('scout.driver') ?? 'null';
    }
}
```
Convention: `create{Name}Driver()` methods. Default driver from config. `__call` delegates.

### Domain Aliasing
```php
public function engine($name = null)
{
    return $this->driver($name);
}
```
Scout aliases `driver()` as `engine()` for domain clarity. Same method, domain-specific language.
