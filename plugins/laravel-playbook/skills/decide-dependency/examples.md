# Dependency Strategy: Examples

Real-world examples from the framework and production packages.

---

## Framework Examples

### Depend: Cherry-Picked Illuminate Components

**Why?** Never depend on `laravel/framework`. Always specify individual illuminate packages.

```json
{
    "require": {
        "illuminate/contracts": "^11.0||^12.0",
        "illuminate/database": "^11.0||^12.0",
        "illuminate/support": "^11.0||^12.0"
    }
}
```

### Suggest: Optional Driver Dependencies (Scout)

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

Guard in code with a helpful message:

```php
protected function ensureAlgoliaClientIsInstalled()
{
    if (class_exists(Algolia::class)) {
        return;
    }

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

Spatie builds and maintains these rather than depending on third-party alternatives.

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

### Taylor's Zero-External-Dep Pattern

First-party packages depend only on illuminate components and PHP:

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

No external dependencies. Everything that would be external is either owned (`laravel/prompts`) or suggested.

### League's Interface-First Approach

The core defines interfaces. Adapters implement them. The bridge wraps them.

```
league/flysystem              -> Core: interfaces + Filesystem class
league/flysystem-aws-s3-v3    -> Adapter: S3 implementation
illuminate/filesystem          -> Bridge: Laravel's Storage facade wraps Flysystem
```

The core has zero framework dependencies. Adapters depend on vendor SDKs. The bridge depends on the framework.

### Dependency Count by Package Complexity

| Complexity | Prod Deps | Examples                                                      |
|------------|-----------|---------------------------------------------------------------|
| Simple     | 3-5       | laravel-permission, laravel-activitylog, laravel-translatable |
| Moderate   | 5-8       | laravel-responsecache, laravel-query-builder                  |
| Complex    | 10-16     | laravel-medialibrary (13), laravel-backup (16)                |

Dependency count should correlate with package complexity. If a simple package has 10+ deps, something is wrong.

### Broad Version Constraints for Stability

Support multiple Laravel versions simultaneously:

```json
{
    "illuminate/support": "^10.0|^11.0|^12.0"
}
```

First-party packages like Scout support up to five Laravel majors. Community packages should support at least two.
