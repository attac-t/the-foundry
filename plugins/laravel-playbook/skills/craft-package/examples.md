# Package: Examples

Patterns from the framework and production code.

---

## The Pattern

### Skeleton with spatie/laravel-package-tools (Recommended)
**Why?** Declarative service provider. Eliminates boilerplate. The community standard.

```json
{
    "name": "vendor/laravel-feature",
    "require": {
        "php": "^8.2",
        "spatie/laravel-package-tools": "^1.16",
        "illuminate/contracts": "^11.0||^12.0",
        "illuminate/support": "^11.0||^12.0"
    },
    "require-dev": {
        "orchestra/testbench": "^9.0||^10.0",
        "pestphp/pest": "^3.0||^4.0",
        "larastan/larastan": "^2.0||^3.0",
        "laravel/pint": "^1.0"
    },
    "autoload": { "psr-4": { "Vendor\\Feature\\": "src" } },
    "extra": { "laravel": { "providers": ["Vendor\\Feature\\FeatureServiceProvider"] } }
}
```
Also include: `description`, `keywords`, `license`, `autoload-dev`, `scripts`, `config`, `minimum-stability`, `prefer-stable`.

### Skeleton without spatie/laravel-package-tools (Taylor's First-Party Style)
**Why?** Zero external dependencies. Full control. How Taylor ships Cashier, Scout, Sanctum.

```json
{
    "name": "laravel/feature",
    "require": {
        "php": "^8.2",
        "illuminate/console": "^11.0|^12.0",
        "illuminate/contracts": "^11.0|^12.0",
        "illuminate/support": "^11.0|^12.0"
    },
    "require-dev": {
        "orchestra/testbench": "^9.0|^10.0",
        "phpstan/phpstan": "^1.10||^2.0",
        "phpunit/phpunit": "^11.0||^12.0"
    },
    "autoload": { "psr-4": { "Laravel\\Feature\\": "src/" } },
    "extra": { "laravel": { "providers": ["Laravel\\Feature\\FeatureServiceProvider"] } }
}
```

### Framework-Agnostic Core (League Pattern)
**Why?** The problem is framework-independent. Build the solution in PHP, bridge it to frameworks.

```json
{
    "name": "vendor/feature",
    "description": "A PHP library for feature management",
    "license": "MIT",
    "require": {
        "php": "^8.2"
    },
    "autoload": {
        "psr-4": { "Vendor\\Feature\\": "src" }
    }
}
```

The Laravel bridge lives in a separate package or is shipped as a service provider within the same package under a distinct namespace.

---

## Common Scenarios

### Optional Dependencies via suggest
**Why?** Runtime guard with helpful error message when optional dep is missing.

```json
{ "suggest": { "algolia/algoliasearch-client-php": "Required to use the Algolia engine (^3.2)." } }
```

```php
if (! class_exists(Algolia::class)) {
    throw new Exception('Please install the suggested Algolia client: algolia/algoliasearch-client-php.');
}
```

### Auto-Discovery with Facade Alias
**Why?** Zero-config facade registration.

```json
{ "extra": { "laravel": { "providers": ["...ServiceProvider"], "aliases": { "Feature": "...\\Facades\\Feature" } } } }
```

### Broad Version Constraints
**Why?** Taylor's first-party packages support up to five major versions.

```json
{ "require": { "illuminate/support": "^10.0|^11.0|^12.0" } }
```

### workbench/ Directory (Taylor's Convention)
**Why?** A mini Laravel app for development, powered by Orchestra Testbench.

```text
workbench/
  app/Models/, app/Providers/
  database/factories/, database/migrations/
  routes/
```
