# DTO: Examples

Patterns from Spatie Laravel Data v4.

---

## Two Types of DTOs

### ✅ Input DTO (Create/Update)
**Why?** Validation, type-safe request handling.
```php
class CreatePostData extends Data
{
    public function __construct(
        #[Required, Max(255)]
        public string $title,
        #[Required]
        public string $body,
    ) {}
}
```

### ✅ Output DTO (Model Representation)
**Why?** Decouple DB schema from API. Include relationships conditionally.
```php
class PostData extends Data
{
    public function __construct(
        public string $id,
        public string $title,
        #[AutoWhenLoadedLazy]
        public Collection $comments,  // Native Collection, not DataCollection
    ) {}
}
```

---

## Native Collection (v4 Way)

### ✅ Prefer Collection over DataCollection
```php
// ✅ v4 preferred
public Collection $items,

// ❌ Old way
public DataCollection $items,
```

### ✅ Access via all()
```php
$items = $data->all();  // Returns array of typed items
```

---

## Lazy Loading

### ✅ AutoWhenLoadedLazy
**Why?** Only serialize if relation was loaded on model.
```php
#[AutoWhenLoadedLazy]
public Collection $comments,
```

---

## Immutability

### ✅ Mutate via with()
```php
// ❌ Don't mutate directly
$data->status = 'paid';

// ✅ Create new instance
$data = $data->with(status: 'paid');
```

---

## From Model

### ✅ Explicit Mapping
```php
public static function fromModel(Order $order): self
{
    return new self(
        id: $order->ulid,
        total: MoneyData::from($order->total),
        items: $order->relationLoaded('items')
            ? $order->items->map(fn ($i) => ItemData::from($i))
            : collect(),
    );
}
```
