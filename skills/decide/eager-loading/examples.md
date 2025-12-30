# Eager Loading: Examples

Real-world examples of eager loading decisions.

---

## Laravel Framework

### Illuminate\Database\Eloquent\Builder::with()
**Why?** Prevent N+1 before query execution.
```php
$posts = Post::with('author', 'comments')->get();

// 3 queries total, not 1 + N + N
```

### Illuminate\Database\Eloquent\Model::load()
**Why?** Add relationships after fetching.
```php
$user = User::find(1);

if ($showDetails) {
    $user->load('posts', 'profile');  // Conditional loading
}
```

### Illuminate\Database\Eloquent\Builder::withCount()
**Why?** Count without loading relationship.
```php
$posts = Post::withCount('comments')->get();

$posts->first()->comments_count;  // No comment models loaded
```

### Constrained Eager Load
**Why?** Load subset of relationship.
```php
User::with(['posts' => fn ($query) => $query
    ->where('published', true)
    ->latest()
    ->limit(5)
])->get();
```

---

## Vendor Packages

### Spatie Query Builder
**Why?** API-driven eager loading.
```php
QueryBuilder::for(User::class)
    ->allowedIncludes(['posts', 'profile', 'posts.comments'])
    ->get();

// GET /users?include=posts,profile
```

### Laravel Nova
**Why?** Resource relationships load on demand.
```php
public static $with = ['author'];  // Always eager load
```

---

## Method Comparison

| Method        | When               | Queries         |
|---------------|--------------------|-----------------|
| `with()`      | Before `get()`     | 1 + N relations |
| `load()`      | After `get()`      | N relations     |
| `withCount()` | Need count only    | 1 subquery      |
| `loadCount()` | Count after fetch  | N subqueries    |

---

## Nested Relationships

### Deep Eager Loading
**Why?** Load multiple levels at once.
```php
Order::with([
    'customer.addresses',
    'items.product.category',
    'payments',
])->get();
```

### Model $with Property
**Why?** Always needed relationships.
```php
class Invoice extends Model
{
    protected $with = ['lineItems', 'customer'];
}
```

---

## Anti-Patterns

### N+1 in Loop
**Why wrong?** Each iteration hits database.
```php
// Bad: N+1 queries
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->customer->name;  // Query per order
}

// Good: 2 queries total
$orders = Order::with('customer')->get();
```

### Over-Eager Loading
**Why wrong?** Loading unused relationships wastes memory.
```php
// Bad: loading everything "just in case"
Order::with(['customer', 'items', 'payments', 'shipping', 'notes'])->get();

// Good: only what's needed
Order::with(['customer', 'items'])->get();
```

### withCount() When You Need Data
**Why wrong?** Will query again when accessing relationship.
```php
// Bad: counted but will query again
$posts = Post::withCount('comments')->get();
$posts->first()->comments;  // Extra query

// Good: if you need comments, load them
$posts = Post::with('comments')->get();
```
