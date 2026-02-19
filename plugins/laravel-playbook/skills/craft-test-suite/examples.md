# Test Suite: Examples

Patterns from Spatie, Taylor, Nuno, Caleb Porzio, and production packages.

---

## The Pattern

### TestCase Anatomy (Spatie)
**Why?** Every package test suite extends Orchestra Testbench. Three methods define the entire testing environment.

```php
// tests/TestCase.php
abstract class TestCase extends Orchestra\Testbench\TestCase
{
    protected function getPackageProviders($app): array
    {
        return [PackageServiceProvider::class];
    }

    protected function getEnvironmentSetUp($app): void
    {
        config()->set('database.default', 'testing');
        config()->set('database.connections.testing', [
            'driver'   => 'sqlite',
            'database' => ':memory:',
        ]);
    }

    protected function setUpDatabase($app): void
    {
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');
    }
}
```

### Pest.php Configuration (Spatie)
**Why?** One file binds the TestCase globally, registers custom expectations, and defines shared helpers.

```php
// tests/Pest.php
uses(TestCase::class)->in(__DIR__);

expect()->extend('toBePublished', function () {
    return $this->status->toBe('published');
});

expect()->extend('toHaveExtension', function (string $extension) {
    $actual = pathinfo($this->value, PATHINFO_EXTENSION);
    expect($actual)->toBe($extension);
    return $this;
});

function createQueryFromFilterRequest(array $filters): QueryBuilder
{
    $request = new Illuminate\Http\Request(['filter' => $filters]);
    return QueryBuilder::for(TestModel::class, $request);
}
```

---

## Common Scenarios

### Domain-Organized Tests (Spatie — laravel-permission)

```
tests/
├── ArchTest.php
├── Commands/
│   ├── CreateRoleTest.php
│   └── SyncPermissionsTest.php
├── Middleware/
│   ├── RoleMiddlewareTest.php
│   └── PermissionMiddlewareTest.php
├── Models/
│   ├── RoleTest.php
│   └── PermissionTest.php
├── Traits/
│   ├── HasRolesTest.php
│   └── HasPermissionsTest.php
├── Pest.php
├── TestCase.php
└── TestSupport/
    ├── TestModels/
    └── TestHelper.php
```

### Architecture Tests — Baseline (Spatie)

```php
// tests/ArchTest.php
arch('no debugging')
    ->expect(['dd', 'dump', 'ray'])
    ->each->not->toBeUsed();
```

### Architecture Tests — Standard (Nuno)

```php
arch('strict types')
    ->expect('App')
    ->toUseStrictTypes();

arch('models extend base')
    ->expect('App\Models')
    ->toExtend('Illuminate\Database\Eloquent\Model')
    ->not->toHaveSuffix('Model');

arch('no debugging')
    ->expect(['dd', 'dump', 'ray', 'die', 'var_dump', 'sleep'])
    ->not->toBeUsed();
```

### Architecture Tests — Presets (Nuno)

```php
// One word activates dozens of architectural constraints
arch()->preset()->strict();
arch()->preset()->php();
arch()->preset()->security();
arch()->preset()->laravel();

// Custom preset
Preset::custom('ddd', function (AbstractPreset $preset) {
    // Define domain-driven design constraints
});
arch()->preset()->ddd();
```

### Higher-Order Expectations (Nuno)

```php
// Each item in a collection
expect($users)->each->toBeInstanceOf(User::class);
expect($items)->each->name->not->toBeEmpty();
expect($values)->each->toBeGreaterThan(0);

// Property drilling
expect($user)->name->toBe('Taylor');
expect($response)->json()->status->toBe('ok');

// Negation
expect($collection)->not->toBeEmpty();
expect($result)->not->toBeNull();

// Sequence for ordered assertions
expect($logs)->sequence(
    fn ($log) => $log->level->toBe('info'),
    fn ($log) => $log->level->toBe('warning'),
    fn ($log) => $log->level->toBe('error'),
);
```

### Custom Expectations (Spatie — laravel-backup)

```php
// tests/Pest.php
expect()->extend('hasItemContaining', function (string $searchString) {
    $found = $this->value->contains(fn ($item) =>
        str_contains($item, $searchString)
    );

    expect($found)->toBeTrue(
        "Failed asserting collection contains item with '{$searchString}'."
    );

    return $this;
});

// Usage
expect($backupFiles)->hasItemContaining('2024-01-15');
```

### Facade ::fake() in Tests (Taylor)

