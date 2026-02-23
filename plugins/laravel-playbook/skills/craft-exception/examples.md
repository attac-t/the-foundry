# Exceptions: Examples

Patterns from the framework and production code.

---

## The Pattern

### Exception Hierarchy

**Why?** Organized by failure category. Base class enables catch-all, subclasses enable precision.

```text
FileCannotBeAdded (abstract)
├── FileIsTooBig
├── MimeTypeNotAllowed
├── FileNameNotAllowed
└── UnreachableUrl

InvalidQuery (abstract, extends HttpException)
├── InvalidFilterQuery
├── InvalidSortQuery
└── InvalidIncludeQuery
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

        return new static("File `{$path}` has a size of {$fileSize} which is greater than the maximum allowed {$maxSize}");
    }
}
```

Multiple named constructors per exception for different failure contexts:

```php
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
// Good -- teaches the fix
"Requested filter(s) `status, type` are not allowed. Allowed filter(s) are `name, email`."
"File has a mime type of application/pdf, while only image/jpeg, image/png are allowed."

// Bad -- tells you nothing
"Invalid input"
"Permission error"
```

### Precise Catch Blocks

```php
try {
    $model->addMedia($file)->toMediaCollection();
} catch (FileIsTooBig $e) {
    // handle size limit
} catch (FileCannotBeAdded $e) {
    // catch-all for file issues
}
```

### Configurable Verbosity
**Why?** Security-sensitive packages control context exposure.

```php
public static function forRoles(array $roles): self
{
    $message = 'User does not have the right roles.';

    if (config('permission.display_role_in_exception')) {
        $message .= ' Necessary roles are '.implode(', ', $roles).'.';
    }

    return new static(403, $message);
}
```

### Wrapping Vendor Exceptions (Cashier Pattern)
**Why?** Consumers catch your exceptions, not the vendor's. Your hierarchy is the contract.

```php
class IncompletePayment extends CashierException
{
    public Stripe\PaymentIntent $payment;

    public static function create(Stripe\PaymentIntent $payment): self
    {
        $exception = new static("The payment attempt for subscription failed.");
        $exception->payment = $payment;

        return $exception;
    }
}

// In your service class
try {
    $stripeSubscription = $user->createStripeSubscription($params);
} catch (StripeException $e) {
    throw IncompletePayment::create($stripeSubscription->latestPayment());
}
```
