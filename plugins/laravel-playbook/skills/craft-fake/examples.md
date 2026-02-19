# Fake: Examples

Patterns from the framework, Livewire, and production packages.

---

## The Pattern

### Taylor's Bus::fake() — The Gold Standard
**Why?** Swap the real dispatcher with a recording double. One line in the test, full assertion API on the result.

```php
// Illuminate\Support\Facades\Bus
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
**Why?** Every Laravel fake follows the same contract: implement the interface, record calls, expose assertions.

```php
class BusFake implements QueueingDispatcher
{
    protected $jobsToFake;
    protected $commands = [];

    public function __construct(QueueingDispatcher $dispatcher, $jobsToFake = [])
    {
        $this->dispatcher = $dispatcher;
        $this->jobsToFake = Arr::wrap($jobsToFake);
    }

    public function dispatch($command)
    {
        if ($this->shouldFakeJob($command)) {
            $this->commands[get_class($command)][] = $command;
        } else {
            return $this->dispatcher->dispatch($command);
        }
    }

    public function assertDispatched(string|Closure $command, callable|int|null $callback = null)
    {
        // Assert the job was dispatched, optionally filtered by closure
    }

    public function assertDispatchedTimes(string|Closure $command, int $times = 1) { /* ... */ }
    public function assertNotDispatched(string|Closure $command, ?callable $callback = null) { /* ... */ }
    public function assertNothingDispatched() { /* ... */ }
}
```

---

## Common Scenarios

### Facade Fake for a Package (Taylor Pattern)

```php
// Your package's facade
class Workflow extends Facade
{
    public static function fake($workflowsToFake = [])
    {
        $actual = static::isFake()
            ? static::getFacadeRoot()->dispatcher
            : static::getFacadeRoot();

        return tap(new WorkflowFake($actual, $workflowsToFake), function ($fake) {
            static::swap($fake);
        });
    }

    protected static function getFacadeAccessor(): string
    {
        return WorkflowManager::class;
    }
}
```

### The Fake Implementation for Your Package

```php
class WorkflowFake implements WorkflowContract
{
    protected array $started = [];
    protected array $completed = [];
    protected bool $preventStray = false;

    public function __construct(
        protected WorkflowContract $actual,
        protected array $workflowsToFake = [],
    ) {}

    public function start(string $workflow, mixed $subject): void
    {
        if ($this->shouldFake($workflow)) {
            $this->started[$workflow][] = $subject;
            return;
        }

        if ($this->preventStray) {
            throw new RuntimeException("Unexpected workflow [{$workflow}] started.");
        }

        $this->actual->start($workflow, $subject);
    }

    public function preventStrayWorkflows(): static
    {
        $this->preventStray = true;
        return $this;
    }

    public function assertStarted(string $workflow, ?Closure $callback = null): void
    {
        PHPUnit::assertTrue(
            $this->wasStarted($workflow, $callback),
            "The [{$workflow}] workflow was not started."
        );
    }

    public function assertStartedTimes(string $workflow, int $times = 1): void
    {
        $count = count($this->started[$workflow] ?? []);

        PHPUnit::assertSame(
            $times, $count,
            "Expected [{$workflow}] to be started {$times} times, but was started {$count} times."
        );
    }

    public function assertNotStarted(string $workflow, ?Closure $callback = null): void
    {
        PHPUnit::assertFalse(
            $this->wasStarted($workflow, $callback),
            "The [{$workflow}] workflow was started unexpectedly."
        );
    }

    public function assertNothingStarted(): void
    {
        PHPUnit::assertEmpty(
            $this->started,
            'Workflows were started unexpectedly: ' . implode(', ', array_keys($this->started)),
        );
    }

    protected function wasStarted(string $workflow, ?Closure $callback = null): bool
    {
        $subjects = $this->started[$workflow] ?? [];

        if (empty($subjects)) {
            return false;
        }

        if ($callback === null) {
            return true;
        }

        return collect($subjects)->contains(fn ($subject) => $callback($subject));
    }
}
```

### Consumer Test Using the Fake

```php
it('starts the onboarding workflow', function () {
    Workflow::fake();

    $user = User::factory()->create();

    (new RegisterUser)->handle($user);

    Workflow::assertStarted('onboarding', fn ($subject) =>
        $subject->is($user)
    );
});

it('does not start workflow for existing users', function () {
    Workflow::fake();

    $user = User::factory()->create(['onboarded' => true]);

    (new RegisterUser)->handle($user);

    Workflow::assertNotStarted('onboarding');
});
```

### Http::fake() — The Most Sophisticated Fake (Taylor)

```php
// Fake all requests
Http::fake();

// Fake specific URLs with responses
Http::fake([
    'github.com/*' => Http::response(['name' => 'Taylor'], 200),
    'forge.laravel.com/*' => Http::response('', 500),
]);

// Fake with sequences
Http::fake([
    'api.example.com/*' => Http::sequence()
        ->push('First call')
        ->push('Second call')
        ->whenEmpty(Http::response('Default')),
]);

// Prevent real requests from leaking
Http::preventStrayRequests();

// Assert
Http::assertSent(fn (Request $request) =>
    $request->url() === 'https://api.example.com/users'
    && $request['name'] === 'Taylor'
);
```

### Closure-Filtered Assertions (Taylor)

```php
Event::fake();

(new ImportProducts)->handle($catalog);

// Assert with closure filter — flexible matching
Event::assertDispatched(ProductImported::class, function ($event) {
    return $event->product->sku === 'WIDGET-001'
        && $event->product->price === 29_99;
});

// Assert count
Event::assertDispatchedTimes(ProductImported::class, 3);
```

### Livewire::test() — Fluent Fake (Caleb Porzio)

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

it('authorizes the action', function () {
    $this->actingAs(User::factory()->create());

    livewire(EditPost::class, ['post' => $post])
        ->call('save')
        ->assertForbidden();
});
```

### Custom Pest Expectations for Your Fake

```php
// In a publishable test helper file
expect()->extend('toHaveStartedWorkflow', function (string $workflow) {
    $fake = app(WorkflowContract::class);

    expect($fake)->toBeInstanceOf(WorkflowFake::class);

    $fake->assertStarted($workflow);

    return $this;
});

// Consumer usage
it('starts onboarding', function () {
    Workflow::fake();

    (new RegisterUser)->handle(User::factory()->create());

    expect(true)->toHaveStartedWorkflow('onboarding');
});
```

### Sanctum::actingAs() — Testing Helper on God Class (Taylor)

```php
// First-party packages ship testing helpers directly on the god class
Sanctum::actingAs($user, ['read', 'write']);

// Usage in tests
it('requires authentication', function () {
    Sanctum::actingAs(User::factory()->create(), ['read']);

    $response = get('/api/posts');

    $response->assertOk();
});
```

### preventStray() Pattern (Taylor)

```php
it('does not make unexpected HTTP calls', function () {
    Http::preventStrayRequests();

    Http::fake([
        'api.stripe.com/*' => Http::response(['ok' => true]),
    ]);

    // Any request NOT matching api.stripe.com/* throws
    (new ProcessPayment)->handle($order);

    Http::assertSent(fn ($request) =>
        str_contains($request->url(), 'api.stripe.com')
    );
});
```
