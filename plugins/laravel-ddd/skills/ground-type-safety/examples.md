# Type Safety: Examples

Patterns for catching bugs before runtime.

---

## Arrays vs DTOs

### ❌ Array: Runtime Errors
```php
function createUser(array $data): User
{
    // Typo: 'emial' instead of 'email'
    // Fails silently or at runtime
    return User::create([
        'name' => $data['name'],
        'email' => $data['emial'],  // Bug!
    ]);
}
```

### ✅ DTO: Compile Time Error
```php
function createUser(CreateUserData $data): User
{
    // IDE catches typo immediately
    return User::create([
        'name' => $data->name,
        'email' => $data->emial,  // IDE: Property does not exist
    ]);
}
```

---

## Return Types

### ❌ Unclear Return
```php
function findUser($id)
{
    // Returns User? null? throws? Who knows.
    return User::find($id);
}
```

### ✅ Explicit Contract
```php
function findUser(int $id): ?User
{
    return User::find($id);
}

function getUser(int $id): User
{
    return User::findOrFail($id);
}
```

---

## Collection Types

### ❌ Generic Collection
```php
/** @var Collection */
public Collection $items;

// What's in the collection? Anything.
foreach ($items as $item) {
    $item->???  // No autocomplete
}
```

### ✅ Typed Collection
```php
/** @var Collection<int, InvoiceLine> */
public Collection $lines;

// IDE knows the type
foreach ($lines as $line) {
    $line->price;  // Autocomplete works
}
```

---

## Strict Types

### ✅ Every File
```php
<?php

declare(strict_types=1);

namespace Domain\Invoicing\Actions;

// Now PHP enforces types strictly
// "1" won't silently become 1
```

---

## The Investment

```
Time to write types:        +10%
Time debugging type bugs:   -90%
Time onboarding new devs:   -50%
Confidence in refactoring:  +500%
```
