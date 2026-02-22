# Docs: Examples

Patterns from the framework and production code.

---

## The Pattern

### Canonical Directory Structure

**Why?** Consistent layout across packages makes navigation predictable.

```text
docs/
  _index.md
  introduction.md
  installation-setup.md
  basic-usage/
  advanced-usage/
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
**Why?** Rate breaking changes so developers can triage.

````markdown
## From v4 to v5

### High Impact

- `MediaCollection` renamed to `MediaGroup` -- search and replace.

### Medium Impact

- The `registerMediaConversions` method signature changed:
  ```php
  // Before
  public function registerMediaConversions(): void
  // After
  public function registerMediaConversions(Media $media = null): void
  ```

### Low Impact

- Config key `default_filesystem_disk` renamed to `disk_name`.
````

### Anticipating the Wall
**Why?** Put warnings BEFORE the step that triggers the error.

```markdown
> **MySQL 8 users**: Run this migration first to avoid `ERROR: 1071 Specified key was too long`.
```

### Rector-Based Automated Migration

```php
return RectorConfig::configure()
    ->withSets([
        LaravelSetList::LARAVEL_110,       // version-specific: 10->11
        LaravelLevelSetList::UP_TO_LARAVEL_110, // cumulative: greenfield
    ]);
```

### Filament's Upgrade Automation
**Why?** Every major version ships an automated upgrade script.

```bash
composer require filament/upgrade
php artisan filament:upgrade
```

Rewrites application code to handle breaking changes automatically.
