# Generator: Examples

Patterns from the framework and production code.

---

## The Pattern

### Pennant's Feature Generator
**Why?** Extends `GeneratorCommand` with stub customization fallback.

```php
#[AsCommand(name: 'pennant:feature')]
class FeatureMakeCommand extends GeneratorCommand
{
    protected $name = 'pennant:feature';
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
        $this->callSilent('vendor:publish', ['--tag' => 'horizon-provider']);
        $this->callSilent('vendor:publish', ['--tag' => 'horizon-assets']);
        $this->callSilent('vendor:publish', ['--tag' => 'horizon-config']);

        $this->info('Horizon installed successfully.');
    }
}
```

---

## Common Scenarios

### Namespaced Publish Tags

```php
$this->publishes([
    __DIR__.'/../config/scout.php' => config_path('scout.php'),
], 'scout-config');

$this->publishesMigrations([
    __DIR__.'/../database/migrations' => database_path('migrations'),
], 'scout-migrations');
```

### Published Application Provider (Horizon Pattern)
**Why?** The package provides infrastructure. The published provider provides customization.

```php
$this->publishes([
    __DIR__.'/../stubs/HorizonServiceProvider.stub' =>
        app_path('Providers/HorizonServiceProvider.php'),
], 'horizon-provider');
```

### Filament Plugin Install
**Why?** Declarative registration, not imperative wiring.

```php
class BlogPlugin implements Plugin
{
    public function register(Panel $panel): void
    {
        $panel->resources([PostResource::class, CategoryResource::class]);
    }
}

$panel->plugin(BlogPlugin::make());
```

### Migration Stubs With Package Tools

```php
$package
    ->name('laravel-permission')
    ->hasMigration('create_permission_tables')
    ->hasConfigFile('permission');
```

`laravel-package-tools` handles timestamp injection during publish. Stubs live as `.php.stub` files.

### Command Naming Conventions

```php
// Package commands: {package}:{action}
'scout:import'
'horizon:install'
'pennant:feature'
'cashier:webhook'

// Generator commands: make:{thing} or {package}:{thing}
'make:form-field'      // Filament generator
```

Use `{package}:{action}` for operations. Use `make:{thing}` only when generating code the user will own and modify.
