# Package Scope: Examples

Real-world examples from the framework and production packages.

---

## Framework Examples

### Micro: laravel-translatable

**Why?** One concept: translatable model attributes. No configuration file needed. Add the trait, declare `$translatable`, done.

```php
class Post extends Model
{
    use HasTranslations;

    public $translatable = ['title', 'body'];
}
```

### Macro: laravel-medialibrary

**Why?** Upload, conversion, and responsive images are tightly coupled. Splitting would force users to install three packages for basic file handling.

```
medialibrary
├── File upload + association
├── Image conversions (thumbnails, crops)
├── Responsive images (srcset generation)
└── Collections (named groups with constraints)
```

### Macro: laravel-backup

**Why?** Sources, destinations, notifications, and cleanup are all required for a functional backup. No single piece works alone.

```
backup
├── Sources (files + databases)
├── Destinations (disks + cloud)
├── Notifications (mail, Slack, Discord)
├── Cleanup (retention strategies)
└── Monitoring (health checks)
```

### Platform: Filament

**Why?** Composable packages that work independently but integrate into a host platform.

```
Foundation Layer
├── support       -> Core utilities
├── schemas       -> Data structures
└── query-builder -> Eloquent utilities

Feature Layer
├── forms         -> Form field components
├── tables        -> Data table system
├── actions       -> Modal and action system
├── notifications -> Toast system
└── widgets       -> Dashboard widgets

Integration Layer
└── panels        -> Admin panel (the host)
```

Each package is installable independently. `panels` aggregates them all. Third-party plugins extend the platform.

---

## Production Patterns

### The Graduation Path

Packages that proved concepts worthy of framework adoption:

- `nunomaduro/pint` -> `laravel/pint` (absorbed as official tooling)
- `nunomaduro/prompts` -> `laravel/prompts` (absorbed as official tooling)
- `tightenco/collect` -> `illuminate/collections` (Laravel extracted it officially)

The best micro packages sometimes make themselves obsolete by proving the concept belongs in the framework.

### When Micro Grows to Macro

Signs your micro package needs macro scope:

1. Users keep asking for the same companion feature
2. You find yourself building a second package that depends on the first
3. The second package has no use case without the first
4. Installation instructions say "also install X for full functionality"

When this happens, merge. One package, one install, one docs site.
