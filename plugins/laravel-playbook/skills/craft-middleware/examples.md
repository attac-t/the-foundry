# Middleware: Examples

Patterns from the framework and production code.

---

## The Pattern

### Route-Level Authorization Middleware
**Why?** Parameterized middleware with pipe-delimited roles, enum support, and the `using()` static constructor.

```php
public function handle(Request $request, Closure $next, $role, ?string $guard = null)
{
    $user = Auth::guard($guard)->user();

    if (! $user) { throw UnauthorizedException::notLoggedIn(); }
    if (! $user->hasAnyRole(explode('|', $role))) { throw UnauthorizedException::forRoles($roles); }

    return $next($request);
}

public static function using(string|BackedEnum $role, ?string $guard = null): string
{
    // ... builds "ClassName:role1|role2,guard" string
}
```

Consumer usage:

```php
Route::middleware('role:admin|editor')->group(fn () => /* ... */);

// Laravel 11+ HasMiddleware
new Middleware(RoleMiddleware::using('admin'), except: ['index', 'show']);

// Route macro (registered by the package)
Route::role('admin')->group(fn () => /* ... */);
```

### Webhook Signature Verification (Cashier)
**Why?** Single-responsibility: verify signature, reject if invalid. No business logic.

```php
public function handle($request, Closure $next)
{
    try {
        WebhookSignature::verifyHeader(
            $request->getContent(),
            $request->header('Stripe-Signature'),
            config('cashier.webhook.secret'),
            config('cashier.webhook.tolerance')
        );
    } catch (SignatureVerificationException $e) {
        throw new AccessDeniedHttpException($e->getMessage(), $e);
    }

    return $next($request);
}
```

### Stateful SPA Authentication (Sanctum)
**Why?** Conditional pipeline: first-party frontend gets session middleware, API requests pass through.

```php
public function handle($request, $next)
{
    $this->configureSecureCookieSessions();

    return (new Pipeline(app()))->send($request)->through(
        static::fromFrontend($request) ? $this->frontendMiddleware() : []
    )->then(fn ($request) => $next($request));
}

// frontendMiddleware() returns [EncryptCookies, StartSession, VerifyCsrfToken, ...]
// fromFrontend() matches referer/origin against configured stateful domains.
```

---

## Common Scenarios

### Response Decoration with Content-Type Guard
**Why?** Always check response type before injecting content.

```php
public function handle(Request $request, Closure $next)
{
    $response = $next($request);

    if (! str_contains($response->headers->get('Content-Type', ''), 'text/html')) {
        return $response;
    }

    $response->setContent(str_replace('</body>', $this->renderToolbar().'</body>', $response->getContent()));

    return $response;
}
```

### Post-Response Cleanup with terminate()
**Why?** Heavy work after the response is sent. Does not block the user.

```php
public function handle(Request $request, Closure $next)
{
    $request->attributes->set('api_started_at', microtime(true));

    return $next($request);
}

public function terminate(Request $request, Response $response): void
{
    $duration = microtime(true) - $request->attributes->get('api_started_at');
    ApiUsageTracker::record([/* endpoint, method, status, duration_ms, consumer */]);
}
```

### Registration in the Service Provider
**Why?** Alias for route-level, push for global.

```php
$router->aliasMiddleware('role', RoleMiddleware::class);
$router->aliasMiddleware('permission', PermissionMiddleware::class);

if (config('package.inject_middleware')) {
    $router->pushMiddlewareToGroup(config('package.middleware_group', 'web'), PackageMiddleware::class);
}
```

### Testing Middleware in Isolation
**Why?** No HTTP overhead. Direct invocation.

```php
it('rejects invalid signatures', function () {
    $request = Request::create('/webhook', 'POST', content: '{"event": "test"}');
    $request->headers->set('Stripe-Signature', 'invalid');

    expect(fn () => (new VerifyWebhookSignature)->handle($request, fn ($r) => response('OK')))
        ->toThrow(AccessDeniedHttpException::class);
});

it('enforces role middleware on routes', function () {
    Route::middleware('role:admin')->get('/test', fn () => 'OK');

    actingAs(userWithRole('admin'))->get('/test')->assertOk();
    actingAs(userWithRole('viewer'))->get('/test')->assertForbidden();
});
```
