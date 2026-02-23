# Test Suite: Examples

Patterns from the framework and production code.

---

## The Pattern

### TestCase Anatomy
**Why?** Three methods define the entire Testbench testing environment.

```php
abstract class TestCase extends Orchestra\Testbench\TestCase
{
    protected function getPackageProviders($app): array { return [PackageServiceProvider::class]; }

    protected function getEnvironmentSetUp($app): void
    {
        config()->set('database.default', 'testing');
        config()->set('database.connections.testing', ['driver' => 'sqlite', 'database' => ':memory:']);
    }

    // setUpDatabase() — loadMigrationsFrom()
}
```

### Pest.php Configuration
**Why?** One file: global TestCase, custom expectations, shared helpers.

```php
uses(TestCase::class)->in(__DIR__);

expect()->extend('toBePublished', fn () => $this->status->toBe('published'));

function createQueryFromFilterRequest(array $filters): QueryBuilder
{
    return QueryBuilder::for(TestModel::class, new Request(['filter' => $filters]));
}
```

---

## Common Scenarios

### Domain-Organized Test Directory

```text
tests/
├── ArchTest.php
├── Commands/
├── Middleware/
├── Models/
├── Traits/
├── Pest.php, TestCase.php
└── TestSupport/
```

### Architecture Tests

```php
arch('no debugging')->expect(['dd', 'dump', 'ray'])->each->not->toBeUsed();
arch('strict types')->expect('App')->toUseStrictTypes();

// Presets: one word activates dozens of constraints
arch()->preset()->strict();
arch()->preset()->laravel();
```

### Higher-Order Expectations

```php
expect($users)->each->toBeInstanceOf(User::class);
expect($user)->name->toBe('Taylor');
expect($logs)->sequence(
    fn ($log) => $log->level->toBe('info'),
    fn ($log) => $log->level->toBe('error'),
);
```

### Facade ::fake() in Tests

```php
it('dispatches the import job', function () {
    Bus::fake();
    post('/api/products/import', ['file' => $file]);
    Bus::assertDispatched(ImportProducts::class, fn ($job) => $job->filename === 'products.csv');
});
// preventStray() pattern — see craft-fake for the full implementation.
```

### Livewire Component Testing

```php
it('creates a post', function () {
    livewire(CreatePost::class)
        ->set('title', 'My Post')->set('content', 'The content')
        ->call('save')
        ->assertDispatched('post-created')
        ->assertHasNoErrors();

    expect(Post::count())->toBe(1);
});

it('validates required fields', function () {
    livewire(CreatePost::class)->set('title', '')->call('save')
        ->assertHasErrors(['title' => 'required']);
});
```

### Filament Resource Testing

```php
it('can list records', function () {
    $posts = Post::factory()->count(10)->create();
    livewire(PostResource\Pages\ListPosts::class)->assertCanSeeTableRecords($posts);
});

it('can create a record', function () {
    $data = Post::factory()->make();
    livewire(PostResource\Pages\CreatePost::class)
        ->fillForm(['title' => $data->title, 'content' => $data->content])
        ->call('create')->assertHasNoFormErrors();
});
```

### Composer Scripts

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

### Mutation Testing
**Why?** If a mutant survives, your test suite has a blind spot.

```bash
pest --mutate                                        # full suite
pest --mutate --class=WorkflowEngine --min=90        # targeted with threshold
pest --mutate --parallel --min=80                     # CI pipeline
```

### Parallel Testing
**Why?** Distribute across CPU cores. Requires test isolation.

```bash
pest --parallel --processes=4
```
