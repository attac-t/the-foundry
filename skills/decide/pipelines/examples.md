# Pipelines: Examples

Real-world examples of Pipeline vs Sequential Calls.

---

## Laravel Framework

### Illuminate\Pipeline\Pipeline
**Why?** Core pipeline implementation.
```php
use Illuminate\Pipeline\Pipeline;

app(Pipeline::class)
    ->send($request)
    ->through([
        TrimStrings::class,
        ConvertEmptyStringsToNull::class,
    ])
    ->thenReturn();
```

### Middleware Stack
**Why?** HTTP requests flow through middleware.
```php
// Kernel.php - Laravel's middleware IS a pipeline
protected $middleware = [
    \App\Http\Middleware\TrustProxies::class,
    \Illuminate\Session\Middleware\StartSession::class,
    \Illuminate\View\Middleware\ShareErrorsFromSession::class,
];
```

### Router Pipeline
**Why?** Route matching and dispatching.
```php
// Framework uses pipeline internally
$this->pipeline
    ->send($request)
    ->through($middleware)
    ->then(fn ($request) => $this->dispatchToRouter());
```

---

## Vendor Packages

### Spatie Query Builder
**Why?** Filters applied as pipeline steps.
```php
QueryBuilder::for(User::class)
    ->allowedFilters(['name', 'email'])  // Pipeline of filters
    ->allowedSorts(['created_at'])
    ->get();
```

### League Pipeline
**Why?** Functional pipeline package.
```php
use League\Pipeline\Pipeline;

$pipeline = (new Pipeline)
    ->pipe(new TimesTwo)
    ->pipe(new AddOne);

$pipeline->process(10); // 21
```

---

## The Step Pattern

### Immutable State
**Why?** Prevents side effects, enables clean flow.
```php
class GenerateDimensionsStep
{
    public function handle(PipelineState $state, Closure $next): mixed
    {
        $dimensions = $this->generateDimensions($state->priceList);

        return $next($state->withDimensions($dimensions));
    }
}
```

### Validation Step
**Why?** Throws on failure, otherwise passes through.
```php
class ValidateOrderStep
{
    public function handle($order, Closure $next): mixed
    {
        throw_if($order->items->isEmpty(), EmptyOrderException::class);

        return $next($order);
    }
}
```

---

## Anti-Patterns

### Pipeline for 2 Steps
**Why wrong?** Overkill. Just call them.
```php
// Bad: overhead for nothing
Pipeline::send($order)->through([StepA::class, StepB::class]);

// Good: direct
$result = $this->stepA->execute($order);
$final = $this->stepB->execute($result);
```

### Control Flow in Pipeline
**Why wrong?** Pipelines are linear. Use Actions for branching.
```php
// Bad: if/else in step
if ($state->order->isDigital()) { return $this->handleDigital(); }

// Good: Action decides
$order->isDigital()
    ? $this->processDigital->execute($order)
    : $this->processPhysical->execute($order);
```
