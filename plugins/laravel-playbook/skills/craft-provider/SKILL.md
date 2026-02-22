---
name: craft-provider
description: Crafting a service provider. The declarative heart of every Laravel package.
---

# Skill: Craft Provider

> "A service provider should read like a table of contents. One glance tells you everything the package offers."

## The Standard

1. **Choose the Right Base Class**: Three approaches, matched to the package type.

   | Approach                           | Base Class                           | When                                                                        |
   |------------------------------------|--------------------------------------|-----------------------------------------------------------------------------|
   | Spatie Package Tools (recommended) | `PackageServiceProvider`             | Most packages. Declarative, minimal boilerplate.                            |
   | Raw ServiceProvider                | `Illuminate\Support\ServiceProvider` | First-party style (Cashier, Sanctum, Scout). Full control, no dependencies. |
   | Filament PanelProvider             | `PanelProvider`                      | Platform packages that ship complete admin panels.                          |

   Spatie's `PackageServiceProvider` is recommended for most packages. It eliminates boilerplate. Use a raw `ServiceProvider` when you need full control or want zero external dependencies (Taylor's first-party pattern). Use `PanelProvider` only for Filament panel packages.

2. **The Declarative Core**: Whether using `configurePackage()` or manual registration, the provider declares what the package ships. One glance reveals everything.

3. **Lifecycle Separation**: Two phases. No ambiguity.

   - **Register phase** -- Container bindings. Singletons, scoped services, interface-to-implementation bindings. No side effects.
   - **Boot phase** -- Side effects. Events, observers, macros, gates, Blade directives, route registration.

4. **Binding Patterns**: Three patterns, each with a clear purpose.

   | Pattern   | Scope           | When                                              |
   |-----------|-----------------|---------------------------------------------------|
   | Singleton | App lifetime    | Stateful shared services (registrars, caches)     |
   | Scoped    | Per-request     | Request-scoped state, Octane-safe                 |
   | Bind      | Fresh each time | Stateless resolution, interface-to-implementation |

   Config-driven binding is the dominant pattern. Read the implementation class from config, bind to an interface. Users swap behavior by editing a config file.

5. **Manager Pattern Registration**: For packages with multiple drivers/implementations, register a Manager as a singleton and bind the default driver interface.

6. **Private Method Decomposition**: Separate concerns into private methods within the provider. Taylor's first-party pattern: `registerRoutes()`, `registerResources()`, `registerPublishing()`, `registerCommands()`. Each concern gets its own method.

7. **Package Name**: When using Spatie tools, always `->name('laravel-{slug}')`. The `shortName()` strips the prefix automatically for config keys, view namespaces, and publish tags.

8. **Publishing Groups**: Namespace publish tags as `{package}-{type}`: `cashier-config`, `cashier-migrations`, `cashier-views`. Consumers publish only what they need.

## The Anti-Patterns

| Don't                                               | Do                                                       | Why                                    |
|-----------------------------------------------------|----------------------------------------------------------|----------------------------------------|
| Mix bindings and side effects in one method         | Register phase for bindings, boot phase for side effects | Separation of concerns                 |
| Hardcode implementation classes                     | Config-driven class resolution                           | Users swap without forking             |
| Register everything as singleton                    | Match the pattern to the need: singleton, scoped, bind   | Wrong scope causes subtle bugs         |
| Skip `->name()` or use a bare name                  | Always `->name('laravel-{slug}')` with Spatie tools      | Consistent publish tags and namespaces |
| One giant boot method                               | Private methods per concern                              | Readable, maintainable                 |
| Forget `callAfterResolving()` for optional services | Defer registration until the dependency is resolved      | Avoids boot-order issues               |

## Real-World Examples

See [examples.md](examples.md).
