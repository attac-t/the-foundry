# API: Examples

Patterns from the framework and production code.

---

## The Pattern

### Trait-Based Entry Point
**Why?** Integrate where developers already work -- on the model.

```php
$model->addMedia($file)
    ->usingName('avatar')
    ->withCustomProperties([...])
    ->toMediaCollection('photos'); // terminal
```

### Static Factory Entry Point
**Why?** One obvious starting point. No constructor, no container lookup.

```php
QueryBuilder::for(User::class)
    ->allowedFilters([...])
    ->allowedSorts([...])
    ->allowedIncludes([...])
    ->get(); // terminal
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
Scout::search('query')          // delegates to EngineManager->driver()->search()
Feature::active('new-ui')      // delegates to FeatureManager->driver()->active()

Scout::driver('meilisearch')->search('query') // explicit driver
```

### Helper Function Entry Point
**Why?** Universal utility. Shortest path to action.

```php
activity()
    ->performedOn($model)
    ->causedBy($user)
    ->withProperties([...])
    ->log('description'); // terminal
```

---

## Common Scenarios

### Named Constructors
**Why?** Every common case gets its own factory. Users pick from the menu.

```php
AllowedFilter::exact('status')
AllowedFilter::partial('name')
AllowedFilter::scope('published')
AllowedFilter::callback('search', fn ($query, $value) => ...)

LogOptions::defaults()
    ->logOnly(['name', 'email'])
    ->logOnlyDirty()
```

### Conditionable Trait
**Why?** Fluent conditional logic without breaking method chains.

```php
$report = ReportBuilder::for($team)
    ->when($request->has('start_date'), fn ($r) => $r->from($request->start_date))
    ->unless($user->isAdmin(), fn ($r) => $r->onlyPublic())
    ->generate();
```

Any class using `Conditionable` gets `when()` and `unless()` for free.

### Tappable Trait
**Why?** Inspection and side-effects without breaking the chain.

```php
$model->addMedia($file)
    ->usingName('avatar')
    ->tap(fn ($adder) => Log::info('Adding media', ['name' => $adder->name]))
    ->toMediaCollection('photos');
```

### Type-Rich Signatures
**Why?** Accept everything reasonable. Meet developers where they are.

```php
public function hasPermissionTo(string|int|Permission|BackedEnum $permission): bool
public function addMedia(string|UploadedFile $file): FileAdder
public static function findById(int|string $id, ?string $guardName = null): self
```

### Closure-Based Configuration (Filament)
**Why?** Every config method accepts a literal value OR a closure. Dynamic behavior without subclassing.

```php
TextInput::make('name')
    ->label(fn () => auth()->user()->isAdmin() ? 'Admin Name' : 'Name')
    ->hidden(fn (Get $get): bool => $get('role') !== 'staff')
    ->required(fn (string $operation): bool => $operation === 'create')
```

### configureUsing() for Global Defaults (Filament)
**Why?** Set defaults for all instances of a component. Individual instances override.

```php
Section::configureUsing(function (Section $section): void {
    $section->columns(2);
});
```

### Named Middleware Parameters (Tim MacDonald)
**Why?** Middleware arguments as named parameters. Type-safe, IDE-friendly, skip optional params.

```php
// String API (positional, fragile)
Route::middleware('throttle:120,1');

// Named parameter API (explicit, skippable)
Route::middleware(ThrottleRequests::with(maxAttempts: 120));

// Variadic via ::in()
Route::middleware(EnsureState::in([PostState::DRAFT, PostState::UNDER_REVIEW]));
```

This pattern was adopted into Laravel's first-party middleware. The package proved the API, the framework absorbed it.

### Progressive Disclosure in Action (Jess Archer -- Laravel Prompts)
**Why?** Four layers of complexity. Each function starts simple. Named arguments unlock power.

```php
// Layer 1 -- One-liner (80%)
$name = text('What is your name?');

// Layer 2 -- Validation and hints (15%)
$email = text(
    label: 'Email address',
    placeholder: 'taylor@example.com',
    required: true,
    validate: ['email' => 'email:rfc'],
);

// Layer 3 -- Dynamic search with closure (4%)
$userId = search(
    label: 'Find a user',
    options: fn (string $value) => strlen($value) > 0
        ? User::whereLike('name', "%{$value}%")->pluck('name', 'id')->all()
        : [],
);

// Layer 4 -- Composable form (1%)
$responses = form()
    ->text('Name', required: true, name: 'name')
    ->password('Password', validate: ['password' => 'min:8'], name: 'password')
    ->confirm('Accept terms?')
    ->submit();
```

### Progressive Disclosure in Action (Permission)

```php
// Layer 1 -- Zero-config
$user->assignRole('admin');

// Layer 2 -- Common customization
$user->hasPermissionTo('edit articles', 'web');

// Layer 3 -- Power user
AllowedFilter::custom('search', new FullTextSearchFilter());

// Layer 4 -- Framework extension
class CustomPermission extends Permission implements PermissionContract { /* ... */ }
```
