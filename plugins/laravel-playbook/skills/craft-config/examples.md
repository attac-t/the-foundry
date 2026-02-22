# Config: Examples

Patterns from the framework and production code.

---

## The Pattern

### Self-Documenting Config
**Why?** The config file IS the documentation. Block comments explain purpose and trade-offs.

```php
return [
    /*
    |--------------------------------------------------------------------------
    | Activity Logger Enabled
    |--------------------------------------------------------------------------
    |
    | When disabled, no activities will be saved to the database.
    |
    */
    'enabled' => env('ACTIVITY_LOGGER_ENABLED', true),

    'activity_model' => \Spatie\Activitylog\Models\Activity::class,
];
```

---

## Common Scenarios

### env() for Runtime Toggles Only
**Why?** Only deployment-sensitive values that change between environments.

```php
// Correct -- changes per environment
'enabled' => env('ACTIVITY_LOGGER_ENABLED', true),
'disk_name' => env('MEDIA_DISK', 'public'),

// Wrong -- structural, not environmental
'activity_model' => env('ACTIVITY_MODEL', Activity::class), // never
```

### Class References for Strategy Swapping
**Why?** Users replace implementations via config. One line to swap behavior.

```php
'activity_model' => \Spatie\Activitylog\Models\Activity::class,
'cache_profile' => \Spatie\ResponseCache\CacheProfiles\CacheAllSuccessfulGetRequests::class,
'cleanup_strategy' => \Spatie\Backup\Tasks\Cleanup\Strategies\DefaultStrategy::class,
```

### Preset-Based Configuration (Pint / Nuno Maduro)
**Why?** One word replaces 100+ granular rules. Override individual rules on top.

```json
{"preset": "laravel"}
```

```json
{"preset": "laravel", "rules": {"concat_space": {"spacing": "one"}}}
```

Pest uses the same pattern: `arch()->preset()->laravel()`.

### Closure-Based Config Values (Filament)
**Why?** Accept closures alongside literal values. Evaluated at runtime with injected context.

```php
TextInput::make('name')
    ->label('Full Name')                                                 // static
    ->label(fn () => auth()->user()->isAdmin() ? 'Admin Name' : 'Name') // closure
    ->hidden(fn (Get $get): bool => $get('role') !== 'staff')
```

### Static Global + Per-Instance Config (Caleb Porzio / Livewire)
**Why?** Global defaults via static methods. Per-component overrides via properties. No config file needed.

```php
// Global -- in AppServiceProvider::boot()
Livewire::setUpdateRoute(fn ($handle) =>
    Route::post('/custom/livewire/update', $handle)
);

// Per-component override
class SearchUsers extends Component
{
    protected $paginationTheme = 'bootstrap';
}
```

### Simple Config (Flat, Under 15 Keys)

```php
return [
    'enabled' => true,
    'table_name' => 'activity_log',
    'database_connection' => null,
    'activity_model' => Activity::class,
    'default_log_name' => 'default',
];
```

### Complex Config (Nested by Concern)

```php
return [
    'source' => [
        'files' => ['include' => [base_path()], 'exclude' => [base_path('vendor')]],
        'databases' => ['mysql'],
    ],
    'destination' => ['disks' => ['local']],
    'notifications' => ['channel' => 'mail'],
];
```

### Config Caching Footgun
**Why?** `config:cache` serializes with `var_export()`. Closures are not serializable.

```php
// WRONG -- breaks config:cache
'filter' => fn ($query) => $query->where('active', true),

// CORRECT -- use class references
'filter' => \App\Filters\ActiveFilter::class,
```

Filament's closure-based config works because those closures are passed to runtime methods, not stored in config files.

### Config Validation at Boot
**Why?** Validate configured classes implement expected interfaces. Fail early.

```php
public function packageBooted(): void
{
    $model = config('workflow.model');

    if (! is_a($model, WorkflowContract::class, true)) {
        throw new InvalidArgumentException(
            "Config [workflow.model] must implement WorkflowContract. Got: {$model}"
        );
    }
}
```