```php
it('dispatches the import job', function () {
    Bus::fake();

    post('/api/products/import', ['file' => $file]);

    Bus::assertDispatched(ImportProducts::class, fn ($job) =>
        $job->filename === 'products.csv'
    );
});

it('sends the welcome notification', function () {
    Notification::fake();

    $user = User::factory()->create();
    (new RegisterUser)->handle($user);

    Notification::assertSentTo($user, WelcomeNotification::class);
    Notification::assertCount(1);
});

it('prevents stray HTTP requests', function () {
    Http::preventStrayRequests();

    Http::fake([
        'api.stripe.com/*' => Http::response(['ok' => true]),
    ]);

    (new ChargeCustomer)->handle($order);

    Http::assertSent(fn ($request) =>
        str_contains($request->url(), 'api.stripe.com')
    );
});
```

### Livewire Component Testing (Caleb Porzio)

```php
use function Pest\Livewire\livewire;

it('creates a post', function () {
    livewire(CreatePost::class)
        ->set('title', 'My Post')
        ->set('content', 'The content')
        ->call('save')
        ->assertDispatched('post-created')
        ->assertHasNoErrors();

    expect(Post::count())->toBe(1);
});

it('validates required fields', function () {
    livewire(CreatePost::class)
        ->set('title', '')
        ->call('save')
        ->assertHasErrors(['title' => 'required']);
});

it('retrieves existing data', function () {
    $post = Post::factory()->create();

    livewire(EditPost::class, ['post' => $post])
        ->assertSet('title', $post->title)
        ->assertSet('content', $post->content);
});

it('dispatches events on save', function () {
    livewire(EditPost::class, ['post' => $post])
        ->set('title', 'Updated Title')
        ->call('save')
        ->assertDispatched('post-updated', id: $post->id);
});
```

### Filament Resource Testing (Dan Harrin)

```php
use function Pest\Livewire\livewire;

it('can list records', function () {
    $posts = Post::factory()->count(10)->create();

    livewire(PostResource\Pages\ListPosts::class)
        ->assertCanSeeTableRecords($posts);
});

it('can create a record', function () {
    $data = Post::factory()->make();

    livewire(PostResource\Pages\CreatePost::class)
        ->fillForm([
            'title' => $data->title,
            'content' => $data->content,
        ])
        ->call('create')
        ->assertHasNoFormErrors();

    $this->assertDatabaseHas(Post::class, ['title' => $data->title]);
});

it('can search records', function () {
    $posts = Post::factory()->count(5)->create();

    livewire(PostResource\Pages\ListPosts::class)
        ->searchTable($posts->first()->title)
        ->assertCanSeeTableRecords(
            $posts->where('title', $posts->first()->title)
        );
});
```

### Composer Scripts (Spatie)

```json
{
    "scripts": {
        "test": "vendor/bin/pest",
        "test-coverage": "vendor/bin/pest --coverage",
        "format": "vendor/bin/pint",
        "analyse": "vendor/bin/phpstan analyse"
    }
}
```

### Comprehensive Test Script (Nuno — Pest itself)

```json
{
    "scripts": {
        "test:lint": "pint --parallel --test",
        "test:type:check": "phpstan analyse --ansi --memory-limit=-1",
        "test:type:coverage": "php bin/pest --type-coverage --min=100",
        "test:unit": "php bin/pest --exclude-group=integration --compact",
        "test:parallel": "php bin/pest --exclude-group=integration --parallel --processes=3",
        "test:integration": "php bin/pest --group=integration -v",
        "test": [
            "@test:lint",
            "@test:type:check",
            "@test:type:coverage",
            "@test:unit",
            "@test:parallel",
            "@test:integration"
        ]
    }
}
```

### Pest Plugin Development (Nuno)

```json
{
    "name": "vendor/pest-plugin-example",
    "type": "library",
    "extra": {
        "pest": {
            "plugins": ["Vendor\\PestPlugin\\ExamplePlugin"]
        }
    },
    "require": {
        "pestphp/pest-plugin": "^4.0"
    }
}
```

```php
namespace Vendor\PestPlugin;

use Pest\Contracts\Plugins\HandlesArguments;

final class ExamplePlugin implements HandlesArguments
{
    public function handleArguments(array $arguments): array
    {
        // Modify CLI arguments
        return $arguments;
    }
}
```

### Type Coverage Enforcement (Nuno)

```json
{
    "scripts": {
        "test:type:coverage": "pest --type-coverage --min=100"
    }
}
```
