# Extension Point: Examples

Patterns from the framework and production packages.

---

## Manager/Driver Pattern (Taylor)

### The Base Pattern
**Why?** Taylor's signature mechanism for multi-implementation services. `extend()` lets consumers register custom drivers without touching core code.

```php
use Illuminate\Support\Manager;

class NotificationManager extends Manager
{
    public function createMailDriver(): MailChannel
    {
        return new MailChannel($this->container->make(Mailer::class));
    }

    public function createSlackDriver(): SlackChannel
    {
        return new SlackChannel(
            $this->container->make(HttpClient::class),
            config('services.slack.webhook_url'),
        );
    }

    public function createDatabaseDriver(): DatabaseChannel
    {
        return new DatabaseChannel();
    }

    public function getDefaultDriver(): string
    {
        return config('notifications.default', 'mail');
    }
}
```

### Consumer Extension
**Why?** One call in a service provider. The custom driver participates in the system like any built-in.

```php
// In AppServiceProvider::boot()
$this->app->make(NotificationManager::class)
    ->extend('teams', function ($app) {
        return new TeamsChannel(
            $app['config']['services.teams.webhook_url']
        );
    });
```

### Domain-Specific Aliases
**Why?** Scout aliases `driver()` as `engine()` for domain clarity. Same method, domain-specific language.

```php
class SearchManager extends Manager
{
    // Domain alias
    public function engine(?string $name = null)
    {
        return $this->driver($name);
    }

    public function createAlgoliaDriver(): AlgoliaEngine { /* ... */ }
    public function createMeilisearchDriver(): MeilisearchEngine { /* ... */ }
    public function createDatabaseDriver(): DatabaseEngine { /* ... */ }

    public function getDefaultDriver(): string
    {
        return config('scout.driver', 'database');
    }
}
```

---

## Render Hooks (Filament)

### Registration
**Why?** Named injection points for plugins to insert UI without modifying templates. Typed enums prevent typos.

```php
use Filament\Support\Facades\FilamentView;
use Filament\View\PanelsRenderHook;

// Global hook -- renders on every page
FilamentView::registerRenderHook(
    PanelsRenderHook::BODY_START,
    fn (): string => Blade::render('@livewire("announcement-banner")'),
);

// Scoped hook -- renders only on specific pages
FilamentView::registerRenderHook(
    PanelsRenderHook::PAGE_START,
    fn (): View => view('warning-banner'),
    scopes: EditUser::class,
);
```

### Key Hook Locations

```
PanelsRenderHook::SIDEBAR_NAV_START
PanelsRenderHook::SIDEBAR_NAV_END
PanelsRenderHook::TOPBAR_START
PanelsRenderHook::TOPBAR_END
PanelsRenderHook::CONTENT_BEFORE
PanelsRenderHook::CONTENT_AFTER
PanelsRenderHook::PAGE_START
PanelsRenderHook::PAGE_END
TablesRenderHook::TOOLBAR_START
TablesRenderHook::TOOLBAR_END
```

---

## Macroable Registration (Taylor)

### Single Method Registration
**Why?** Runtime extension of any Macroable class. The package ships the hook, consumers add methods.

```php
// Add a method to Collection
Collection::macro('toUpper', function () {
    return $this->map(fn ($value) => strtoupper($value));
});

// Add a method to Request
Request::macro('isApiRequest', function () {
    return $this->is('api/*');
});

// Add a route macro
Route::macro('role', function ($roles) {
    return $this->middleware("role:{$roles}");
});
```

### Bulk Registration via Mixin
**Why?** Register multiple macros from a single class. The double-closure pattern binds to the target instance.

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

---

## Adapter Pattern (League)

### Interface as Extension Point
**Why?** Framework-agnostic core. Implement the interface, pass it to the core, done. No registration ceremony.

```php
// Core defines the interface
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    public function delete(string $path): void;
    // ... 14 more methods
}

// Custom adapter implements it
class DropboxAdapter implements FilesystemAdapter
{
    public function __construct(private DropboxClient $client) {}

    public function write(string $path, string $contents, Config $config): void
    {
        $this->client->upload($path, $contents);
    }

    public function read(string $path): string
    {
        return $this->client->download($path);
    }

    // ... remaining methods
}

// Usage -- no registration needed
$filesystem = new Filesystem(new DropboxAdapter($client));
```

### Laravel Bridge for Adapters
**Why?** Config-driven adapter selection. The bridge maps config to adapters.

```php
// In a service provider
Storage::extend('dropbox', function ($app, $config) {
    $adapter = new DropboxAdapter(new DropboxClient($config['token']));

    return new FilesystemAdapter(
        new Filesystem($adapter, $config),
        $adapter,
        $config
    );
});
```

---

## Strategy Pattern + Config Binding

### Config-Driven Class Resolution
**Why?** Global behavior swap via config. Users change one value to replace an implementation.

```php
// config/feature.php
'cache_profile' => \App\Cache\AggressiveCacheProfile::class,
'cleanup_strategy' => \App\Backup\CustomCleanupStrategy::class,

// Service provider binds config to interface
$this->app->bind(CacheProfile::class, config('feature.cache_profile'));
$this->app->bind(CleanupStrategy::class, config('feature.cleanup_strategy'));
```

### Built-in Factories with Custom Escape Hatch
**Why?** Named constructors for common cases. Raw interface for everything else.

```php
// Built-in strategies via named constructors
AllowedFilter::exact('status')
AllowedFilter::partial('name')
AllowedFilter::scope('published')

// Custom strategy via interface
AllowedFilter::custom('search', new FullTextSearchFilter())
// FullTextSearchFilter implements Filter
```

---

## Events

### Domain Events at Lifecycle Boundaries
**Why?** Loosest coupling. The package fires events. It doesn't know or care who's listening.

```php
// Package dispatches events at key moments
RoleAttachedEvent::dispatch($model, $rolesOrIds);
PermissionDetachedEvent::dispatch($model, $permissionsOrIds);
TranslationHasBeenSetEvent::dispatch($model, $key, $locale, $oldValue, $newValue);
FeatureResolved::dispatch($feature, $scope, $value);
WebhookReceived::dispatch($payload);
```

---

## Static Callback Customization (Taylor)

### God Class Callbacks
**Why?** Simple, focused customization points. Called from `AppServiceProvider::boot()`.

```php
// Customize token retrieval
Sanctum::getAccessTokenFromRequestUsing(function ($request) {
    return $request->cookie('api_token');
});

// Customize currency formatting
Cashier::formatCurrencyUsing(function ($amount, $currency) {
    return '$' . number_format($amount / 100, 2);
});

// Customize authorization
Horizon::auth(function ($request) {
    return $request->user()->isAdmin();
});
```

---

## The use{Model}() Pattern (Taylor)

### Model Class Customization
**Why?** Let consumers swap internal model classes without config. Static setters on the god class.

```php
// In AppServiceProvider::boot()
Cashier::useCustomerModel(Team::class);
Cashier::useSubscriptionModel(TeamSubscription::class);
Sanctum::usePersonalAccessTokenModel(CustomToken::class);

// The package references the static property
$model = static::$customerModel;
```
