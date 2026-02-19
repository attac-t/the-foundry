# Config: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Self-Documenting Config (Spatie)
**Why?** The config file IS the documentation. Multi-line comments explain purpose, defaults, and trade-offs.

```php
return [

    /*
    |--------------------------------------------------------------------------
    | Activity Logger Enabled
    |--------------------------------------------------------------------------
    |
    | When disabled, no activities will be saved to the database. This is
    | useful for testing environments or when you need to temporarily
    | pause logging during bulk operations.
    |
    */

    'enabled' => env('ACTIVITY_LOGGER_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Activity Model
    |--------------------------------------------------------------------------
    |
    | The model used to store activity log entries. You may replace this
    | with your own model as long as it implements the Activity contract
    | and extends Eloquent's Model class.
    |
    */

    'activity_model' => \Spatie\Activitylog\Models\Activity::class,
];
```

---

## Common Scenarios

### env() for Runtime Toggles Only
Deployment-sensitive values that change between environments.

```php
// Correct -- these change per environment
'enabled' => env('ACTIVITY_LOGGER_ENABLED', true),
'cache_store' => env('RESPONSE_CACHE_DRIVER', 'file'),
'disk_name' => env('MEDIA_DISK', 'public'),
'queue_connection' => env('FEATURE_QUEUE', 'default'),

// Wrong -- these are structural, not environmental
'activity_model' => env('ACTIVITY_MODEL', Activity::class),  // Never
'table_name' => env('ACTIVITY_TABLE'),                         // Never
```

### Class References for Strategy Swapping
Users replace implementations via config. One line to swap behavior.

```php
'activity_model' => \Spatie\Activitylog\Models\Activity::class,
'cache_profile' => \Spatie\ResponseCache\CacheProfiles\CacheAllSuccessfulGetRequests::class,
'cleanup_strategy' => \Spatie\Backup\Tasks\Cleanup\Strategies\DefaultStrategy::class,
'width_calculator' => \Spatie\MediaLibrary\ResponsiveImages\WidthCalculator\FileSizeOptimizedWidthCalculator::class,
```

### Preset-Based Configuration (Pint / Nuno Maduro)
One word replaces 100+ granular rules. Override individual rules on top.

```json
{
    "preset": "laravel"
}
```

```json
{
    "preset": "laravel",
    "rules": {
        "concat_space": {
            "spacing": "one"
        }
    }
}
```

Available presets: `laravel`, `per`, `psr12`, `symfony`, `empty`. The default is `laravel` when no config file exists.

Pest uses the same pattern for architecture testing:

```php
arch()->preset()->strict();
arch()->preset()->laravel();
arch()->preset()->security();
```

### Closure-Based Config Values (Filament)
Accept closures alongside literal values. Evaluated at runtime with injected context.

```php
TextInput::make('name')
    ->label('Full Name')                    // static value
    ->label(fn () => auth()->user()->isAdmin() ? 'Admin Name' : 'Name')  // closure

Toggle::make('is_admin')
    ->hidden(fn (Get $get): bool => $get('role') !== 'staff')

TextInput::make('company')
    ->required(fn (string $operation): bool => $operation === 'create')
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
        'files' => [
            'include' => [base_path()],
            'exclude' => [base_path('vendor'), base_path('node_modules')],
        ],
        'databases' => ['mysql'],
    ],
    'destination' => [
        'disks' => ['local'],
        'filename_prefix' => '',
    ],
    'notifications' => [
        'channel' => 'mail',
        'notifiable' => \Spatie\Backup\Notifications\Notifiable::class,
    ],
];
```

### Table and Model Customization

```php
'models' => [
    'permission' => \Spatie\Permission\Models\Permission::class,
    'role' => \Spatie\Permission\Models\Role::class,
],

'table_names' => [
    'roles' => 'roles',
    'permissions' => 'permissions',
    'model_has_permissions' => 'model_has_permissions',
    'model_has_roles' => 'model_has_roles',
    'role_has_permissions' => 'role_has_permissions',
],
```
