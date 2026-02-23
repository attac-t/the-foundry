---
name: craft-extension-point
description: Crafting extension points. Making code flexible means fewer feature requests.
---

# Skill: Craft Extension Point

> "Every `private` method is a feature request waiting to happen."

## The Standard

1. **Manager/Driver Pattern**: Taylor's signature extensibility mechanism. Register built-in drivers via `create{Name}Driver()` methods. Consumers add custom drivers via `extend()`. The default driver delegates through `__call()`.

   This is the primary extension mechanism for multi-implementation services: cache, mail, notifications, queue, session, filesystem, Scout engines, Socialite providers, Pennant feature stores.

2. **Config-Driven Binding**: Define contracts. Bind implementations via config. Users swap behavior by changing a config value. No code changes, no service provider overrides. Global behavior swap. Zero ceremony.

3. **Macroable Registration**: Runtime extension of any class using the `Macroable` trait. `macro()` for single methods, `mixin()` for bulk-registering from a class. Used across the framework: Collection, Builder, Request, Response, Router, Str.

4. **Render Hooks (Filament)**: Named injection points where plugins insert Blade content. Typed enum constants define hook locations. Scoped hooks target specific pages. 60+ hook points across panels, tables, actions.

5. **Adapter Pattern (League)**: Framework-agnostic core with framework-specific adapters. The interface IS the extension point. Implement it, pass it to the core, done. No registration, no discovery, no plugin manifest.

6. **Strategy Pattern + Config**: Accept interface implementations for custom behavior. Built-in factories for common cases, raw interface for everything else. The user chooses from your menu or brings their own dish.

7. **Events**: Fire domain events at lifecycle boundaries. Users hook in without touching core code. Events are the loosest coupling. The package doesn't know or care who's listening.

8. **Static Callback Customization**: Accept callbacks on the "god class" for customization points. `Sanctum::authenticateAccessTokensUsing()`, `Cashier::formatCurrencyUsing()`, `Horizon::auth()`. Called from `AppServiceProvider::boot()`.

9. **The `use{Model}()` Pattern**: Let consumers swap internal model classes via static setters on the god class. `Cashier::useCustomerModel(Team::class)`. The package references `static::$customerModel` instead of hardcoding.

## The Hierarchy

Choose the right extension mechanism for the scope:

| Scope                       | Mechanism                     | Example                                  |
|-----------------------------|-------------------------------|------------------------------------------|
| Multi-driver services       | Manager/Driver pattern        | `Scout::extend('elastic', fn () => ...)` |
| Global (app-wide)           | Config-driven binding         | Swap the `Role` model via config         |
| Runtime (ad-hoc)            | Macroable registration        | `Collection::macro('toUpper', ...)`      |
| UI injection                | Render hooks                  | `PanelsRenderHook::SIDEBAR_NAV_END`      |
| Framework-agnostic          | Adapter/Interface             | Implement `FilesystemAdapter`            |
| Per-use (one call)          | Callback injection            | Custom filter closure                    |
| Reusable (shared)           | Interface implementation      | Custom `Filter` class                    |
| Decoupled (fire-and-forget) | Events                        | `RoleAttachedEvent`                      |
| Model customization         | `use{Model}()` static setters | `Sanctum::usePersonalAccessTokenModel()` |

Start with config binding for simple swaps. Use the Manager pattern for driver-based architectures. Events for side effects. Macroable for ad-hoc runtime extensions.

## The Anti-Patterns

| Don't                                    | Do                                                        | Why                                       |
|------------------------------------------|-----------------------------------------------------------|-------------------------------------------|
| `private` methods that prevent extension | `protected` -- let subclasses override                    | Every `private` is a closed door          |
| `final` classes that block inheritance   | `final` only on value objects and DTOs                    | Extension is a feature, not a risk        |
| No events at lifecycle boundaries        | Dispatch events at create, update, delete, attach, detach | Users need hooks without modifying source |
| Hardcoded implementations                | Config-driven class resolution                            | Users swap without forking                |
| Only closures, no interfaces             | Closures for one-offs, interfaces for reusable strategies | Closures don't compose, interfaces do     |
| Reinventing the driver pattern           | Extend `Illuminate\Support\Manager`                       | The wheel is already round                |
| One extension mechanism for everything   | Match the mechanism to the scope                          | Different problems need different tools   |

**See also:** ground-extensibility (when and why to extend), craft-macro (deep dive on Macroable).

## Real-World Examples

See [examples.md](examples.md).
