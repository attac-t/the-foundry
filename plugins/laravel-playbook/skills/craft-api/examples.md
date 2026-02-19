# API: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Trait-Based Entry Point (Spatie)
**Why?** Integrate where developers already work -- on the model.

```php
$model->addMedia($file)           // returns FileAdder
    ->usingName('avatar')          // returns FileAdder
    ->withCustomProperties([...])  // returns FileAdder
    ->toMediaCollection('photos'); // TERMINAL -- returns Media
```

### Static Factory Entry Point (Spatie)
**Why?** One obvious starting point. No constructor, no container lookup.

```php
QueryBuilder::for(User::class)    // factory -- returns QueryBuilder
    ->allowedFilters([...])        // returns QueryBuilder
    ->allowedSorts([...])          // returns QueryBuilder
    ->allowedIncludes([...])       // returns QueryBuilder
    ->get();                       // TERMINAL -- Eloquent result
```

### ::make() Schema Builder (Filament)
**Why?** Declarative component construction. Resolves through the container for global overrides.

```php
TextInput::make('name')
    ->required()
    ->maxLength(255)
    ->live(onBlur: true)
    ->afterStateUpdated(fn (Set $set, ?string $state) =>
        $set('slug', Str::slug($state ?? ''))
    )
```

### Manager Entry Point (Taylor)
**Why?** Multi-implementation service with default driver delegation.

```php
// Facade delegates to manager's default driver
Scout::search('query')         // delegates to EngineManager->driver()->search()
Feature::active('new-ui')     // delegates to FeatureManager->driver()->active()

// Explicit driver selection
Scout::driver('meilisearch')->search('query')
```

### Helper Function Entry Point (Spatie)
**Why?** Universal utility. Used everywhere. Shortest path to action.

```php
activity()                         // returns ActivityLogger
    ->performedOn($model)          // returns ActivityLogger
    ->causedBy($user)              // returns ActivityLogger
    ->withProperties([...])        // returns ActivityLogger
    ->log('description');          // TERMINAL -- returns ?Activity
```

---

## Common Scenarios

### Named Constructors
Every common case gets its own factory. Users pick from the menu.

```php
AllowedFilter::exact('status')
AllowedFilter::partial('name')
AllowedFilter::scope('published')
AllowedFilter::callback('search', fn ($query, $value) => ...)

LogOptions::defaults()
    ->logOnly(['name', 'email'])
    ->logOnlyDirty()
    ->dontSubmitEmptyLogs()
```

### Conditionable Trait
Fluent conditional logic without breaking method chains.

```php
use Illuminate\Support\Traits\Conditionable;

class ReportBuilder
{
    use Conditionable;

    // ...
}

// Usage -- no manual if/else in the chain
$report = ReportBuilder::for($team)
    ->when($request->has('start_date'), fn ($r) => $r->from($request->start_date))
    ->when($request->has('end_date'), fn ($r) => $r->until($request->end_date))
    ->unless($user->isAdmin(), fn ($r) => $r->onlyPublic())
    ->generate();
```

### Tappable Trait
Inspection and side-effects without breaking the chain.

```php
use Illuminate\Support\Traits\Tappable;

$model->addMedia($file)
    ->usingName('avatar')
    ->tap(fn ($adder) => Log::info('Adding media', ['name' => $adder->name]))
    ->toMediaCollection('photos');
```

### Type-Rich Signatures
Accept everything reasonable. Meet developers where they are.

```php
public function hasPermissionTo(string|int|Permission|BackedEnum $permission): bool
public function addMedia(string|UploadedFile $file): FileAdder
public static function findById(int|string $id, ?string $guardName = null): self
```

### Closure-Based Configuration (Filament)
Every configuration method accepts a literal value OR a closure. Dynamic behavior without subclassing.

```php
TextInput::make('name')
    ->label(fn () => auth()->user()->isAdmin() ? 'Admin Name' : 'Name')
    ->hidden(fn (Get $get): bool => $get('role') !== 'staff')
    ->required(fn (string $operation): bool => $operation === 'create')
    ->default(fn (): string => auth()->user()->name)
```

### configureUsing() for Global Defaults (Filament)
Set defaults for all instances of a component. Individual instances override.

```php
// In a service provider's boot()
Section::configureUsing(function (Section $section): void {
    $section->columns(2);
});

TextInput::configureUsing(function (TextInput $input): void {
    $input->maxLength(255);
});
```

### Progressive Disclosure in Action

```php
// Layer 1 -- Zero-config
$user->assignRole('admin');

// Layer 2 -- Common customization
$user->assignRole('admin', 'editor');
$user->hasPermissionTo('edit articles', 'web');

// Layer 3 -- Power user
AllowedFilter::custom('search', new FullTextSearchFilter());
LogBatch::withinBatch(function () { /* ... */ });

// Layer 4 -- Framework extension
class CustomPermission extends Permission implements PermissionContract { /* ... */ }
class CustomFilter implements Filter { public function __invoke(...) { /* ... */ } }
```
