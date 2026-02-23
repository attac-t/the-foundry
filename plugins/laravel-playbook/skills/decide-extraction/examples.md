# Package Extraction: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### The Extraction Lifecycle

Eight phases. Each has a clear deliverable.

**1. Identify the seam**
```text
Project code      -> Depends on your domain, your database, your users
Extractable code  -> Depends on Laravel primitives and PHP fundamentals
```
Litmus test: replace every `App\` reference with a generic type. Still makes sense? Extractable.

**2. Evaluate the landscape**
Search Packagist, evaluate alternatives, identify your differentiation. If three packages solve this with 5k+ stars, your DX must be meaningfully better.

**3. Draw boundaries**
```text
IN:  Code that solves the general problem
OUT: Code that solves YOUR specific problem with it
```
Config referencing your table names, hard-coded model classes, app-specific event listeners -- all out.

**4. Decouple**
```php
// App\Models\User -> configurable model or contract
// Hard-coded values -> config('your-package.key') with defaults
// Direct calls -> events (let the host app decide)
// Your User model -> Authenticatable contract
```

**5. Migrate namespace**
```text
Before: App\Support\Feature\FeatureManager
After:  Vendor\Feature\FeatureManager
```
Move classes one by one. Run tests after each move. Green stays green.

**6. Dual-run**
```php
// config/feature.php
'driver' => env('FEATURE_DRIVER', 'internal'), // 'internal' or 'package'
```
Run both side-by-side. Cut over when the package driver passes all tests in staging.

**7. Composerize**
Scaffold with `laravel-package-tools`. Set up `orchestra/testbench`. `composer test` must pass with zero host-app dependencies.

**8. Ship**
README, CI matrix (PHP 8.2+, Laravel 11+), auto-discovery, MIT license, Packagist registered, tag `1.0.0`.

---

### laravel-medialibrary
**Why?** Every client project needed file uploads with conversions. Same logic copy-pasted across projects.
```text
App code:  App\Services\ImageUploader (hard-coded to S3, specific sizes)
Package:   Spatie\MediaLibrary\HasMedia (any disk, any conversion, any model)
```
Extraction signal: the third project that needed it.

### laravel-permission
**Why?** Role-based access control, reimplemented on every project with slight variations.

Extraction signal: the same guard/role/permission tables kept appearing.

### laravel-data
**Why?** Internal DTO classes copy-pasted so often it became a running joke.

Started as simple DTOs. Grew to handle validation, transformation, TypeScript generation -- natural micro-to-macro graduation.

---

## Production Patterns

### Pain-Driven Extraction

**Pest:** Extracted from a *workflow*, not application code. Kept PHPUnit as the engine. Extracted only the DX layer -- immediate access to PHPUnit's entire ecosystem.

**Flysystem:** Core is pure PHP. No framework dependency. Adapters are separate packages. Laravel adopted it as the filesystem driver.

### Framework Extraction

**illuminate/collections:** Tighten built `tightenco/collect` as a standalone, proving demand. Laravel absorbed it. That is success, not failure.

**Laravel Prompts:** Zero dependencies beyond PHP. Works with any CLI app. Ships with first-party Laravel integration.

### Extraction Anti-Patterns

**Premature package:** Wait for the second project. The first tells you the problem exists. The second tells you the generic solution.

**Domain leak:**
```php
// Bad: package knows your domain
public function export(Order $order): Csv

// Good: package works with any data
public function export(Exportable $record): Csv
```

**Kitchen sink:** Extract the smallest useful surface. You can always expand scope. You can never shrink a public API without a breaking change.
