# Provider: Examples

Patterns from the framework and production code.

---

## Approach A: Spatie Package Tools (Recommended)

### Declarative Core
**Why?** Eliminates boilerplate. One method declares the entire package surface.

```php
class WorkflowServiceProvider extends PackageServiceProvider
{
    public function configurePackage(Package $package): void
    {
        $package->name('laravel-workflow')->hasConfigFile()
            ->hasMigration('create_workflows_table')
            ->hasMigration('create_workflow_steps_table')
            ->hasCommands([PruneCompletedWorkflows::class]);
    }

    public function packageRegistered(): void
    {
        $this->app->singleton(WorkflowRegistrar::class);
        $this->app->scoped(WorkflowContext::class);
        $this->app->bind(WorkflowContract::class, fn ($app) => $app->make(config('workflow.model', Workflow::class)));
        $this->app->bind(WorkflowEngine::class, config('workflow.engine'));
    }

    public function packageBooted(): void
    {
        Workflow::observe(config('workflow.observer'));
        Event::listen(WorkflowCompleted::class, SyncCacheListener::class);
        Gate::define('manage-workflows', fn ($user) => $user->hasRole('admin'));
    }
}
```

### Lifecycle Hooks
**Why?** `packageRegistered()` for bindings. `packageBooted()` for side effects. Never mix them.

```php
// packageRegistered() — Container bindings only
$this->app->singleton(PermissionRegistrar::class);
$this->app->scoped(CauserResolver::class);
$this->app->bind(CacheProfile::class, config('responsecache.cache_profile'));

// packageBooted() — Side effects: events, observers, macros, gates
Feature::observe(FeatureObserver::class);
Route::macro('role', fn ($roles) => $this->middleware("role:{$roles}"));
Blade::if('feature', fn ($feature) => Feature::active($feature));
```

---

## Approach B: Raw ServiceProvider (Taylor's First-Party Style)

### Private Method Decomposition
**Why?** Full control, zero dependencies. Each concern gets its own private method. (Cashier, Scout, Sanctum)

```php
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
        // ... registerPublishing(), registerCommands()
    }

    private function configure(): void { $this->mergeConfigFrom(__DIR__.'/../config/catalog.php', 'catalog'); }

    private function registerManager(): void
    {
        $this->app->singleton(CatalogManager::class, fn ($app) => new CatalogManager($app));
        $this->app->alias(CatalogManager::class, 'catalog');
    }

    private function registerBindings(): void
    {
        $this->app->bind(CatalogContract::class, fn ($app) => $app->make(config('catalog.model', Catalog::class)));
    }

    private function registerRoutes(): void
    {
        if (Catalog::$registersRoutes) {
            Route::group(
                ['prefix' => config('catalog.path', 'catalog'), 'middleware' => config('catalog.middleware', 'web')],
                fn () => $this->loadRoutesFrom(__DIR__.'/../routes/web.php')
            );
        }
    }

    // registerResources(), registerPublishing(), registerCommands() — same pattern
}
```

### Deferred Registration with callAfterResolving
**Why?** Register only when dependencies are resolved. Avoids boot-order issues. (Pennant, Horizon)

```php
$this->callAfterResolving('blade.compiler', function ($blade) {
    $blade->if('feature', fn ($feature) => Feature::active($feature));
});

$this->callAfterResolving(QueueManager::class, function ($manager) {
    $manager->addConnector('custom', fn () => new CustomConnector($this->app['config']));
});
```

### The ignoreRoutes() Pattern
**Why?** Let consumers opt out of package-registered routes. (Cashier, Sanctum)

```php
class Catalog
{
    public static bool $registersRoutes = true;

    public static function ignoreRoutes(): static { static::$registersRoutes = false; return new static; }
}

// Consumer: Catalog::ignoreRoutes() in AppServiceProvider::register()
```

---

## Approach C: Filament PanelProvider

### Distributing a Complete Panel
**Why?** For platform packages that ship an entire admin panel. (Filament ecosystem)

```php
class BlogPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->id('blog')->path('blog')
            ->resources([PostResource::class, CategoryResource::class])
            ->pages([BlogSettings::class])
            ->widgets([BlogStatsWidget::class])
            ->middleware([EncryptCookies::class, AddQueuedCookiesToResponse::class])
            ->authMiddleware([Authenticate::class]);
    }
}
```

---

## Common Scenarios

### Conditional Environment Registration (Barry vd. Heuvel Pattern)
**Why?** Dev-only packages must not break production. `class_exists()` guards against missing `--dev` deps.

```php
if ($this->app->isLocal()) {
    if (class_exists(\Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider::class)) {
        $this->app->register(\Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider::class);
    }
    // ... same for Debugbar, Telescope, etc.
}
```

### Manager Registration
**Why?** Singleton manager, alias for facade access.

```php
$this->app->singleton(NotificationManager::class, fn ($app) => new NotificationManager($app));
$this->app->alias(NotificationManager::class, 'notifications');
```

### Config-Driven Binding
**Why?** Implementation lives in config. Users swap by editing one line.

```php
$this->app->bind(InvoiceRenderer::class, fn ($app) => $app->make(config('cashier.invoices.renderer', DompdfInvoiceRenderer::class)));
$this->app->bind(CleanupStrategy::class, config('backup.cleanup.strategy'));
```

### Deferred Service Provider
**Why?** Only boot when the binding is resolved. Free performance.

```php
class ReportingServiceProvider extends ServiceProvider implements DeferrableProvider
{
    public function register(): void
    {
        $this->app->singleton(ReportEngine::class, fn ($app) => new ReportEngine(
            config('reporting.driver'), $app->make(CacheManager::class),
        ));
    }

    public function provides(): array { return [ReportEngine::class]; }
}
```

### Octane Compatibility
**Why?** Reset state on request boundaries. Or better: use `scoped()` instead of `singleton()`.

```php
// Manual reset for existing singletons
$this->app['events']->listen(
    [RequestReceived::class, TaskReceived::class],
    fn () => $this->app[FeatureManager::class]->flushCache()
);

// Preferred: scoped() auto-resets per request
$this->app->scoped(RequestContext::class, fn ($app) => new RequestContext($app['request']));
```
