# The Playbook: Examples

Origin stories and philosophy from across the Laravel ecosystem.

---

## Origin Stories

### Taylor — Cashier From Forge Billing
**Why?** Real billing needs drove the package.
```php
// Cashier exists because Forge needed Stripe billing.
// The static configuration class is Taylor's signature:
Cashier::useCustomerModel(Team::class);
Cashier::useSubscriptionModel(TeamSubscription::class);
Cashier::calculateTaxes();

// One class configures the entire package.
// Born from production, refined into a package.
```

### Nuno — Beauty as Product
**Why?** CLI output should feel good.
```php
// Pest won because test output is beautiful.
// The entire API is global functions — dead simple:
test('user can login', function () {
    expect(true)->toBeTrue();
});

// Architecture testing in one word:
arch()->preset()->laravel();

// 40+ rules activated by a single preset.
// Beauty is not vanity. It is adoption strategy.
```

### Spatie — Client Projects to Open Source
**Why?** Packages born from real work.
```php
// Permission started in a client project.
// The trait integrates where developers already think:
class User extends Model
{
    use HasRoles;
}

$user->assignRole('admin');
// Reads like English. Zero new mental models.
```

### Filament — Platform Thinking
**Why?** The admin panel is one consumer, not the product.
```php
// Filament is not "an admin panel."
// It is a UI component platform.
// Forms, tables, and actions work independently:
TextInput::make('name')
    ->required()
    ->maxLength(255)

// Every config method accepts a value OR a closure.
// This is the killer pattern:
TextInput::make('name')
    ->label(fn () => auth()->user()->isAdmin() ? 'Admin Name' : 'Name')
```

### League — The Interface Is the Package
**Why?** Framework-agnostic by design.
```php
// Flysystem defines interfaces. Adapters implement them.
// Laravel wraps them. Symfony wraps them. Anyone wraps them.
interface FilesystemAdapter
{
    public function write(string $path, string $contents, Config $config): void;
    public function read(string $path): string;
    // ...
}

// The core solves the hard problem.
// The bridge adds ergonomics.
```

---

## Different DX Philosophies

### Taylor: Static Configuration + Trait Integration
```php
// God class pattern — static properties with use{Model}() setters
Sanctum::usePersonalAccessTokenModel(CustomToken::class);
Horizon::auth(fn ($request) => $request->user()->isAdmin());

// Traits as integration
class User extends Model
{
    use Searchable, Billable, HasApiTokens;
}
```

### Spatie: Config-Driven + Package Tools
```php
// Declarative service provider
$package
    ->name('laravel-permission')
    ->hasConfigFile()
    ->hasMigration('create_permission_tables')
    ->hasCommands([CacheResetCommand::class]);

// Config-driven model swapping
'models' => ['role' => App\Models\CustomRole::class]
```

### Nuno: Global Functions + Presets
```php
// Function-based API (not class-based)
test('something works', fn () => expect(true)->toBeTrue());

// Preset-based configuration
// pint.json: {"preset": "laravel"}
// One word replaces 100+ rules.
```

### Filament: Declarative Schema + Closure Customization
```php
// Schema builder for UI
$form->schema([
    TextInput::make('title')->required(),
    Select::make('status')->options([...]),
]);

// Every method accepts value OR closure
TextInput::make('company')
    ->required(fn (string $operation): bool => $operation === 'create')
```

Each approach serves its audience. Taylor optimizes for the framework author. Spatie optimizes for the package consumer. Nuno optimizes for the developer's joy. Filament optimizes for the admin builder. Know your audience.
