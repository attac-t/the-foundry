# Generator: Examples

Patterns from first-party Laravel packages and the Filament ecosystem.

---

## The Pattern

### Pennant's Feature Generator
**Why?** Extends `GeneratorCommand` with stub customization fallback.
```php
#[AsCommand(name: 'pennant:feature')]
class FeatureMakeCommand extends GeneratorCommand
{
    protected $name = 'pennant:feature';
    protected $description = 'Create a new feature class';
    protected $type = 'Feature';

    protected function getStub()
    {
        return file_exists($customPath = $this->laravel->basePath('stubs/feature.stub'))
            ? $customPath
            : __DIR__.'/../../stubs/feature.stub';
    }
}
```

### Horizon's Install Command
**Why?** One command publishes everything the user needs.
```php
#[AsCommand(name: 'horizon:install')]
class InstallCommand extends Command
{
    public function handle(): void
    {
        $this->comment('Publishing Horizon Service Provider...');
        $this->callSilent('vendor:publish', [
            '--tag' => 'horizon-provider',
        ]);

        $this->comment('Publishing Horizon Assets...');
        $this->callSilent('vendor:publish', [
            '--tag' => 'horizon-assets',
        ]);

        $this->comment('Publishing Horizon Configuration...');
        $this->callSilent('vendor:publish', [
            '--tag' => 'horizon-config',
        ]);

        $this->info('Horizon installed successfully.');
    }
}
```

---

## Common Scenarios

### Namespaced Publish Tags
```php
// In your service provider's boot method
$this->publishes([
    __DIR__.'/../config/scout.php' => config_path('scout.php'),
], 'scout-config');

$this->publishesMigrations([
    __DIR__.'/../database/migrations' => database_path('migrations'),
], 'scout-migrations');

$this->publishes([
    __DIR__.'/../resources/views' => resource_path('views/vendor/scout'),
], 'scout-views');
```

### Published Application Provider (Horizon Pattern)
```php
// stubs/HorizonServiceProvider.stub -> app/Providers/HorizonServiceProvider.php
$this->publishes([
    __DIR__.'/../stubs/HorizonServiceProvider.stub' =>
        app_path('Providers/HorizonServiceProvider.php'),
], 'horizon-provider');
```
The package provides infrastructure. The published provider provides customization. Users configure authorization, notifications, and runtime behavior in their own provider.

### Filament Plugin Install
```php
class BlogPlugin implements Plugin
{
    public function register(Panel $panel): void
    {
        $panel->resources([
            PostResource::class,
            CategoryResource::class,
        ]);
    }
}

// Registration is declarative, not imperative
$panel->plugin(BlogPlugin::make());
```
Filament plugins register resources, pages, and widgets through the Panel builder. No manual wiring. The plugin's `register()` method is the install command.

### Migration Stubs With Package Tools
```php
// In configurePackage()
$package
    ->name('laravel-permission')
    ->hasMigration('create_permission_tables')
    ->hasConfigFile('permission');
```
Spatie's `laravel-package-tools` handles timestamp injection during publish. Stubs live in `database/migrations/` as `.php.stub` files. The developer runs `vendor:publish --tag=permission-migrations` and controls timing.

### Command Naming Conventions
```php
// Package-specific commands: {package}:{action}
'scout:import'
'scout:flush'
'horizon:install'
'horizon:snapshot'
'pennant:feature'
'pennant:purge'
'cashier:webhook'

// Generator commands: make:{thing} or {package}:{thing}
'pennant:feature'   // Generates a Feature class
'make:form-field'   // Filament generator
```
Use `{package}:{action}` for operations. Use `make:{thing}` only when generating code the user will own and modify.
