# API Entry Point: Examples

Real-world examples from the framework and production packages.

---

## Framework Examples

### Trait: Laravel Cashier's Billable

**Why?** Billing behavior belongs on the user model -- `$user->charge()` is natural.

```php
use Laravel\Cashier\Billable;

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
use Spatie\ResponseCache\Facades\ResponseCache;

ResponseCache::clear();
ResponseCache::forget('/users');
```

### Static Factory: QueryBuilder

**Why?** Entry point to a fluent chain. No model attachment, no global state.

```php
use Spatie\QueryBuilder\QueryBuilder;

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

**Why?** Multiple search backends (Algolia, Meilisearch, database). Users pick a driver via config, extend with custom engines.

```php
// Default engine from config
$results = Product::search('laptop')->get();

// Specific engine
Scout::engine('meilisearch');

// Custom engine via extend()
Scout::extend('elasticsearch', function ($app) {
    return new ElasticsearchEngine($app['config']['scout.elasticsearch']);
});
```

### Manager: Socialite

**Why?** Each OAuth provider is a driver. Users extend with custom providers.

```php
// Built-in driver
return Socialite::driver('github')->redirect();

// Custom driver
Socialite::extend('discord', function ($app) {
    $config = $app['config']['services.discord'];
    return new DiscordProvider($app['request'], $config['client_id'], $config['client_secret'], $config['redirect']);
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

Many packages use both. The trait integrates at the model level; the facade provides global operations.

```php
// Trait on the model
class User extends Model
{
    use HasRoles;
}

// Facade for cache management
app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
```

### The Manager Pattern Anatomy

The convention: `create{Name}Driver()` methods. Default driver from config. `__call` delegates to it.

```php
class EngineManager extends Manager
{
    public function createAlgoliaDriver() { /* ... */ }
    public function createMeilisearchDriver() { /* ... */ }
    public function createDatabaseDriver() { /* ... */ }

    public function getDefaultDriver()
    {
        return config('scout.driver') ?? 'null';
    }
}
```

### Domain Aliasing on Managers

Scout aliases `driver()` as `engine()` for domain clarity. Same method, domain-specific language.

```php
public function engine($name = null)
{
    return $this->driver($name);
}
```
