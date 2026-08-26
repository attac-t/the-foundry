# Null Object: Examples

Patterns for safe defaults.

---

## The Problem

### ❌ Null Checks Everywhere
**Why?** Repetitive. Easy to miss one. Bugs hide.
```php
$logo = $job->company
    ? ($job->company->profile
        ? $job->company->profile->logo
        : asset('default.png'))
    : asset('default.png');
```

---

## Laravel's `withDefault()`

### ✅ Basic Usage
**Why?** Relationship always returns an object. Never null.
```php
public function company(): BelongsTo
{
    return $this->belongsTo(Company::class)->withDefault();
}

// Now this never fails
$name = $job->company->name;  // '' if no company
```

### ✅ With Default Values
**Why?** Meaningful defaults, not empty strings.
```php
public function author(): BelongsTo
{
    return $this->belongsTo(User::class)->withDefault([
        'name' => 'Guest Author',
        'email' => 'guest@example.com',
    ]);
}
```

### ✅ With Closure
**Why?** Dynamic defaults based on parent.
```php
public function company(): BelongsTo
{
    return $this->belongsTo(Company::class)->withDefault(function (Company $company, Job $job) {
        $company->name = 'Unknown Company';
        $company->logo = asset('default-company.png');
    });
}
```

---

## Custom Null Objects

### ✅ NullUser Class
**Why?** Complex behavior beyond simple defaults.
```php
class NullUser extends User
{
    public function __construct()
    {
        $this->name = 'Guest';
        $this->email = 'guest@example.com';
    }

    public function isGuest(): bool
    {
        return true;
    }

    public function can(string $ability): bool
    {
        return false;  // Guests can't do anything
    }
}
```

### ✅ Usage Pattern
```php
public function currentUser(): User
{
    return auth()->user() ?? new NullUser();
}

// No null checks needed
$user = $this->currentUser();
$user->name;        // 'Guest' if not logged in
$user->isGuest();   // true if not logged in
$user->can('edit'); // false if not logged in
```

---

## `optional()` Helper

### When to Use
**One-off access**: When you access a potentially null object once.
```php
// Good: Single access
$city = optional($user->address)->city;
```

### When NOT to Use
**Repeated access**: Use null object instead.
```php
// Bad: Multiple optional() calls
$city = optional($user->address)->city;
$zip = optional($user->address)->zip;
$country = optional($user->address)->country;

// Good: withDefault() once
public function address(): HasOne
{
    return $this->hasOne(Address::class)->withDefault();
}
```

---

## Decision Table

| Scenario                  | Pattern             |
| ------------------------- | ------------------- |
| Single null check         | Just check          |
| Same null check 3+ places | Null object         |
| Eloquent relationship     | `withDefault()`     |
| Complex null behavior     | Custom Null class   |
| One-off optional access   | `optional()` helper |

---

## When NOT to Use

### ❌ Masking Meaningful Null
**Why?** Sometimes null carries domain meaning.
```php
// Bad: Hiding that subscription doesn't exist
public function subscription(): HasOne
{
    return $this->hasOne(Subscription::class)->withDefault([
        'plan' => 'free',
    ]);
}

// Good: Null means "no subscription" - handle explicitly
if (! $user->subscription) {
    return 'Please subscribe';
}
```

### ❌ Hiding Errors
**Why?** Null object shouldn't silence bugs.
```php
// Bad: Masking a broken relationship
public function manager(): BelongsTo
{
    return $this->belongsTo(User::class)->withDefault();
}
// If manager_id is set but user doesn't exist, you want to know!

// Good: Only use withDefault when null is expected
public function assignedManager(): BelongsTo
{
    return $this->belongsTo(User::class, 'assigned_manager_id')->withDefault();
}
// This column is nullable by design
```

### ❌ Everywhere
**Why?** Not everything needs a null object.
```php
// Bad: Null object for ephemeral data
class NullApiResponse extends ApiResponse { ... }

// Good: Just handle the null case
if (! $response) {
    throw new ApiException('No response received');
}
```
