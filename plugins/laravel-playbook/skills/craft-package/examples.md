# Package: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Skeleton with spatie/laravel-package-tools (Recommended)
**Why?** Declarative service provider. Eliminates boilerplate. The community standard.

```json
{
    "name": "vendor/laravel-feature",
    "description": "A clear, one-line description",
    "keywords": ["vendor", "laravel", "feature"],
    "license": "MIT",
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
    "autoload": {
        "psr-4": { "Vendor\\Feature\\": "src" }
    },
    "autoload-dev": {
        "psr-4": { "Vendor\\Feature\\Tests\\": "tests" }
    },
    "scripts": {
        "test": "vendor/bin/pest",
        "analyse": "vendor/bin/phpstan analyse",
        "format": "vendor/bin/pint",
        "test-coverage": "vendor/bin/pest --coverage"
    },
    "config": {
        "sort-packages": true,
        "allow-plugins": { "pestphp/pest-plugin": true }
    },
    "extra": {
        "laravel": {
            "providers": ["Vendor\\Feature\\FeatureServiceProvider"]
        }
    },
    "minimum-stability": "dev",
    "prefer-stable": true
}
```

### Skeleton without spatie/laravel-package-tools (Taylor's First-Party Style)
**Why?** Zero external dependencies. Full control. How Taylor ships Cashier, Scout, Sanctum.

```json
{
    "name": "laravel/feature",
    "description": "A clear, one-line description",
    "keywords": ["laravel", "feature"],
    "license": "MIT",
    "require": {
        "php": "^8.2",
        "illuminate/console": "^11.0|^12.0",
        "illuminate/contracts": "^11.0|^12.0",
        "illuminate/database": "^11.0|^12.0",
        "illuminate/support": "^11.0|^12.0"
    },
    "require-dev": {
        "mockery/mockery": "^1.0",
        "orchestra/testbench": "^9.0|^10.0",
        "phpstan/phpstan": "^1.10||^2.0",
        "phpunit/phpunit": "^11.0||^12.0"
    },
    "autoload": {
        "psr-4": { "Laravel\\Feature\\": "src/" }
    },
    "autoload-dev": {
        "psr-4": { "Laravel\\Feature\\Tests\\": "tests/" }
    },
    "extra": {
        "laravel": {
            "providers": ["Laravel\\Feature\\FeatureServiceProvider"]
        },
        "branch-alias": {
            "dev-master": "1.x-dev"
        }
    },
    "minimum-stability": "dev",
    "prefer-stable": true
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
Runtime checks with helpful error messages.

```json
{
    "suggest": {
        "algolia/algoliasearch-client-php": "Required to use the Algolia engine (^3.2).",
        "meilisearch/meilisearch-php": "Required to use the Meilisearch engine (^1.0)."
    }
}
```

```php
protected function ensureAlgoliaClientIsInstalled(): void
{
    if (class_exists(Algolia::class)) {
        return;
    }

    throw new Exception(
        'Please install the suggested Algolia client: algolia/algoliasearch-client-php.'
    );
}
```

### Auto-Discovery with Facade Alias

```json
{
    "extra": {
        "laravel": {
            "providers": ["Vendor\\Feature\\FeatureServiceProvider"],
            "aliases": {
                "Feature": "Vendor\\Feature\\Facades\\Feature"
            }
        }
    }
}
```

### Broad Version Constraints
Support multiple Laravel versions simultaneously. Taylor's first-party packages support up to five.

```json
{
    "require": {
        "illuminate/support": "^10.0|^11.0|^12.0"
    }
}
```

### workbench/ Directory (Taylor's Convention)
A mini Laravel app for development, powered by Orchestra Testbench.

```
workbench/
  app/
    Models/
    Providers/
  database/
    factories/
    migrations/
  routes/
```
