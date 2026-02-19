# Extensibility: Examples

Patterns and anti-patterns from across the Laravel ecosystem.

---

## Manager/Driver Pattern (Taylor)

### Scout's EngineManager
**Why?** Multiple search backends, one interface.
```php
class EngineManager extends Manager
{
    public function createAlgoliaDriver() { /* ... */ }
    public function createMeilisearchDriver() { /* ... */ }
    public function createDatabaseDriver() { /* ... */ }
    public function createCollectionDriver() { /* ... */ }
    public function createNullDriver() { /* ... */ }

    public function getDefaultDriver()
    {
        return config('scout.driver') ?? 'null';
    }
}

// User extends with a custom engine
Scout::extend('elasticsearch', function ($app) {
    return new ElasticsearchEngine(
        $app['config']['scout.elasticsearch']
    );
});
```

### Pennant's Custom Manager
**Why?** Manager pattern without extending the base class, with decorator wrapping.
```php
class FeatureManager
{
    protected $stores = [];
    protected $customCreators = [];

    public function extend($driver, Closure $callback)
    {
        $this->customCreators[$driver] = $callback->bindTo($this, $this);
        return $this;
    }
}

// Every driver is wrapped in a Decorator for cross-cutting concerns
Feature::extend('redis', function ($app, $config) {
    return new RedisDriver($app['redis'], $config);
});
```

---

## Adapter Pattern (League)

### Flysystem's FilesystemAdapter
**Why?** The interface is the extension point.
```php
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    public function delete(string $path): void;
    // ... 14 more methods
}

// Any backend implements the interface
class DropboxAdapter implements FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void
    {
        $this->client->upload($path, $contents);
    }
    // ... implement remaining methods
}

// No registration needed — pass to Filesystem, done
$filesystem = new Filesystem(new DropboxAdapter($client));
```

---

## Plugin System (Filament)

### The Plugin Contract
**Why?** Three methods. That's the entire contract.
```php
class BlogPlugin implements Plugin
{
    public function getId(): string
    {
        return 'blog';
    }

    public function register(Panel $panel): void
    {
        $panel->resources([
            PostResource::class,
            CategoryResource::class,
        ]);
    }

    public function boot(Panel $panel): void {}
}

// Registration
$panel->plugin(BlogPlugin::make());

// Runtime access
filament('blog')->hasAuthorResource();
```

---

## Config-Driven Bindings (Spatie)

### Model Customization via Config
**Why?** One config key replaces dozens of individual options.
```php
// config/permission.php
'models' => ['role' => App\Models\Role::class]

// Service provider
$this->app->bind(RoleContract::class,
    fn ($app) => $app->make($app->config['permission.models.role']));
```
The user extends the model, overrides what they need, registers it in config.

### Strategy Swap via Config
**Why?** Swap the entire implementation with one line.
```php
// config/responsecache.php
'cache_profile' => CacheAllSuccessfulGetRequests::class,

// User swaps to custom profile
'cache_profile' => App\CacheProfiles\CacheAuthenticatedRequests::class,
```

---

## Static Callback Customization (Taylor)

### Sanctum Token Retrieval
**Why?** One closure customizes a critical behavior.
```php
Sanctum::getAccessTokenFromRequestUsing(function ($request) {
    return $request->cookie('api_token');
});
```

### Cashier Currency Formatting
```php
Cashier::formatCurrencyUsing(function ($amount, $currency) {
    return '$' . number_format($amount / 100, 2);
});
```

### The use{Model}() Pattern
```php
// In AppServiceProvider::boot()
Cashier::useCustomerModel(Team::class);
Cashier::useSubscriptionModel(TeamSubscription::class);
Sanctum::usePersonalAccessTokenModel(CustomToken::class);
```
The package references `static::$customerModel` instead of hardcoding. Users swap internal classes without forking.

---

## Events (Cross-Ecosystem)

### Taylor's Packages
```php
// Pennant
Laravel\Pennant\Events\FeatureResolved::class
Laravel\Pennant\Events\FeatureUpdated::class

// Cashier
Laravel\Cashier\Events\WebhookReceived::class
Laravel\Cashier\Events\WebhookHandled::class
```

### Spatie's Packages
```php
// Permission
RoleAttachedEvent::dispatch($model, $rolesOrIds);
PermissionDetachedEvent::dispatch($model, $permissionsOrIds);

// Translatable
TranslationHasBeenSetEvent::dispatch($model, $key, $locale, $old, $new);
```

---

## Macroable (Taylor)

### Adding Methods at Runtime
```php
Collection::macro('toUpper', function () {
    return $this->map(fn ($value) => strtoupper($value));
});

Request::macro('isApiRequest', function () {
    return $this->is('api/*');
});
```

### Mixin for Bulk Registration
```php
class CollectionMixin
{
    public function toUpper()
    {
        return function () {
            return $this->map(fn ($v) => strtoupper($v));
        };
    }
}

Collection::mixin(new CollectionMixin);
```

---

## The Extensibility Hierarchy

When to use which pattern:

| Scale              | Pattern           | Example                                     |
|--------------------|-------------------|---------------------------------------------|
| Simple swap        | Config binding    | Spatie model customization                  |
| Single behavior    | Static callback   | `Sanctum::getAccessTokenFromRequestUsing()` |
| Runtime methods    | Macroable         | `Collection::macro()`                       |
| Multi-driver       | Manager/Driver    | Scout, Socialite, Pennant                   |
| Framework-agnostic | Adapter/Interface | Flysystem, EventSauce                       |
| Platform hosting   | Plugin system     | Filament panels                             |
| Decoupled reaction | Events            | Webhook handling, state changes             |
