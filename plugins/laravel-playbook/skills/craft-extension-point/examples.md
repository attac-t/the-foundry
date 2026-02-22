# Extension Point: Examples

Patterns from the framework and production code.

---

## The Pattern

### Manager/Driver Pattern
**Why?** Multi-implementation services. `extend()` lets consumers register custom drivers without touching core code.

```php
class NotificationManager extends Manager
{
    public function createMailDriver(): MailChannel { /* ... */ }
    public function createSlackDriver(): SlackChannel { /* ... */ }

    public function getDefaultDriver(): string
    {
        return config('notifications.default', 'mail');
    }
}
```

Consumer extension -- one call in a service provider:

```php
$this->app->make(NotificationManager::class)
    ->extend('teams', fn ($app) => new TeamsChannel(
        $app['config']['services.teams.webhook_url']
    ));
```

### Adapter Pattern
**Why?** Framework-agnostic core. Implement the interface, pass it in, done.

```php
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    public function delete(string $path): void;
    // ...
}

class DropboxAdapter implements FilesystemAdapter
{
    public function __construct(private DropboxClient $client) {}
    // ... implement each method
}

$filesystem = new Filesystem(new DropboxAdapter($client)); // no registration needed
```

### Macroable Registration
**Why?** Runtime extension of any Macroable class.

```php
// Single method
Collection::macro('toUpper', fn () =>
    $this->map(fn ($value) => strtoupper($value))
);

// Bulk via mixin class
Collection::mixin(new CollectionMixin);
```

---

## Common Scenarios

### Render Hooks (Filament)
**Why?** Named injection points for plugins to insert UI without modifying templates.

```php
FilamentView::registerRenderHook(
    PanelsRenderHook::BODY_START,
    fn (): string => Blade::render('@livewire("announcement-banner")'),
);

// Scoped to specific pages
FilamentView::registerRenderHook(
    PanelsRenderHook::PAGE_START,
    fn (): View => view('warning-banner'),
    scopes: EditUser::class,
);
```

### Config-Driven Class Resolution
**Why?** Global behavior swap via config. One value to replace an implementation.

```php
// config/feature.php
'cache_profile' => \App\Cache\AggressiveCacheProfile::class,

// Service provider binds config to interface
$this->app->bind(CacheProfile::class, config('feature.cache_profile'));
```

### Built-in Factories with Custom Escape Hatch
**Why?** Named constructors for common cases. Raw interface for everything else.

```php
AllowedFilter::exact('status')
AllowedFilter::partial('name')
AllowedFilter::scope('published')
AllowedFilter::custom('search', new FullTextSearchFilter()) // escape hatch
```

### Domain Events at Lifecycle Boundaries
**Why?** Loosest coupling. The package fires events. It doesn't know or care who's listening.

```php
RoleAttachedEvent::dispatch($model, $rolesOrIds);
PermissionDetachedEvent::dispatch($model, $permissionsOrIds);
FeatureResolved::dispatch($feature, $scope, $value);
```

### Static Callback Customization
**Why?** Simple, focused customization points. Called from `AppServiceProvider::boot()`.

```php
Sanctum::getAccessTokenFromRequestUsing(fn ($request) =>
    $request->cookie('api_token')
);

Cashier::formatCurrencyUsing(fn ($amount, $currency) =>
    '$' . number_format($amount / 100, 2)
);

Horizon::auth(fn ($request) => $request->user()->isAdmin());
```

### The use{Model}() Pattern
**Why?** Let consumers swap internal model classes without config.

```php
Cashier::useCustomerModel(Team::class);
Cashier::useSubscriptionModel(TeamSubscription::class);
Sanctum::usePersonalAccessTokenModel(CustomToken::class);
```

### Package Auto-Discovery
**Why?** Zero-ceremony installation. `composer require` and it works.

```json
{
    "extra": {
        "laravel": {
            "providers": ["Vendor\\Package\\PackageServiceProvider"],
            "aliases": {"Package": "Vendor\\Package\\Facades\\Package"}
        }
    }
}
```
