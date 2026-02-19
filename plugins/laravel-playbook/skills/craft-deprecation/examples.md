# Deprecation: Examples

Patterns from Symfony, Taylor, Filament, and PHP 8.4.

---

## The Pattern

### PHP 8.4 Attribute (Native)
**Why?** Zero-dependency deprecation. IDE strikethrough, static analysis, and `E_USER_DEPRECATED` at runtime — all from one attribute.

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
use function Symfony\Component\Deprecation\trigger_deprecation;

#[\Deprecated(message: 'Use newMethod() instead', since: '2.3')]
public function oldMethod(): void
{
    trigger_deprecation(
        'vendor/package',
        '2.3',
        'Method "%s::oldMethod()" is deprecated, use "newMethod()" instead.',
        static::class,
    );

    $this->newMethod();
}
```

### trigger_deprecation() (Symfony convention)
**Why?** The standard for runtime deprecation notices. Caught by error handlers, surfaced by PHPUnit/Pest, invisible to end users in production.

```php
// composer require symfony/deprecation-contracts
use function Symfony\Component\Deprecation\trigger_deprecation;

trigger_deprecation(
    'vendor/package',  // Package that owns the deprecation
    '2.3',             // Version where it was deprecated
    'The "%s" class is deprecated, use "%s" instead.',
    OldClass::class,
    NewClass::class,
);
```

---

## Common Scenarios

### Class Deprecation — Extend and Redirect

```php
// src/NewProcessor.php — the replacement
class NewProcessor
{
    public function process(): Result { /* ... */ }
}

// src/OldProcessor.php — deprecated, proxies to new
/**
 * @deprecated since 2.3, use NewProcessor instead.
 */
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

### Method Deprecation — One-Line Proxy

```php
/**
 * @deprecated since 3.1, use calculateTotal() instead.
 */
#[\Deprecated(message: 'Use calculateTotal() instead', since: '3.1')]
public function getTotal(): Money
{
    trigger_deprecation('vendor/package', '3.1',
        'Method "%s::getTotal()" is deprecated, use "calculateTotal()" instead.',
        static::class);

    return $this->calculateTotal();
}
```

### Package Deprecation — composer.json

```json
{
    "name": "vendor/old-package",
    "abandoned": "vendor/new-package",
    "description": "[DEPRECATED] Use vendor/new-package instead."
}
```

### UPGRADING.md Entry (Symfony-Style)

```markdown
## UPGRADING FROM 2.x to 3.0

### High Impact

#### `OldProcessor` Removed
**Likelihood of Impact: High**

The `OldProcessor` class, deprecated in 2.3, has been removed.
Use `NewProcessor` instead.

Before:
```php
$processor = new OldProcessor();
```

After:
```php
$processor = new NewProcessor();
```

### Medium Impact

#### `getTotal()` Removed
**Likelihood of Impact: Medium**

The `getTotal()` method, deprecated in 2.5, has been removed.
Use `calculateTotal()` instead.
```

### Rector Rule for Automated Migration (Filament-Style)

```php
// rector.php — shipped with the package upgrade command
use Rector\Config\RectorConfig;
use Rector\Renaming\Rector\Name\RenameClassRector;
use Rector\Renaming\Rector\MethodCall\RenameMethodRector;

return RectorConfig::configure()
    ->withRules([
        RenameClassRector::class,
        RenameMethodRector::class,
    ])
    ->withConfiguredRule(RenameClassRector::class, [
        'Vendor\Package\OldProcessor' => 'Vendor\Package\NewProcessor',
    ])
    ->withConfiguredRule(RenameMethodRector::class, [
        new \Rector\Renaming\ValueObject\MethodCallRename(
            'Vendor\Package\Calculator',
            'getTotal',
            'calculateTotal',
        ),
    ]);
```

### CHANGELOG Entry

```markdown
## 2.3.0

### Deprecated
- `OldProcessor` is deprecated, use `NewProcessor` instead (#142)
- `Calculator::getTotal()` is deprecated, use `calculateTotal()` instead (#143)
```
