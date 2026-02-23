# Documentation Strategy: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### README-Only: Spatie Response Cache
**Why?** Simple config, one usage pattern. Everything fits in a single page.
```markdown
## Installation
composer require spatie/laravel-responsecache

## Usage
That's it. Responses are cached automatically.

## Configuration
php artisan vendor:publish --tag="responsecache-config"
```

### README-Only: Spatie Translatable
**Why?** One trait, one concept. The README IS the documentation.
```php
class Post extends Model
{
    use HasTranslations;

    public $translatable = ['title', 'body'];
}

$post->setTranslation('title', 'en', 'My Post');
$post->setTranslation('title', 'fr', 'Mon Article');
```
Three API methods. No configuration surface. A docs site adds friction, not value.

### Docs Site: Spatie Media Library
**Why?** 40+ config keys. Conversions, responsive images, collections, S3 integration. README would scroll forever.
```text
docs/
  installation-setup.md
  basic-usage/
    preparing-your-model.md
    associating-files.md
    retrieving-media.md
  advanced-usage/
    defining-conversions.md
    responsive-images.md
    generating-custom-urls.md
```

### Docs Site: Filament
**Why?** Four packages, each with distinct usage patterns. A single README cannot serve this.
```text
docs/
  panels/
    getting-started.md
    resources/
    pages/
  forms/
    getting-started.md
    fields/
  tables/
    getting-started.md
    columns/
```

### Docs Site: Laravel Cashier
**Why?** Multiple integration surfaces (subscriptions, charges, invoices, webhooks). Each needs its own page.
```text
docs/
  subscriptions.md
  single-charges.md
  invoices.md
  webhooks.md
  testing.md
```

---

## Production Patterns

### The Transition Signal
```markdown
<!-- Your README is fighting its own format -->
<details>
<summary>Advanced Configuration</summary>
... 200 lines hidden ...
</details>

<details>
<summary>Custom Drivers</summary>
... 150 lines hidden ...
</details>
```
More than 3 `<details>` blocks? Move depth to a docs site. Keep the README as a landing page.
