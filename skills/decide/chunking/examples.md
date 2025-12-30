# Chunking: Examples

Real-world examples of chunking decisions.

---

## Laravel Framework

### Illuminate\Database\Eloquent\Builder::chunk()
**Why?** Process large datasets without memory exhaustion.
```php
User::chunk(200, function (Collection $users) {
    foreach ($users as $user) {
        // Process each user
    }
});
```

### Illuminate\Database\Eloquent\Builder::chunkById()
**Why?** Safe when modifying records during iteration.
```php
User::where('active', false)
    ->chunkById(200, function (Collection $users) {
        foreach ($users as $user) {
            $user->delete();  // Safe: uses ID-based pagination
        }
    });
```

### Illuminate\Database\Eloquent\Builder::lazy()
**Why?** Generator-style streaming for exports.
```php
User::lazy()->each(function (User $user) {
    // Memory-efficient: loads one at a time
    $this->exportToFile($user);
});
```

### Illuminate\Database\Eloquent\Builder::cursor()
**Why?** Minimal memory footprint for read-only.
```php
foreach (User::cursor() as $user) {
    // One model in memory at a time
    echo $user->email;
}
```

---

## Vendor Packages

### Spatie Laravel Excel
**Why?** Exports use chunking internally.
```php
use Maatwebsite\Excel\Concerns\FromQuery;

class UsersExport implements FromQuery
{
    public function query()
    {
        return User::query();  // Package chunks automatically
    }
}
```

### Laravel Horizon
**Why?** Batch processing in chunks.
```php
Bus::batch(
    User::cursor()->map(fn ($user) => new ProcessUser($user->id))
)->dispatch();
```

---

## Method Comparison

| Method        | Memory | Modifies Safe | Returns        |
|---------------|--------|---------------|----------------|
| `chunk()`     | Low    | Risky         | void           |
| `chunkById()` | Low    | Safe          | void           |
| `cursor()`    | Lowest | No            | LazyCollection |
| `lazy()`      | Lowest | No            | LazyCollection |
| `lazyById()`  | Low    | Safe          | LazyCollection |

---

## The Offset Bug

### chunk() with Modifications
**Why wrong?** Deleting shifts offsets, skips records.
```php
// Bad: deletes shift offsets
Order::query()->chunk(100, function ($orders) {
    $orders->each->delete();  // Will skip records
});

// Good: ID-based, no offset issues
Order::query()->chunkById(100, function ($orders) {
    $orders->each->delete();  // All records processed
});
```

---

## Anti-Patterns

### get() for Large Datasets
**Why wrong?** Loads everything into memory.
```php
// Bad: memory explosion
$all = Product::all();

// Good: stream it
Product::query()->cursor()->each(...);
```

### cursor() with Modifications
**Why wrong?** Single database cursor can't handle mid-iteration changes.
```php
// Bad: cursor + update
Product::cursor()->each(fn ($p) => $p->update([...]));

// Good: chunkById for updates
Product::chunkById(100, fn ($chunk) => $chunk->each->update([...]));
```
