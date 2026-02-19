# Provider: Examples

Patterns from the framework and production packages.

---

## Approach A: Spatie Package Tools (Recommended)

### Declarative Core
**Why?** Eliminates boilerplate. One method declares the entire package surface.

```php
use Spatie\LaravelPackageTools\Package;
use Spatie\LaravelPackageTools\PackageServiceProvider;

class WorkflowServiceProvider extends PackageServiceProvider
{
    public function configurePackage(Package $package): void
    {
        $package
            ->name('laravel-workflow')
            ->hasConfigFile()
            ->hasMigration('create_workflows_table')
            ->hasMigration('create_workflow_steps_table')
            ->hasCommands([
                PruneCompletedWorkflows::class,
            ]);
    }

    public function packageRegistered(): void
    {
        $this->app->singleton(WorkflowRegistrar::class);
        $this->app->scoped(WorkflowContext::class);

        $this->app->bind(
            WorkflowContract::class,
            fn ($app) => $app->make(config('workflow.model', Workflow::class))
        );

        $this->app->bind(
            WorkflowEngine::class,
            config('workflow.engine')
        );
    }

    public function packageBooted(): void
    {
        Workflow::observe(config('workflow.observer'));

        Event::listen(WorkflowCompleted::class, SyncCacheListener::class);

        Gate::define('manage-workflows', function ($user) {
            return $user->hasRole('admin');
        });
    }
}
```

### Lifecycle Hooks
**Why?** `packageRegistered()` for bindings. `packageBooted()` for side effects. Never mix them.

```php
// packageRegistered() — Container bindings only
public function packageRegistered(): void
{
    $this->app->singleton(PermissionRegistrar::class);

    $this->app->scoped(CauserResolver::class);

    $this->app->bind(
        CacheProfile::class,
        config('responsecache.cache_profile')
    );
}

// packageBooted() — Side effects: events, observers, macros, gates
public function packageBooted(): void
{
    Feature::observe(FeatureObserver::class);

    Route::macro('role', function ($roles) {
        return $this->middleware("role:{$roles}");
    });

    Blade::if('feature', function ($feature) {
        return Feature::active($feature);
    });
}
```

---

## Approach B: Raw ServiceProvider (Taylor's First-Party Style)

### Private Method Decomposition
**Why?** Full control, zero dependencies. Each concern gets its own private method. (Cashier, Scout, Sanctum)

```php
use Illuminate\Support\ServiceProvider;

class CatalogServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->configure();
        $this->registerManager();
        $this->registerBindings();
    }

    public function boot(): void
    {
        $this->registerRoutes();
        $this->registerResources();
        $this->registerPublishing();
        $this->registerCommands();
    }

    private function configure(): void
    {
        $this->mergeConfigFrom(__DIR__.'/../config/catalog.php', 'catalog');
    }

    private function registerManager(): void
    {
        $this->app->singleton(CatalogManager::class, function ($app) {
            return new CatalogManager($app);
        });

        $this->app->alias(CatalogManager::class, 'catalog');
    }

    private function registerBindings(): void
    {
        $this->app->bind(
            CatalogContract::class,
            fn ($app) => $app->make(config('catalog.model', Catalog::class))
        );
    }

    private function registerRoutes(): void
    {
        if (Catalog::$registersRoutes) {
            Route::group([
                'prefix' => config('catalog.path', 'catalog'),
                'namespace' => 'Vendor\Catalog\Http\Controllers',
                'middleware' => config('catalog.middleware', 'web'),
            ], function () {
                $this->loadRoutesFrom(__DIR__.'/../routes/web.php');
            });
        }
    }

    private function registerResources(): void
    {
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'catalog');
        $this->loadMigrationsFrom(__DIR__.'/../database/migrations');
    }

    private function registerPublishing(): void
    {
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__.'/../config/catalog.php' => config_path('catalog.php'),
            ], 'catalog-config');

            $this->publishes([
                __DIR__.'/../resources/views' => resource_path('views/vendor/catalog'),
            ], 'catalog-views');
        }
    }

    private function registerCommands(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                SyncCatalogCommand::class,
                PruneCatalogCommand::class,
            ]);
        }
    }
}
```

### Deferred Registration with callAfterResolving
**Why?** Register services only when their dependencies are resolved. Avoids boot-order issues. (Pennant, Horizon)

```php
public function boot(): void
{
    // Register Blade directive only when Blade is resolved
    $this->callAfterResolving('blade.compiler', function ($blade) {
        $blade->if('feature', function ($feature) {
            return Feature::active($feature);
        });
    });

    // Register connector only when QueueManager is resolved
    $this->callAfterResolving(QueueManager::class, function ($manager) {
        $manager->addConnector('custom', function () {
            return new CustomConnector($this->app['config']);
        });
    });
}
```

### The ignoreRoutes() Pattern
**Why?** Let consumers opt out of package-registered routes. (Cashier, Sanctum)

```php
// In the "god class"
class Catalog
{
    public static bool $registersRoutes = true;

    public static function ignoreRoutes(): static
    {
        static::$registersRoutes = false;
        return new static;
    }
}

// In AppServiceProvider::register()
Catalog::ignoreRoutes();
```

---

## Approach C: Filament PanelProvider

### Distributing a Complete Panel
**Why?** For platform packages that ship an entire admin panel. (Filament ecosystem)

```php
use Filament\Panel;
use Filament\PanelProvider;

class BlogPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->id('blog')
            ->path('blog')
            ->resources([
                PostResource::class,
                CategoryResource::class,
            ])
            ->pages([
                BlogSettings::class,
            ])
            ->widgets([
                BlogStatsWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
```

---

## Common Scenarios

### Manager Registration
Register a Manager as a singleton. Delegate unknown calls to the default driver.

```php
public function register(): void
{
    $this->app->singleton(NotificationManager::class, function ($app) {
        return new NotificationManager($app);
    });

    // Facade accessor
    $this->app->alias(NotificationManager::class, 'notifications');
}
```

### Config-Driven Binding
The dominant pattern. Implementation class lives in config. Users swap by editing one line.

```php
$this->app->bind(
    InvoiceRenderer::class,
    fn ($app) => $app->make(config('cashier.invoices.renderer', DompdfInvoiceRenderer::class))
);

$this->app->bind(
    CleanupStrategy::class,
    config('backup.cleanup.strategy')
);
```

### Octane Compatibility
Reset state on Octane request boundaries. Required for stateful singletons.

```php
public function boot(): void
{
    $this->app['events']->listen([
        \Laravel\Octane\Events\RequestReceived::class,
        \Laravel\Octane\Events\TaskReceived::class,
    ], fn () => $this->app[FeatureManager::class]
        ->setContainer(Container::getInstance())
        ->flushCache());
}
```
