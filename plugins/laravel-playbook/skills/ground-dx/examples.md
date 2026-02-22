# The 7 DX Dimensions: Examples

Attributed examples from across the Laravel ecosystem.

---

## First-Touch

### Spatie Translatable — Zero Setup
**Why?** No config, no migrations, no publish step.
```php
class Post extends Model
{
    use HasTranslations;

    public $translatable = ['title'];
}

$post->title; // Returns current locale automatically
```

### Filament — Artisan Generator
**Why?** One command scaffolds a full CRUD resource.
```bash
php artisan make:filament-resource Post --generate
```
Generates resource, pages, form schema, and table columns from the model's database columns.

### league/csv — No Framework Needed
**Why?** `new` it and use it. No container, no config, no provider.
```php
$csv = Reader::createFromPath('/path/to/data.csv', 'r');
$csv->setHeaderOffset(0);

foreach ($csv->getRecords() as $record) {
    // Process
}
```

---

## Cognitive Load

### Taylor — Domain Language
**Why?** Method names read like English.
```php
$user->assignRole('admin');
Feature::active('new-dashboard');
Sanctum::actingAs($user, ['read', 'write']);
```

### Nuno — Functions Over Classes
**Why?** The simplest possible surface.
```php
test('user can login', function () {
    expect($response->status())->toBe(200);
});
```

### Filament — PHP as Declarative UI
**Why?** One concept: components with fluent configuration.
```php
TextInput::make('title')
    ->required()
    ->maxLength(255)
    ->live(onBlur: true)
```

---

## Error Messages

### Spatie — What's Wrong AND What's Valid
**Why?** The error message teaches the fix.
```php
// InvalidFilterQuery (HTTP 400)
"Requested filter(s) `status, type` are not allowed. Allowed filter(s) are `name, email`."

// FileIsTooBig
"File `/path/to/file.jpg` has a size of 15MB which is greater than the maximum allowed 10MB."

// GuardDoesNotMatch
"The given role or permission should use guard `web` instead of `api`."
```

### Taylor — Runtime Dependency Guards
**Why?** Helpful message when an optional dependency is missing.
```php
protected function ensureAlgoliaClientIsInstalled()
{
    if (class_exists(Algolia::class)) {
        return;
    }

    throw new Exception(
        'Please install the suggested Algolia client: algolia/algoliasearch-client-php.'
    );
}
```

---

## IDE Experience

### Barry vd. Heuvel — IDE Helper Generation
**Why?** Three commands generate complete IDE metadata. No manual PHPDoc maintenance. Run once, autocompletion everywhere.

```bash
# Generate PHPDoc for all Facades → _ide_helper.php
php artisan ide-helper:generate

# Generate PHPDoc for Eloquent models (columns, relations, scopes)
php artisan ide-helper:models --write

# Generate PhpStorm meta for container resolution
php artisan ide-helper:meta
```

The `@mixin` approach lets models inherit QueryBuilder autocompletion:

```php
/**
 * @mixin \Eloquent
 * @property int $id
 * @property string $name
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmail(string $value)
 */
class User extends Model {}
```

Package authors: ship `@mixin` and `@method` annotations so consumers get autocompletion without installing IDE Helper.

### Spatie — Generic Types on Core Classes
**Why?** Autocomplete preserves model specificity.
```php
/** @template TModel of Model */
class QueryBuilder { /* ... */ }

/** @return MorphMany<TMedia, $this> */
public function media(): MorphMany { /* ... */ }
```

### Taylor — Facade @method Annotations
**Why?** Full autocompletion through facades.
```php
/**
 * @method static PendingRequest timeout(int $seconds)
 * @method static PendingRequest withToken(string $token, string $type = 'Bearer')
 * @method static Response get(string $url, array $query = [])
 */
class Http extends Facade { /* ... */ }
```

### Nuno — PHPStan Extensions
**Why?** Type-aware expectation chains.
```php
// Larastan auto-discovers via composer.json
{
    "type": "phpstan-extension",
    "extra": {
        "phpstan": {
            "includes": ["extension.neon"]
        }
    }
}
```

### Jess Archer — Laravel Prompts as DX Philosophy
**Why?** Beautiful CLI UX from plain functions. No classes, no configuration, no Symfony console ceremony.

```php
use function Laravel\Prompts\text;
use function Laravel\Prompts\select;
use function Laravel\Prompts\confirm;

$name = text('What is your name?');
$role = select('Role?', ['Member', 'Admin', 'Owner']);
$confirmed = confirm('Proceed?');
```

Functions over classes. The simplest possible surface for the most common interaction.

---

## Migration Path

### Filament — Automated Upgrade Scripts
**Why?** The upgrade package rewrites your code.
```bash
composer require filament/upgrade
php artisan filament:upgrade
```
Handles namespace changes, method renames, and configuration restructuring automatically. This lowers the cost of major versions dramatically.

### Spatie — Additive Migrations
**Why?** Never alter, always extend.
```text
database/migrations/
  create_activity_log_table.php.stub
  add_event_column_to_activity_log_table.php.stub
  add_batch_uuid_column_to_activity_log_table.php.stub
```

### Taylor — Broad Version Constraints
**Why?** Developers have time to upgrade.
```json
{
    "illuminate/support": "^9.0|^10.0|^11.0|^12.0|^13.0"
}
```
Scout supports five major Laravel versions simultaneously.

---

## Defaults

### Taylor — Static Properties With Setters
**Why?** Defaults work. Customization is one method call.
```php
// Works out of the box with User model
// Customize when needed:
Cashier::useCustomerModel(Team::class);
```

### Nuno — Preset-Based Defaults
**Why?** One word replaces 100+ configuration options.
```json
{
    "preset": "laravel"
}
```

### Filament — configureUsing() for Global Defaults
**Why?** Set defaults for every instance of a component.
```php
Section::configureUsing(function (Section $section): void {
    $section->columns(2);
});
```
Individual instances override these defaults.

---

## Progressive Disclosure

### The Four Layers In Practice

**Layer 1 — Trait or function (80%)**
```php
use HasRoles;
$user->assignRole('admin');
```

**Layer 2 — Config or preset (15%)**
```php
// config/permission.php
'models' => ['role' => CustomRole::class]

// pint.json
{"preset": "laravel", "rules": {"concat_space": {"spacing": "one"}}}
```

**Layer 3 — Provider or plugin (4%)**
```php
// Custom bindings in packageBooted()
$this->app->bind(CacheProfile::class, CustomCacheProfile::class);

// Filament plugin registration
$panel->plugin(BlogPlugin::make()->authorResource());
```

**Layer 4 — Contract implementation (1%)**
```php
class CustomFilter implements Filter
{
    public function __invoke(Builder $query, mixed $value, string $property): Builder
    {
        return $query->whereFullText($property, $value);
    }
}

class DropboxAdapter implements FilesystemAdapter
{
    // Implement all 17 methods
}
```
