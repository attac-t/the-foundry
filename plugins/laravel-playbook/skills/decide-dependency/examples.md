# Dependency Strategy: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### Cherry-Pick: Illuminate Components
**Why?** Never depend on `laravel/framework`. Specify individual packages.
```json
{
    "require": {
        "illuminate/contracts": "^11.0||^12.0",
        "illuminate/database": "^11.0||^12.0",
        "illuminate/support": "^11.0||^12.0"
    }
}
```

### Suggest: Optional Drivers (Scout)
**Why?** Each search engine is optional. Users install only what they need.
```json
{
    "suggest": {
        "algolia/algoliasearch-client-php": "Required to use the Algolia engine (^3.2).",
        "meilisearch/meilisearch-php": "Required to use the Meilisearch engine (^1.0).",
        "typesense/typesense-php": "Required to use the Typesense engine (^4.9)."
    }
}
```
Guard in code:
```php
if (! class_exists(Algolia::class)) {
    throw new Exception('Please install the suggested Algolia client: algolia/algoliasearch-client-php.');
}
```

### Own: Spatie's Critical Path Libraries
**Why?** These are on the critical path. If they break, the package breaks.
```json
{
    "require": {
        "spatie/image": "^3.7",
        "spatie/db-dumper": "^3.6",
        "spatie/temporary-directory": "^2.2"
    }
}
```

### Conflict: Known-Bad Versions
**Why?** Prevent silent runtime failures from incompatible versions.
```json
{
    "conflict": {
        "php-ffmpeg/php-ffmpeg": "<0.6.1"
    }
}
```

---

## Production Patterns

### Zero-External-Dep Pattern (Taylor)
```json
{
    "require": {
        "php": "^8.2",
        "illuminate/bus": "^11.0|^12.0",
        "illuminate/contracts": "^11.0|^12.0",
        "illuminate/database": "^11.0|^12.0",
        "illuminate/support": "^11.0|^12.0"
    }
}
```
No external dependencies. Everything that would be external is either owned or suggested.

### Dependency Count by Complexity

| Complexity | Prod Deps | Examples                                       |
|------------|-----------|------------------------------------------------|
| Simple     | 3-5       | laravel-permission, laravel-activitylog        |
| Moderate   | 5-8       | laravel-responsecache, laravel-query-builder   |
| Complex    | 10-16     | laravel-medialibrary (13), laravel-backup (16) |

If a simple package has 10+ deps, something is wrong.

### Broad Version Constraints
```json
{
    "illuminate/support": "^10.0|^11.0|^12.0"
}
```
First-party packages support up to five Laravel majors. Community packages should support at least two.
