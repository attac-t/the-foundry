# Docs: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Canonical Directory Structure

**Why?** Consistent layout across packages makes navigation predictable.

```
docs/
  _index.md
  introduction.md
  requirements.md
  installation-setup.md
  basic-usage/
    first-feature.md
    second-feature.md
  advanced-usage/
    extending.md
    custom-implementations.md
  changelog.md
  upgrading.md
```

### Frontmatter with Version Metadata

**Why?** The `_index.md` carries context for the docs renderer.

```yaml
---
title: v3
slogan: Associate files with Eloquent models.
githubUrl: https://github.com/vendor/laravel-medialibrary
branch: main
---
```

---

## Common Scenarios

### Impact-Rated Upgrade Guide

Rate breaking changes so developers can triage:

```markdown
## From v4 to v5

### High Impact

- `MediaCollection` renamed to `MediaGroup` -- search and replace across your codebase.

### Medium Impact

- The `registerMediaConversions` method signature changed:
  ```php
  // Before
  public function registerMediaConversions(): void
  // After
  public function registerMediaConversions(Media $media = null): void
  ```

### Low Impact

- The `default_filesystem_disk` config key renamed to `disk_name`.
```

### Anticipating the Wall

Put warnings BEFORE the step that triggers the error:

```markdown
> **MySQL 8 users**: Run this migration first to avoid `ERROR: 1071 Specified key was too long`.
```

### Rector-Based Automated Migration

Version-specific rule sets for automated upgrades:

```php
use Driftingly\RectorLaravel\Set\LaravelSetList;
use Driftingly\RectorLaravel\Set\LaravelLevelSetList;

return RectorConfig::configure()
    ->withSets([
        // Version-specific: only changes from 10->11
        LaravelSetList::LARAVEL_110,

        // Cumulative: all rules up to Laravel 11
        LaravelLevelSetList::UP_TO_LARAVEL_110,
    ]);
```

Two set types: specific (upgrading one version) and cumulative (greenfield on latest).

### Filament's Upgrade Automation

Every major version ships an automated upgrade script:

```bash
composer require filament/upgrade
php artisan filament:upgrade
```

The `filament/upgrade` package rewrites application code to handle breaking changes. This dramatically lowers the cost of major versions.
