# Package Scope: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### Micro: laravel-translatable
**Why?** One concept: translatable model attributes. Add the trait, declare `$translatable`, done.
```php
class Post extends Model
{
    use HasTranslations;

    public $translatable = ['title', 'body'];
}
```

### Macro: laravel-medialibrary
**Why?** Upload, conversion, and responsive images are tightly coupled. Splitting would force three packages for basic file handling.
```text
medialibrary
├── File upload + association
├── Image conversions
├── Responsive images
└── Collections
```

### Macro: laravel-backup
**Why?** Sources, destinations, notifications, and cleanup are all required. No single piece works alone.
```text
backup
├── Sources (files + databases)
├── Destinations (disks + cloud)
├── Notifications (mail, Slack, Discord)
├── Cleanup (retention strategies)
└── Monitoring (health checks)
```

### Platform: Filament
**Why?** Composable packages that work independently but integrate into a host platform.
```text
Foundation:  support, schemas, query-builder
Features:    forms, tables, actions, notifications, widgets
Integration: panels (the host)
```
Each package installable independently. `panels` aggregates them. Third-party plugins extend the platform.

---

## Production Patterns

### The Graduation Path
```text
nunomaduro/pint       -> laravel/pint
nunomaduro/prompts    -> laravel/prompts
tightenco/collect     -> illuminate/collections
```
The best micro packages prove the concept belongs in the framework.

### When Micro Grows to Macro

Signals:
1. Users keep asking for the same companion feature
2. You build a second package that depends on the first
3. The second package has no use case without the first
4. Installation instructions say "also install X for full functionality"

When this happens, merge. One package, one install, one docs site.
