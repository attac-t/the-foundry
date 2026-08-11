---
name: craft-middleware
description: Crafting package middleware. The invisible gatekeepers that guard, transform, and decorate every request.
---

# Skill: Craft Middleware

> "Good middleware is invisible. The consumer knows it's there because things work. They never have to think about it."

## The Standard

1. **Route-Level by Default**: Register middleware as aliased route middleware, not global. Let consumers apply it where they need it. Global middleware is a power grab -- reserve it for truly cross-cutting concerns like debugbar injection or CORS.

   ```php
   // In the service provider boot method
   app('router')->aliasMiddleware('role', RoleMiddleware::class);
   app('router')->aliasMiddleware('permission', PermissionMiddleware::class);
   ```

2. **The `using()` Static Constructor**: Every parameterized middleware must expose a static `using()` method that returns the middleware string. This is the Laravel 11+ `HasMiddleware` interface pattern. It replaces stringly-typed middleware declarations with type-safe, IDE-friendly calls.

   ```php
   public static function using(string|BackedEnum $role, ?string $guard = null): string
   {
       $args = is_null($guard) ? $role : "{$role},{$guard}";

       return static::class.':'.$args;
   }
   ```

   Consumer usage with `HasMiddleware`:

   ```php
   public static function middleware(): array
   {
       return [
           new Middleware(RoleMiddleware::using('admin'), except: ['index']),
       ];
   }
   ```

3. **Parameter Parsing**: Accept pipe-delimited parameters for multi-value middleware. Parse enums natively. Spatie's pattern: `role:admin|editor` where `|` separates OR conditions.

4. **Response-Aware Decoration**: Middleware that modifies responses (injecting HTML, adding headers) must check the response type before acting. Never inject HTML into JSON responses. Never decorate binary downloads.

   The guard: check `Content-Type` before decorating. Debugbar's pattern -- only inject into responses that are actual HTML documents.

5. **The `terminate()` Method**: Use it for cleanup after the response has been sent to the client. Logging, telemetry, cache warming. Never put slow work in `handle()` when `terminate()` exists.

6. **Conditional Registration**: Register middleware only when the package is enabled or the dependency exists. Wrap registration in config checks. Debugbar registers its middleware only when the debugbar is enabled.

   ```php
   if ($this->app['config']->get('debugbar.enabled')) {
       app('router')->pushMiddlewareToGroup('web', InjectDebugbar::class);
   }
   ```

7. **Middleware Groups**: When your package needs multiple middleware applied together, push to existing groups (`web`, `api`) sparingly. Prefer creating a named group consumers can apply themselves. If you must push to a group, make it configurable.

   ```php
   // Configurable group injection
   $group = config('package.middleware_group', 'web');
   app('router')->pushMiddlewareToGroup($group, YourMiddleware::class);
   ```

8. **Middleware Priority**: When execution order matters (authentication before authorization, session before CSRF), register priority via `$middlewarePriority` awareness. Document the ordering requirement clearly.

9. **Testing Middleware in Isolation**: Middleware is a function: Request in, Response out. Test it directly by constructing a request, calling `handle()`, and asserting on the response. No HTTP test overhead needed.

   ```php
   $middleware = new VerifyWebhookSignature();
   $response = $middleware->handle($request, fn ($req) => new Response('OK'));
   ```

10. **Laravel 11+ Registration**: In Laravel 11+, consumers register middleware aliases in `bootstrap/app.php` via `->withMiddleware()`, not in `Kernel.php`. Your package still registers via the service provider -- this change only affects the consumer side. Document both patterns.

## The Anti-Patterns

| Don't                                        | Do                                            | Why                                                    |
|----------------------------------------------|-----------------------------------------------|--------------------------------------------------------|
| Register as global when route-level suffices | Alias middleware, let consumers apply it      | Global middleware runs on every request -- wasteful    |
| Inject HTML into JSON responses              | Check `Content-Type` before decorating        | Breaks API consumers silently                          |
| Use stringly-typed parameters only           | Expose a `using()` static method              | Type safety, IDE completion, refactor-proof            |
| Hardcode middleware group assignment         | Make the target group configurable            | Not every app uses `web` for the same purpose          |
| Put slow work in `handle()`                  | Use `terminate()` for post-response work      | Don't block the response for telemetry                 |
| Forget to handle unauthenticated users       | Check `$request->user()` before accessing     | Null user in middleware causes 500 errors              |
| Throw generic exceptions                     | Throw domain-specific exceptions with context | "Unauthorized" is useless; "Missing role: admin" helps |
| Skip middleware priority documentation       | Document ordering requirements clearly        | Middleware order bugs are invisible and maddening      |

## Real-World Examples

See [examples.md](examples.md).
