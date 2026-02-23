# Deprecation: Examples

Patterns from the framework and production code.

---

## The Pattern

### PHP 8.4 Attribute (Native)
**Why?** Zero-dependency deprecation. IDE strikethrough, static analysis, and `E_USER_DEPRECATED` at runtime.

```php
#[\Deprecated(message: 'Use newMethod() instead', since: '2.3')]
public function oldMethod(): void
{
    $this->newMethod();
}
```

### Hybrid Bridge (PHP 8.3 and below)
**Why?** The attribute is ignored on older PHP. `trigger_deprecation()` fills the gap.

```php
#[\Deprecated(message: 'Use newMethod() instead', since: '2.3')]
public function oldMethod(): void
{
    trigger_deprecation('vendor/package', '2.3',
        'Method "%s::oldMethod()" is deprecated, use "newMethod()" instead.',
        static::class);

    $this->newMethod();
}
```

### trigger_deprecation() (Symfony convention)
**Why?** The standard for runtime deprecation notices. Caught by error handlers, surfaced by PHPUnit/Pest.

```php
use function Symfony\Component\Deprecation\trigger_deprecation;

trigger_deprecation(
    'vendor/package', '2.3',
    'The "%s" class is deprecated, use "%s" instead.',
    OldClass::class, NewClass::class,
);
```

---

## Common Scenarios

### Class Deprecation -- Extend and Redirect

```php
/** @deprecated since 2.3, use NewProcessor instead. */
class OldProcessor extends NewProcessor
{
    public function __construct()
    {
        trigger_deprecation('vendor/package', '2.3',
            'The "%s" class is deprecated, use "%s" instead.',
            self::class, NewProcessor::class);

        parent::__construct();
    }
}
```

### Method Deprecation -- One-Line Proxy

```php
/** @deprecated since 3.1, use calculateTotal() instead. */
#[\Deprecated(message: 'Use calculateTotal() instead', since: '3.1')]
public function getTotal(): Money
{
    trigger_deprecation('vendor/package', '3.1', /* ... */);

    return $this->calculateTotal();
}
```

### Package Deprecation -- composer.json

```json
{
    "name": "vendor/old-package",
    "abandoned": "vendor/new-package",
    "description": "[DEPRECATED] Use vendor/new-package instead."
}
```

### UPGRADING.md Entry (Symfony-Style)

````markdown
## UPGRADING FROM 2.x to 3.0

### High Impact

#### `OldProcessor` Removed
**Likelihood of Impact: High**

The `OldProcessor` class, deprecated in 2.3, has been removed.

Before:
```php
$processor = new OldProcessor();
```

After:
```php
$processor = new NewProcessor();
```
````

### rector-laravel -- Automated Upgrades (Jason McCreary / Driftingly)
**Why?** Ship Rector rules so consumers can automate their upgrade.

```php
// rector.php -- consumer runs this to upgrade
return RectorConfig::configure()
    ->withSetProviders(LaravelSetProvider::class)
    ->withComposerBased(laravel: true);
```

For package-specific upgrades, ship a custom set:

```php
return RectorConfig::configure()
    ->withSets([LaravelLevelSetList::UP_TO_LARAVEL_110]);
```

Deprecate in v2, ship Rector rules alongside v3, consumers run one command.

### Rector Rule for Automated Migration

```php
return RectorConfig::configure()
    ->withConfiguredRule(RenameClassRector::class, [
        'Vendor\Package\OldProcessor' => 'Vendor\Package\NewProcessor',
    ])
    ->withConfiguredRule(RenameMethodRector::class, [
        new MethodCallRename('Vendor\Package\Calculator', 'getTotal', 'calculateTotal'),
    ]);
```

### CHANGELOG Entry

```markdown
## 2.3.0

### Deprecated

- `OldProcessor` is deprecated, use `NewProcessor` instead (#142)
- `Calculator::getTotal()` is deprecated, use `calculateTotal()` instead (#143)
```
