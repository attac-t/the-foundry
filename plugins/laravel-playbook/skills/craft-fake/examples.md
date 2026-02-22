# Fake: Examples

Patterns from the framework and production code.

---

## The Pattern

### Taylor's Bus::fake() -- The Gold Standard
**Why?** Swap the real dispatcher with a recording double. One line in the test, full assertion API.

```php
public static function fake($jobsToFake = [], ?BatchRepository $batchRepository = null)
{
    $actualDispatcher = static::isFake()
        ? static::getFacadeRoot()->dispatcher
        : static::getFacadeRoot();

    return tap(new BusFake($actualDispatcher, $jobsToFake, $batchRepository), function ($fake) {
        static::swap($fake);
    });
}
```

### The Fake Class Anatomy (Taylor)
**Why?** Every Laravel fake follows: implement the interface, record calls, expose assertions.

```php
class BusFake implements QueueingDispatcher
{
    protected $commands = [];

    public function dispatch($command)
    {
        if ($this->shouldFakeJob($command)) {
            $this->commands[get_class($command)][] = $command;
        } else {
            return $this->dispatcher->dispatch($command);
        }
    }

    public function assertDispatched(string|Closure $command, callable|int|null $callback = null) { /* ... */ }
    public function assertNotDispatched(string|Closure $command, ?callable $callback = null) { /* ... */ }
    public function assertNothingDispatched() { /* ... */ }
}
```

---

## Common Scenarios

### Facade Fake for a Package

```php
class Workflow extends Facade
{
    public static function fake($workflowsToFake = [])
    {
        $actual = static::isFake()
            ? static::getFacadeRoot()->dispatcher
            : static::getFacadeRoot();

        return tap(new WorkflowFake($actual, $workflowsToFake), fn ($fake) =>
            static::swap($fake)
        );
    }
}
```

### The Fake Implementation

```php
class WorkflowFake implements WorkflowContract
{
    protected array $started = [];

    public function start(string $workflow, mixed $subject): void
    {
        if ($this->shouldFake($workflow)) {
            $this->started[$workflow][] = $subject;
            return;
        }

        $this->actual->start($workflow, $subject);
    }

    public function assertStarted(string $workflow, ?Closure $callback = null): void { /* ... */ }
    // ... assertStartedTimes(), assertNotStarted(), assertNothingStarted()
}
```

### Consumer Test Using the Fake

```php
it('starts the onboarding workflow', function () {
    Workflow::fake();

    (new RegisterUser)->handle(User::factory()->create());

    Workflow::assertStarted('onboarding', fn ($subject) =>
        $subject->is($user)
    );
});
```

### Http::fake() -- The Most Sophisticated Fake (Taylor)

```php
Http::fake([
    'github.com/*' => Http::response(['name' => 'Taylor'], 200),
    'forge.laravel.com/*' => Http::response('', 500),
]);

Http::preventStrayRequests(); // any unmocked request throws

Http::assertSent(fn (Request $request) =>
    $request->url() === 'https://api.example.com/users'
);
```

### Closure-Filtered Assertions (Taylor)
**Why?** Flexible matching on recorded events.

```php
Event::fake();

(new ImportProducts)->handle($catalog);

Event::assertDispatched(ProductImported::class, fn ($event) =>
    $event->product->sku === 'WIDGET-001'
);

Event::assertDispatchedTimes(ProductImported::class, 3);
```

### Livewire::test() -- Fluent Fake (Caleb Porzio)

```php
livewire(CreatePost::class)
    ->set('title', 'My Post')
    ->set('content', 'The content')
    ->call('save')
    ->assertDispatched('post-created')
    ->assertHasNoErrors();
```

### CallableFake (Tim MacDonald)
**Why?** `Bus::fake()` for closures. Assert what a callback was called with.

```php
$callable = new CallableFake();

$repository->resolveDependencies($callable);

$callable
    ->assertTimesInvoked(2)
    ->assertCalled(fn (Dependency $dep): bool =>
        Str::startsWith($dep->name, 'spatie/')
    );
```

For `Closure` type-hints, use `->asClosure()`. For return-value control, use `CallableFake::withReturnResolver()`.

### Log::fake() (Tim MacDonald)
**Why?** Laravel has no built-in `Log::fake()`. Same assertion patterns as `Bus::fake()`.

```php
LogFake::bind();

(new ImportProducts)->handle($catalog);

Log::assertLogged(fn (LogEntry $log) =>
    $log->level === 'info' && $log->message === 'Products imported.'
);

Log::channel('slack')->assertLogged(fn (LogEntry $log) => $log->level === 'critical');
```

### preventStray() Pattern (Taylor)
**Why?** Any request NOT matching the faked URLs throws.

```php
Http::preventStrayRequests();

Http::fake([
    'api.stripe.com/*' => Http::response(['ok' => true]),
]);

(new ProcessPayment)->handle($order); // unmocked requests throw
```

### Sanctum::actingAs() -- Testing Helper on God Class (Taylor)

```php
Sanctum::actingAs(User::factory()->create(), ['read', 'write']);

$response = get('/api/posts');
$response->assertOk();
```
