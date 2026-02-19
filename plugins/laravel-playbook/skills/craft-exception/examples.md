# Exceptions: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Exception Hierarchy

**Why?** Organized by failure category. The base class enables catch-all, subclasses enable precision.

```
FileCannotBeAdded (abstract)
├── FileIsTooBig
├── MimeTypeNotAllowed
├── FileNameNotAllowed
├── InvalidBase64Data
└── UnreachableUrl

InvalidQuery (abstract, extends HttpException)
├── InvalidFilterQuery
├── InvalidSortQuery
├── InvalidIncludeQuery
└── InvalidAppendQuery
```

### Named Constructors with Context

**Why?** Factory methods encapsulate message formatting and interpolate context.

```php
class FileIsTooBig extends FileCannotBeAdded
{
    public static function create(string $path, ?int $size = null): self
    {
        $fileSize = File::getHumanReadableSize($size ?: filesize($path));
        $maxSize = File::getHumanReadableSize(config('media-library.max_file_size'));

        return new static(
            "File `{$path}` has a size of {$fileSize} which is greater than the maximum allowed {$maxSize}"
        );
    }
}

class UnauthorizedException extends HttpException
{
    public static function forRoles(array $roles): self { /* ... */ }
    public static function forPermissions(array $permissions): self { /* ... */ }
    public static function notLoggedIn(): self { /* ... */ }
}
```

---

## Common Scenarios

### Messages That Teach

```php
// Good -- teaches the developer
"Requested filter(s) `status, type` are not allowed. Allowed filter(s) are `name, email`."
"File has a mime type of application/pdf, while only image/jpeg, image/png are allowed."
"There is no permission named `edit articles` for guard `web`."

// Bad -- tells you nothing
"Invalid input"
"Permission error"
"File too large"
```

### Precise Catch Blocks

```php
try {
    $model->addMedia($file)->toMediaCollection();
} catch (FileIsTooBig $e) {
    // handle size limit
} catch (MimeTypeNotAllowed $e) {
    // handle wrong type
} catch (FileCannotBeAdded $e) {
    // catch-all for file issues
}
```

### Configurable Verbosity

Security-sensitive packages control context exposure:

```php
class UnauthorizedException extends HttpException
{
    public static function forRoles(array $roles): self
    {
        $message = 'User does not have the right roles.';

        if (config('permission.display_role_in_exception')) {
            $message .= ' Necessary roles are '.implode(', ', $roles).'.';
        }

        return new static(403, $message);
    }
}
```

### Wrapping Vendor Exceptions (Cashier Pattern)

When your package wraps a third-party service, catch vendor exceptions and re-throw as your own:

```php
class PaymentFailedException extends CashierException
{
    public static function fromStripe(StripeException $e): self
    {
        return new static(
            "Payment failed: {$e->getMessage()}",
            $e->getCode(),
            $e
        );
    }
}

// In your service class
try {
    $stripe->charges->create($params);
} catch (StripeException $e) {
    throw PaymentFailedException::fromStripe($e);
}
```

Consumers catch `PaymentFailedException`, not `StripeException`. Your exception hierarchy is the contract.
